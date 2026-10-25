-- ==============================================================================
-- FAUNOVA MIGRATION 022: Fix Ambiguous "post_id" in get_user_public_posts RPC
-- Sesuai Plan 5.7, 5.9 & AGENTS.md
-- Menyelesaikan error: column reference "post_id" is ambiguous (42702)
-- saat memuat profil publik (PublicProfilePage) dan tab postingan sendiri (ProfilePage)
-- ==============================================================================

-- 1. PERBAIKAN RPC GET_USER_PUBLIC_POSTS (Dipanggil oleh SocialService.fetchUserPublicPosts)
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
        SELECT lk.post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes lk
        GROUP BY lk.post_id
    ) l ON l.post_id = p.id
    WHERE p.user_id = p_target_user_id
      AND p.deleted_at IS NULL
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_public_posts(UUID, INT) TO anon, authenticated;
