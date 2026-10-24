-- ==============================================================================
-- FAUNOVA — UJI ISOLASI RLS DUA AKUN & KEAMANAN MULTI-TENANT (Sesi S22)
-- Sesuai acuan: docs/plan_faunova_revisi_5_final.md (Bagian 13 & 15) & AGENTS.md
-- ==============================================================================
--
-- CARA MENJALANKAN:
-- Buka Supabase Dashboard -> SQL Editor -> Tempel seluruh skrip ini -> Klik 'Run'.
-- Seluruh pengujian dibungkus dalam blok TRANSAKSI (BEGIN ... ROLLBACK).
-- Basis data Anda TIDAK AKAN terkotori oleh data uji coba setelah selesai.
--
-- HASIL:
-- Menampilkan tabel laporan pengujian status LULUS (PASS) / GAGAL (FAIL).
-- ==============================================================================

BEGIN;

-- 1. Buat tabel sementara untuk menampung hasil pengujian
CREATE TEMP TABLE IF NOT EXISTS test_results (
    test_id SERIAL PRIMARY KEY,
    category TEXT NOT NULL,
    test_case TEXT NOT NULL,
    expected TEXT NOT NULL,
    actual TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('PASS', 'FAIL'))
);

-- Beri izin akses ke tabel temporary untuk role authenticated
GRANT ALL ON test_results TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE test_results_test_id_seq TO authenticated;

-- 2. Jalankan skenario simulasi multi-tenant dua akun
DO $$
DECLARE
    -- Gunakan gen_random_uuid() agar selalu unik dan valid hex
    user_a UUID := gen_random_uuid();
    user_b UUID := gen_random_uuid();
    v_count INT;
    v_scan_a UUID := gen_random_uuid();
    v_cap_a UUID := gen_random_uuid();
    v_post_a UUID := gen_random_uuid();
    v_tx_a UUID := gen_random_uuid();
    v_quiz_a UUID := gen_random_uuid();
    v_chat_a UUID := gen_random_uuid();
    v_req_a UUID := gen_random_uuid();
    v_idemp_a UUID := gen_random_uuid();
    v_user_a_username TEXT := 'user_a_' || substr(md5(random()::text), 1, 8);
    v_user_b_username TEXT := 'user_b_' || substr(md5(random()::text), 1, 8);
    v_order_id TEXT := 'ORDER-TEST-' || substr(md5(random()::text), 1, 10);
    v_q_id UUID;
