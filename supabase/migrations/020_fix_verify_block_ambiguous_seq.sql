-- ==============================================================================
-- FAUNOVA MIGRATION 020: Fix Ambiguous "seq" Column in verify_block RPC
-- Per Plan 5.2: Perbaikan referensi kolom 'seq' yang ambigu di PL/pgSQL
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.verify_block(p_capture_id UUID)
RETURNS TABLE (
    is_valid BOOLEAN,
    seq BIGINT,
    failure_reason TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    v_cap RECORD;
    v_prev_cap RECORD;
    v_expected_prev TEXT;
    v_calculated_hash TEXT;
BEGIN
    SELECT c.* INTO v_cap
    FROM public.captures c
    WHERE c.id = p_capture_id AND c.deleted_at IS NULL;

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, NULL::BIGINT, 'Tangkapan tidak ditemukan.'::TEXT;
        RETURN;
    END IF;

    -- Tentukan previous hash yang sah
    IF v_cap.seq = 1 THEN
        v_expected_prev := encode(extensions.digest(v_cap.user_id::TEXT, 'sha256'), 'hex');
    ELSE
        SELECT c.block_hash INTO v_prev_cap
        FROM public.captures c
        WHERE c.user_id = v_cap.user_id AND c.seq = (v_cap.seq - 1) AND c.deleted_at IS NULL;

        IF NOT FOUND THEN
            RETURN QUERY SELECT false, v_cap.seq, 'Blok pendahulu tidak ditemukan.'::TEXT;
            RETURN;
        END IF;
        v_expected_prev := v_prev_cap.block_hash;
    END IF;

    IF v_cap.previous_hash != v_expected_prev THEN
        RETURN QUERY SELECT false, v_cap.seq, 'Previous hash tidak valid.'::TEXT;
        RETURN;
    END IF;

    -- Hitung ulang hash kanonis
    v_calculated_hash := public.faunova_calculate_block_hash(
        v_cap.seq,
        v_cap.previous_hash,
        v_cap.photo_sha256,
        v_cap.latitude,
        v_cap.longitude,
        v_cap.camera_heading,
        v_cap.received_at,
        v_cap.user_id
    );

    IF v_cap.block_hash != v_calculated_hash THEN
        RETURN QUERY SELECT false, v_cap.seq, 'Data kanonis blok ini tidak cocok dengan block_hash tersimpan.'::TEXT;
        RETURN;
    END IF;

    RETURN QUERY SELECT true, v_cap.seq, 'Blok terverifikasi valid dan tersambung sah ke rantai kanonis.'::TEXT;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_block(UUID) TO authenticated, anon, service_role;
