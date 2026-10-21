-- ==============================================================================
-- FAUNOVA MIGRATION 007: Sistem Kuis Biologi Satwa Liar (Plan 5.8 & AGENTS.md Sesi S13)
-- Aturan Keras:
-- 1. Kunci jawaban (correct_option) TIDAK PERNAH dikirim ke klien.
-- 2. Skor kuis dihitung ulang secara deterministik di server.
-- 3. profiles.best_quiz_score diperbarui konsisten di server.
-- ==============================================================================

-- 1. TABEL BANK SOAL KUIS (quiz_questions)
CREATE TABLE IF NOT EXISTS public.quiz_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category TEXT NOT NULL,
    question TEXT NOT NULL,
    options JSONB NOT NULL,
    correct_option SMALLINT NOT NULL CHECK (correct_option BETWEEN 0 AND 3),
    explanation TEXT DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_quiz_questions_active ON public.quiz_questions(is_active) WHERE is_active = true;
CREATE UNIQUE INDEX IF NOT EXISTS idx_quiz_questions_question ON public.quiz_questions(question);

ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

-- Klien TIDAK DIBERI izin SELECT langsung pada tabel quiz_questions agar correct_option tidak bocor
-- Hanya RPC SECURITY DEFINER yang dapat membaca bank soal

-- 2. TABEL SESI KUIS (quiz_sessions)
CREATE TABLE IF NOT EXISTS public.quiz_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    question_ids UUID[] NOT NULL,
    status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'expired', 'abandoned')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at TIMESTAMPTZ,
    score INT DEFAULT 0,
    correct_count INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_quiz_sessions_user_finished ON public.quiz_sessions(user_id, finished_at DESC);

ALTER TABLE public.quiz_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna hanya dapat melihat sesi kuis miliknya sendiri"
    ON public.quiz_sessions FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- 3. TABEL JAWABAN KUIS (quiz_answers)
CREATE TABLE IF NOT EXISTS public.quiz_answers (
    session_id UUID NOT NULL REFERENCES public.quiz_sessions(id) ON DELETE CASCADE,
    question_id UUID NOT NULL REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
    selected_option SMALLINT CHECK (selected_option BETWEEN 0 AND 3 OR selected_option IS NULL),
    elapsed_ms_client INT DEFAULT 0,
    is_correct BOOLEAN NOT NULL DEFAULT false,
    server_received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (session_id, question_id)
);

ALTER TABLE public.quiz_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna dapat melihat jawaban sesi miliknya"
    ON public.quiz_answers FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.quiz_sessions s
            WHERE s.id = quiz_answers.session_id AND s.user_id = auth.uid()
        )
    );

-- 4. RPC START_QUIZ_SESSION
-- Memulai sesi kuis baru dan mengembalikan 10 soal TANPA KUNCI JAWABAN (correct_option)
CREATE OR REPLACE FUNCTION public.start_quiz_session()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_session_id UUID;
    v_q_ids UUID[];
    v_questions JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk memulai kuis.';
    END IF;

    -- Batalkan sesi in_progress lama yang belum selesai jika lebih dari 10 menit
    UPDATE public.quiz_sessions
    SET status = 'abandoned', finished_at = now()
    WHERE user_id = v_user_id 
      AND status = 'in_progress'
      AND started_at < now() - INTERVAL '10 minutes';

    -- Ambil 10 soal acak dari bank soal aktif
    SELECT array_agg(q.id),
           jsonb_agg(
               jsonb_build_object(
                   'id', q.id,
                   'category', q.category,
                   'question', q.question,
                   'options', q.options
                   -- KUNCI JAWABAN (correct_option) SENGAJA TIDAK DISERTAKAN!
               )
           )
    INTO v_q_ids, v_questions
    FROM (
        SELECT id, category, question, options
        FROM public.quiz_questions
        WHERE is_active = true
        ORDER BY random()
        LIMIT 10
    ) q;

    IF v_q_ids IS NULL OR array_length(v_q_ids, 1) < 1 THEN
        RAISE EXCEPTION 'Bank soal belum mencukupi. Hubungi kurator.';
    END IF;

    -- Simpan sesi baru
    INSERT INTO public.quiz_sessions (user_id, question_ids, status, started_at)
    VALUES (v_user_id, v_q_ids, 'in_progress', now())
    RETURNING id INTO v_session_id;

    RETURN jsonb_build_object(
        'success', true,
        'session_id', v_session_id,
        'total_questions', array_length(v_q_ids, 1),
        'questions', v_questions
    );
