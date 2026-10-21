-- ==============================================================================
-- FAUNOVA MIGRATION 009: Shake-to-Quiz (Goyang HP Sensor Accelerometer)
-- Sesuai Plan 5.8 (190-196, 440) & AGENTS.md (Sesi S15)
-- Aturan Keras:
-- 1. Kuota 3x per hari dihitung di server berbasis tanggal WIB (wib_today()).
-- 2. Kunci jawaban TIDAK PERNAH dikirim ke klien saat klaim soal kejutan.
-- 3. Jawaban dan status benar/salah divalidasi langsung oleh server database.
-- ==============================================================================

-- 1. TABEL SHAKE_LOG (Plan 440)
CREATE TABLE IF NOT EXISTS public.shake_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date_wib DATE NOT NULL,
    question_id UUID NOT NULL REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'claimed' CHECK (status IN ('claimed', 'answered', 'expired')),
    selected_option SMALLINT CHECK (selected_option BETWEEN 0 AND 3),
    is_correct BOOLEAN,
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    answered_at TIMESTAMPTZ,
    idempotency_key UUID NOT NULL,
    CONSTRAINT uq_shake_log_user_idempotency UNIQUE (user_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_shake_log_user_date ON public.shake_log(user_id, date_wib);

ALTER TABLE public.shake_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna hanya dapat melihat riwayat shake miliknya"
    ON public.shake_log FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- 2. RPC GET_SHAKE_QUOTA
-- Mengambil kuota shake harian pengguna (Maks 3 kali per hari WIB)
CREATE OR REPLACE FUNCTION public.get_shake_quota()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_today DATE;
    v_used_count INT;
    v_max_quota INT := 3;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk memeriksa kuota goyang HP.';
    END IF;

    v_today := public.wib_today();

    SELECT COUNT(*)
    INTO v_used_count
    FROM public.shake_log
    WHERE user_id = v_user_id AND date_wib = v_today;

    RETURN jsonb_build_object(
        'success', true,
        'used_quota', v_used_count,
        'max_quota', v_max_quota,
        'remaining_quota', GREATEST(0, v_max_quota - v_used_count),
        'date_wib', v_today
    );
END;
$$;

-- 3. RPC CLAIM_SHAKE_QUIZ (Plan 192, Hard Rule 5)
-- Mengklaim 1 soal kejutan baru berdasarkan sensor goyang HP
CREATE OR REPLACE FUNCTION public.claim_shake_quiz(
    p_idempotency_key UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_today DATE;
    v_used_count INT;
    v_existing RECORD;
    v_question RECORD;
    v_claim_id UUID;
    v_max_quota INT := 3;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk mengklaim kuis goyang HP.';
    END IF;

    IF p_idempotency_key IS NULL THEN
        RAISE EXCEPTION 'Idempotency key wajib disertakan.';
    END IF;

    v_today := public.wib_today();

    -- Kunci baris jika sudah pernah ada request dengan idempotency_key yang sama
    SELECT * INTO v_existing
    FROM public.shake_log
    WHERE user_id = v_user_id AND idempotency_key = p_idempotency_key;

    IF FOUND THEN
        -- Kembalikan soal yang sama
        SELECT id, category, question, options INTO v_question
        FROM public.quiz_questions
        WHERE id = v_existing.question_id;

        SELECT COUNT(*) INTO v_used_count
        FROM public.shake_log
        WHERE user_id = v_user_id AND date_wib = v_today;

        RETURN jsonb_build_object(
            'success', true,
            'claim_id', v_existing.id,
            'question_id', v_question.id,
            'category', v_question.category,
            'question', v_question.question,
            'options', v_question.options,
            'remaining_quota', GREATEST(0, v_max_quota - v_used_count),
            'already_answered', (v_existing.status = 'answered'),
            'message', 'Kuis goyang HP berhasil dipulihkan.'
        );
    END IF;

    -- Hitung kuota yang sudah dipakai hari ini
    SELECT COUNT(*)
    INTO v_used_count
    FROM public.shake_log
    WHERE user_id = v_user_id AND date_wib = v_today;

    IF v_used_count >= v_max_quota THEN
        RETURN jsonb_build_object(
            'success', false,
            'quota_exceeded', true,
            'used_quota', v_used_count,
            'max_quota', v_max_quota,
            'remaining_quota', 0,
            'message', 'Kuota goyang HP harian kamu sudah habis (3/3). Kuota diperbarui kembali besok pukul 00:00 WIB.'
        );
    END IF;

    -- Ambil 1 soal acak dari bank soal aktif
    SELECT id, category, question, options
    INTO v_question
    FROM public.quiz_questions
    WHERE is_active = true
    ORDER BY random()
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Bank soal belum memiliki pertanyaan aktif.';
    END IF;

    -- Catat klaim baru ke tabel shake_log
    INSERT INTO public.shake_log (
        user_id,
        date_wib,
        question_id,
        status,
        claimed_at,
        idempotency_key
    ) VALUES (
        v_user_id,
        v_today,
        v_question.id,
        'claimed',
        now(),
        p_idempotency_key
    )
    RETURNING id INTO v_claim_id;

    RETURN jsonb_build_object(
        'success', true,
        'claim_id', v_claim_id,
        'question_id', v_question.id,
        'category', v_question.category,
        'question', v_question.question,
        'options', v_question.options,
        'remaining_quota', GREATEST(0, v_max_quota - (v_used_count + 1)),
        'already_answered', false,
        'message', 'Soal kejutan berhasil ditemukan dari goyangan HP!'
    );
END;
$$;

-- 4. RPC ANSWER_SHAKE_QUIZ (Plan 193)
-- Menjawab kuis goyang HP dan mengevaluasi kebenaran di server
CREATE OR REPLACE FUNCTION public.answer_shake_quiz(
    p_claim_id UUID,
    p_selected_option INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_claim RECORD;
    v_question RECORD;
    v_is_correct BOOLEAN;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk menjawab kuis goyang HP.';
    END IF;

    IF p_selected_option IS NULL OR p_selected_option < 0 OR p_selected_option > 3 THEN
        RAISE EXCEPTION 'Pilihan jawaban tidak valid. Harus antara 0 sampai 3.';
    END IF;

    -- Kunci baris klaim
    SELECT * INTO v_claim
    FROM public.shake_log
    WHERE id = p_claim_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Klaim kuis goyang HP tidak ditemukan.';
    END IF;

    IF v_claim.user_id <> v_user_id THEN
        RAISE EXCEPTION 'Akses ditolak: Klaim ini bukan milik Anda.';
    END IF;

    IF v_claim.status = 'answered' THEN
        RAISE EXCEPTION 'Kuis goyang HP ini sudah pernah dijawab sebelumnya.';
    END IF;

    -- Ambil data pertanyaan dan kunci jawaban asli dari bank soal
    SELECT * INTO v_question
    FROM public.quiz_questions
    WHERE id = v_claim.question_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Soal kuis tidak ditemukan.';
    END IF;

    v_is_correct := (p_selected_option = v_question.correct_option);

    -- Perbarui baris klaim
    UPDATE public.shake_log
    SET status = 'answered',
        selected_option = p_selected_option,
        is_correct = v_is_correct,
        answered_at = now()
    WHERE id = p_claim_id;

    RETURN jsonb_build_object(
        'success', true,
        'claim_id', p_claim_id,
        'question_id', v_question.id,
        'selected_option', p_selected_option,
        'is_correct', v_is_correct,
        'correct_option', v_question.correct_option,
        'explanation', v_question.explanation,
        'message', CASE 
            WHEN v_is_correct THEN 'Hebat! Jawabanmu benar. Progres lencana Si Goyang bertambah.'
            ELSE 'Jawabanmu kurang tepat. Pelajari pembahasannya!'
        END
    );
END;
$$;

-- Izin eksekusi RPC
GRANT EXECUTE ON FUNCTION public.get_shake_quota() TO authenticated;
GRANT EXECUTE ON FUNCTION public.claim_shake_quiz(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.answer_shake_quiz(UUID, INT) TO authenticated;
