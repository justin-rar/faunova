-- ==============================================================================
-- FAUNOVA MIGRATION 005: Follow, Tab Mengikuti, Like & Profil Publik
-- Sesuai Dokumen Desain Plan 5.7, 5.9, 18, 19 & AGENTS.md (Sesi S10)
-- ==============================================================================

-- 1. RPC TOGGLE_FOLLOW_USER
-- Mengikuti atau berhenti mengikuti akun lain secara atomik dan idempoten
-- Memeriksa constraint follower_id <> followed_id (tidak bisa follow diri sendiri)
CREATE OR REPLACE FUNCTION public.toggle_follow_user(
    p_target_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_current_user_id UUID;
    v_already_following BOOLEAN;
    v_new_is_following BOOLEAN;
    v_followers_count BIGINT;
    v_following_count BIGINT;
BEGIN
    v_current_user_id := auth.uid();
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus terautentikasi untuk mengikuti pengguna lain.';
    END IF;

    IF v_current_user_id = p_target_user_id THEN
        RAISE EXCEPTION 'Pengguna tidak dapat mengikuti diri sendiri.';
    END IF;

    -- Pastikan target pengguna ada di tabel profiles
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_target_user_id) THEN
        RAISE EXCEPTION 'Profil target tidak ditemukan.';
    END IF;

    -- Periksa status relasi follow saat ini
    SELECT EXISTS (
        SELECT 1 FROM public.follows
        WHERE follower_id = v_current_user_id AND followed_id = p_target_user_id
    ) INTO v_already_following;

    IF v_already_following THEN
        -- Batalkan ikuti (Unfollow)
        DELETE FROM public.follows
        WHERE follower_id = v_current_user_id AND followed_id = p_target_user_id;
        v_new_is_following := false;
    ELSE
        -- Ikuti (Follow)
        INSERT INTO public.follows (follower_id, followed_id, created_at)
        VALUES (v_current_user_id, p_target_user_id, now())
        ON CONFLICT (follower_id, followed_id) DO NOTHING;
        v_new_is_following := true;
    END IF;

    -- Hitung jumlah pengikut (followers) dan yang diikuti (following) target
    SELECT COUNT(*)::BIGINT INTO v_followers_count
    FROM public.follows WHERE followed_id = p_target_user_id;

    SELECT COUNT(*)::BIGINT INTO v_following_count
    FROM public.follows WHERE follower_id = p_target_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'target_user_id', p_target_user_id,
        'is_following', v_new_is_following,
        'followers_count', v_followers_count,
        'following_count', v_following_count
    );
END;
$$;

-- 2. PENYELARASAN RPC GET_FOR_YOU_FEED
-- Memastikan kolom join u.display_name dan u.avatar_path sesuai skema profiles
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
        u.display_name AS author_name,
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

-- 3. RPC GET_FOLLOWING_FEED
-- Mengambil feed linimasa akun yang diikuti (Tab "Mengikuti")
-- Koordinat privat terlindungi dengan grid-snapping (display_latitude & display_longitude)
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
SET search_path = public, auth
AS $$
DECLARE
    v_current_user_id UUID;
    v_clamped_limit INT;
BEGIN
    v_current_user_id := auth.uid();
    IF v_current_user_id IS NULL THEN
        RETURN;
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
        c.species_name,
        c.category,
        c.photo_object_path,
        c.seq AS block_seq,
        c.block_hash,
        c.photo_sha256,
        u.id AS author_id,
        u.display_name AS author_name,
        u.username AS author_username,
        u.avatar_path AS author_avatar,
        u.verified_until AS author_verified_until,
        COALESCE(l.likes_total, 0)::BIGINT AS likes_count,
        EXISTS (
            SELECT 1 FROM public.likes my_l 
            WHERE my_l.post_id = p.id AND my_l.user_id = v_current_user_id
        ) AS is_liked_by_me
    FROM public.posts p
    JOIN public.captures c ON c.id = p.capture_id AND c.deleted_at IS NULL
    JOIN public.profiles u ON u.id = p.user_id
    JOIN public.follows f ON f.followed_id = p.user_id AND f.follower_id = v_current_user_id
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

