-- ==============================================================================
-- FAUNOVA MIGRATION 026: Preserve Capitalized Nickname in Display Name
-- Mempertahankan username selalu huruf kecil (lowercase) untuk konsistensi URL/identitas,
-- serta memastikan display_name menjaga huruf kapital nickname/nama pengguna.
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
    raw_user_name TEXT;
BEGIN
    -- Username selalu dipaksa huruf kecil sesuai aturan konsistensi sistem
    new_username := lower(COALESCE(
        NEW.raw_user_meta_data->>'username',
        'kolektor_' || substr(md5(random()::text), 1, 8)
    ));
    
    -- Nama tampilan (Display Name / Nickname) menjaga huruf kapital asli pengguna
    raw_user_name := COALESCE(
        NEW.raw_user_meta_data->>'display_name',
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'nickname',
        NEW.raw_user_meta_data->>'raw_username',
        NEW.raw_user_meta_data->>'username',
        'Penjelajah Faunova'
    );

    new_display_name := TRIM(raw_user_name);
    IF new_display_name = '' THEN
        new_display_name := 'Penjelajah Faunova';
    END IF;

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
    ON CONFLICT (id) DO UPDATE
    SET 
        display_name = EXCLUDED.display_name,
        updated_at = now();

    RETURN NEW;
END;
$$;
