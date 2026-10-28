-- ==============================================================================
-- FAUNOVA MIGRATION: 032_update_dummy_posts_and_avatars.sql
-- Memperbaiki foto tangkapan satwa dummy agar sesuai spesies dan menambahkan
-- avatar foto profil realistis untuk seluruh akun dummy komunitas.
-- Sesuai AGENTS.md Aturan Keras 3: RLS aktif di semua tabel, skema via migrations.
-- ==============================================================================

DO $$
DECLARE
    u_wayan UUID := 'aa111111-1111-1111-1111-111111111111';
    u_siti UUID  := 'bb222222-2222-2222-2222-222222222222';
    u_budi UUID  := 'cc333333-3333-3333-3333-333333333333';
    u_borneo UUID:= 'dd444444-4444-4444-4444-444444444444';
    u_dewi UUID  := 'ee555555-5555-5555-5555-555555555555';
    u_faiz UUID  := 'ff666666-6666-6666-6666-666666666666';

    c_komodo UUID := '11111111-cccc-cccc-cccc-cccccccccccc';
    c_jalak UUID  := '22222222-cccc-cccc-cccc-cccccccccccc';
    c_ape UUID    := '44444444-cccc-cccc-cccc-cccccccccccc';
    c_bird UUID   := '55555555-cccc-cccc-cccc-cccccccccccc';
    c_turtle UUID := '66666666-cccc-cccc-cccc-cccccccccccc';
