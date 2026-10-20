# Supabase - Faunova

Folder ini digunakan untuk menyimpan seluruh skrip migrasi database Supabase dan konfigurasi terkait.

## Aturan Migrasi (AGENTS.md)
1. **Semua perubahan skema wajib lewat migration di `supabase/migrations/`**, bukan hanya lewat dashboard.
2. **RLS (Row Level Security) aktif di semua tabel.**
3. Fungsi `SECURITY DEFINER` wajib menetapkan `search_path`, memakai nama tabel berkualifikasi skema, dan memeriksa `auth.uid()`.
4. Rahasia/secret (Gemini API key, Midtrans Server Key, Service Role) **hanya** diatur di Supabase Edge Function secrets, tidak disimpan di repo.

## Urutan Sesi Terkait Supabase
- **S1**: Struktur awal repo & konfigurasi client.
- **S2**: Autentikasi Supabase Auth & template email Brevo.
- **S3**: Migrasi inti (`profiles`, `scans`, `captures`, `posts`, `follows`, `likes`), RLS, view publik.
