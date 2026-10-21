-- ==============================================================================
-- FAUNOVA MIGRATION 004: create_post, Grid Snapping, dan Feed Komunitas
-- Sesuai Dokumen Desain Plan 5.7, 5.9, 18, 19 & AGENTS.md (Sesi S9)
-- ==============================================================================

-- 1. FUNGSI DETERMINISTIK GRID SNAPPING SERVER-SIDE (Ukuran sel 0.01° x 0.01°)
-- Koordinat asli hewan TIDAK PERNAH terekspos ke publik; hanya titik pusat sel grid.
CREATE OR REPLACE FUNCTION public.faunova_snap_to_grid(
    p_lat NUMERIC,
    p_lng NUMERIC
)
RETURNS TABLE (
    display_latitude NUMERIC,
    display_longitude NUMERIC
)
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_lat IS NULL OR p_lng IS NULL THEN
        RETURN QUERY SELECT NULL::NUMERIC, NULL::NUMERIC;
        RETURN;
    END IF;

    -- Pusat sel: (floor(coord / 0.01) * 0.01) + 0.005
    RETURN QUERY SELECT 
        ROUND((floor(p_lat / 0.01) * 0.01 + 0.005), 6)::NUMERIC,
        ROUND((floor(p_lng / 0.01) * 0.01 + 0.005), 6)::NUMERIC;
END;
$$;