BEGIN
    -- 1. PERBARUI FOTO PROFIL REALISTIS AKUN DUMMY DI PUBLIC.PROFILES
    -- Dr. Wayan Suastika, M.Si
    UPDATE public.profiles
    SET avatar_path = 'https://images.unsplash.com/photo-1544168190-79c17527004f?w=200&auto=format&fit=crop&q=80'
    WHERE id = u_wayan OR username = 'wayan_bali';

    -- Siti Sarah, S.Hut
    UPDATE public.profiles
    SET avatar_path = 'https://images.unsplash.com/photo-1589553009868-c7b2bb474531?w=200&auto=format&fit=crop&q=80'
    WHERE id = u_siti OR username = 'siti_sumatera';

    -- Budi Satria Wibowo
    UPDATE public.profiles
    SET avatar_path = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop&q=80'
    WHERE id = u_budi OR username = 'budi_satria';

    -- Dedi Pratama
    UPDATE public.profiles
    SET avatar_path = 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=200&auto=format&fit=crop&q=80'
    WHERE id = u_borneo OR username = 'borneo_wildlife';

    -- Dewi Lestari
    UPDATE public.profiles
    SET avatar_path = 'https://images.unsplash.com/photo-1534751516642-a1af1ef26a56?w=200&auto=format&fit=crop&q=80'
    WHERE id = u_dewi OR username = 'dewi_papua';

    -- Faiz Alamsyah
    UPDATE public.profiles
    SET avatar_path = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop&q=80'
    WHERE id = u_faiz OR username = 'faiz_ocean';

    -- 2. PERBAIKI FOTO SATWA PADA TABEL PUBLIC.CAPTURES AGAR SESUAI SPESIES
    -- Komodo (Varanus komodoensis) — ganti foto macan tutul dengan foto Komodo dragon
    UPDATE public.captures
    SET photo_object_path = 'https://images.unsplash.com/photo-1562578057-3ca1f7815237?w=900&auto=format&fit=crop&q=80'
    WHERE id = c_komodo OR (species_name ILIKE '%komodo%' AND photo_object_path LIKE '%photo-1544979590%');

    -- Jalak Bali (Leucopsar rothschildi) — ganti foto burung bayan hijau dengan Jalak Bali putih
    UPDATE public.captures
    SET photo_object_path = 'https://images.unsplash.com/photo-1521566652839-697aa473761a?w=900&auto=format&fit=crop&q=80'
    WHERE id = c_jalak OR (species_name ILIKE '%jalak%' AND photo_object_path LIKE '%photo-1552728089%');

    -- Orangutan Kalimantan (Pongo pygmaeus) — ganti foto burung pemakan lebah dengan Orangutan Kalimantan
    UPDATE public.captures
    SET photo_object_path = 'https://images.unsplash.com/photo-1552656504-5fd2ed591222?w=900&auto=format&fit=crop&q=80'
    WHERE id = c_ape OR (species_name ILIKE '%orangutan%' AND photo_object_path LIKE '%photo-1535083783855%');

    -- Cenderawasih Kuning Kecil (Paradisaea minor) — ganti foto macaw kuning-biru dengan burung eksotis hutan
    UPDATE public.captures
    SET photo_object_path = 'https://images.unsplash.com/photo-1618098750285-9402745c67e7?w=900&auto=format&fit=crop&q=80'
    WHERE id = c_bird OR (species_name ILIKE '%cenderawasih%' AND photo_object_path LIKE '%photo-1452570053594%');

    -- Penyu Hijau (Chelonia mydas) — ganti foto penyelam scuba dengan penyu laut berenang di laut lepas
    UPDATE public.captures
    SET photo_object_path = 'https://images.unsplash.com/photo-1437622368342-7a3d73a34c8f?w=900&auto=format&fit=crop&q=80'
    WHERE id = c_turtle OR (species_name ILIKE '%penyu%' AND photo_object_path LIKE '%photo-1544551763%');

    -- 3. SET KREDENSIAL KATA SANDI UNTUK SELURUH AKUN DUMMY DI AUTH.USERS
    -- Password: Password123!
    UPDATE auth.users
    SET 
        encrypted_password = extensions.crypt('Password123!', extensions.gen_salt('bf')),
        email_confirmed_at = COALESCE(email_confirmed_at, now()),
        raw_app_meta_data = jsonb_build_object('provider', 'email', 'providers', array['email']),
        raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb),
        aud = 'authenticated',
        role = 'authenticated',
        is_sso_user = false,
        updated_at = now()
    WHERE id IN (u_wayan, u_siti, u_budi, u_borneo, u_dewi, u_faiz)
       OR email IN (
           'dr_wayan@faunova.id',
           'siti_sarah@faunova.id',
           'budi_satria@faunova.id',
           'dedi_borneo@faunova.id',
           'dewi_papua@faunova.id',
           'faiz_ocean@faunova.id'
       );

    -- 4. DAFTARKAN IDENTITAS KE AUTH.IDENTITIES (WAJIB AGAR GOTRUE DAPAT AUTENTIKASI LOGIN EMAIL)
    DELETE FROM auth.identities
    WHERE user_id IN (u_wayan, u_siti, u_budi, u_borneo, u_dewi, u_faiz);

    INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    VALUES
        (u_wayan,  u_wayan,  u_wayan::text,  jsonb_build_object('sub', u_wayan::text,  'email', 'dr_wayan@faunova.id'),     'email', now(), now(), now()),
        (u_siti,   u_siti,   u_siti::text,   jsonb_build_object('sub', u_siti::text,   'email', 'siti_sarah@faunova.id'),   'email', now(), now(), now()),
        (u_budi,   u_budi,   u_budi::text,   jsonb_build_object('sub', u_budi::text,   'email', 'budi_satria@faunova.id'),  'email', now(), now(), now()),
        (u_borneo, u_borneo, u_borneo::text, jsonb_build_object('sub', u_borneo::text, 'email', 'dedi_borneo@faunova.id'), 'email', now(), now(), now()),
        (u_dewi,   u_dewi,   u_dewi::text,   jsonb_build_object('sub', u_dewi::text,   'email', 'dewi_papua@faunova.id'),   'email', now(), now(), now()),
        (u_faiz,   u_faiz,   u_faiz::text,   jsonb_build_object('sub', u_faiz::text,   'email', 'faiz_ocean@faunova.id'),   'email', now(), now(), now());

END $$;

