-- ==============================================================================
-- FAUNOVA MIGRATION 014: PERBAIKAN RPC FEED & SEED KOMUNITAS DEMO SATWA
-- Sesuai acuan: docs/plan_faunova_revisi_5_final.md (Bagian 15, 17, 18) & Scope S24
-- ==============================================================================
--
-- 1. Menyelesaikan error: column reference "post_id" is ambiguous (42702)
--    pada RPC get_for_you_feed, get_following_feed, dan get_user_posts.
-- 2. Menambahkan 6 akun kurasi peneliti satwa Nusantara lengkap dengan
--    centang biru, tangkapan jurnal kamera, dan postingan feed dengan foto asli.
-- ==============================================================================

-- ==============================================================================
-- BAGIAN 1: PERBAIKAN RPC GET_FOR_YOU_FEED
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
        SELECT lk.post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes lk
        GROUP BY lk.post_id
    ) l ON l.post_id = p.id
    WHERE p.deleted_at IS NULL
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

-- ==============================================================================
-- BAGIAN 2: PERBAIKAN RPC GET_FOLLOWING_FEED
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
SET search_path = public, auth
AS $$
DECLARE
    v_current_user_id UUID;
    v_clamped_limit INT;
BEGIN
    v_current_user_id := auth.uid();
    v_clamped_limit := LEAST(GREATEST(p_limit, 1), 50);

    IF v_current_user_id IS NULL THEN
        RETURN;
    END IF;

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
    JOIN public.follows f ON f.followed_id = p.user_id AND f.follower_id = v_current_user_id
    JOIN public.captures c ON c.id = p.capture_id AND c.deleted_at IS NULL
    JOIN public.profiles u ON u.id = p.user_id
    LEFT JOIN (
        SELECT lk.post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes lk
        GROUP BY lk.post_id
    ) l ON l.post_id = p.id
    WHERE p.deleted_at IS NULL
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

-- ==============================================================================
-- BAGIAN 3: PERBAIKAN RPC GET_USER_POSTS
-- ==============================================================================
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
        SELECT lk.post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes lk
        GROUP BY lk.post_id
    ) l ON l.post_id = p.id
    WHERE p.user_id = p_user_id
      AND p.deleted_at IS NULL
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