-- 4. RPC GET_PUBLIC_PROFILE
-- Mengambil profil publik pengguna lengkap beserta agregat statistik
-- Tidak membocorkan kolom rahasia atau koordinat mentah
CREATE OR REPLACE FUNCTION public.get_public_profile(
    p_target_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_current_user_id UUID;
    v_profile RECORD;
    v_captures_count BIGINT;
    v_posts_count BIGINT;
    v_followers_count BIGINT;
    v_following_count BIGINT;
    v_is_followed BOOLEAN;
BEGIN
    v_current_user_id := auth.uid();

    SELECT 
        id,
        username,
        display_name,
        avatar_path,
        bio,
        (verified_until IS NOT NULL AND verified_until > now()) AS is_verified,
        streak_count,
        best_quiz_score,
        created_at
    INTO v_profile
    FROM public.profiles
    WHERE id = p_target_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('found', false);
    END IF;

    -- Hitung total koleksi aktif
    SELECT COUNT(*)::BIGINT INTO v_captures_count
    FROM public.captures
    WHERE user_id = p_target_user_id AND deleted_at IS NULL;

    -- Hitung total postingan publik
    SELECT COUNT(*)::BIGINT INTO v_posts_count
    FROM public.posts
    WHERE user_id = p_target_user_id AND deleted_at IS NULL;

    -- Hitung pengikut (followers)
    SELECT COUNT(*)::BIGINT INTO v_followers_count
    FROM public.follows
    WHERE followed_id = p_target_user_id;

    -- Hitung yang diikuti (following)
    SELECT COUNT(*)::BIGINT INTO v_following_count
    FROM public.follows
    WHERE follower_id = p_target_user_id;

    -- Status apakah saya mengikuti user target ini
    IF v_current_user_id IS NOT NULL AND v_current_user_id <> p_target_user_id THEN
        SELECT EXISTS (
            SELECT 1 FROM public.follows
            WHERE follower_id = v_current_user_id AND followed_id = p_target_user_id
        ) INTO v_is_followed;
    ELSE
        v_is_followed := false;
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'id', v_profile.id,
        'username', v_profile.username,
        'display_name', v_profile.display_name,
        'avatar_path', v_profile.avatar_path,
        'bio', COALESCE(v_profile.bio, ''),
        'is_verified', v_profile.is_verified,
        'streak_count', v_profile.streak_count,
        'best_quiz_score', v_profile.best_quiz_score,
        'created_at', v_profile.created_at,
        'captures_count', v_captures_count,
        'posts_count', v_posts_count,
        'followers_count', v_followers_count,
        'following_count', v_following_count,
        'is_followed_by_me', v_is_followed,
        'is_my_profile', (v_current_user_id = p_target_user_id)
    );
END;
$$;

-- 5. RPC GET_USER_PUBLIC_POSTS
-- Mengambil daftar postingan publik dari profil pengguna tertentu
CREATE OR REPLACE FUNCTION public.get_user_public_posts(
    p_target_user_id UUID,
    p_limit INT DEFAULT 30
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
        c.species_name,
        c.category,
        c.photo_object_path,
        c.seq AS block_seq,
        c.block_hash,
        c.photo_sha256,
        u.id AS author_id,
        u.display_name AS author_name,
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
    JOIN public.captures c ON c.id = p.capture_id AND c.deleted_at IS NULL
    JOIN public.profiles u ON u.id = p.user_id
    LEFT JOIN (
        SELECT post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes
        GROUP BY post_id
    ) l ON l.post_id = p.id
    WHERE p.user_id = p_target_user_id
      AND p.deleted_at IS NULL
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

-- Hak akses eksekusi RPC
GRANT EXECUTE ON FUNCTION public.toggle_follow_user(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_for_you_feed(INT, TIMESTAMPTZ) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_following_feed(INT, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_public_profile(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_public_posts(UUID, INT) TO anon, authenticated;