END;
$$;

-- 5. RPC FINISH_QUIZ_SESSION
-- Memvalidasi jawaban, menghitung skor di server, dan memperbarui best_quiz_score
CREATE OR REPLACE FUNCTION public.finish_quiz_session(
    p_session_id UUID,
    p_answers JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_session RECORD;
    v_answer RECORD;
    v_question RECORD;
    v_q_id UUID;
    v_selected_opt INT;
    v_elapsed_ms INT;
    v_is_correct BOOLEAN;
    v_total_score INT := 0;
    v_correct_count INT := 0;
    v_combo INT := 0;
    v_max_combo INT := 0;
    v_base_points INT := 100;
    v_combo_bonus INT := 25;
    v_speed_bonus INT := 0;
    v_old_best INT := 0;
    v_new_best INT := 0;
    v_summary JSONB := '[]'::JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk menyelesaikan kuis.';
    END IF;

    -- Kunci sesi agar tidak bisa di-submit ganda
    SELECT * INTO v_session
    FROM public.quiz_sessions
    WHERE id = p_session_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesi kuis tidak ditemukan.';
    END IF;

    IF v_session.user_id <> v_user_id THEN
        RAISE EXCEPTION 'Akses ditolak: Anda bukan pemilik sesi kuis ini.';
    END IF;

    IF v_session.status <> 'in_progress' THEN
        RAISE EXCEPTION 'Sesi kuis ini sudah selesai atau kedaluwarsa.';
    END IF;

    -- Iterasi setiap jawaban yang dikirim klien
    FOR v_answer IN SELECT * FROM jsonb_to_recordset(p_answers) AS x(
        question_id UUID,
        selected_option INT,
        elapsed_ms INT
    )
    LOOP
        v_q_id := v_answer.question_id;
        v_selected_opt := v_answer.selected_option;
        v_elapsed_ms := COALESCE(v_answer.elapsed_ms, 0);

        -- Periksa apakah question_id termasuk dalam soal sesi
        IF NOT (v_q_id = ANY(v_session.question_ids)) THEN
            RAISE EXCEPTION 'ID soal % tidak terdaftar pada sesi ini.', v_q_id;
        END IF;

        -- Ambil kunci jawaban asli dari bank soal
        SELECT * INTO v_question
        FROM public.quiz_questions
        WHERE id = v_q_id;

        IF FOUND THEN
            IF v_selected_opt IS NOT NULL AND v_selected_opt = v_question.correct_option THEN
                v_is_correct := true;
                v_correct_count := v_correct_count + 1;
                v_combo := v_combo + 1;
                IF v_combo > v_max_combo THEN
                    v_max_combo := v_combo;
                END IF;

                -- Speed bonus jika dijawab cepat (< 8 detik)
                IF v_elapsed_ms > 0 AND v_elapsed_ms < 8000 THEN
                    v_speed_bonus := ROUND((8000 - v_elapsed_ms) / 100.0);
                ELSE
                    v_speed_bonus := 0;
                END IF;

                v_total_score := v_total_score + v_base_points + (v_combo * v_combo_bonus) + v_speed_bonus;
            ELSE
                v_is_correct := false;
                v_combo := 0;
            END IF;

            -- Simpan ke riwayat jawaban
            INSERT INTO public.quiz_answers (
                session_id, question_id, selected_option, elapsed_ms_client, is_correct, server_received_at
            ) VALUES (
                p_session_id, v_q_id, v_selected_opt, v_elapsed_ms, v_is_correct, now()
            )
            ON CONFLICT (session_id, question_id) DO NOTHING;

            -- Rekap penjelasan untuk edukasi pengguna
            v_summary := v_summary || jsonb_build_object(
                'question_id', v_q_id,
                'question', v_question.question,
                'selected_option', v_selected_opt,
                'correct_option', v_question.correct_option,
                'is_correct', v_is_correct,
                'explanation', v_question.explanation
            );
        END IF;
    END LOOP;

    -- Update sesi kuis menjadi selesai
    UPDATE public.quiz_sessions
    SET status = 'completed',
        finished_at = now(),
        score = v_total_score,
        correct_count = v_correct_count
    WHERE id = p_session_id;

    -- Update skor tertinggi di profil pengguna secara atomik (Plan 186)
    SELECT COALESCE(best_quiz_score, 0) INTO v_old_best
    FROM public.profiles
    WHERE id = v_user_id;

    v_new_best := GREATEST(v_old_best, v_total_score);

    UPDATE public.profiles
    SET best_quiz_score = v_new_best,
        updated_at = now()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'session_id', p_session_id,
        'score', v_total_score,
        'correct_count', v_correct_count,
        'max_combo', v_max_combo,
        'previous_best', v_old_best,
        'best_quiz_score', v_new_best,
        'is_new_best', (v_total_score > v_old_best),
        'answers_summary', v_summary
    );
