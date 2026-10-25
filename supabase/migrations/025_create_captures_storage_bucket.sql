-- ==============================================================================
-- FAUNOVA MIGRATION 025: Create Storage Bucket for Captures and Avatars
-- Sesuai Dokumen Desain Plan 5.3 & Rencana Perbaikan Bug 1
-- Catatan Keras: File migrasi ini disiapkan untuk deployment infrastruktur storage
-- dan TIDAK dijalankan langsung ke database production sesuai instruksi pengguna.
-- ==============================================================================

-- 1. Buat bucket penyimpanan publik untuk tangkapan foto satwa (captures)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'captures',
    'captures',
    true,
    5242880, -- Batas 5MB per foto
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 2. Kebijakan RLS Penyimpanan:
-- A. Siapa pun dapat membaca foto observasi publik
DROP POLICY IF EXISTS "Public Captures Read Access" ON storage.objects;
CREATE POLICY "Public Captures Read Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'captures');

-- B. Pengguna terautentikasi dapat mengunggah foto capture ke direktori mereka sendiri
DROP POLICY IF EXISTS "Users can upload their own captures" ON storage.objects;
CREATE POLICY "Users can upload their own captures"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'captures' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- C. Pengguna dapat memperbarui atau menghapus foto miliknya sendiri
DROP POLICY IF EXISTS "Users can update their own captures" ON storage.objects;
CREATE POLICY "Users can update their own captures"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'captures' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "Users can delete their own captures" ON storage.objects;
CREATE POLICY "Users can delete their own captures"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'captures' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);
