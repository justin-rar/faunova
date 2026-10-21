-- ==============================================================================
-- FAUNOVA MIGRATION 008: Streak Check-in & Tantangan Hari Ini (Plan 5.8 & Sesi S14)
-- Aturan Keras:
-- 1. Kuota dan streak HANYA diubah lewat RPC server (auth.uid()).
-- 2. Menggunakan tanggal WIB resmi (Asia/Jakarta) dari waktu server.
-- 3. Klaim ganda streak pada hari WIB yang sama ditolak (idempotensi).
-- 4. Kunci jawaban Tantangan Hari Ini TIDAK PERNAH dikirim ke klien sebelum dijawab.
-- ==============================================================================

-- 1. HELPER: TANGGAL RESMI WIB SERVER (Asia/Jakarta)
CREATE OR REPLACE FUNCTION public.wib_today()
RETURNS DATE
LANGUAGE sql
STABLE
AS $$
    SELECT (now() AT TIME ZONE 'Asia/Jakarta')::DATE;
$$;

-- 2. TABEL LOG TANTANGAN HARI INI (daily_challenge_log)
CREATE TABLE IF NOT EXISTS public.daily_challenge_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    challenge_date DATE NOT NULL,
    question_id UUID NOT NULL REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
    selected_option SMALLINT CHECK (selected_option BETWEEN 0 AND 3),
    is_correct BOOLEAN NOT NULL DEFAULT false,
    answered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_daily_challenge_user_date UNIQUE (user_id, challenge_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_challenge_user_date ON public.daily_challenge_log(user_id, challenge_date);

ALTER TABLE public.daily_challenge_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna hanya dapat melihat riwayat tantangan miliknya"
    ON public.daily_challenge_log FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- 3. RPC CLAIM_DAILY_STREAK (Plan 168-170, 543)
-- Memproses check-in streak harian berbasis tanggal WIB server
CREATE OR REPLACE FUNCTION public.claim_daily_streak()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_current_streak INT;
    v_last_claim DATE;
    v_today DATE;
    v_new_streak INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk melakukan check-in streak.';
    END IF;

    v_today := public.wib_today();

    -- Kunci baris profil untuk mencegah race condition / klaim paralel
    SELECT streak_count, last_streak_claim_date
    INTO v_current_streak, v_last_claim
    FROM public.profiles
    WHERE id = v_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profil pengguna tidak ditemukan.';
    END IF;

    v_current_streak := COALESCE(v_current_streak, 0);

    -- Pengecekan Idempotensi / Klaim Ganda pada hari WIB yang sama
    IF v_last_claim IS NOT NULL AND v_last_claim = v_today THEN
        RETURN jsonb_build_object(
            'success', true,
            'already_claimed', true,
            'is_new_claim', false,
            'streak_count', v_current_streak,
            'last_streak_claim_date', v_last_claim,
            'wib_today', v_today,
            'message', 'Kamu sudah melakukan check-in streak hari ini. Kembali lagi besok!'
        );
    END IF;

    -- Evaluasi kelanjutan streak
    IF v_last_claim IS NOT NULL AND v_last_claim = (v_today - 1) THEN
        -- Check-in kemarin, streak berlanjut (+1)
        v_new_streak := v_current_streak + 1;
    ELSE
        -- Pertama kali atau terlewat lebih dari 1 hari, reset ke 1 (Plan 169)
        v_new_streak := 1;
    END IF;

    -- Perbarui profil secara atomik di server
    UPDATE public.profiles
    SET streak_count = v_new_streak,
        last_streak_claim_date = v_today,
        updated_at = now()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'already_claimed', false,
        'is_new_claim', true,
        'streak_count', v_new_streak,
        'last_streak_claim_date', v_today,
        'wib_today', v_today,
        'message', 'Check-in berhasil! Streak observasi kamu kini ' || v_new_streak || ' hari berturut-turut.'
    );
END;
$$;

-- 4. RPC GET_STREAK_STATUS
-- Mengambil status streak pengguna saat ini dan apakah sudah check-in hari ini
CREATE OR REPLACE FUNCTION public.get_streak_status()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_current_streak INT;
    v_last_claim DATE;
    v_today DATE;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk melihat status streak.';
    END IF;

    v_today := public.wib_today();

    SELECT streak_count, last_streak_claim_date
    INTO v_current_streak, v_last_claim
    FROM public.profiles
    WHERE id = v_user_id;

    v_current_streak := COALESCE(v_current_streak, 0);

    RETURN jsonb_build_object(
        'success', true,
        'streak_count', v_current_streak,
        'last_streak_claim_date', v_last_claim,
        'is_claimed_today', (v_last_claim IS NOT NULL AND v_last_claim = v_today),
        'wib_today', v_today
    );
END;
$$;

