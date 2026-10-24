-- Migration 017: Perbaiki referensi kolom dan ID badge di save_capture_with_chain
-- Kolom waktu perolehan badge di tabel user_badges adalah 'unlocked_at' (bukan 'awarded_at')
-- dan ID badge untuk tangkapan pertama adalah 'pemula' (bukan 'first_discovery').

CREATE OR REPLACE FUNCTION public.save_capture_with_chain(
    p_scan_id UUID,
    p_photo_path TEXT DEFAULT NULL,
    p_custom_desc TEXT DEFAULT NULL
)
RETURNS TABLE (
    capture_id UUID,
    seq BIGINT,
    previous_hash TEXT,
    block_hash TEXT,
    species_name TEXT,
    category TEXT,
    photo_sha256 TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_scan RECORD;
    v_last_block RECORD;
    v_seq BIGINT;
    v_prev_hash TEXT;
    v_block_hash TEXT;
    v_species_name TEXT;
    v_category TEXT;
    v_description TEXT;
    v_photo_path TEXT;
    v_new_capture_id UUID;
    v_created_at TIMESTAMPTZ;
BEGIN
    -- Identifikasi pengguna dari sesi JWT
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan untuk menyimpan koleksi.'
            USING ERRCODE = '28000';
    END IF;

    -- Concurrency: Kunci transaksi advisory lock per user
    PERFORM pg_advisory_xact_lock(hashtextextended(v_user_id::TEXT, 0));

    -- Baca scan dan validasi integritas
    SELECT * INTO v_scan
    FROM public.scans
    WHERE id = p_scan_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Scan tidak ditemukan.'
            USING ERRCODE = 'P0002';
    END IF;

    IF v_scan.user_id != v_user_id THEN
        RAISE EXCEPTION 'Anda bukan pemilik hasil scan ini.'
            USING ERRCODE = '42501';
    END IF;

    IF v_scan.is_animal IS NOT TRUE THEN
        RAISE EXCEPTION 'Objek bukan satwa. Hanya satwa teridentifikasi yang dapat disimpan ke koleksi (Plan 5.3).'
            USING ERRCODE = '22023';
    END IF;

    IF v_scan.capture_status = 'saved' THEN
        RAISE EXCEPTION 'Hasil scan ini sudah pernah disimpan ke koleksi sebelumnya.'
            USING ERRCODE = '23505';
    END IF;

    -- Cek duplikasi di tabel captures
    IF EXISTS (SELECT 1 FROM public.captures WHERE scan_id = p_scan_id) THEN
        RAISE EXCEPTION 'Tangkapan dengan scan ini sudah ada di koleksi.'
            USING ERRCODE = '23505';
    END IF;

    -- Ekstraksi nama spesies dan taksonomi dari hasil AI
    v_species_name := COALESCE(
        v_scan.result->>'name',
        'Satwa Terverifikasi'
    );
    v_category := COALESCE(
        v_scan.result->>'categoryOrSpecies',
        'Fauna Indonesia'
    );
    v_description := COALESCE(
        NULLIF(TRIM(p_custom_desc), ''),
        v_scan.result->>'description',
        ''
    );
    v_photo_path := COALESCE(
        NULLIF(TRIM(p_photo_path), ''),
        v_scan.temp_object_path,
        'captures/' || v_user_id::TEXT || '/' || p_scan_id::TEXT || '.jpg'
    );

    -- Cari blok terakhir milik user untuk membentuk rantai sambungan
    SELECT c.seq, c.block_hash INTO v_last_block
    FROM public.captures c
    WHERE c.user_id = v_user_id
    ORDER BY c.seq DESC
    LIMIT 1;

    IF FOUND THEN
        v_seq := v_last_block.seq + 1;
        v_prev_hash := v_last_block.block_hash;
    ELSE
        -- Blok Genesis (seq = 1): previous_hash = SHA-256(user_id)
        v_seq := 1;
        v_prev_hash := encode(extensions.digest(v_user_id::TEXT, 'sha256'), 'hex');
    END IF;

    -- Hitung block_hash kanonis SHA-256
    v_block_hash := public.faunova_calculate_block_hash(
        v_seq,
        v_prev_hash,
        v_scan.photo_sha256,
        v_scan.latitude,
        v_scan.longitude,
        v_scan.camera_heading,
        v_scan.received_at,
        v_user_id
    );

    v_created_at := now();

    -- Masukkan ke tabel public.captures
    INSERT INTO public.captures (
        scan_id,
        user_id,
        photo_object_path,
        species_name,
        category,
        description,
        latitude,
        longitude,
        camera_heading,
        received_at,
        seq,
        previous_hash,
        block_hash,
        photo_sha256,
        created_at
    ) VALUES (
        p_scan_id,
        v_user_id,
        v_photo_path,
        v_species_name,
        v_category,
        v_description,
        v_scan.latitude,
        v_scan.longitude,
        v_scan.camera_heading,
        v_scan.received_at,
        v_seq,
        v_prev_hash,
        v_block_hash,
        v_scan.photo_sha256,
        v_created_at
    )
    RETURNING id INTO v_new_capture_id;

    -- Update status di tabel scans menjadi 'saved'
    UPDATE public.scans
    SET capture_status = 'saved'
    WHERE id = p_scan_id;

    -- Evaluasi lencana MVP 1: Koleksi Perdana (seq = 1) -> badge 'pemula'
    IF v_seq = 1 THEN
        INSERT INTO public.user_badges (user_id, badge_id, is_unlocked, current_progress, unlocked_at)
        VALUES (v_user_id, 'pemula', true, 1, now())
        ON CONFLICT (user_id, badge_id) DO UPDATE
        SET is_unlocked = true, current_progress = 1, unlocked_at = COALESCE(public.user_badges.unlocked_at, now());
    END IF;

    -- Kembalikan baris hasil
    RETURN QUERY SELECT
        v_new_capture_id,
        v_seq,
        v_prev_hash,
        v_block_hash,
        v_species_name,
        v_category,
        v_scan.photo_sha256,
        v_created_at;
END;
$$;
