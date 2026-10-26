-- ==============================================================================
-- FAUNOVA MIGRATION 030: Perbaikan Kolom Ambigu "post_id" & LEFT JOIN Captures
-- Sesuai Acuan: Plan 5.7, 5.9, Regression 1 & Aturan Keras AGENTS.md
-- 
-- Masalah yang Diselesaikan:
-- 1. Error 42702: column reference "post_id" is ambiguous pada get_for_you_feed,
--    get_following_feed, dan get_user_public_posts akibat subquery likes tanpa alias.
-- 2. INNER JOIN public.captures yang berpotensi membuang postingan yang capture_id-nya
--    tidak terhubung atau postingan lama sebelum relasi ketat. Diubah menjadi LEFT JOIN
--    dengan filter NULL-safe sehingga postingan non-deleted tetap tampil.
-- 3. Menghapus overload ganda get_user_public_posts(UUID, INT) agar PostgREST dapat
--    memilih fungsi dengan parameter default secara deterministik.
-- ==============================================================================

-- 0. BERSIHKAN OVERLOAD LAMA GET_USER_PUBLIC_POSTS
DROP FUNCTION IF EXISTS public.get_user_public_posts(UUID, INT);
DROP FUNCTION IF EXISTS public.get_user_public_posts(UUID, INT, TIMESTAMPTZ);

-- ==============================================================================
-- 1. PERBAIKAN RPC GET_FOR_YOU_FEED
-- ==============================================================================
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
SET search_path = public, auth, pg_temp
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
        COALESCE(c.species_name, 'Satwa Terverifikasi') AS species_name,
        c.category,
        COALESCE(c.photo_object_path, '') AS photo_object_path,
        COALESCE(c.seq, 1)::BIGINT AS block_seq,
        COALESCE(c.block_hash, '') AS block_hash,
        COALESCE(c.photo_sha256, '') AS photo_sha256,
        u.id AS author_id,
        COALESCE(u.display_name, u.username, 'Penjelajah Satwa') AS author_name,
        u.username AS author_username,
        u.avatar_path AS author_avatar,
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
    LEFT JOIN public.captures c ON c.id = p.capture_id
    JOIN public.profiles u ON u.id = p.user_id
    LEFT JOIN (
        SELECT lk.post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes lk
        GROUP BY lk.post_id
    ) l ON l.post_id = p.id
    WHERE p.deleted_at IS NULL
      AND p.trashed_at IS NULL
      AND (c.id IS NULL OR (c.deleted_at IS NULL AND c.trashed_at IS NULL AND c.purged_at IS NULL))
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_for_you_feed(INT, TIMESTAMPTZ) TO anon, authenticated;

