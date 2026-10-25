-- Migration 023: RPC verify_quiz_question untuk umpan balik instan per-soal (Gaya Quizizz)
-- Memungkinkan klien mengetahui apakah pilihan benar/salah secara langsung saat menjawab,
-- menjaga combo streak jujur (reset saat salah) tanpa harus membocorkan seluruh kunci jawaban di awal sesi.

CREATE OR REPLACE FUNCTION public.verify_quiz_question(
    p_session_id UUID,
    p_question_id UUID,
    p_selected_option INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_session RECORD;
    v_question RECORD;
    v_is_correct BOOLEAN;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus masuk untuk memverifikasi jawaban kuis.';
    END IF;

    -- Validasi apakah sesi kuis milik user dan masih berlangsung
    SELECT * INTO v_session
    FROM public.quiz_sessions
    WHERE id = p_session_id AND user_id = v_user_id AND status = 'in_progress';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sesi kuis tidak aktif atau tidak ditemukan.';
    END IF;

    -- Validasi apakah soal termasuk dalam sesi kuis
    IF NOT (p_question_id = ANY(v_session.question_ids)) THEN
        RAISE EXCEPTION 'ID soal tidak terdaftar pada sesi kuis ini.';
    END IF;

    -- Ambil data soal
    SELECT * INTO v_question
    FROM public.quiz_questions
    WHERE id = p_question_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Soal kuis tidak ditemukan.';
    END IF;

    v_is_correct := (p_selected_option IS NOT NULL AND p_selected_option = v_question.correct_option);

    RETURN jsonb_build_object(
        'success', true,
        'is_correct', v_is_correct,
        'correct_option', v_question.correct_option,
        'explanation', v_question.explanation
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_quiz_question(UUID, UUID, INT) TO authenticated;
