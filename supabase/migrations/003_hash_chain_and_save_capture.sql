-- ==============================================================================
-- FAUNOVA MIGRATION 003: Hash-Chain Kanonis SHA-256 & save_capture RPC
-- Sesuai Dokumen Desain Plan 5.2, 5.3 & AGENTS.md (Sesi S7)
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. FUNGSI ENKODE KANONIS (Plan 5.2)
-- Menghasilkan representasi string baku dan deterministik dari metadata tangkapan
-- Format: seq|previous_hash|photo_sha256|latitude|longitude|camera_heading|received_at|user_id
CREATE OR REPLACE FUNCTION public.faunova_canonical_encode(
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
SET search_path = public, pg_temp
AS $$
DECLARE
    v_lat_str TEXT;
    v_lng_str TEXT;
    v_heading_str TEXT;
    v_received_str TEXT;
BEGIN
    -- Format lat/lng: string 6 angka desimal atau 'NULL'
    IF p_latitude IS NULL THEN
        v_lat_str := 'NULL';
    ELSE
        v_lat_str := to_char(p_latitude, 'FM990.000000');
    END IF;

    IF p_longitude IS NULL THEN
        v_lng_str := 'NULL';
    ELSE
        v_lng_str := to_char(p_longitude, 'FM990.000000');
    END IF;

    -- Format heading: string 2 desimal atau 'NULL'
    IF p_camera_heading IS NULL THEN
        v_heading_str := 'NULL';
    ELSE
        v_heading_str := to_char(p_camera_heading, 'FM990.00');
    END IF;

    -- Format received_at: ISO-8601 UTC dengan microsecond 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
    v_received_str := to_char(p_received_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');

    RETURN p_seq::TEXT || '|' ||
           p_previous_hash || '|' ||
           p_photo_sha256 || '|' ||
           v_lat_str || '|' ||
           v_lng_str || '|' ||
           v_heading_str || '|' ||
           v_received_str || '|' ||
           p_user_id::TEXT;
END;
$$;

-- 2. FUNGSI HITUNG BLOCK HASH (SHA-256)
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
SET search_path = public, pg_temp
AS $$
BEGIN
    RETURN encode(
        digest(
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

-- 3. TRIGGER IMUTABILITAS RANTAI DI TABEL CAPTURES (Plan 5.2)
-- Menolak setiap upaya UPDATE pada kolom-kolom rantai hash kanonis
CREATE OR REPLACE FUNCTION public.prevent_capture_chain_tamper()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    IF OLD.seq != NEW.seq OR
       OLD.previous_hash != NEW.previous_hash OR
       OLD.block_hash != NEW.block_hash OR
       OLD.photo_sha256 != NEW.photo_sha256 OR
       OLD.latitude IS DISTINCT FROM NEW.latitude OR
       OLD.longitude IS DISTINCT FROM NEW.longitude OR
       OLD.camera_heading IS DISTINCT FROM NEW.camera_heading OR
       OLD.received_at != NEW.received_at OR
       OLD.user_id != NEW.user_id THEN
        RAISE EXCEPTION 'Kolom rantai hash bersifat imutabel dan tidak dapat diubah (Plan 5.2)'
            USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_capture_chain_tamper ON public.captures;
CREATE TRIGGER trg_prevent_capture_chain_tamper
BEFORE UPDATE ON public.captures
FOR EACH ROW
EXECUTE FUNCTION public.prevent_capture_chain_tamper();

-- 4. RPC ATOMIK save_capture_with_chain (Plan 5.2 & 5.3)
-- Menggunakan advisory lock pg_advisory_xact_lock(hashtextextended(user_id, 0))
-- Menolak scan bukan satwa, scan milik orang lain, atau scan yang sudah disimpan
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
SET search_path = public, pg_temp
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
    -- Menjamin dua request simpan bersamaan diserialisasi secara aman tanpa fork chain
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

    -- Ekstraksi nama spesies dan taksonomi dari hasil Gemini
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
        v_prev_hash := encode(digest(v_user_id::TEXT, 'sha256'), 'hex');
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

    -- Tandai scan sebagai sudah disimpan
    UPDATE public.scans
    SET capture_status = 'saved'
    WHERE id = p_scan_id;

    RETURN QUERY
    SELECT
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

-- 5. FUNGSI VERIFIKASI RANTAI PENUH (Plan 5.2 - verify_chain)
-- Memeriksa seluruh rantai integritas milik seorang pengguna dari seq 1..N
-- Mengembalikan seq pertama yang rusak jika ada baris/kolom yang dimanipulasi
CREATE OR REPLACE FUNCTION public.verify_chain(p_user_id UUID)
RETURNS TABLE (
    is_valid BOOLEAN,
    total_blocks INT,
    broken_seq BIGINT,
    failure_reason TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_expected_prev TEXT;
    v_calculated_hash TEXT;
    v_count INT := 0;
    v_expected_seq BIGINT := 1;
    r RECORD;
BEGIN
    -- Genesis expected previous hash
    v_expected_prev := encode(digest(p_user_id::TEXT, 'sha256'), 'hex');

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

-- 6. FUNGSI VERIFIKASI PER BLOK (Plan 5.2 - verify_block)
-- Verifikasi cepat satu blok tangkapan terhadap blok sebelumnya (untuk badge terverifikasi di feed)
CREATE OR REPLACE FUNCTION public.verify_block(p_capture_id UUID)
RETURNS TABLE (
    is_valid BOOLEAN,
    seq BIGINT,
    failure_reason TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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
        v_expected_prev := encode(digest(v_cap.user_id::TEXT, 'sha256'), 'hex');
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
        RETURN QUERY SELECT false, v_cap.seq, 'Integritas blok cacat/telah dimanipulasi.';
        RETURN;
    END IF;

    RETURN QUERY SELECT true, v_cap.seq, 'Blok sah dan terverifikasi.';
END;
$$;

-- 7. Hak Akses Eksekusi (Grant)
GRANT EXECUTE ON FUNCTION public.faunova_canonical_encode(BIGINT, TEXT, TEXT, NUMERIC, NUMERIC, NUMERIC, TIMESTAMPTZ, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.faunova_calculate_block_hash(BIGINT, TEXT, TEXT, NUMERIC, NUMERIC, NUMERIC, TIMESTAMPTZ, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.save_capture_with_chain(UUID, TEXT, TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.verify_chain(UUID) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION public.verify_block(UUID) TO authenticated, anon, service_role;
