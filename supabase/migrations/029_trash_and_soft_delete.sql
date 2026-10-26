-- ==============================================================================
-- FAUNOVA MIGRATION 029: Fitur Sampah (Trash / Soft Delete), Pemulihan & Purge
-- Sesuai Acuan: Plan 5.2, 5.3, 5.7, 5.9, Scope Tingkat 3 & Aturan Keras AGENTS.md
-- ==============================================================================

-- 1. TAMBAH KOLOM TRASH PADA TABEL POSTS DAN CAPTURES
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS trashed_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE public.captures ADD COLUMN IF NOT EXISTS trashed_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE public.captures ADD COLUMN IF NOT EXISTS purged_at TIMESTAMPTZ DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_posts_trashed_at ON public.posts(user_id, trashed_at) WHERE trashed_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_captures_trashed_at ON public.captures(user_id, trashed_at) WHERE trashed_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_captures_purged_at ON public.captures(user_id, purged_at) WHERE purged_at IS NOT NULL;

-- ==============================================================================
-- 2. RPC TRASH_POST (Pindahkan Postingan ke Sampah)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.trash_post(p_post_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_post RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    SELECT id, user_id, trashed_at, deleted_at INTO v_post
    FROM public.posts
    WHERE id = p_post_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Postingan tidak ditemukan.' USING ERRCODE = 'P0002';
    END IF;

    IF v_post.user_id <> v_user_id THEN
        RAISE EXCEPTION 'Akses ditolak: postingan ini bukan milik akun Anda.' USING ERRCODE = '42501';
    END IF;

    -- Aturan Keras: Postingan yang disembunyikan oleh moderasi (deleted_at IS NOT NULL) tidak boleh di-trash
    IF v_post.deleted_at IS NOT NULL THEN
        RAISE EXCEPTION 'Postingan telah dimoderasi dan tidak dapat dipindahkan ke Sampah.' USING ERRCODE = '22023';
    END IF;

    -- Idempoten: Jika sudah di Sampah, jangan reset trashed_at yang ada
    IF v_post.trashed_at IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', true,
            'post_id', p_post_id,
            'trashed_at', v_post.trashed_at,
            'already_trashed', true
        );
    END IF;

    UPDATE public.posts
    SET trashed_at = now()
    WHERE id = p_post_id;

    RETURN jsonb_build_object(
        'success', true,
        'post_id', p_post_id,
        'trashed_at', now(),
        'already_trashed', false
    );
END;
$$;

