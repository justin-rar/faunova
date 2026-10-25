-- ==============================================================================
-- FAUNOVA MIGRATION 027: Tabel Notifikasi Sosial & RLS Penerima
-- Sesuai Dokumen Desain Plan 5.9, Scope Tingkat 3 & AGENTS.md
-- Catatan: File migrasi ini disiapkan untuk skema database masa depan,
-- TIDAK dijalankan langsung ke production DB sesuai instruksi pengaman.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('follow', 'like', 'system')),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Constraint: Pelaku aksi tidak boleh sama dengan penerima (like/follow diri sendiri tidak boleh buat notifikasi)
    CONSTRAINT chk_actor_not_recipient CHECK (actor_id <> recipient_id)
);

-- Index performa untuk pencarian notifikasi penerima
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_created 
ON public.notifications (recipient_id, created_at DESC);

-- RLS: Keamanan tingkat baris
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 1. Pengguna hanya dapat membaca notifikasi miliknya sendiri (sebagai recipient)
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications"
ON public.notifications FOR SELECT
TO authenticated
USING (recipient_id = auth.uid());

-- 2. Pengguna terautentikasi dapat membuat notifikasi untuk orang lain (actor_id = auth.uid())
-- dan DILARANG membuat notifikasi untuk diri sendiri (recipient_id <> auth.uid())
DROP POLICY IF EXISTS "Users can insert notifications for others" ON public.notifications;
CREATE POLICY "Users can insert notifications for others"
ON public.notifications FOR INSERT
TO authenticated
WITH CHECK (
    actor_id = auth.uid() 
    AND recipient_id <> auth.uid()
);

-- 3. Pengguna hanya dapat memperbarui (misal mark as read) notifikasi miliknya sendiri
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
ON public.notifications FOR UPDATE
TO authenticated
USING (recipient_id = auth.uid());

-- RPC untuk mengambil daftar notifikasi pengguna saat ini secara aman
CREATE OR REPLACE FUNCTION public.get_my_notifications(
    p_limit INT DEFAULT 20
)
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
SET search_path = public, auth
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n.recipient_id,
        n.actor_id,
        COALESCE(p.display_name, p.username, 'Penjelajah Satwa') AS actor_name,
        p.username AS actor_username,
        p.avatar_path AS actor_avatar,
        n.type,
        n.post_id,
        n.title,
        n.body,
        n.is_read,
        n.created_at
    FROM public.notifications n
    JOIN public.profiles p ON p.id = n.actor_id
    WHERE n.recipient_id = auth.uid()
      AND n.actor_id <> auth.uid()
    ORDER BY n.created_at DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 50);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_notifications(INT) TO authenticated;