-- 2. RPC ATOMIK CREATE_POST
-- Menerima capture_id milik user, menghitung koordinat grid di server, dan menyisipkan post
CREATE OR REPLACE FUNCTION public.create_post(
    p_capture_id UUID,
    p_caption TEXT DEFAULT '',
    p_visibility TEXT DEFAULT 'coarse',
    p_area_label TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_capture RECORD;
    v_disp_lat NUMERIC := NULL;
    v_disp_lng NUMERIC := NULL;
    v_final_area TEXT := NULL;
    v_post_id UUID;
    v_created_at TIMESTAMPTZ;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: autentikasi diperlukan.'
            USING ERRCODE = '42501';
    END IF;

    -- Validasi visibilitas lokasi (hanya 'coarse' atau 'hidden')
    IF p_visibility NOT IN ('coarse', 'hidden') THEN
        RAISE EXCEPTION 'Parameter visibility harus coarse atau hidden.'
            USING ERRCODE = '22023';
    END IF;

    -- Validasi panjang teks caption (maksimal 500 karakter)
    IF length(COALESCE(p_caption, '')) > 500 THEN
        RAISE EXCEPTION 'Panjang takarir melebihi batas 500 karakter.'
            USING ERRCODE = '22023';
    END IF;

    -- Ambil data capture dan validasi kepemilikan
    SELECT id, user_id, latitude, longitude, species_name, category, photo_object_path, seq, block_hash, deleted_at
    INTO v_capture
    FROM public.captures
    WHERE id = p_capture_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tangkapan koleksi tidak ditemukan.'
            USING ERRCODE = 'P0002';
    END IF;

    IF v_capture.user_id <> v_user_id THEN
        RAISE EXCEPTION 'Akses ditolak: tangkapan ini bukan milik akun Anda.'
            USING ERRCODE = '42501';
    END IF;

    IF v_capture.deleted_at IS NOT NULL THEN
        RAISE EXCEPTION 'Tangkapan yang telah dihapus tidak dapat diposting.'
            USING ERRCODE = '22023';
    END IF;

    -- Periksa apakah tangkapan ini sudah pernah diposting dan masih aktif
    IF EXISTS (
        SELECT 1 FROM public.posts 
        WHERE capture_id = p_capture_id AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Tangkapan ini sudah pernah Anda publikasikan ke linimasa.'
            USING ERRCODE = '23505';
    END IF;

    -- Hitung koordinat publik jika opsi lokasi 'coarse' dipilih dan koordinat tersedia
    IF p_visibility = 'coarse' AND v_capture.latitude IS NOT NULL AND v_capture.longitude IS NOT NULL THEN
        SELECT display_latitude, display_longitude
        INTO v_disp_lat, v_disp_lng
        FROM public.faunova_snap_to_grid(v_capture.latitude, v_capture.longitude);

        v_final_area := COALESCE(NULLIF(TRIM(p_area_label), ''), 'Area Perkiraan (Grid 0.01°)');
    ELSE
        -- Jika 'hidden' atau koordinat asli NULL, jangan sertakan koordinat atau label
        v_disp_lat := NULL;
        v_disp_lng := NULL;
        v_final_area := NULL;
    END IF;

    -- Masukkan ke tabel public.posts
    INSERT INTO public.posts (
        capture_id,
        user_id,
        caption,
        location_visibility,
        display_latitude,
        display_longitude,
        area_label,
        created_at
    ) VALUES (
        p_capture_id,
        v_user_id,
        COALESCE(TRIM(p_caption), ''),
        p_visibility,
        v_disp_lat,
        v_disp_lng,
        v_final_area,
        now()
    )
    RETURNING id, created_at INTO v_post_id, v_created_at;

    -- Kembalikan data postingan aman tanpa membocorkan koordinat mentah
    RETURN jsonb_build_object(
        'post_id', v_post_id,
        'capture_id', p_capture_id,
        'caption', COALESCE(TRIM(p_caption), ''),
        'location_visibility', p_visibility,
        'display_latitude', v_disp_lat,
        'display_longitude', v_disp_lng,
        'area_label', v_final_area,
        'created_at', v_created_at
    );
END;
$$;

-- 3. RPC GET_FOR_YOU_FEED
-- Mengambil feed linimasa publik "Untuk Kamu" dengan keyset pagination
-- Hanya mengembalikan koordinat hasil grid (display_latitude & display_longitude)
CREATE OR REPLACE FUNCTION public.get_for_you_feed(
    p_limit INT DEFAULT 20,
    p_cursor TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    post_id UUID,
    caption TEXT,
    location_visibility TEXT,
    display_latitude NUMERIC,
    display_longitude NUMERIC,
    area_label TEXT,
    post_created_at TIMESTAMPTZ,
    capture_id UUID,
    species_name TEXT,
    category TEXT,
    photo_object_path TEXT,
    block_seq BIGINT,
    block_hash CHAR(64),
    photo_sha256 CHAR(64),
    author_id UUID,
    author_name TEXT,
    author_username TEXT,
    author_avatar TEXT,
    author_verified_until TIMESTAMPTZ,
    likes_count BIGINT,
    is_liked_by_me BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_current_user_id UUID;
    v_clamped_limit INT;
BEGIN
    v_current_user_id := auth.uid();
    v_clamped_limit := LEAST(GREATEST(p_limit, 1), 50);

    RETURN QUERY
    SELECT 
        p.id AS post_id,
        p.caption,
        p.location_visibility,
        p.display_latitude,
        p.display_longitude,
        p.area_label,
        p.created_at AS post_created_at,
        c.id AS capture_id,
        c.species_name,
        c.category,
        c.photo_object_path,
        c.seq AS block_seq,
        c.block_hash,
        c.photo_sha256,
        u.id AS author_id,
        u.full_name AS author_name,
        u.username AS author_username,
        u.avatar_url AS author_avatar,
        u.verified_until AS author_verified_until,
        COALESCE(l.likes_total, 0)::BIGINT AS likes_count,
        CASE 
            WHEN v_current_user_id IS NULL THEN false
            ELSE EXISTS (
                SELECT 1 FROM public.likes my_l 
                WHERE my_l.post_id = p.id AND my_l.user_id = v_current_user_id
            )
        END AS is_liked_by_me
    FROM public.posts p
    JOIN public.captures c ON c.id = p.capture_id AND c.deleted_at IS NULL
    JOIN public.profiles u ON u.id = p.user_id
    LEFT JOIN (
        SELECT post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes
        GROUP BY post_id
    ) l ON l.post_id = p.id
    WHERE p.deleted_at IS NULL
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

-- 4. RPC TOGGLE_POST_LIKE
-- Menyukai atau membatalkan suka secara atomik dan idempoten
CREATE OR REPLACE FUNCTION public.toggle_post_like(
    p_post_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_already_liked BOOLEAN;
    v_new_count BIGINT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: autentikasi diperlukan.'
            USING ERRCODE = '42501';
    END IF;

    -- Periksa apakah postingan ada dan aktif
    IF NOT EXISTS (
        SELECT 1 FROM public.posts WHERE id = p_post_id AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Postingan tidak ditemukan atau telah dihapus.'
            USING ERRCODE = 'P0002';
    END IF;

    -- Periksa status like saat ini
    SELECT EXISTS (
        SELECT 1 FROM public.likes WHERE post_id = p_post_id AND user_id = v_user_id
    ) INTO v_already_liked;

    IF v_already_liked THEN
        DELETE FROM public.likes 
        WHERE post_id = p_post_id AND user_id = v_user_id;
    ELSE
        INSERT INTO public.likes (post_id, user_id, created_at)
        VALUES (p_post_id, v_user_id, now())
        ON CONFLICT (post_id, user_id) DO NOTHING;
    END IF;

    -- Hitung total like terkini
    SELECT COUNT(*)::BIGINT INTO v_new_count
    FROM public.likes
    WHERE post_id = p_post_id;

    RETURN jsonb_build_object(
        'post_id', p_post_id,
        'is_liked', NOT v_already_liked,
        'likes_count', v_new_count
    );
END;
$$;

-- Hak akses eksekusi RPC untuk pengguna terautentikasi
GRANT EXECUTE ON FUNCTION public.faunova_snap_to_grid(NUMERIC, NUMERIC) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.create_post(UUID, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_for_you_feed(INT, TIMESTAMPTZ) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.toggle_post_like(UUID) TO authenticated;
