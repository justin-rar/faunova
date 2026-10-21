-- ==============================================================================
-- FAUNOVA MIGRATION 010: Sistem Badge Gelar & Pencapaian (Plan 5.8 Sesi S16)
-- Aturan Keras:
-- 1. Syarat dan pembukaan badge HANYA dievaluasi di server (RPC/database).
-- 2. RLS aktif: Pengguna hanya dapat membaca badge miliknya.
-- ==============================================================================

-- 1. TABEL DEFINISI BADGE (badges)
CREATE TABLE IF NOT EXISTS public.badges (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    target_count INT NOT NULL DEFAULT 1,
    icon_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Umum',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Daftar badge dapat dibaca oleh seluruh pengguna"
    ON public.badges FOR SELECT
    TO authenticated
    USING (true);

-- 2. TABEL PENCAPAIAN BADGE PENGGUNA (user_badges)
CREATE TABLE IF NOT EXISTS public.user_badges (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    badge_id TEXT NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
    is_unlocked BOOLEAN NOT NULL DEFAULT false,
    current_progress INT NOT NULL DEFAULT 0,
    unlocked_at TIMESTAMPTZ,
    notified BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_unlocked ON public.user_badges(user_id, is_unlocked);

ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pengguna hanya dapat membaca badge miliknya"
    ON public.user_badges FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- 3. SEED 8 BADGE GELAR RESMI FAUNOVA (Plan 207-217)
INSERT INTO public.badges (id, name, description, target_count, icon_name, category) VALUES
(
    'pemula',
    'Pemula',
    '1 tangkapan pertama disimpan ke koleksi kanonis.',
    1,
    'eco',
    'Koleksi'
),
(
    'kolektor',
    'Kolektor',
    'Simpan 10 tangkapan hewan ke dalam koleksi.',
    10,
    'auto_stories',
    'Koleksi'
),
(
    'rajin',
    'Rajin',
    'Lakukan check-in streak observasi 7 hari berturut-turut.',
    7,
    'local_fire_department',
    'Observasi'
),
(
    'si_pintar',
    'Si Pintar',
    'Selesaikan 5 sesi kuis biologi di Arena Kuis.',
    5,
    'psychology',
    'Kuis'
),
(
    'juara_kuis',
    'Juara Kuis',
    'Raih skor minimal 1000 dalam satu sesi kuis.',
    1000,
    'military_tech',
    'Kuis'
),
(
    'sosialita',
    'Sosialita',
    'Dapatkan akumulasi minimal 5 pengikut atau 10 suka pada postingan.',
    5,
    'groups',
    'Sosial'
),
(
    'rutin_menantang',
    'Rutin Menantang',
    'Jawab dengan benar Tantangan Hari Ini sebanyak 5 kali.',
    5,
    'stars',
    'Tantangan'
),
(
    'si_goyang',
    'Si Goyang',
    'Jawab dengan benar 10 soal kuis goyang HP (Shake-to-Quiz).',
    10,
    'vibration',
    'Sensor'
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    target_count = EXCLUDED.target_count,
    icon_name = EXCLUDED.icon_name,
    category = EXCLUDED.category;

-- 4. RPC GET_USER_BADGES
-- Menghitung progres terkini setiap badge secara dinamis di server dan membuka badge jika syarat terpenuhi
CREATE OR REPLACE FUNCTION public.get_user_badges()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_captures_count INT := 0;
    v_streak INT := 0;
    v_quiz_sessions_count INT := 0;
    v_best_quiz_score INT := 0;
    v_social_count INT := 0;
    v_challenge_correct INT := 0;
    v_shake_correct INT := 0;
    
    v_b RECORD;
    v_prog INT;
    v_target INT;
    v_unlocked BOOLEAN;
    v_was_unlocked BOOLEAN;
    v_unlocked_at TIMESTAMPTZ;
    v_newly_unlocked BOOLEAN;
    v_result JSONB := '[]'::JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk melihat lencana gelar.';
    END IF;

    -- Hitung metrik pengguna dari tabel sumber kebenaran (Source of Truth)
    -- 1. Jumlah tangkapan hewan
    SELECT COUNT(*) INTO v_captures_count
    FROM public.captures
    WHERE user_id = v_user_id;

    -- 2. Streak count & best quiz score dari profiles
    SELECT COALESCE(streak_count, 0), COALESCE(best_quiz_score, 0)
    INTO v_streak, v_best_quiz_score
    FROM public.profiles
    WHERE id = v_user_id;

    -- 3. Jumlah sesi kuis yang selesai
    SELECT COUNT(*) INTO v_quiz_sessions_count
    FROM public.quiz_sessions
    WHERE user_id = v_user_id AND status = 'completed';

    -- 4. Metrik sosial (jumlah pengikut + suka diterima)
    SELECT (
        (SELECT COUNT(*) FROM public.follows WHERE followed_id = v_user_id) +
        (SELECT COUNT(*) FROM public.likes l JOIN public.posts p ON l.post_id = p.id WHERE p.user_id = v_user_id)
    ) INTO v_social_count;

    -- 5. Tantangan harian dijawab benar
    SELECT COUNT(*) INTO v_challenge_correct
    FROM public.daily_challenge_log
    WHERE user_id = v_user_id AND is_correct = true;

    -- 6. Shake-to-quiz dijawab benar
    SELECT COUNT(*) INTO v_shake_correct
    FROM public.shake_log
    WHERE user_id = v_user_id AND is_correct = true;

    -- Evaluasi setiap badge
    FOR v_b IN SELECT * FROM public.badges ORDER BY target_count ASC, name ASC
    LOOP
        v_target := v_b.target_count;
        CASE v_b.id
            WHEN 'pemula' THEN v_prog := v_captures_count;
            WHEN 'kolektor' THEN v_prog := v_captures_count;
            WHEN 'rajin' THEN v_prog := v_streak;
            WHEN 'si_pintar' THEN v_prog := v_quiz_sessions_count;
            WHEN 'juara_kuis' THEN v_prog := v_best_quiz_score;
            WHEN 'sosialita' THEN v_prog := v_social_count;
            WHEN 'rutin_menantang' THEN v_prog := v_challenge_correct;
            WHEN 'si_goyang' THEN v_prog := v_shake_correct;
            ELSE v_prog := 0;
        END CASE;

        v_unlocked := (v_prog >= v_target);

        -- Periksa data tersimpan di user_badges
        SELECT is_unlocked, unlocked_at
        INTO v_was_unlocked, v_unlocked_at
        FROM public.user_badges
        WHERE user_id = v_user_id AND badge_id = v_b.id;

        IF NOT FOUND THEN
            v_was_unlocked := false;
            v_unlocked_at := CASE WHEN v_unlocked THEN now() ELSE NULL END;
            v_newly_unlocked := v_unlocked;

            INSERT INTO public.user_badges (
                user_id, badge_id, is_unlocked, current_progress, unlocked_at, notified
            ) VALUES (
                v_user_id, v_b.id, v_unlocked, v_prog, v_unlocked_at, v_unlocked
            );
        ELSE
            v_newly_unlocked := (v_unlocked AND NOT v_was_unlocked);
            IF v_unlocked AND NOT v_was_unlocked THEN
                v_unlocked_at := now();
            END IF;

            UPDATE public.user_badges
            SET current_progress = v_prog,
                is_unlocked = v_unlocked,
                unlocked_at = COALESCE(unlocked_at, v_unlocked_at),
                updated_at = now()
            WHERE user_id = v_user_id AND badge_id = v_b.id;
        END IF;

        v_result := v_result || jsonb_build_object(
            'id', v_b.id,
            'name', v_b.name,
            'description', v_b.description,
            'target_count', v_target,
            'current_progress', LEAST(v_prog, v_target),
            'actual_progress', v_prog,
            'is_unlocked', v_unlocked,
            'unlocked_at', v_unlocked_at,
            'icon_name', v_b.icon_name,
            'category', v_b.category,
            'is_newly_unlocked', v_newly_unlocked
        );
    END LOOP;

    RETURN v_result;
END;
$$;

-- Izin eksekusi RPC
GRANT EXECUTE ON FUNCTION public.get_user_badges() TO authenticated;
