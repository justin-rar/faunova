-- ==============================================================================
-- FAUNOVA MIGRATION 012: Centang Biru (verified_until, kuota chat 10, prioritas pencarian)
-- Sesuai Plan 5.4, Plan 120-126, Plan 150 & AGENTS.md (Sesi S20)
-- ==============================================================================

-- 1. PEMBARUAN RPC GET_PUBLIC_PROFILE: Menyertakan verified_until dan is_verified aktif
CREATE OR REPLACE FUNCTION public.get_public_profile(
    p_target_user_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
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
        (verified_until IS NOT NULL AND verified_until > timezone('utc', now())) AS is_verified,
        verified_until,
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
        'verified_until', v_profile.verified_until,
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

-- 2. PEMBARUAN RPC RESERVE_CHAT_QUOTA (Aturan Keras 2 & Plan 125, 150):
-- Server secara otomatis menetapkan kuota = 10 jika verified_until > now(), selain itu 5.
CREATE OR REPLACE FUNCTION public.reserve_chat_quota(
    p_scan_id UUID,
    p_user_id UUID,
    p_limit INT DEFAULT NULL
)
RETURNS TABLE(allowed BOOLEAN, current_chat_count INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_verified_until TIMESTAMPTZ;
    v_effective_limit INT;
    v_new_count INT;
BEGIN
    -- Ambil status verified_until pengguna dari tabel profiles di server
    SELECT verified_until INTO v_verified_until
    FROM public.profiles
    WHERE id = p_user_id;

    -- Kuota 10 pertanyaan jika Centang Biru aktif, selain itu 5 reguler (Plan 125, 150)
    IF v_verified_until IS NOT NULL AND v_verified_until > timezone('utc', now()) THEN
        v_effective_limit := 10;
    ELSE
        v_effective_limit := 5;
    END IF;

    -- Jika klien mengirimkan p_limit tertentu, jangan izinkan melebihi v_effective_limit
    IF p_limit IS NOT NULL AND p_limit > 0 AND p_limit < v_effective_limit THEN
        v_effective_limit := p_limit;
    END IF;

    -- Update bersyarat dengan kunci baris atomik
    UPDATE public.scans
    SET chat_count = chat_count + 1
    WHERE id = p_scan_id
      AND user_id = p_user_id
      AND is_animal = true
      AND chat_count < v_effective_limit
    RETURNING chat_count INTO v_new_count;

    IF FOUND THEN
        RETURN QUERY SELECT true, v_new_count;
    ELSE
        SELECT chat_count INTO v_new_count 
        FROM public.scans 
        WHERE id = p_scan_id AND user_id = p_user_id;
        
        RETURN QUERY SELECT false, COALESCE(v_new_count, v_effective_limit);
    END IF;
END;
$$;

-- 3. PEMBARUAN RPC SEARCH_ACCOUNTS: Prioritas Centang Biru di urutan teratas (Plan 5.4: 126)
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
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_current_user_id UUID;
    v_clean_query TEXT;
    v_clamped_limit INT;
    v_now TIMESTAMPTZ := timezone('utc', now());
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
        (p.verified_until IS NOT NULL AND p.verified_until > v_now) AS is_verified,
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
        -- ATURAN KERAS (Plan 126): Prioritas Centang Biru di urutan teratas
        (p.verified_until IS NOT NULL AND p.verified_until > v_now) DESC,
        p.streak_count DESC,
        p.display_name ASC
    LIMIT v_clamped_limit;
END;
$$;

-- Berikan izin eksekusi kepada peran terautentikasi dan publik
GRANT EXECUTE ON FUNCTION public.get_public_profile(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_chat_quota(UUID, UUID, INT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.search_accounts(TEXT, INT) TO anon, authenticated;
