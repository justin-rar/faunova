# AGENTS.md — Aturan untuk agen coding (Faunova)

Faunova adalah aplikasi sosial koleksi hewan. Stack: Flutter, Supabase (Auth, Postgres, Storage, Edge Functions), Gemini API, Midtrans Sandbox. Acuan desain ada di `docs/plan_faunova_revisi_5_final.md`, urutan kerja di `docs/scope.md`.

Kerjakan hanya fitur yang diminta pada sesi ini. Baca bagian plan yang relevan saja. Jangan mengubah keputusan desain tanpa izin.

## Aturan keras

1. **Tidak ada secret di klien atau repo.** Kunci Gemini, server key Midtrans, dan `service_role` hanya di secrets Edge Function. Jangan taruh di kode Flutter, log, atau file yang di-commit. Pakai `.env.example` tanpa nilai asli.
2. **Aturan bisnis di server.** Kuota, skor kuis, streak, badge, hash-chain, dan `verified_until` hanya diubah lewat RPC atau Edge Function. Flutter tidak pernah menulis kolom ini langsung.
3. **RLS aktif di semua tabel.** Semua perubahan skema lewat migration di `supabase/migrations`, bukan hanya lewat dashboard. Fungsi `SECURITY DEFINER` wajib menetapkan `search_path`, memakai nama tabel berkualifikasi skema, dan memeriksa `auth.uid()`.
4. **Koordinat tepat tidak pernah keluar ke publik.** Feed dan pencarian hanya memakai koordinat hasil grid dari server. Data publik lewat view atau RPC, bukan tabel mentah.
5. **Kunci jawaban kuis tidak pernah dikirim ke klien.**
6. **Midtrans:** masa aktif Centang Biru hanya berubah dari webhook yang lolos verifikasi signature, dicocokkan dengan order, nominal, dan user, dan idempotent. Halaman redirect tidak boleh mengaktifkan apa pun.
7. **Jangan menambah fitur, package, atau refactor besar di luar permintaan.** Tanyakan dulu.

## Aturan kerja

- Satu target per sesi. Setelah selesai jalankan `flutter analyze` dan tes yang relevan.
- Jangan menyatakan berhasil sebelum dijalankan. Sebutkan dengan jelas apa yang belum teruji, terutama yang membutuhkan HP fisik (kamera, GPS, kompas, accelerometer, biometrik, notifikasi).
- Setiap fitur menangani state loading, error, kosong, dan offline. Teks antarmuka berbahasa Indonesia.
- Akhir sesi: perbarui `CATATAN.md` (selesai, rusak, langkah berikutnya).

## Desain visual

- Palet: sage tua `#5C7457` (header, ikon aktif), sage `#8FA28A`, sage muda `#C7D3C0` (kartu), gading `#F7F4ED` (latar), emas `#C8A96B` (tombol utama), emas tua `#7F6326` (teks beraksen emas), teks gelap `#1F2A1E`, merah status `#B3261E`.
- Teks di atas sage, sage muda, gading, dan emas memakai teks gelap. Teks putih hanya di atas sage tua.
- Efek kaca (blur) hanya di bottom bar penuh. Header, kartu, dan panel lain memakai warna solid.

## Catatan

Nama file dan lokasi aturan ini mungkin perlu disesuaikan dengan cara Antigravity membaca rules proyek. Cek dokumentasinya. Isi aturannya yang penting.
