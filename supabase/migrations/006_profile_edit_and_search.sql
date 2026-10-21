-- ==============================================================================
-- FAUNOVA MIGRATION 006: Edit Profil Sendiri dan Pencarian Akun & Spesies
-- Sesuai Dokumen Desain Plan 5.2, 5.4, 5.7, 18 & AGENTS.md (Sesi S11)
-- ==============================================================================

-- 1. INDEKS EKSPRESI UNTUK PENCARIAN CEPAT (Plan 5.7 & 459)
CREATE INDEX IF NOT EXISTS idx_profiles_lower_username ON public.profiles(lower(username));
CREATE INDEX IF NOT EXISTS idx_profiles_lower_display_name ON public.profiles(lower(display_name));
CREATE INDEX IF NOT EXISTS idx_captures_lower_species ON public.captures(lower(species_name));

-- 2. RPC UPDATE_MY_PROFILE
-- Memperbarui data profil sendiri (nama tampilan, bio, avatar) dengan validasi server
CREATE OR REPLACE FUNCTION public.update_my_profile(
    p_display_name TEXT,
    p_bio TEXT DEFAULT NULL,
    p_avatar_path TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID;
    v_clean_name TEXT;
    v_clean_bio TEXT;
    v_updated RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus terautentikasi untuk memperbarui profil.';
    END IF;

    v_clean_name := TRIM(COALESCE(p_display_name, ''));
    IF char_length(v_clean_name) < 2 THEN
        RAISE EXCEPTION 'Nama tampilan harus memiliki minimal 2 karakter.';
    END IF;

    IF char_length(v_clean_name) > 60 THEN
        RAISE EXCEPTION 'Nama tampilan maksimal 60 karakter.';
    END IF;

    v_clean_bio := TRIM(COALESCE(p_bio, ''));
    IF char_length(v_clean_bio) > 300 THEN
        RAISE EXCEPTION 'Bio profil maksimal 300 karakter.';
    END IF;

    UPDATE public.profiles
    SET 
        display_name = v_clean_name,
        bio = v_clean_bio,
        avatar_path = COALESCE(p_avatar_path, avatar_path),
        updated_at = now()
    WHERE id = v_user_id
    RETURNING 
        id, 
        username, 
        display_name, 
        avatar_path, 
        bio, 
        (verified_until IS NOT NULL AND verified_until > now()) AS is_verified,
        streak_count,
        best_quiz_score,
        updated_at
    INTO v_updated;

    RETURN jsonb_build_object(
        'success', true,
        'id', v_updated.id,
        'username', v_updated.username,
        'display_name', v_updated.display_name,
        'avatar_path', v_updated.avatar_path,
        'bio', v_updated.bio,
        'is_verified', v_updated.is_verified,
        'streak_count', v_updated.streak_count,
        'best_quiz_score', v_updated.best_quiz_score,
        'updated_at', v_updated.updated_at
    );
END;
$$;

-- 3. RPC SEARCH_ACCOUNTS
-- Pencarian akun penjelajah dengan aturan keras Plan 5.4 & 126:
-- Akun terverifikasi Centang Biru (is_verified) selalu DIPRIORITASKAN di urutan teratas!
CREATE OR REPLACE FUNCTION public.search_accounts(
    p_query TEXT DEFAULT '',
    p_limit INT DEFAULT 20
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
    captures_count BIGINT,
    followers_count BIGINT,
    is_followed_by_me BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_current_user_id UUID;
    v_clean_query TEXT;
    v_clamped_limit INT;
BEGIN
    v_current_user_id := auth.uid();
    v_clean_query := TRIM(COALESCE(p_query, ''));
    v_clamped_limit := LEAST(GREATEST(p_limit, 1), 50);

    RETURN QUERY
    SELECT 
        p.id,
        p.username,
        p.display_name,
        p.avatar_path,
        p.bio,
        (p.verified_until IS NOT NULL AND p.verified_until > now()) AS is_verified,
        p.streak_count,
        p.best_quiz_score,
        COALESCE(c.total_caps, 0)::BIGINT AS captures_count,
        COALESCE(f.total_followers, 0)::BIGINT AS followers_count,
        CASE 
            WHEN v_current_user_id IS NULL THEN false
            ELSE EXISTS (
                SELECT 1 FROM public.follows my_f
                WHERE my_f.follower_id = v_current_user_id AND my_f.followed_id = p.id
            )
        END AS is_followed_by_me
    FROM public.profiles p
    LEFT JOIN (
        SELECT user_id, COUNT(*)::BIGINT AS total_caps
        FROM public.captures
        WHERE deleted_at IS NULL
        GROUP BY user_id
    ) c ON c.user_id = p.id
    LEFT JOIN (
        SELECT followed_id, COUNT(*)::BIGINT AS total_followers
        FROM public.follows
        GROUP BY followed_id
    ) f ON f.followed_id = p.id
    WHERE (
        v_clean_query = '' OR 
        p.username ILIKE '%' || v_clean_query || '%' OR 
        p.display_name ILIKE '%' || v_clean_query || '%'
    )
    ORDER BY 
        -- ATURAN KERAS: Prioritas Centang Biru di urutan teratas
        (p.verified_until IS NOT NULL AND p.verified_until > now()) DESC,
        p.streak_count DESC,
        p.display_name ASC
    LIMIT v_clamped_limit;
END;
$$;

-- 4. RPC SEARCH_SPECIES
-- Pencarian taksonomi dan katalog satwa liar
-- Tanpa membocorkan koordinat privat
CREATE OR REPLACE FUNCTION public.search_species(
    p_query TEXT DEFAULT '',
    p_category TEXT DEFAULT 'Semua',
    p_limit INT DEFAULT 20
)
RETURNS TABLE (
    species_name TEXT,
    category TEXT,
    sample_photo_path TEXT,
    observations_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_clean_query TEXT;
    v_clean_category TEXT;
    v_clamped_limit INT;
BEGIN
    v_clean_query := TRIM(COALESCE(p_query, ''));
    v_clean_category := TRIM(COALESCE(p_category, 'Semua'));
    v_clamped_limit := LEAST(GREATEST(p_limit, 1), 50);

    RETURN QUERY
    SELECT 
        c.species_name,
        c.category,
        MAX(c.photo_object_path) AS sample_photo_path,
        COUNT(*)::BIGINT AS observations_count
    FROM public.captures c
    WHERE c.deleted_at IS NULL
      AND (
          v_clean_query = '' OR 
          c.species_name ILIKE '%' || v_clean_query || '%' OR 
          c.category ILIKE '%' || v_clean_query || '%'
      )
      AND (
          v_clean_category = 'Semua' OR 
          c.category ILIKE '%' || v_clean_category || '%'
      )
    GROUP BY c.species_name, c.category
    ORDER BY COUNT(*) DESC, c.species_name ASC
    LIMIT v_clamped_limit;
END;
$$;

-- Hak akses eksekusi RPC
GRANT EXECUTE ON FUNCTION public.update_my_profile(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_accounts(TEXT, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.search_species(TEXT, TEXT, INT) TO anon, authenticated;