-- ==============================================================================
-- 3. RPC RESTORE_POST (Pulihkan Postingan dari Sampah)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.restore_post(p_post_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_post RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    SELECT p.id, p.user_id, p.trashed_at, p.deleted_at, p.capture_id,
           c.trashed_at AS cap_trashed, c.purged_at AS cap_purged
    INTO v_post
    FROM public.posts p
    JOIN public.captures c ON c.id = p.capture_id
    WHERE p.id = p_post_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Postingan tidak ditemukan.' USING ERRCODE = 'P0002';
    END IF;

    IF v_post.user_id <> v_user_id THEN
        RAISE EXCEPTION 'Akses ditolak: postingan ini bukan milik akun Anda.' USING ERRCODE = '42501';
    END IF;

    IF v_post.deleted_at IS NOT NULL THEN
        RAISE EXCEPTION 'Postingan telah dimoderasi dan tidak dapat dipulihkan.' USING ERRCODE = '22023';
    END IF;

    IF v_post.trashed_at IS NULL THEN
        RAISE EXCEPTION 'Postingan tidak berada di Sampah.' USING ERRCODE = '22023';
    END IF;

    -- Batas retensi 30 hari
    IF v_post.trashed_at < (now() - INTERVAL '30 days') THEN
        RAISE EXCEPTION 'Masa retensi postingan telah kedaluwarsa (lebih dari 30 hari).' USING ERRCODE = '22023';
    END IF;

    -- Validasi status koleksi induk
    IF v_post.cap_purged IS NOT NULL THEN
        RAISE EXCEPTION 'Koleksi terkait telah dipurge permanen.' USING ERRCODE = '22023';
    END IF;

    IF v_post.cap_trashed IS NOT NULL THEN
        RAISE EXCEPTION 'Koleksi terkait masih berada di Sampah. Pulihkan koleksi terlebih dahulu.' USING ERRCODE = '22023';
    END IF;

    UPDATE public.posts
    SET trashed_at = NULL
    WHERE id = p_post_id;

    RETURN jsonb_build_object(
        'success', true,
        'post_id', p_post_id
    );
END;
$$;

-- ==============================================================================
-- 4. RPC TRASH_CAPTURE (Pindahkan Koleksi ke Sampah)
-- Catatan Keras: Tidak mengubah kolom apa pun pada posts! Post tersembunyi via filter capture.
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.trash_capture(p_capture_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_cap RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    SELECT id, user_id, trashed_at, purged_at INTO v_cap
    FROM public.captures
    WHERE id = p_capture_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tangkapan koleksi tidak ditemukan.' USING ERRCODE = 'P0002';
    END IF;

    IF v_cap.user_id <> v_user_id THEN
        RAISE EXCEPTION 'Akses ditolak: koleksi ini bukan milik akun Anda.' USING ERRCODE = '42501';
    END IF;

    IF v_cap.purged_at IS NOT NULL THEN
        RAISE EXCEPTION 'Koleksi telah dipurge permanen.' USING ERRCODE = '22023';
    END IF;

    -- Idempoten: Jangan reset trashed_at jika sudah ada di sampah
    IF v_cap.trashed_at IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', true,
            'capture_id', p_capture_id,
            'trashed_at', v_cap.trashed_at,
            'already_trashed', true
        );
    END IF;

    UPDATE public.captures
    SET trashed_at = now()
    WHERE id = p_capture_id;

    RETURN jsonb_build_object(
        'success', true,
        'capture_id', p_capture_id,
        'trashed_at', now(),
        'already_trashed', false
    );
END;
$$;

-- ==============================================================================
-- 5. RPC RESTORE_CAPTURE (Pulihkan Koleksi dari Sampah)
-- Catatan Keras: Tidak mengubah posts.trashed_at! Jika post trashed manual, tetap di sampah.
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.restore_capture(p_capture_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_cap RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    SELECT id, user_id, trashed_at, purged_at INTO v_cap
    FROM public.captures
    WHERE id = p_capture_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tangkapan koleksi tidak ditemukan.' USING ERRCODE = 'P0002';
    END IF;

    IF v_cap.user_id <> v_user_id THEN
        RAISE EXCEPTION 'Akses ditolak: koleksi ini bukan milik akun Anda.' USING ERRCODE = '42501';
    END IF;

    IF v_cap.purged_at IS NOT NULL THEN
        RAISE EXCEPTION 'Koleksi telah dipurge permanen.' USING ERRCODE = '22023';
    END IF;

    IF v_cap.trashed_at IS NULL THEN
        RAISE EXCEPTION 'Koleksi tidak berada di Sampah.' USING ERRCODE = '22023';
    END IF;

    IF v_cap.trashed_at < (now() - INTERVAL '30 days') THEN
        RAISE EXCEPTION 'Masa retensi koleksi telah kedaluwarsa (lebih dari 30 hari).' USING ERRCODE = '22023';
    END IF;

    UPDATE public.captures
    SET trashed_at = NULL
    WHERE id = p_capture_id;

    RETURN jsonb_build_object(
        'success', true,
        'capture_id', p_capture_id
    );
END;
$$;

-- ==============================================================================
-- 6. RPC GET_MY_TRASH (Daftar Sampah Aktif Pengguna < 30 Hari)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.get_my_trash(p_retention_days INT DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_posts JSONB;
    v_captures JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    -- 1. Ambil postingan di sampah (< 30 hari dan tidak dimoderasi)
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'post_id', p.id,
        'capture_id', p.capture_id,
        'caption', p.caption,
        'species_name', c.species_name,
        'photo_object_path', c.photo_object_path,
        'trashed_at', p.trashed_at,
        'days_left', GREATEST(0, p_retention_days - EXTRACT(DAY FROM now() - p.trashed_at)::INT)
    ) ORDER BY p.trashed_at DESC), '[]'::jsonb)
    INTO v_posts
    FROM public.posts p
    JOIN public.captures c ON c.id = p.capture_id
    WHERE p.user_id = v_user_id
      AND p.trashed_at IS NOT NULL
      AND p.deleted_at IS NULL
      AND p.trashed_at >= (now() - (p_retention_days || ' days')::INTERVAL);

    -- 2. Ambil koleksi di sampah (< 30 hari dan belum dipurge)
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'capture_id', c.id,
        'species_name', c.species_name,
        'category', c.category,
        'photo_object_path', c.photo_object_path,
        'seq', c.seq,
        'trashed_at', c.trashed_at,
        'days_left', GREATEST(0, p_retention_days - EXTRACT(DAY FROM now() - c.trashed_at)::INT),
        'has_linked_post', EXISTS (
            SELECT 1 FROM public.posts p2
            WHERE p2.capture_id = c.id
        )
    ) ORDER BY c.trashed_at DESC), '[]'::jsonb)
    INTO v_captures
    FROM public.captures c
    WHERE c.user_id = v_user_id
      AND c.trashed_at IS NOT NULL
      AND c.purged_at IS NULL
      AND c.trashed_at >= (now() - (p_retention_days || ' days')::INTERVAL);

    RETURN jsonb_build_object(
        'posts', v_posts,
        'captures', v_captures
    );