-- Izin pemanggilan RPC
GRANT EXECUTE ON FUNCTION public.get_for_you_feed(INT, TIMESTAMPTZ) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_following_feed(INT, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_posts(UUID, INT, TIMESTAMPTZ) TO anon, authenticated;

-- ==============================================================================
-- BAGIAN 4: SEED AKUN DEMO & JURNAL SATWA INDONESIA
-- ==============================================================================
DO $$
DECLARE
    u_wayan UUID := 'aa111111-1111-1111-1111-111111111111';
    u_siti UUID  := 'bb222222-2222-2222-2222-222222222222';
    u_budi UUID  := 'cc333333-3333-3333-3333-333333333333';
    u_borneo UUID:= 'dd444444-4444-4444-4444-444444444444';
    u_dewi UUID  := 'ee555555-5555-5555-5555-555555555555';
    u_faiz UUID  := 'ff666666-6666-6666-6666-666666666666';

    s_komodo UUID := '11111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    s_jalak UUID  := '22222222-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    s_tiger UUID  := '33333333-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    s_ape UUID    := '44444444-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    s_bird UUID   := '55555555-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    s_turtle UUID := '66666666-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

    c_komodo UUID := '11111111-cccc-cccc-cccc-cccccccccccc';
    c_jalak UUID  := '22222222-cccc-cccc-cccc-cccccccccccc';
    c_tiger UUID  := '33333333-cccc-cccc-cccc-cccccccccccc';
    c_ape UUID    := '44444444-cccc-cccc-cccc-cccccccccccc';
    c_bird UUID   := '55555555-cccc-cccc-cccc-cccccccccccc';
    c_turtle UUID := '66666666-cccc-cccc-cccc-cccccccccccc';

    p_komodo UUID := '11111111-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    p_jalak UUID  := '22222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    p_tiger UUID  := '33333333-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    p_ape UUID    := '44444444-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    p_bird UUID   := '55555555-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    p_turtle UUID := '66666666-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
BEGIN
    -- 1. DAFTARKAN AUTH.USERS DEMO
    INSERT INTO auth.users (id, aud, role, email, created_at, updated_at)
    VALUES
        (u_wayan, 'authenticated', 'authenticated', 'dr_wayan@faunova.id', now(), now()),
        (u_siti, 'authenticated', 'authenticated', 'siti_sarah@faunova.id', now(), now()),
        (u_budi, 'authenticated', 'authenticated', 'budi_satria@faunova.id', now(), now()),
        (u_borneo, 'authenticated', 'authenticated', 'dedi_borneo@faunova.id', now(), now()),
        (u_dewi, 'authenticated', 'authenticated', 'dewi_papua@faunova.id', now(), now()),
        (u_faiz, 'authenticated', 'authenticated', 'faiz_ocean@faunova.id', now(), now())
    ON CONFLICT (id) DO NOTHING;

    -- 2. SEED PROFIL KOLEKTOR (Centang Biru aktif untuk Wayan, Siti, Budi, Faiz)
    INSERT INTO public.profiles (id, username, display_name, bio, verified_until, streak_count, best_quiz_score)
    VALUES
        (u_wayan, 'wayan_bali', 'Dr. Wayan Suastika, M.Si', 'Dokter satwa & ranger Pulau Komodo. Mengamati keanekaragaman reptil purba nusantara.', now() + interval '60 days', 28, 98),
        (u_siti, 'siti_sumatera', 'Siti Sarah, S.Hut', 'Peneliti karnivora besar & patroli konservasi SMART Bukit Barisan Selatan.', now() + interval '45 days', 21, 95),
        (u_budi, 'budi_satria', 'Budi Satria Wibowo', 'Pencinta ornitologi & penjelajah hutan tropis Indonesia. Mengamati burung endemik Wallacea.', now() + interval '30 days', 14, 92),
        (u_borneo, 'borneo_wildlife', 'Dedi Pratama', 'Konservasionis Orangutan Kalimantan & pemantau koridor hutan Tanjung Puting.', NULL, 9, 88),
        (u_dewi, 'dewi_papua', 'Dewi Lestari', 'Pengamat Aves tanah Papua & pegiat edukasi keanekaragaman hayati nusantara.', NULL, 7, 85),
        (u_faiz, 'faiz_ocean', 'Faiz Alamsyah', 'Naturalis laut & penyelam konservasi terumbu karang Kepulauan Derawan.', now() + interval '20 days', 12, 90)
    ON CONFLICT (id) DO UPDATE SET
        username = EXCLUDED.username,
        display_name = EXCLUDED.display_name,
        bio = EXCLUDED.bio,
        verified_until = EXCLUDED.verified_until,
        streak_count = EXCLUDED.streak_count,
        best_quiz_score = EXCLUDED.best_quiz_score;

    -- 3. SEED SCAN SATWA
    INSERT INTO public.scans (id, user_id, request_id, status, is_animal, photo_sha256, latitude, longitude, camera_heading, received_at)
    VALUES
        (s_komodo, u_wayan, '11111111-1111-1111-1111-000000000001', 'completed', true, '7f9a8b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a', -8.585233, 119.495411, 135.0, now() - interval '15 minutes'),
        (s_jalak, u_budi, '22222222-2222-2222-2222-000000000002', 'completed', true, '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b', -8.115211, 114.525188, 90.0, now() - interval '1 hour'),
        (s_tiger, u_siti, '33333333-3333-3333-3333-000000000003', 'completed', true, '3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d', -5.255411, 104.225199, 180.0, now() - interval '3 hours'),
        (s_ape, u_borneo, '44444444-4444-4444-4444-000000000004', 'completed', true, '5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f', -2.755188, 111.925188, 220.0, now() - interval '6 hours'),
        (s_bird, u_dewi, '55555555-5555-5555-5555-000000000005', 'completed', true, '7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b', -1.155211, 133.955411, 45.0, now() - interval '10 hours'),
        (s_turtle, u_faiz, '66666666-6666-6666-6666-000000000006', 'completed', true, '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b', 2.255199, 118.255188, 310.0, now() - interval '14 hours')
    ON CONFLICT (id) DO NOTHING;

    -- 4. SEED CAPTURES (Buku Besar Hash-Chain Kanonis)
    INSERT INTO public.captures (id, scan_id, user_id, photo_object_path, species_name, category, description, latitude, longitude, camera_heading, received_at, seq, previous_hash, block_hash, photo_sha256)
    VALUES
        (c_komodo, s_komodo, u_wayan, 'https://images.unsplash.com/photo-1544979590-37e9b47eb705?w=900&auto=format&fit=crop&q=80', 'Komodo', 'Varanus komodoensis', 'Individu jantan dewasa di savana Loh Liang', -8.585233, 119.495411, 135.0, now() - interval '15 minutes', 1, '0000000000000000000000000000000000000000000000000000000000000000', '7f9a8b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a', '7f9a8b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a'),
        (c_jalak, s_jalak, u_budi, 'https://images.unsplash.com/photo-1552728089-57bdde30beb3?w=900&auto=format&fit=crop&q=80', 'Jalak Bali', 'Leucopsar rothschildi', 'Sepasang bertengger di pesisir Teluk Brumbun', -8.115211, 114.525188, 90.0, now() - interval '1 hour', 1, '0000000000000000000000000000000000000000000000000000000000000000', '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b', '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b'),
        (c_tiger, s_tiger, u_siti, 'https://images.unsplash.com/photo-1561731216-c3a4d99437d5?w=900&auto=format&fit=crop&q=80', 'Harimau Sumatera', 'Panthera tigris sumatrae', 'Melintasi sempadan sungai koridor konservasi', -5.255411, 104.225199, 180.0, now() - interval '3 hours', 1, '0000000000000000000000000000000000000000000000000000000000000000', '3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d', '3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d'),
        (c_ape, s_ape, u_borneo, 'https://images.unsplash.com/photo-1535083783855-76ae62b2914e?w=900&auto=format&fit=crop&q=80', 'Orangutan Kalimantan', 'Pongo pygmaeus', 'Induk mengajarkan anak mencari buah ara di kanopi', -2.755188, 111.925188, 220.0, now() - interval '6 hours', 1, '0000000000000000000000000000000000000000000000000000000000000000', '5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f', '5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f'),
        (c_bird, s_bird, u_dewi, 'https://images.unsplash.com/photo-1452570053594-1b985d6ea890?w=900&auto=format&fit=crop&q=80', 'Cenderawasih Kuning Kecil', 'Paradisaea minor', 'Tarian pikat di dahan display Arfak', -1.155211, 133.955411, 45.0, now() - interval '10 hours', 1, '0000000000000000000000000000000000000000000000000000000000000000', '7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b', '7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b'),
        (c_turtle, s_turtle, u_faiz, 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=900&auto=format&fit=crop&q=80', 'Penyu Hijau', 'Chelonia mydas', 'Melayang tenang di atas padang lamun Derawan', 2.255199, 118.255188, 310.0, now() - interval '14 hours', 1, '0000000000000000000000000000000000000000000000000000000000000000', '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b', '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b')
    ON CONFLICT (id) DO NOTHING;

    -- 5. SEED POSTINGAN FEED PUBLIK (Koordinat Kasar Ter-Grid 0.01 Derajat)
    INSERT INTO public.posts (id, capture_id, user_id, caption, location_visibility, display_latitude, display_longitude, area_label, created_at)
    VALUES
        (p_komodo, c_komodo, u_wayan, 'Individu Komodo jantan dewasa berukuran 2.8 meter sedang berjemur di savana Loh Liang. Kondisi fisik sangat prima dengan lidah bercabang aktif mendeteksi aroma.', 'coarse', -8.585000, 119.495000, 'Pulau Komodo, TN Komodo (Area Perkiraan)', now() - interval '15 minutes'),
        (p_jalak, c_jalak, u_budi, 'Teramati sepasang Jalak Bali bertengger di dahan beringin pesisir Teluk Brumbun. Jambul putih tegak sempurna dalam kondisi sehat dan terlindungi.', 'coarse', -8.115000, 114.525000, 'Taman Nasional Bali Barat (Area Perkiraan)', now() - interval '1 hour'),
        (p_tiger, c_tiger, u_siti, 'Visualisasi langsung Harimau Sumatera melintasi sempadan sungai saat patroli konservasi SMART. Gerakan sangat hening dan penuh kewaspadaan.', 'coarse', -5.255000, 104.225000, 'TN Bukit Barisan Selatan, Lampung (Area Perkiraan)', now() - interval '3 hours'),
        (p_ape, c_ape, u_borneo, 'Induk Orangutan Kalimantan mengajarkan anaknya mencari buah ara di kanopi hutan primer. Sangat tenang tanpa merasa terganggu.', 'coarse', -2.755000, 111.925000, 'Taman Nasional Tanjung Puting, Kalteng (Area Perkiraan)', now() - interval '6 hours'),
        (p_bird, c_bird, u_dewi, 'Atraksi tarian pikat Cenderawasih jantan di dahan display pada ketinggian 20 meter. Bulu kuning keemasan mekar memukau di hutan pegunungan.', 'coarse', -1.155000, 133.955000, 'Cagar Alam Pegunungan Arfak, Papua (Area Perkiraan)', now() - interval '10 hours'),
        (p_turtle, c_turtle, u_faiz, 'Penyu Hijau dewasa melayang tenang di atas padang lamun terumbu karang tepi pulau. Jarak pandang air laut mencapai 25 meter.', 'coarse', 2.255000, 118.255000, 'Kepulauan Derawan, Kalimantan Timur (Area Perkiraan)', now() - interval '14 hours')
    ON CONFLICT (id) DO NOTHING;

    -- 6. SEED RELASI LIKE
    INSERT INTO public.likes (user_id, post_id, created_at)
    VALUES
        (u_siti, p_komodo, now() - interval '10 minutes'),
        (u_budi, p_komodo, now() - interval '8 minutes'),
        (u_faiz, p_komodo, now() - interval '5 minutes'),
        (u_wayan, p_jalak, now() - interval '50 minutes'),
        (u_dewi, p_jalak, now() - interval '40 minutes'),
        (u_wayan, p_tiger, now() - interval '2 hours'),
        (u_borneo, p_tiger, now() - interval '1 hour'),
        (u_faiz, p_tiger, now() - interval '45 minutes'),
        (u_budi, p_ape, now() - interval '5 hours'),
        (u_siti, p_bird, now() - interval '9 hours'),
        (u_wayan, p_turtle, now() - interval '12 hours')
    ON CONFLICT DO NOTHING;

    -- 7. SEED RELASI FOLLOW SALING MENGIKUTI
    INSERT INTO public.follows (follower_id, followed_id)
    VALUES
        (u_wayan, u_siti),
        (u_wayan, u_budi),
        (u_siti, u_wayan),
        (u_budi, u_wayan),
        (u_borneo, u_wayan),
        (u_dewi, u_budi),
        (u_faiz, u_wayan)
    ON CONFLICT DO NOTHING;

END $$;
