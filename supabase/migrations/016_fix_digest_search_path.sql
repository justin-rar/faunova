-- Migration 016: Perbaiki search_path dan kualifikasi fungsi digest() untuk pgcrypto
-- Supabase menempatkan ekstensi pgcrypto di skema 'extensions'.
-- Fungsi SECURITY DEFINER dan IMMUTABLE yang menghitung SHA-256 blok kanonis wajib menyertakan 'extensions'
-- dalam search_path agar tidak terjadi galat: "function digest(text, unknown) does not exist".

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 1. FUNGSI HITUNG BLOCK HASH (SHA-256)
CREATE OR REPLACE FUNCTION public.faunova_calculate_block_hash(
    p_seq BIGINT,
    p_previous_hash TEXT,
    p_photo_sha256 TEXT,
    p_latitude NUMERIC,
    p_longitude NUMERIC,
    p_camera_heading NUMERIC,
    p_received_at TIMESTAMPTZ,
    p_user_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public, extensions, pg_temp
AS $$
BEGIN
    RETURN encode(
        extensions.digest(
            public.faunova_canonical_encode(
                p_seq,
                p_previous_hash,
                p_photo_sha256,
                p_latitude,
                p_longitude,
                p_camera_heading,
                p_received_at,
                p_user_id
            ),
            'sha256'
        ),
        'hex'
    );
END;
$$;

-- 2. FUNGSI SIMPAN TANGKAPAN DENGAN RANTAI HASH (Plan 5.2 - save_capture_with_chain)
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

    -- Evaluasi lencana MVP 1: Koleksi Perdana (seq = 1)
    IF v_seq = 1 THEN
        INSERT INTO public.user_badges (user_id, badge_id, awarded_at)
        SELECT v_user_id, 'first_discovery', now()
        ON CONFLICT (user_id, badge_id) DO NOTHING;
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

-- 3. FUNGSI VERIFIKASI RANTAI LENGKAP (Plan 5.2 - verify_chain)
CREATE OR REPLACE FUNCTION public.verify_chain(p_user_id UUID)
RETURNS TABLE (
    is_valid BOOLEAN,
    total_blocks INT,
    broken_seq BIGINT,
    failure_reason TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
    v_expected_prev TEXT;
    v_calculated_hash TEXT;
    v_count INT := 0;
    v_expected_seq BIGINT := 1;
    r RECORD;
BEGIN
    -- Genesis expected previous hash
    v_expected_prev := encode(extensions.digest(p_user_id::TEXT, 'sha256'), 'hex');

    FOR r IN
        SELECT *
        FROM public.captures
        WHERE user_id = p_user_id AND deleted_at IS NULL
        ORDER BY seq ASC
    LOOP
        v_count := v_count + 1;

        -- 1. Periksa kontinuitas urutan nomor urut (seq)
        IF r.seq != v_expected_seq THEN
            RETURN QUERY SELECT
                false,
                v_count,
                r.seq,
                'Urutan nomor blok terputus (Diharapkan #' || v_expected_seq::TEXT || ', ditemukan #' || r.seq::TEXT || ')';
            RETURN;
        END IF;

        -- 2. Periksa previous_hash sesuai sambungan hash blok sebelumnya
        IF r.previous_hash != v_expected_prev THEN
            RETURN QUERY SELECT
                false,
                v_count,
                r.seq,
                'Previous hash tidak cocok dengan rantai blok sebelumnya pada seq #' || r.seq::TEXT;
            RETURN;
        END IF;

        -- 3. Hitung ulang hash kanonis dan bandingkan dengan block_hash tersimpan
        v_calculated_hash := public.faunova_calculate_block_hash(
            r.seq,
            r.previous_hash,
            r.photo_sha256,
            r.latitude,
            r.longitude,
            r.camera_heading,
            r.received_at,
            r.user_id
        );

        IF r.block_hash != v_calculated_hash THEN
            RETURN QUERY SELECT
                false,
                v_count,
                r.seq,
                'Manipulasi data terdeteksi: Block hash tidak cocok dengan data kanonis pada seq #' || r.seq::TEXT;
            RETURN;
        END IF;

        -- Lanjut ke blok berikutnya
        v_expected_prev := r.block_hash;
        v_expected_seq := v_expected_seq + 1;
    END LOOP;

    -- Seluruh rantai valid!
    RETURN QUERY SELECT
        true,
        v_count,
        NULL::BIGINT,
        'Rantai hash SHA-256 kanonis utuh dan terverifikasi sempurna.'::TEXT;
END;
$$;

-- 4. FUNGSI VERIFIKASI PER BLOK (Plan 5.2 - verify_block)
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
    SELECT * INTO v_cap
    FROM public.captures
    WHERE id = p_capture_id AND deleted_at IS NULL;

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, NULL::BIGINT, 'Tangkapan tidak ditemukan.';
        RETURN;
    END IF;

    -- Tentukan previous hash yang sah
    IF v_cap.seq = 1 THEN
        v_expected_prev := encode(extensions.digest(v_cap.user_id::TEXT, 'sha256'), 'hex');
    ELSE
        SELECT block_hash INTO v_prev_cap
        FROM public.captures
        WHERE user_id = v_cap.user_id AND seq = (v_cap.seq - 1) AND deleted_at IS NULL;

        IF NOT FOUND THEN
            RETURN QUERY SELECT false, v_cap.seq, 'Blok pendahulu tidak ditemukan.';
            RETURN;
        END IF;
        v_expected_prev := v_prev_cap.block_hash;
    END IF;

    IF v_cap.previous_hash != v_expected_prev THEN
        RETURN QUERY SELECT false, v_cap.seq, 'Previous hash tidak valid.';
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
        RETURN QUERY SELECT false, v_cap.seq, 'Data kanonis blok ini tidak cocok dengan block_hash tersimpan.';
        RETURN;
    END IF;

    RETURN QUERY SELECT true, v_cap.seq, 'Blok terverifikasi valid dan tersambung sah ke rantai kanonis.'::TEXT;
END;
$$;