END;
$$;

-- ==============================================================================
-- 7. RPC GET_EXPIRED_TRASH (Daftar Sampah Kedaluwarsa > 30 Hari untuk Lazy Purge)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.get_expired_trash(p_retention_days INT DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_expired_posts JSONB;
    v_expired_captures JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    -- Ambil post yang telah melewati batas 30 hari
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', p.id,
        'type', 'post'
    )), '[]'::jsonb)
    INTO v_expired_posts
    FROM public.posts p
    WHERE p.user_id = v_user_id
      AND p.trashed_at IS NOT NULL
      AND p.trashed_at < (now() - (p_retention_days || ' days')::INTERVAL);

    -- Ambil capture yang telah melewati batas 30 hari beserta path fotonya
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
        'id', c.id,
        'type', 'capture',
        'photo_object_path', c.photo_object_path
    )), '[]'::jsonb)
    INTO v_expired_captures
    FROM public.captures c
    WHERE c.user_id = v_user_id
      AND c.trashed_at IS NOT NULL
      AND c.purged_at IS NULL
      AND c.trashed_at < (now() - (p_retention_days || ' days')::INTERVAL);

    RETURN jsonb_build_object(
        'posts', v_expired_posts,
        'captures', v_expired_captures
    );
END;
$$;

-- ==============================================================================
-- 8. RPC PURGE_TRASH_ITEM (Hapus Permanen Item di Sampah)
-- Idempoten, verifikasi kepemilikan, dan pastikan item sedang di Sampah.
-- Untuk capture: Hard-delete post terkait (cascade likes/reports/notif), lalu tombstone capture.
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.purge_trash_item(
    p_type TEXT,
    p_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_post RECORD;
    v_cap RECORD;
    v_photo_path TEXT := NULL;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    IF p_type NOT IN ('post', 'capture') THEN
        RAISE EXCEPTION 'Tipe item tidak valid (harus post atau capture).' USING ERRCODE = '22023';
    END IF;

    IF p_type = 'post' THEN
        SELECT id, user_id, trashed_at INTO v_post
        FROM public.posts
        WHERE id = p_id;

        IF NOT FOUND THEN
            -- Idempoten: Jika sudah terhapus, kembalikan sukses
            RETURN jsonb_build_object(
                'success', true,
                'type', 'post',
                'id', p_id,
                'already_purged', true
            );
        END IF;

        IF v_post.user_id <> v_user_id THEN
            RAISE EXCEPTION 'Akses ditolak: postingan ini bukan milik akun Anda.' USING ERRCODE = '42501';
        END IF;

        IF v_post.trashed_at IS NULL THEN
            RAISE EXCEPTION 'Item tidak berada di Sampah (hanya item di Sampah yang dapat di-purge).' USING ERRCODE = '22023';
        END IF;

        -- Hard delete: Cascade menghapus likes, post_reports, dan notifications
        DELETE FROM public.posts WHERE id = p_id;

        RETURN jsonb_build_object(
            'success', true,
            'type', 'post',
            'id', p_id,
            'already_purged', false
        );

    ELSE -- p_type = 'capture'
        SELECT id, user_id, trashed_at, purged_at, photo_object_path INTO v_cap
        FROM public.captures
        WHERE id = p_id;

        IF NOT FOUND THEN
            RETURN jsonb_build_object(
                'success', true,
                'type', 'capture',
                'id', p_id,
                'already_purged', true
            );
        END IF;

        IF v_cap.user_id <> v_user_id THEN
            RAISE EXCEPTION 'Akses ditolak: koleksi ini bukan milik akun Anda.' USING ERRCODE = '42501';
        END IF;

        -- Idempoten jika sudah berstatus tombstone purged
        IF v_cap.purged_at IS NOT NULL THEN
            RETURN jsonb_build_object(
                'success', true,
                'type', 'capture',
                'id', p_id,
                'already_purged', true
            );
        END IF;

        IF v_cap.trashed_at IS NULL THEN
            RAISE EXCEPTION 'Item tidak berada di Sampah (hanya item di Sampah yang dapat di-purge).' USING ERRCODE = '22023';
        END IF;

        v_photo_path := v_cap.photo_object_path;

        -- 1. Hapus postingan terkait secara fisik (agar likes, reports, notifications cascade)
        DELETE FROM public.posts WHERE capture_id = p_id;

        -- 2. Lakukan Cryptographic Tombstone pada baris capture
        -- Pertahankan seluruh kolom hash: seq, previous_hash, block_hash, photo_sha256, lat, lng, heading, received_at, user_id
        UPDATE public.captures
        SET purged_at = now(),
            species_name = '[Observasi Dipurge]',
            photo_object_path = 'purged',
            category = NULL,
            description = NULL
        WHERE id = p_id;

        RETURN jsonb_build_object(
            'success', true,
            'type', 'capture',
            'id', p_id,
            'photo_object_path', v_photo_path,
            'already_purged', false
        );
    END IF;
END;
$$;

-- ==============================================================================
-- 9. PERBARUI RPC CREATE_POST (Dukung Bagikan Ulang / Re-Share Auto-Restore)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.create_post(
    p_capture_id UUID,
    p_caption TEXT DEFAULT '',
    p_visibility TEXT DEFAULT 'coarse',
    p_area_label TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_capture RECORD;
    v_disp_lat NUMERIC := NULL;
    v_disp_lng NUMERIC := NULL;
    v_final_area TEXT := NULL;
    v_existing_post RECORD;
    v_post_id UUID;
    v_created_at TIMESTAMPTZ;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    IF p_visibility NOT IN ('coarse', 'hidden') THEN
        RAISE EXCEPTION 'Parameter visibility harus coarse atau hidden.' USING ERRCODE = '22023';
    END IF;

    IF length(COALESCE(p_caption, '')) > 500 THEN
        RAISE EXCEPTION 'Panjang takarir melebihi batas 500 karakter.' USING ERRCODE = '22023';
    END IF;

    -- Ambil data capture dan validasi
    SELECT id, user_id, latitude, longitude, species_name, category, photo_object_path, seq, block_hash, deleted_at, trashed_at, purged_at
    INTO v_capture
    FROM public.captures
    WHERE id = p_capture_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tangkapan koleksi tidak ditemukan.' USING ERRCODE = 'P0002';
    END IF;

    IF v_capture.user_id <> v_user_id THEN
        RAISE EXCEPTION 'Akses ditolak: tangkapan ini bukan milik akun Anda.' USING ERRCODE = '42501';
    END IF;

    IF v_capture.deleted_at IS NOT NULL THEN
        RAISE EXCEPTION 'Tangkapan yang telah dihapus tidak dapat diposting.' USING ERRCODE = '22023';
    END IF;

    -- Aturan Keras: Tolak tangkapan yang berada di Sampah atau sudah dipurge
    IF v_capture.trashed_at IS NOT NULL OR v_capture.purged_at IS NOT NULL THEN
        RAISE EXCEPTION 'Tangkapan yang berada di Sampah tidak dapat dipublikasikan.' USING ERRCODE = '22023';
    END IF;

    -- Hitung koordinat publik jika opsi lokasi 'coarse' dipilih
    IF p_visibility = 'coarse' AND v_capture.latitude IS NOT NULL AND v_capture.longitude IS NOT NULL THEN
        SELECT display_latitude, display_longitude
        INTO v_disp_lat, v_disp_lng
        FROM public.faunova_snap_to_grid(v_capture.latitude, v_capture.longitude);

        v_final_area := COALESCE(NULLIF(TRIM(p_area_label), ''), 'Area Perkiraan (Grid 0.01°)');
    ELSE
        v_disp_lat := NULL;
        v_disp_lng := NULL;
        v_final_area := NULL;
    END IF;

    -- Periksa apakah postingan untuk capture ini sudah ada di database
    SELECT id, trashed_at, deleted_at INTO v_existing_post
    FROM public.posts
    WHERE capture_id = p_capture_id;

    IF FOUND THEN
        -- Kasus 1: Postingan pernah di-ban oleh moderasi laporan -> DILARANG KERAS DIPULIHKAN
        IF v_existing_post.deleted_at IS NOT NULL THEN
            RAISE EXCEPTION 'Postingan ini telah diblokir oleh moderasi komunitas.' USING ERRCODE = '23505';
        END IF;

        -- Kasus 2: Postingan sedang aktif di linimasa
        IF v_existing_post.trashed_at IS NULL THEN
            RAISE EXCEPTION 'Tangkapan ini sudah pernah Anda publikasikan ke linimasa.' USING ERRCODE = '23505';
        END IF;

        -- Kasus 3: Postingan berada di Sampah (trashed_at IS NOT NULL) -> RE-SHARE AUTO-RESTORE
        -- Mempertahankan baris yang sama beserta riwayat like sebelumnya
        UPDATE public.posts
        SET trashed_at = NULL,
            caption = COALESCE(TRIM(p_caption), ''),
            location_visibility = p_visibility,
            display_latitude = v_disp_lat,
            display_longitude = v_disp_lng,
            area_label = v_final_area,
            created_at = now()
        WHERE id = v_existing_post.id
        RETURNING id, created_at INTO v_post_id, v_created_at;

        RETURN jsonb_build_object(
            'post_id', v_post_id,
            'capture_id', p_capture_id,
            'caption', COALESCE(TRIM(p_caption), ''),
            'location_visibility', p_visibility,
            'display_latitude', v_disp_lat,
            'display_longitude', v_disp_lng,
            'area_label', v_final_area,
            'created_at', v_created_at,
            'restored_from_trash', true
        );
    END IF;

    -- Jika belum pernah diposting sama sekali -> Masukkan baris baru
    INSERT INTO public.posts (
        capture_id,
        user_id,
        caption,
        location_visibility,
        display_latitude,
        display_longitude,
        area_label,
        created_at
    ) VALUES (
        p_capture_id,
        v_user_id,
        COALESCE(TRIM(p_caption), ''),
        p_visibility,
        v_disp_lat,
        v_disp_lng,
        v_final_area,
        now()
    )
    RETURNING id, created_at INTO v_post_id, v_created_at;

    RETURN jsonb_build_object(
        'post_id', v_post_id,
        'capture_id', p_capture_id,
        'caption', COALESCE(TRIM(p_caption), ''),
        'location_visibility', p_visibility,
        'display_latitude', v_disp_lat,
        'display_longitude', v_disp_lng,
        'area_label', v_final_area,
        'created_at', v_created_at,
        'restored_from_trash', false
    );
END;
$$;

-- ==============================================================================
-- 10. PERBARUI FILTER KUERI FEED & PROFIL UNTUK MENGECUALIKAN TRASH / PURGE
-- ==============================================================================

-- A. FEED UNTUK KAMU
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
        c.species_name,
        c.category,
        c.photo_object_path,
        c.seq AS block_seq,
        c.block_hash,
        c.photo_sha256,
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
    JOIN public.captures c ON c.id = p.capture_id 
                          AND c.deleted_at IS NULL 
                          AND c.trashed_at IS NULL 
                          AND c.purged_at IS NULL
    JOIN public.profiles u ON u.id = p.user_id
    LEFT JOIN (
        SELECT post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes
        GROUP BY post_id
    ) l ON l.post_id = p.id
    WHERE p.deleted_at IS NULL
      AND p.trashed_at IS NULL
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

-- B. FEED MENGIKUTI
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
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_current_user_id UUID;
    v_clamped_limit INT;
BEGIN
    v_current_user_id := auth.uid();
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: autentikasi diperlukan.' USING ERRCODE = '42501';
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
        COALESCE(u.display_name, u.username, 'Penjelajah Satwa') AS author_name,
        u.username AS author_username,
        u.avatar_path AS author_avatar,
        u.verified_until AS author_verified_until,
        COALESCE(l.likes_total, 0)::BIGINT AS likes_count,
        EXISTS (
            SELECT 1 FROM public.likes my_l 
            WHERE my_l.post_id = p.id AND my_l.user_id = v_current_user_id
        ) AS is_liked_by_me
    FROM public.posts p
    JOIN public.captures c ON c.id = p.capture_id 
                          AND c.deleted_at IS NULL 
                          AND c.trashed_at IS NULL 
                          AND c.purged_at IS NULL
    JOIN public.profiles u ON u.id = p.user_id
    JOIN public.follows f ON f.followed_id = p.user_id AND f.follower_id = v_current_user_id
    LEFT JOIN (
        SELECT post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes
        GROUP BY post_id
    ) l ON l.post_id = p.id
    WHERE p.deleted_at IS NULL
      AND p.trashed_at IS NULL
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

-- C. POSTINGAN PUBLIK PENGGUNA (PROFIL)
CREATE OR REPLACE FUNCTION public.get_user_public_posts(
    p_target_user_id UUID,
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
        c.species_name,
        c.category,
        c.photo_object_path,
        c.seq AS block_seq,
        c.block_hash,
        c.photo_sha256,
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
    JOIN public.captures c ON c.id = p.capture_id 
                          AND c.deleted_at IS NULL 
                          AND c.trashed_at IS NULL 
                          AND c.purged_at IS NULL
    JOIN public.profiles u ON u.id = p.user_id
    LEFT JOIN (
        SELECT post_id, COUNT(*)::BIGINT AS likes_total
        FROM public.likes
        GROUP BY post_id
    ) l ON l.post_id = p.id
    WHERE p.user_id = p_target_user_id
      AND p.deleted_at IS NULL
      AND p.trashed_at IS NULL
      AND (p_cursor IS NULL OR p.created_at < p_cursor)
    ORDER BY p.created_at DESC
    LIMIT v_clamped_limit;
END;
$$;

-- D. METRIK PROFIL PENGGUNA
CREATE OR REPLACE FUNCTION public.get_user_profile_metrics(
    p_target_user_id UUID
)
RETURNS TABLE (
    total_captures BIGINT,
    total_posts BIGINT,
    followers_count BIGINT,
    following_count BIGINT,
    is_following_by_me BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_current_user_id UUID;
    v_total_captures BIGINT;
    v_total_posts BIGINT;
    v_followers_count BIGINT;
    v_following_count BIGINT;
    v_is_following BOOLEAN := false;
BEGIN
    v_current_user_id := auth.uid();

    SELECT COUNT(*)::BIGINT INTO v_total_captures
    FROM public.captures
    WHERE user_id = p_target_user_id 
      AND deleted_at IS NULL 
      AND trashed_at IS NULL 
      AND purged_at IS NULL;

    SELECT COUNT(*)::BIGINT INTO v_total_posts
    FROM public.posts p
    JOIN public.captures c ON c.id = p.capture_id
    WHERE p.user_id = p_target_user_id 
      AND p.deleted_at IS NULL 
      AND p.trashed_at IS NULL
      AND c.trashed_at IS NULL 
      AND c.purged_at IS NULL;

    SELECT COUNT(*)::BIGINT INTO v_followers_count
    FROM public.follows
    WHERE followed_id = p_target_user_id;

    SELECT COUNT(*)::BIGINT INTO v_following_count
    FROM public.follows
    WHERE follower_id = p_target_user_id;

    IF v_current_user_id IS NOT NULL AND v_current_user_id != p_target_user_id THEN
        SELECT EXISTS (
            SELECT 1 FROM public.follows
            WHERE follower_id = v_current_user_id AND followed_id = p_target_user_id
        ) INTO v_is_following;
    END IF;

    RETURN QUERY SELECT 
        COALESCE(v_total_captures, 0),
        COALESCE(v_total_posts, 0),
        COALESCE(v_followers_count, 0),
        COALESCE(v_following_count, 0),
        v_is_following;
END;
$$;

-- E. TOGGLE POST LIKE (Tolak Like Jika Post / Capture Berada di Sampah / Purged)
CREATE OR REPLACE FUNCTION public.toggle_post_like(
    p_post_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_already_liked BOOLEAN;
    v_new_count BIGINT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: autentikasi diperlukan.' USING ERRCODE = '42501';
    END IF;

    -- Periksa apakah postingan ada, aktif, dan tidak di sampah
    IF NOT EXISTS (
        SELECT 1 
        FROM public.posts p
        JOIN public.captures c ON c.id = p.capture_id
        WHERE p.id = p_post_id 
          AND p.deleted_at IS NULL 
          AND p.trashed_at IS NULL
          AND c.trashed_at IS NULL 
          AND c.purged_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Postingan tidak ditemukan atau telah dihapus.' USING ERRCODE = 'P0002';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.likes WHERE post_id = p_post_id AND user_id = v_user_id
    ) INTO v_already_liked;

    IF v_already_liked THEN
        DELETE FROM public.likes 
        WHERE post_id = p_post_id AND user_id = v_user_id;
    ELSE
        INSERT INTO public.likes (post_id, user_id, created_at)
        VALUES (p_post_id, v_user_id, now())
        ON CONFLICT (post_id, user_id) DO NOTHING;
    END IF;

    SELECT COUNT(*)::BIGINT INTO v_new_count
    FROM public.likes
    WHERE post_id = p_post_id;

    RETURN jsonb_build_object(
        'post_id', p_post_id,
        'is_liked', NOT v_already_liked,
        'likes_count', v_new_count
    );
END;
$$;

-- F. NOTIFIKASI SAYA (Saring Notifikasi Postingan yang Berada di Sampah / Purge)
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
        n.title,
        n.body,
        n.is_read,
        n.created_at
    FROM public.notifications n
    JOIN public.profiles p_act ON p_act.id = n.actor_id
    LEFT JOIN public.posts p ON p.id = n.post_id
    LEFT JOIN public.captures c ON c.id = p.capture_id
    WHERE n.recipient_id = auth.uid()
      AND n.actor_id <> auth.uid()
      -- Saring postingan yang sedang di sampah, dipurge, atau dimoderasi
      AND (
          n.post_id IS NULL 
          OR (p.id IS NOT NULL AND p.trashed_at IS NULL AND p.deleted_at IS NULL AND c.trashed_at IS NULL AND c.purged_at IS NULL)
      )
    ORDER BY n.created_at DESC
    LIMIT LEAST(GREATEST(p_limit, 1), 50);
END;
$$;

-- F2. HITUNG NOTIFIKASI BELUM DIBACA (Saring Postingan di Sampah / Purge)
CREATE OR REPLACE FUNCTION public.get_my_unread_notifications_count()
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_count BIGINT;
BEGIN
    SELECT COUNT(*)::BIGINT INTO v_count
    FROM public.notifications n
    LEFT JOIN public.posts p ON p.id = n.post_id
    LEFT JOIN public.captures c ON c.id = p.capture_id
    WHERE n.recipient_id = auth.uid()
      AND n.actor_id <> auth.uid()
      AND n.is_read = false
      AND (
          n.post_id IS NULL 
          OR (p.id IS NOT NULL AND p.trashed_at IS NULL AND p.deleted_at IS NULL AND c.trashed_at IS NULL AND c.purged_at IS NULL)
      );
    RETURN COALESCE(v_count, 0);
END;
$$;

-- G. PENCARIAN AKUN (Saring Penghitung Post / Capture di Sampah)
CREATE OR REPLACE FUNCTION public.search_verified_fauna_accounts(
    p_query TEXT DEFAULT '',
    p_category TEXT DEFAULT 'all',
    p_limit INT DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    username TEXT,
    display_name TEXT,
    avatar_path TEXT,
    bio TEXT,
    verified_until TIMESTAMPTZ,
    is_verified BOOLEAN,
    conservation_title TEXT,
    observation_count BIGINT,
    posts_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_clean_query TEXT;
    v_clamped_limit INT;
BEGIN
    v_clean_query := TRIM(COALESCE(p_query, ''));
    v_clamped_limit := LEAST(GREATEST(p_limit, 1), 50);

    RETURN QUERY
    SELECT 
        p.id,
        p.username,
        p.display_name,
        p.avatar_path,
        p.bio,
        p.verified_until,
        (p.verified_until IS NOT NULL AND p.verified_until > now()) AS is_verified,
        CASE 
            WHEN p.verified_until IS NOT NULL AND p.verified_until > now() THEN 'Konservasionis Terverifikasi'
            ELSE 'Penjelajah Alam'
        END AS conservation_title,
        COALESCE(cap.total_captures, 0)::BIGINT AS observation_count,
        COALESCE(pst.total_posts, 0)::BIGINT AS posts_count
    FROM public.profiles p
    LEFT JOIN (
        SELECT user_id, COUNT(*)::BIGINT AS total_captures
        FROM public.captures
        WHERE deleted_at IS NULL AND trashed_at IS NULL AND purged_at IS NULL
          AND (
              p_category = 'all' 
              OR category = p_category
              OR (p_category = 'Mamalia' AND category IN ('Mamalia', 'Mamalia Darat', 'Mamalia Laut'))
              OR (p_category = 'Aves' AND category IN ('Aves', 'Burung'))
              OR (p_category = 'Reptilia' AND category IN ('Reptil', 'Reptilia'))
              OR (p_category = 'Amfibi' AND category IN ('Amfibia', 'Amfibi'))
          )
        GROUP BY user_id
    ) cap ON cap.user_id = p.id
    LEFT JOIN (
        SELECT p2.user_id, COUNT(*)::BIGINT AS total_posts
        FROM public.posts p2
        JOIN public.captures c2 ON c2.id = p2.capture_id
        WHERE p2.deleted_at IS NULL AND p2.trashed_at IS NULL AND c2.trashed_at IS NULL AND c2.purged_at IS NULL
        GROUP BY p2.user_id
    ) pst ON pst.user_id = p.id
    WHERE (
        v_clean_query = ''
        OR p.username ILIKE '%' || v_clean_query || '%'
        OR p.display_name ILIKE '%' || v_clean_query || '%'
    )
    ORDER BY 
        (p.verified_until IS NOT NULL AND p.verified_until > now()) DESC,
        observation_count DESC,
        p.created_at ASC
    LIMIT v_clamped_limit;
END;
$$;

-- ==============================================================================
-- 11. HAK AKSES EKSEKUSI RPC
-- ==============================================================================
REVOKE EXECUTE ON FUNCTION public.trash_post(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.trash_post(UUID) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.restore_post(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.restore_post(UUID) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.trash_capture(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.trash_capture(UUID) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.restore_capture(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.restore_capture(UUID) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_my_trash(INT) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_my_trash(INT) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_expired_trash(INT) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_expired_trash(INT) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.purge_trash_item(TEXT, UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.purge_trash_item(TEXT, UUID) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.get_my_unread_notifications_count() FROM anon;
GRANT EXECUTE ON FUNCTION public.get_my_unread_notifications_count() TO authenticated;