END;
$$;

-- Izin eksekusi RPC
GRANT EXECUTE ON FUNCTION public.start_quiz_session() TO authenticated;
GRANT EXECUTE ON FUNCTION public.finish_quiz_session(UUID, JSONB) TO authenticated;

-- ==============================================================================
-- 6. SEED BANK SOAL BIOLOGI & SATWA INDONESIA (Plan 5.8)
-- ==============================================================================
INSERT INTO public.quiz_questions (category, question, options, correct_option, explanation) VALUES
(
    'Aves',
    'Burung endemik Bali yang memiliki jambul putih dan kelopak mata berwarna biru terang adalah...',
    '["Cenderawasih Kuning", "Jalak Bali", "Maleo Senkawor", "Kakatua Jambul Kuning"]'::jsonb,
    1,
    'Jalak Bali (Leucopsar rothschildi) adalah burung pengicau endemik Pulau Bali yang berada dalam status Kritis (CR).'
),
(
    'Reptilia',
    'Komodo (Varanus komodoensis) mendeteksi mangsa dan bangkai dari kejauhan terutama menggunakan organ...',
    '["Telinga tengah", "Organ Jacobson pada lidah bercabang", "Mata berkemampuan malam", "Lubang pit termal"]'::jsonb,
    1,
    'Komodo menjentikkan lidah bercabangnya untuk menangkap partikel aroma di udara lalu mengantarkannya ke organ Jacobson di langit-langit mulut.'
),
(
    'Mamalia',
    'Orangutan Sumatera (Pongo abelii) memiliki ciri morfologis khas dibanding Orangutan Kalimantan, yaitu...',
    '["Bulu lebih lebat dan warna jingga lebih terang", "Tidak memiliki kantung pipi", "Ekor lebih panjang", "Bertubuh dua kali lebih besar"]'::jsonb,
    0,
    'Orangutan Sumatera berbulu lebih panjang, lebih halus, dan warnanya lebih pucat/jingga terang serta memiliki ikatan sosial lebih tinggi.'
),
(
    'Biogeografi',
    'Garis khayal yang memisahkan fauna tipe Asiatis dan tipe Peralihan di kepulauan Indonesia disebut...',
    '["Garis Weber", "Garis Wallace", "Garis Lydekker", "Garis Khatulistiwa"]'::jsonb,
    1,
    'Garis Wallace membentang antara Selat Lombok dan Selat Makassar, memisahkan wilayah Oriental (Asiatis) dengan wilayah Wallacea (Peralihan).'
),
(
    'Mamalia',
    'Anoa (Bubalus depressicornis) yang sering dijuluki sapi kerdil merupakan satwa endemik pulau...',
    '["Sumatera", "Kalimantan", "Sulawesi", "Papua"]'::jsonb,
    2,
    'Anoa adalah bovid terkecil di dunia yang hidup endemik di hutan hujan tropis Pulau Sulawesi.'
),
(
    'Aves',
    'Burung Maleo (Macrocephalon maleo) meletakkan telurnya untuk ditetaskan menggunakan...',
    '["Mengerami sendiri di sarang pohon", "Panas bumi (geotermal) atau pasir pantai bervolkanik", "Sarang gua kapur", "Membawa telur di kantung dada"]'::jsonb,
    1,
    'Maleo tidak mengerami telurnya, melainkan menguburnya di pasir berpasir vulkanik atau area berpanas bumi di Sulawesi.'
),
(
    'Mamalia',
    'Badak Jawa (Rhinoceros sondaicus) memiliki perbedaan utama dengan Badak Sumatera yaitu...',
    '["Memiliki satu cula (cula tunggal)", "Memiliki dua cula panjang", "Bertubuh belang seperti tapir", "Tidak memiliki lipatan kulit"]'::jsonb,
    0,
    'Badak Jawa memiliki satu cula (monoceros), sedangkan Badak Sumatera memiliki dua cula (diceros) dan tubuh yang lebih berambut.'
),
(
    'Konservasi',
    'Kategori status konservasi IUCN untuk spesies yang menghadapi risiko kepunahan amat tinggi di alam liar adalah...',
    '["Least Concern (LC)", "Vulnerable (VU)", "Critically Endangered (CR)", "Near Threatened (NT)"]'::jsonb,
    2,
    'Critically Endangered (CR / Kritis) menandakan spesies menghadapi risiko kepunahan luar biasa tinggi di alam liar dalam waktu dekat.'
),
(
    'Mamalia',
    'Bekantan (Nasalis larvatus) adalah monyet hidung panjang endemik hutan bakau di pulau...',
    '["Kalimantan", "Jawa", "Sumatera", "Bali"]'::jsonb,
    0,
    'Bekantan adalah satwa maskot Kalimantan Selatan yang hidup di hutan rawa mangrove Kalimantan.'
),
(
    'Reptilia',
    'Kura-kura Leher Ular Rote (Chelodina mccordi) memiliki ciri khas yang unik berupa...',
    '["Tempurung lunak transparan", "Leher panjang yang tidak dapat ditarik lurus ke dalam tempurung", "Dapat memanjat pohon bakau", "Bisa bernapas melalui insang"]'::jsonb,
    1,
    'Lehernya yang sangat panjang ditekuk ke samping (pleurodira) dan tidak dapat ditarik lurus ke dalam tempurung.'
),
(
    'Mamalia',
    'Harimau Sumatera (Panthera tigris sumatrae) adalah subspesies harimau terkecil yang masih bertahan, beradaptasi dengan...',
    '["Kawasan padang rumput sabana luas", "Hutan hujan lebat Sumatera", "Gurun pasir kering", "Puncak pegunungan bersalju"]'::jsonb,
    1,
    'Ukuran tubuhnya yang ramping dengan loreng lebih rapat memudahkannya menyusup dan berburu di antara vegetasi rapat hutan hujan tropis Sumatera.'
),
(
    'Amfibi',
    'Katak Pohon Mutiara (Nyctixalus margaritifer) merupakan amfibi endemik Jawa yang memiliki ciri khas...',
    '["Bintik-bintik putih menyerupai mutiara di kulit punggungnya", "Ekor panjang seperti kadal", "Tubuh bercahaya di kegelapan (bioluminesensi)", "Ukuran sebesar piring makan"]'::jsonb,
    0,
    'Nyctixalus margaritifer memiliki bintik putih menonjol seperti taburan mutiara pada kulitnya yang cokelat kemerahan.'
)
ON CONFLICT (question) DO NOTHING;
