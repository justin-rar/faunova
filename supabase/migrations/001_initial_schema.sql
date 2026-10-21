-- ==============================================================================
-- FAUNOVA - MIGRATION 001: SKEMA INTI (Sesi S3)
-- Acuan: AGENTS.md, docs/plan_faunova_revisi_5_final.md Bagian 15 & 16
-- ==============================================================================

-- 1. EKSTENSI (UUID)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TABEL PROFILES (Kolektor Satwa)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    avatar_path TEXT,
    bio TEXT DEFAULT '',
    streak_count INT NOT NULL DEFAULT 0 CHECK (streak_count >= 0),
    last_streak_claim_date DATE,
    verified_until TIMESTAMPTZ,
    best_quiz_score INT NOT NULL DEFAULT 0 CHECK (best_quiz_score >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT username_min_length CHECK (char_length(username) >= 3),
    CONSTRAINT username_valid_chars CHECK (username ~ '^[a-z0-9_]+$')
);

-- Indeks performa profil
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_verified ON public.profiles(verified_until);

-- Aktifkan RLS di profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy RLS profiles:
-- 1. Pemilik dapat melihat profil lengkapnya sendiri
CREATE POLICY "Profiles: Pemilik dapat membaca profil sendiri"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- 2. Pemilik hanya boleh mengubah kolom profil bebas (username, display_name, avatar_path, bio)
CREATE POLICY "Profiles: Pemilik dapat memperbarui profil sendiri"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ==============================================================================
-- 3. TRIGGER OTOMATIS: Registrasi auth.users -> public.profiles
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    new_username TEXT;
    new_display_name TEXT;
BEGIN
    -- Ambil dari metadata pendaftaran jika ada, atau fallback ke username acak dari email
    new_username := lower(COALESCE(
        NEW.raw_user_meta_data->>'username',
        'kolektor_' || substr(md5(random()::text), 1, 8)
    ));
    
    new_display_name := COALESCE(
        NEW.raw_user_meta_data->>'display_name',
        NEW.raw_user_meta_data->>'full_name',
        'Penjelajah Faunova'
    );

    INSERT INTO public.profiles (
        id,
        username,
        display_name,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        new_username,
        new_display_name,
        now(),
        now()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

-- Trigger pada tabel auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 4. VIEW PROFIL PUBLIK (Aman, Tanpa Kolom Sensitif / Private)
-- ==============================================================================
CREATE OR REPLACE VIEW public.public_profiles AS
SELECT 
    p.id,
    p.username,
    p.display_name,
    p.avatar_path,
    p.bio,
    (p.verified_until IS NOT NULL AND p.verified_until > now()) AS is_verified,
    p.streak_count,
    p.best_quiz_score,
    p.created_at
FROM public.profiles p;

-- Grant SELECT ke anon dan authenticated untuk public_profiles
GRANT SELECT ON public.public_profiles TO anon, authenticated;

-- ==============================================================================
-- 5. TABEL SCANS & DAILY_SCAN_USAGE (AI Scan & Kuota)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.scans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    request_id UUID NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'rejected_not_animal')),
    is_animal BOOLEAN,
    result JSONB,
    photo_sha256 CHAR(64),
    temp_object_path TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    camera_heading NUMERIC,
    location_check TEXT,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    provider_started_at TIMESTAMPTZ,
    chat_count INT NOT NULL DEFAULT 0,
    photo_deleted_at TIMESTAMPTZ,
    capture_status TEXT DEFAULT 'none' CHECK (capture_status IN ('none', 'saved', 'discarded')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_scans_user_request UNIQUE (user_id, request_id)
);

CREATE INDEX IF NOT EXISTS idx_scans_user_created ON public.scans(user_id, created_at DESC);

ALTER TABLE public.scans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Scans: Pemilik dapat membaca riwayat scan sendiri"
    ON public.scans FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- Kuota Harian Scan (20 scan / hari, dihitung WIB)
CREATE TABLE IF NOT EXISTS public.daily_scan_usage (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date_wib DATE NOT NULL,
    used_count INT NOT NULL DEFAULT 0 CHECK (used_count >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY(user_id, date_wib)
);

ALTER TABLE public.daily_scan_usage ENABLE ROW LEVEL SECURITY;

CREATE POLICY "DailyScanUsage: Pemilik dapat membaca kuota scan sendiri"
    ON public.daily_scan_usage FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

-- ==============================================================================
-- 6. TABEL CAPTURES (Koleksi Hewan Terverifikasi + Hash Chain)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.captures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scan_id UUID UNIQUE REFERENCES public.scans(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    photo_object_path TEXT NOT NULL,
    species_name TEXT NOT NULL,
    category TEXT,
    description TEXT DEFAULT '',
    latitude NUMERIC,
    longitude NUMERIC,
    camera_heading NUMERIC,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    seq BIGINT NOT NULL,
    previous_hash CHAR(64) NOT NULL,
    block_hash CHAR(64) NOT NULL,
    photo_sha256 CHAR(64) NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_captures_user_seq UNIQUE (user_id, seq)
);

CREATE INDEX IF NOT EXISTS idx_captures_user_created ON public.captures(user_id, created_at DESC);

ALTER TABLE public.captures ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Captures: Pemilik dapat membaca koleksi sendiri"
    ON public.captures FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id AND deleted_at IS NULL);

-- ==============================================================================
-- 7. TABEL POSTS (Feed Komunitas — Koordinat Snapped, Tanpa Koordinat Tepat)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    capture_id UUID UNIQUE REFERENCES public.captures(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    caption TEXT DEFAULT '',
    location_visibility TEXT NOT NULL CHECK (location_visibility IN ('coarse', 'hidden')),
    display_latitude NUMERIC,
    display_longitude NUMERIC,
    area_label TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_posts_feed_created ON public.posts(created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_posts_user_created ON public.posts(user_id, created_at DESC) WHERE deleted_at IS NULL;

ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Siapa pun (authenticated) boleh membaca postingan yang aktif
CREATE POLICY "Posts: Pengguna dapat membaca postingan aktif"
    ON public.posts FOR SELECT
    TO authenticated
    USING (deleted_at IS NULL);

-- Pemilik boleh menghapus post (soft delete)
CREATE POLICY "Posts: Pemilik dapat memperbarui post sendiri"
    ON public.posts FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ==============================================================================
-- 8. TABEL FOLLOWS & LIKES (Relasi Sosial)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.follows (
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    followed_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY(follower_id, followed_id),
    CONSTRAINT follows_not_self CHECK (follower_id <> followed_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_followed ON public.follows(followed_id, follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id, followed_id);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Follows: Pengguna dapat membaca relasi follow"
    ON public.follows FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Follows: Pengguna dapat follow"
    ON public.follows FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Follows: Pengguna dapat unfollow"
    ON public.follows FOR DELETE
    TO authenticated
    USING (auth.uid() = follower_id);

CREATE TABLE IF NOT EXISTS public.likes (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_post ON public.likes(post_id, created_at DESC);

ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Likes: Pengguna dapat membaca like"
    ON public.likes FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Likes: Pengguna dapat memberi like"
    ON public.likes FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Likes: Pengguna dapat menarik like"
    ON public.likes FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
