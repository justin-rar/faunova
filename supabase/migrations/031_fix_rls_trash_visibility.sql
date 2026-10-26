-- ==============================================================================
-- FAUNOVA MIGRATION 031: Penyelarasan Visibilitas Sampah (Trash) dan RLS
-- Sesuai Aturan Keras AGENTS.md & Scope S21
--
-- Masalah yang diselesaikan:
-- 1. RLS SELECT pada posts dan captures belum memfilter trashed_at dan purged_at,
--    sehingga query langsung ke tabel masih melihat item di tempat sampah.
-- 2. RPC get_user_posts (dari migrasi 014) belum memfilter trashed_at, sehingga
--    postingan di tempat sampah masih terlihat saat membuka profil penjelajah.
-- 3. RPC get_my_notifications menampilkan pesan ramah jika postingan terkait
--    berada di tempat sampah (tanpa crash atau error pada klien).
-- ==============================================================================

-- 1. PERBAIKI RLS POLICY POSTS: Filter deleted_at IS NULL DAN trashed_at IS NULL
DROP POLICY IF EXISTS "Posts: Pengguna dapat membaca postingan aktif" ON public.posts;

CREATE POLICY "Posts: Pengguna dapat membaca postingan aktif"
    ON public.posts FOR SELECT
    TO authenticated
    USING (deleted_at IS NULL AND trashed_at IS NULL);

-- 2. PERBAIKI RLS POLICY CAPTURES: Filter trashed_at IS NULL DAN purged_at IS NULL
DROP POLICY IF EXISTS "Captures: Pemilik dapat membaca koleksi sendiri" ON public.captures;

CREATE POLICY "Captures: Pemilik dapat membaca koleksi sendiri"
    ON public.captures FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NULL AND trashed_at IS NULL AND purged_at IS NULL);

-- 3. PERBAIKAN RPC GET_USER_POSTS: Filter trashed_at pada posts dan captures
CREATE OR REPLACE FUNCTION public.get_user_posts(
    p_user_id UUID,
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
    WHERE p.user_id = p_user_id
      AND p.deleted_at IS NULL
      AND p.trashed_at IS NULL
      AND (c.id IS NULL OR (c.deleted_at IS NULL AND c.trashed_at IS NULL AND c.purged_at IS NULL))
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_posts(UUID, INT, TIMESTAMPTZ) TO anon, authenticated;

-- 4. PERBAIKAN RPC GET_MY_NOTIFICATIONS: Pesan ramah untuk postingan di Sampah
CREATE OR REPLACE FUNCTION public.get_my_notifications(p_limit INT DEFAULT 30)
RETURNS TABLE (
    id UUID,
    recipient_id UUID,
    actor_id UUID,
    actor_name TEXT,
    actor_username TEXT,
    actor_avatar TEXT,
    type TEXT,
    post_id UUID,
    title TEXT,
    body TEXT,
    is_read BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n.recipient_id,
        n.actor_id,
        COALESCE(p_act.display_name, p_act.username, 'Penjelajah Satwa') AS actor_name,
        p_act.username AS actor_username,
        p_act.avatar_path AS actor_avatar,
        n.type,
        n.post_id,
        CASE 
            WHEN n.post_id IS NOT NULL AND (p.id IS NULL OR p.trashed_at IS NOT NULL OR p.deleted_at IS NOT NULL OR c.trashed_at IS NOT NULL OR c.purged_at IS NOT NULL) THEN 'Postingan Tidak Tersedia'
            ELSE n.title
        END AS title,
        CASE 
            WHEN n.post_id IS NOT NULL AND (p.id IS NULL OR p.trashed_at IS NOT NULL OR p.deleted_at IS NOT NULL OR c.trashed_at IS NOT NULL OR c.purged_at IS NOT NULL) THEN 'Postingan ini telah dipindahkan ke Sampah atau tidak lagi tersedia.'
            ELSE n.body
        END AS body,
        n.is_read,
        n.created_at
    FROM public.notifications n
    JOIN public.profiles p_act ON p_act.id = n.actor_id
    LEFT JOIN public.posts p ON p.id = n.post_id
    LEFT JOIN public.captures c ON c.id = p.capture_id
    WHERE n.recipient_id = auth.uid()
      AND n.actor_id <> auth.uid()
    ORDER BY n.created_at DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 50);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_notifications(INT) TO authenticated;