BEGIN
    -- =========================================================================
    -- FASE 1: SEED DATA DILAKUKAN SEBAGAI ADMIN / SISTEM (POSTGRES PRIVILEGE)
    -- Karena aturan server Faunova: scans, captures, posts, dsb diisi lewat server/RPC
    -- =========================================================================

    -- A. Daftarkan akun auth.users sementara
    INSERT INTO auth.users (id, aud, role, email, created_at, updated_at)
    VALUES 
        (user_a, 'authenticated', 'authenticated', v_user_a_username || '@faunova.id', now(), now()),
        (user_b, 'authenticated', 'authenticated', v_user_b_username || '@faunova.id', now(), now())
    ON CONFLICT (id) DO NOTHING;

    -- B. Pastikan profil terisi dengan username unik
    INSERT INTO public.profiles (id, username, display_name, bio)
    VALUES 
        (user_a, v_user_a_username, 'Kolektor Satwa A', 'Peneliti Wallacea'),
        (user_b, v_user_b_username, 'Kolektor Satwa B', 'Fotografer Satwa Liar')
    ON CONFLICT (id) DO UPDATE SET 
        username = EXCLUDED.username, 
        display_name = EXCLUDED.display_name,
        bio = EXCLUDED.bio;

    -- C. Pastikan ada bank soal aktif untuk pengujian kuis
    SELECT id INTO v_q_id FROM public.quiz_questions WHERE is_active = TRUE LIMIT 1;
    IF v_q_id IS NULL THEN
        INSERT INTO public.quiz_questions (category, question, options, correct_option, explanation, is_active)
        VALUES ('Aves', 'Burung endemik Bali dengan bulu putih bersih adalah?', 
                '["Jalak Bali", "Cenderawasih", "Elang Jawa", "Kakatua"]'::jsonb, 0, 'Jalak Bali adalah fauna endemik Bali.', TRUE)
        RETURNING id INTO v_q_id;
    END IF;

    -- D. Seed scan User A
    INSERT INTO public.scans (
        id, user_id, request_id, status, is_animal, photo_sha256,
        latitude, longitude, camera_heading, received_at
    ) VALUES (
        v_scan_a, user_a, v_req_a, 'completed', true,
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        -8.112233, 115.223344, 145.5, now()
    ) ON CONFLICT DO NOTHING;

    -- E. Seed chat User A
    INSERT INTO public.scan_chats (
        id, scan_id, user_id, role, content
    ) VALUES (
        v_chat_a, v_scan_a, user_a, 'user', 'Apakah Jalak Bali ini jantan atau betina?'
    ) ON CONFLICT DO NOTHING;

    -- F. Seed capture User A (koleksi privat dengan koordinat presisi)
    INSERT INTO public.captures (
        id, scan_id, user_id, photo_object_path, species_name, category, description,
        latitude, longitude, camera_heading, received_at, seq, previous_hash, block_hash, photo_sha256
    ) VALUES (
        v_cap_a, v_scan_a, user_a, 'captures/user_a/jalak.jpg', 'Jalak Bali', 'Aves',
        'Ditemukan di dahan pohon asam TNBB', -8.112233, 115.223344, 145.5, now(), 1,
        '0000000000000000000000000000000000000000000000000000000000000000',
        '1111111111111111111111111111111111111111111111111111111111111111',
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
    ) ON CONFLICT DO NOTHING;

    -- G. Seed post User A (postingan publik dengan koordinat kasar / grid snapping)
    INSERT INTO public.posts (
        id, capture_id, user_id, caption, location_visibility,
        display_latitude, display_longitude, area_label
    ) VALUES (
        v_post_a, v_cap_a, user_a, 'Observasi pagi Jalak Bali di TNBB', 'coarse',
        -8.110000, 115.220000, 'Taman Nasional Bali Barat'
    ) ON CONFLICT DO NOTHING;

    -- H. Seed transaksi Midtrans User A
    INSERT INTO public.transactions (
        id, order_id, user_id, amount_idr, currency, status, entitlement_days
    ) VALUES (
        v_tx_a, v_order_id, user_a, 15000, 'IDR', 'pending', 30
    ) ON CONFLICT DO NOTHING;

    -- I. Seed sesi kuis User A
    INSERT INTO public.quiz_sessions (
        id, user_id, question_ids, status
    ) VALUES (
        v_quiz_a, user_a, ARRAY[v_q_id], 'in_progress'
    ) ON CONFLICT DO NOTHING;


    -- =========================================================================
    -- FASE 2: BERALIH PERAN KE USER B SEBAGAI USER BIASA (AUTHENTICATED)
    -- Di sini pengujian penetrasi keamanan RLS dijalankan secara nyata
    -- =========================================================================
    PERFORM set_config('role', 'authenticated', true);
    PERFORM set_config('request.jwt.claim.sub', user_b::text, true);


    -- -------------------------------------------------------------------------
    -- UJI 1: User B mencoba membaca tabel `scans` milik User A
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count FROM public.scans WHERE user_id = user_a;
    IF v_count = 0 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B SELECT scans milik User A', '0 baris (Terisolasi)', v_count || ' baris', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B SELECT scans milik User A', '0 baris (Terisolasi)', v_count || ' baris bocor!', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 2: User B mencoba mengubah `scans` milik User A
    -- -------------------------------------------------------------------------
    UPDATE public.scans SET status = 'failed' WHERE id = v_scan_a;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 0 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B UPDATE scans milik User A', '0 baris terpengaruh', v_count || ' baris terpengaruh', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B UPDATE scans milik User A', '0 baris terpengaruh', v_count || ' baris berhasil diubah!', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 3: User B mencoba membaca `scan_chats` milik User A
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count FROM public.scan_chats WHERE user_id = user_a;
    IF v_count = 0 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B SELECT scan_chats milik User A', '0 baris (Terisolasi)', v_count || ' baris', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B SELECT scan_chats milik User A', '0 baris (Terisolasi)', v_count || ' baris bocor!', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 4: User B mencoba membaca `captures` privat milik User A (Kerahasiaan Koordinat)
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count FROM public.captures WHERE user_id = user_a;
    IF v_count = 0 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B SELECT captures privat milik User A', '0 baris (Koleksi privat)', v_count || ' baris', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B SELECT captures privat milik User A', '0 baris (Koleksi privat)', v_count || ' baris bocor!', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 5: User B membaca `posts` publik milik User A (Harus terlihat dengan koordinat ter-grid)
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count FROM public.posts WHERE id = v_post_a;
    IF v_count = 1 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Public Access', 'User B SELECT posts publik milik User A', '1 baris terlihat', '1 baris terlihat', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Public Access', 'User B SELECT posts publik milik User A', '1 baris terlihat', v_count || ' baris', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 6: User B mencoba menghapus `posts` publik milik User A
    -- -------------------------------------------------------------------------
    DELETE FROM public.posts WHERE id = v_post_a;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 0 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B DELETE posts milik User A', '0 baris terhapus (Ditolak RLS)', v_count || ' baris terhapus', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B DELETE posts milik User A', '0 baris terhapus (Ditolak RLS)', v_count || ' baris terhapus!', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 7: User B mencoba membaca `transactions` milik User A
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count FROM public.transactions WHERE user_id = user_a;
    IF v_count = 0 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Financial Privacy', 'User B SELECT transactions milik User A', '0 baris (Privasi keuangan)', v_count || ' baris', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Financial Privacy', 'User B SELECT transactions milik User A', '0 baris (Privasi keuangan)', v_count || ' baris bocor!', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 8: User B mencoba membaca atau memanipulasi `quiz_sessions` milik User A
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count FROM public.quiz_sessions WHERE user_id = user_a;
    IF v_count = 0 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B SELECT quiz_sessions milik User A', '0 baris (Sesi privat)', v_count || ' baris', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B SELECT quiz_sessions milik User A', '0 baris (Sesi privat)', v_count || ' baris bocor!', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 9: User B mencoba mem-follow dirinya sendiri (Harus ditolak CHECK constraint)
    -- -------------------------------------------------------------------------
    BEGIN
        INSERT INTO public.follows (follower_id, followed_id) VALUES (user_b, user_b);
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Integrity Check', 'User B follow dirinya sendiri', 'Ditolak constraint CHECK', 'Berhasil masuk (Pelanggaran aturan)', 'FAIL');
    EXCEPTION WHEN check_violation THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Integrity Check', 'User B follow dirinya sendiri', 'Ditolak constraint CHECK', 'Ditolak dengan benar (check_violation)', 'PASS');
    END;

    -- -------------------------------------------------------------------------
    -- UJI 10: User B mem-follow User A (Diizinkan), lalu follow lagi (Idempoten / Konflik)
    -- -------------------------------------------------------------------------
    INSERT INTO public.follows (follower_id, followed_id) VALUES (user_b, user_a)
    ON CONFLICT (follower_id, followed_id) DO NOTHING;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 1 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Social Relation', 'User B follow User A pertama kali', '1 relasi dibuat', '1 relasi dibuat', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Social Relation', 'User B follow User A pertama kali', '1 relasi dibuat', v_count || ' relasi', 'FAIL');
    END IF;

    -- Uji idempoten: Follow kedua kali tidak menduplikasi baris
    INSERT INTO public.follows (follower_id, followed_id) VALUES (user_b, user_a)
    ON CONFLICT (follower_id, followed_id) DO NOTHING;
    SELECT count(*) INTO v_count FROM public.follows WHERE follower_id = user_b AND followed_id = user_a;
    IF v_count = 1 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Idempotency', 'User B follow User A kedua kali (Idempoten)', 'Tetap 1 baris (Tidak duplikasi)', '1 baris', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Idempotency', 'User B follow User A kedua kali (Idempoten)', 'Tetap 1 baris (Tidak duplikasi)', v_count || ' baris', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 11: User B menyukai postingan User A, lalu unlike idempoten
    -- -------------------------------------------------------------------------
    INSERT INTO public.likes (user_id, post_id) VALUES (user_b, v_post_a)
    ON CONFLICT (user_id, post_id) DO NOTHING;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 1 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Social Relation', 'User B like postingan User A', '1 like tercatat', '1 like tercatat', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Social Relation', 'User B like postingan User A', '1 like tercatat', v_count || ' like', 'FAIL');
    END IF;

    -- User B mencoba menghapus like milik User A (harus 0 terhapus karena where user_id = user_a)
    DELETE FROM public.likes WHERE user_id = user_a AND post_id = v_post_a;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 0 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B mencoba menghapus like milik User A', '0 baris terhapus', '0 baris terhapus', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('RLS Isolation', 'User B mencoba menghapus like milik User A', '0 baris terhapus', v_count || ' baris terhapus!', 'FAIL');
    END IF;

    -- -------------------------------------------------------------------------
    -- UJI 12: Profil Publik User A terbaca oleh User B tanpa kolom sensitif
    -- -------------------------------------------------------------------------
    SELECT count(*) INTO v_count FROM public.public_profiles WHERE id = user_a;
    IF v_count = 1 THEN
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Public Profiles View', 'User B membaca public_profiles User A', '1 baris publik terbaca', '1 baris publik terbaca', 'PASS');
    ELSE
        INSERT INTO test_results (category, test_case, expected, actual, status)
        VALUES ('Public Profiles View', 'User B membaca public_profiles User A', '1 baris publik terbaca', v_count || ' baris', 'FAIL');
    END IF;

    -- Kembalikan role ke admin (postgres) sebelum keluar blok
    PERFORM set_config('role', 'postgres', true);

END $$;

-- 3. Tampilkan seluruh ringkasan hasil pengujian
SELECT 
    test_id,
    category AS "Kategori",
    test_case AS "Kasus Uji RLS & Keamanan",
    expected AS "Ekspektasi Keamanan",
    actual AS "Hasil Aktual",
    status AS "Status"
FROM test_results
ORDER BY test_id ASC;

-- 4. Rollback transaksi agar basis data tetap bersih tanpa data sampah
ROLLBACK;