-- ==============================================================================
-- 2. PERBAIKAN RPC GET_FOLLOWING_FEED
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.get_following_feed(
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
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_current_user_id UUID;
    v_clamped_limit INT;
BEGIN
    v_current_user_id := auth.uid();
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

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
        COALESCE(c.species_name, 'Satwa Terverifikasi') AS species_name,
        c.category,
        COALESCE(c.photo_object_path, '') AS photo_object_path,
        COALESCE(c.seq, 1)::BIGINT AS block_seq,
        COALESCE(c.block_hash, '') AS block_hash,
        COALESCE(c.photo_sha256, '') AS photo_sha256,
        u.id AS author_id,
        COALESCE(u.display_name, u.username, 'Penjelajah Satwa') AS author_name,
        u.username AS author_username,
        u.avatar_path AS author_avatar,
        u.verified_until AS author_verified_until,
        COALESCE(l.likes_total, 0)::BIGINT AS likes_count,
        EXISTS (
            SELECT 1 FROM public.likes my_l 
            WHERE my_l.post_id = p.id AND my_l.user_id = v_current_user_id
        ) AS is_liked_by_me
    FROM public.posts p
    LEFT JOIN public.captures c ON c.id = p.capture_id
    JOIN public.profiles u ON u.id = p.user_id
    JOIN public.follows f ON f.followed_id = p.user_id AND f.follower_id = v_current_user_id
    LEFT JOIN (
        SELECT lk.post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes lk
        GROUP BY lk.post_id
    ) l ON l.post_id = p.id
    WHERE p.deleted_at IS NULL
      AND p.trashed_at IS NULL
      AND (c.id IS NULL OR (c.deleted_at IS NULL AND c.trashed_at IS NULL AND c.purged_at IS NULL))
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_following_feed(INT, TIMESTAMPTZ) TO authenticated;

-- ==============================================================================
-- 3. PERBAIKAN RPC GET_USER_PUBLIC_POSTS
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.get_user_public_posts(
    p_target_user_id UUID,
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
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_current_user_id UUID;
    v_clamped_limit INT;
BEGIN
    v_current_user_id := auth.uid();
    v_clamped_limit := LEAST(GREATEST(p_limit, 1), 60);

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
        COALESCE(c.species_name, 'Satwa Terverifikasi') AS species_name,
        c.category,
        COALESCE(c.photo_object_path, '') AS photo_object_path,
        COALESCE(c.seq, 1)::BIGINT AS block_seq,
        COALESCE(c.block_hash, '') AS block_hash,
        COALESCE(c.photo_sha256, '') AS photo_sha256,
        u.id AS author_id,
        COALESCE(u.display_name, u.username, 'Penjelajah Satwa') AS author_name,
        u.username AS author_username,
        u.avatar_path AS author_avatar,
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
    LEFT JOIN public.captures c ON c.id = p.capture_id
    JOIN public.profiles u ON u.id = p.user_id
    LEFT JOIN (
        SELECT lk.post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes lk
        GROUP BY lk.post_id
    ) l ON l.post_id = p.id
    WHERE p.user_id = p_target_user_id
      AND p.deleted_at IS NULL
      AND p.trashed_at IS NULL
      AND (c.id IS NULL OR (c.deleted_at IS NULL AND c.trashed_at IS NULL AND c.purged_at IS NULL))
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_public_posts(UUID, INT, TIMESTAMPTZ) TO anon, authenticated;

-- ==============================================================================
-- 4. PERBAIKAN RPC GET_USER_PROFILE_METRICS
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.get_user_profile_metrics(
    p_target_user_id UUID
)
RETURNS TABLE (
    total_captures BIGINT,
    total_posts BIGINT,
    followers_count BIGINT,
    following_count BIGINT,
    is_following_by_me BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_current_user_id UUID;
    v_total_captures BIGINT;
    v_total_posts BIGINT;
    v_followers_count BIGINT;
    v_following_count BIGINT;
    v_is_following BOOLEAN := false;
BEGIN
    v_current_user_id := auth.uid();

    SELECT COUNT(*)::BIGINT INTO v_total_captures
    FROM public.captures
    WHERE user_id = p_target_user_id 
      AND deleted_at IS NULL 
      AND trashed_at IS NULL 
      AND purged_at IS NULL;

    SELECT COUNT(*)::BIGINT INTO v_total_posts
    FROM public.posts p
    LEFT JOIN public.captures c ON c.id = p.capture_id
    WHERE p.user_id = p_target_user_id 
      AND p.deleted_at IS NULL 
      AND p.trashed_at IS NULL
      AND (c.id IS NULL OR (c.deleted_at IS NULL AND c.trashed_at IS NULL AND c.purged_at IS NULL));

    SELECT COUNT(*)::BIGINT INTO v_followers_count
    FROM public.follows
    WHERE followed_id = p_target_user_id;

    SELECT COUNT(*)::BIGINT INTO v_following_count
    FROM public.follows
    WHERE follower_id = p_target_user_id;

    IF v_current_user_id IS NOT NULL AND v_current_user_id != p_target_user_id THEN
        SELECT EXISTS (
            SELECT 1 FROM public.follows
            WHERE follower_id = v_current_user_id AND followed_id = p_target_user_id
        ) INTO v_is_following;
    END IF;

    RETURN QUERY SELECT 
        COALESCE(v_total_captures, 0),
        COALESCE(v_total_posts, 0),
        COALESCE(v_followers_count, 0),
        COALESCE(v_following_count, 0),
        v_is_following;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_profile_metrics(UUID) TO anon, authenticated;

-- ==============================================================================
-- 5. PERBAIKAN RPC TOGGLE_POST_LIKE
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.toggle_post_like(
    p_post_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_already_liked BOOLEAN;
    v_new_count BIGINT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    -- Periksa apakah postingan ada, aktif, dan tidak di sampah (LEFT JOIN aman)
    IF NOT EXISTS (
        SELECT 1 
        FROM public.posts p
        LEFT JOIN public.captures c ON c.id = p.capture_id
        WHERE p.id = p_post_id 
          AND p.deleted_at IS NULL 
          AND p.trashed_at IS NULL
          AND (c.id IS NULL OR (c.deleted_at IS NULL AND c.trashed_at IS NULL AND c.purged_at IS NULL))
    ) THEN
        RAISE EXCEPTION 'Postingan tidak ditemukan atau telah dihapus.' USING ERRCODE = 'P0002';
    END IF;

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

GRANT EXECUTE ON FUNCTION public.toggle_post_like(UUID) TO authenticated;