-- 5. RPC GET_DAILY_CHALLENGE (Plan 198, Hard Rule 5)
-- Mengambil 1 soal tantangan hari ini seragam untuk seluruh pengguna berdasarkan tanggal WIB
CREATE OR REPLACE FUNCTION public.get_daily_challenge()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_today DATE;
    v_question RECORD;
    v_log RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk mengakses Tantangan Hari Ini.';
    END IF;

    v_today := public.wib_today();

    -- Pilih 1 soal deterministik berdasarkan tanggal WIB dari bank soal aktif
    SELECT id, category, question, options, correct_option, explanation
    INTO v_question
    FROM public.quiz_questions
    WHERE is_active = true
    ORDER BY md5(id::text || v_today::text)
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Bank soal belum memiliki pertanyaan aktif.';
    END IF;

    -- Cek apakah pengguna sudah menjawab tantangan hari ini
    SELECT * INTO v_log
    FROM public.daily_challenge_log
    WHERE user_id = v_user_id AND challenge_date = v_today;

    IF FOUND THEN
        -- Pengguna sudah menjawab: tampilkan jawaban dan pembahasan edukatif
        RETURN jsonb_build_object(
            'success', true,
            'challenge_date', v_today,
            'question_id', v_question.id,
            'category', v_question.category,
            'question', v_question.question,
            'options', v_question.options,
            'already_answered', true,
            'selected_option', v_log.selected_option,
            'is_correct', v_log.is_correct,
            'correct_option', v_question.correct_option,
            'explanation', v_question.explanation
        );
    ELSE
        -- Pengguna BELUM menjawab: KUNCI JAWABAN (correct_option) DAN PEMBAHASAN HARUS DIRAHASIAKAN (Hard Rule 5)
        RETURN jsonb_build_object(
            'success', true,
            'challenge_date', v_today,
            'question_id', v_question.id,
            'category', v_question.category,
            'question', v_question.question,
            'options', v_question.options,
            'already_answered', false,
            'selected_option', NULL,
            'is_correct', NULL,
            'correct_option', NULL,
            'explanation', NULL
        );
    END IF;
END;
$$;

-- 6. RPC ANSWER_DAILY_CHALLENGE (Plan 199)
-- Mengirim jawaban tantangan harian dan memvalidasi kebenaran di server
CREATE OR REPLACE FUNCTION public.answer_daily_challenge(
    p_selected_option INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_today DATE;
    v_question RECORD;
    v_is_correct BOOLEAN;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk menjawab Tantangan Hari Ini.';
    END IF;

    IF p_selected_option IS NULL OR p_selected_option < 0 OR p_selected_option > 3 THEN
        RAISE EXCEPTION 'Pilihan jawaban tidak valid. Harus bernilai antara 0 sampai 3.';
    END IF;

    v_today := public.wib_today();

    -- Tolak jika sudah dijawab hari ini (idempotensi)
    IF EXISTS (
        SELECT 1 FROM public.daily_challenge_log
        WHERE user_id = v_user_id AND challenge_date = v_today
    ) THEN
        RAISE EXCEPTION 'Tantangan hari ini sudah dijawab. Tantangan berikutnya tersedia pukul 00:00 WIB.';
    END IF;

    -- Ambil soal deterministik hari ini
    SELECT id, category, question, options, correct_option, explanation
    INTO v_question
    FROM public.quiz_questions
    WHERE is_active = true
    ORDER BY md5(id::text || v_today::text)
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Soal tantangan tidak ditemukan.';
    END IF;

    v_is_correct := (p_selected_option = v_question.correct_option);

    -- Simpan jawaban ke log
    INSERT INTO public.daily_challenge_log (
        user_id,
        challenge_date,
        question_id,
        selected_option,
        is_correct,
        answered_at
    ) VALUES (
        v_user_id,
        v_today,
        v_question.id,
        p_selected_option,
        v_is_correct,
        now()
    );

    RETURN jsonb_build_object(
        'success', true,
        'challenge_date', v_today,
        'question_id', v_question.id,
        'selected_option', p_selected_option,
        'is_correct', v_is_correct,
        'correct_option', v_question.correct_option,
        'explanation', v_question.explanation,
        'points_earned', CASE WHEN v_is_correct THEN 50 ELSE 0 END,
        'message', CASE 
            WHEN v_is_correct THEN 'Luar biasa! Jawabanmu benar (+50 Poin).'
            ELSE 'Jawabanmu kurang tepat. Pelajari pembahasannya untuk menambah wawasan!'
        END
    );
END;
$$;

-- Izin eksekusi RPC
GRANT EXECUTE ON FUNCTION public.wib_today() TO authenticated;
GRANT EXECUTE ON FUNCTION public.claim_daily_streak() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_streak_status() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_daily_challenge() TO authenticated;
GRANT EXECUTE ON FUNCTION public.answer_daily_challenge(INT) TO authenticated;
