-- ==============================================================================
-- FAUNOVA MIGRATION 013: Perbaikan RPC update_my_profile dan Dukungan Avatar
-- Sesuai Dokumen Desain Plan 5.2, 5.7, 18 & AGENTS.md (Sesi S22)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.update_my_profile(
    p_display_name TEXT,
    p_bio TEXT DEFAULT NULL,
    p_avatar_path TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
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

    -- Update row profile yang ada
    UPDATE public.profiles
    SET 
        display_name = v_clean_name,
        bio = v_clean_bio,
        avatar_path = CASE 
            WHEN p_avatar_path = '__clear__' THEN NULL 
            WHEN p_avatar_path IS NOT NULL THEN p_avatar_path 
            ELSE avatar_path 
        END,
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

    -- Jika baris belum ada di profiles (misal akun dibuat sebelum trigger aktif), buat baris baru (upsert aman)
    IF NOT FOUND THEN
        INSERT INTO public.profiles (
            id,
            username,
            display_name,
            bio,
            avatar_path,
            created_at,
            updated_at
        ) VALUES (
            v_user_id,
            'kolektor_' || substr(md5(v_user_id::text), 1, 8),
            v_clean_name,
            v_clean_bio,
            CASE WHEN p_avatar_path = '__clear__' THEN NULL ELSE p_avatar_path END,
            now(),
            now()
        )
        RETURNING 
            id, 
            username, 
            display_name, 
            avatar_path, 
            bio, 
            false AS is_verified,
            streak_count,
            best_quiz_score,
            updated_at
        INTO v_updated;
    END IF;

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

-- Berikan hak akses eksekusi RPC ke pengguna yang terautentikasi
GRANT EXECUTE ON FUNCTION public.update_my_profile(TEXT, TEXT, TEXT) TO authenticated;
