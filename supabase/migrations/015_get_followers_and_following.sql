-- ==============================================================================
-- FAUNOVA MIGRATION 015: RPC GET_USER_FOLLOWERS & GET_USER_FOLLOWING
-- Mengambil daftar profil pengikut (followers) dan yang diikuti (following)
-- Sesuai AGENTS.md (SECURITY DEFINER, search_path, RLS)
-- ==============================================================================

-- 1. RPC GET_USER_FOLLOWERS
CREATE OR REPLACE FUNCTION public.get_user_followers(
    p_target_user_id UUID,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    username TEXT,
    display_name TEXT,
    avatar_path TEXT,
    bio TEXT,
    is_verified BOOLEAN,
    streak_count INT,
    best_quiz_score INT,
    followers_count BIGINT,
    following_count BIGINT,
    is_followed_by_me BOOLEAN,
    is_my_profile BOOLEAN
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
    v_clamped_limit := LEAST(GREATEST(p_limit, 1), 100);

    RETURN QUERY
    SELECT 
        u.id,
        u.username,
        u.display_name,
        u.avatar_path,
        COALESCE(u.bio, '') AS bio,
        (u.verified_until IS NOT NULL AND u.verified_until > now()) AS is_verified,
        u.streak_count,
        u.best_quiz_score,
        COALESCE(fc.count, 0)::BIGINT AS followers_count,
        COALESCE(fg.count, 0)::BIGINT AS following_count,
        CASE 
            WHEN v_current_user_id IS NULL THEN false
            ELSE EXISTS (
                SELECT 1 FROM public.follows my_f 
                WHERE my_f.follower_id = v_current_user_id AND my_f.followed_id = u.id
            )
        END AS is_followed_by_me,
        (v_current_user_id IS NOT NULL AND v_current_user_id = u.id) AS is_my_profile
    FROM public.follows f
    JOIN public.profiles u ON u.id = f.follower_id
    LEFT JOIN (
        SELECT followed_id, COUNT(*)::BIGINT AS count
        FROM public.follows
        GROUP BY followed_id
    ) fc ON fc.followed_id = u.id
    LEFT JOIN (
        SELECT follower_id, COUNT(*)::BIGINT AS count
        FROM public.follows
        GROUP BY follower_id
    ) fg ON fg.follower_id = u.id
    WHERE f.followed_id = p_target_user_id
    ORDER BY f.created_at DESC
    LIMIT v_clamped_limit OFFSET GREATEST(p_offset, 0);
END;
$$;

-- 2. RPC GET_USER_FOLLOWING
CREATE OR REPLACE FUNCTION public.get_user_following(
    p_target_user_id UUID,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    username TEXT,
    display_name TEXT,
    avatar_path TEXT,
    bio TEXT,
    is_verified BOOLEAN,
    streak_count INT,
    best_quiz_score INT,
    followers_count BIGINT,
    following_count BIGINT,
    is_followed_by_me BOOLEAN,
    is_my_profile BOOLEAN
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
    v_clamped_limit := LEAST(GREATEST(p_limit, 1), 100);

    RETURN QUERY
    SELECT 
        u.id,
        u.username,
        u.display_name,
        u.avatar_path,
        COALESCE(u.bio, '') AS bio,
        (u.verified_until IS NOT NULL AND u.verified_until > now()) AS is_verified,
        u.streak_count,
        u.best_quiz_score,
        COALESCE(fc.count, 0)::BIGINT AS followers_count,
        COALESCE(fg.count, 0)::BIGINT AS following_count,
        CASE 
            WHEN v_current_user_id IS NULL THEN false
            ELSE EXISTS (
                SELECT 1 FROM public.follows my_f 
                WHERE my_f.follower_id = v_current_user_id AND my_f.followed_id = u.id
            )
        END AS is_followed_by_me,
        (v_current_user_id IS NOT NULL AND v_current_user_id = u.id) AS is_my_profile
    FROM public.follows f
    JOIN public.profiles u ON u.id = f.followed_id
    LEFT JOIN (
        SELECT followed_id, COUNT(*)::BIGINT AS count
        FROM public.follows
        GROUP BY followed_id
    ) fc ON fc.followed_id = u.id
    LEFT JOIN (
        SELECT follower_id, COUNT(*)::BIGINT AS count
        FROM public.follows
        GROUP BY follower_id
    ) fg ON fg.follower_id = u.id
    WHERE f.follower_id = p_target_user_id
    ORDER BY f.created_at DESC
    LIMIT v_clamped_limit OFFSET GREATEST(p_offset, 0);
END;
$$;

-- Grant izin ke anon dan authenticated
GRANT EXECUTE ON FUNCTION public.get_user_followers(UUID, INT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_following(UUID, INT, INT) TO anon, authenticated;
