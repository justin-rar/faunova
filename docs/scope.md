# scope.md — Faunova: ruang lingkup dan urutan kerja

Konteks: dibangun sendiri dengan Antigravity, sekitar 14 hari, siklus kerja 6 jam (1 sesi = 1 jendela pemakaian). Dua sesi per hari sudah cukup, tiga sesi per hari memberi cadangan. HP Android fisik tersedia untuk tes. Laporan dikerjakan tim.

Dokumen acuan desain: `plan_faunova_revisi_5_final.md`. Berkas ini hanya menentukan **urutan dan batas kerja**, bukan mengubah keputusan desain.

---

## 1. Tiga tingkat

| Tingkat | Isi |
|---|---|
| **1. Alur tipis** | Register, verifikasi email, login, lupa password, profil, bottom nav. Kamera, scan AI, chat AI, simpan koleksi, hash-chain, peta, Verifikasi Rantai. Posting, feed dua tab, follow, like |
| **2. Sisa kriteria dosen** | Pencarian, Hive terenkripsi + kurs, konversi waktu, kuis, streak, Tantangan Hari Ini, shake-to-quiz, badge, biometrik, notifikasi lokal, Midtrans sandbox + Centang Biru, Saran & Kesan |
| **3. Jika sempat** | Hapus akun, tombstone rantai, reconciliation job, cleanup terjadwal (cron), ledger refund, status machine penuh, komentar, offline capture, notifikasi dalam aplikasi, tombol Laporkan, login Google |

Semua kriteria wajib dosen ada di Tingkat 1 dan 2. Tingkat 3 tidak boleh mengorbankan keduanya.

## 2. Aturan sesi

- **Satu sesi, satu target yang bisa dites.** Akhiri dengan commit.
- **Awal sesi:** beri agen `AGENTS.md` dan spesifikasi fitur yang dikerjakan saja (bukan seluruh plan).
- **Akhir sesi:** perbarui `CATATAN.md` (selesai, rusak, langkah berikutnya) supaya sesi berikutnya tidak mulai dari nol.
- **Jangan klaim selesai sebelum dites.** Fitur yang butuh sensor, kamera, biometrik, atau notifikasi dites di HP fisik.

## 3. Urutan sesi

| Hari | Sesi | Target | Cek selesai |
|---|---|---|---|
| 1 | S1 | Repo, kerangka Flutter, palet warna, bottom bar kaca, 5 tab kosong. Proyek Supabase dan `.env.example` | Aplikasi jalan di HP, 5 tab berpindah |
| 1 | S2 | Register, verifikasi email (Brevo), login, lupa password, logout | Email sampai di Gmail dan Outlook, login berhasil |
| 2 | S3 | Migration inti (profiles, scans, captures, posts, follows, likes), RLS, view profil publik | Tes dua akun: user B tidak bisa membaca data user A |
| 2 | S4 | **Uji berisiko:** Edge Function ke Gemini dengan foto asli, kompas di HP, Midtrans stub | Tiap uji punya hasil tertulis (lulus/gagal) |
| 3 | S5 | Kamera layar penuh, kompres, GPS + heading, `ai-gateway` mode scan, halaman hasil | Foto hewan teridentifikasi, foto non-hewan ditolak |
| 3 | S6 | Chat AI per scan dan kuota atomik (5/10 pertanyaan, 20 scan/hari) | Kuota terakhir tidak bisa ditembus dua request paralel |
| 4 | S7 | `save-capture` dan fungsi hash-chain (format kanonis, advisory lock) | Mengubah satu kolom membuat verifikasi gagal |
| 4 | S8 | Koleksi (grid, detail), peta, tombol Verifikasi Rantai | Peta terbuka, rantai putus saat data diubah |
| 5 | S9 | `create_post` (grid snapping di server) dan feed Untuk Kamu | Feed tidak pernah memuat koordinat tepat |
| 5 | S10 | Follow, tab Mengikuti, like, profil publik | Follow dan like idempotent |
| 6 | S11 | Profil sendiri (foto, bio, edit), pencarian akun dan spesies | Pencarian mengembalikan hasil benar |
| 6 | S12 | Hive terenkripsi (cache koleksi, kurs, setting), konversi waktu 4 zona | Koleksi terbaca offline, jam tampil di 4 zona |
| 7 | S13 | Kuis: `start`/`finish_quiz_session`, UI timer, nyawa, combo. **Manual:** buat dan review ~100 soal di luar aplikasi | Skor dihitung server, kunci jawaban tidak dikirim ke klien |
| 7 | S14 | Streak check-in dan Tantangan Hari Ini | Klaim ganda ditolak |
| 8 | S15 | Shake-to-quiz (accelerometer), kuota 3x/hari | Goyang HP memunculkan soal, kuota server berlaku |
| 8 | S16 | Badge (mulai 4 badge) dan pop-up lokal | Badge terbuka setelah syarat terpenuhi |
| 9 | S17 | Biometrik: toggle, sesi tersimpan, 5 kali gagal | Alur ikut `plan` bagian 5.1 |
| 9 | S18 | Notifikasi lokal terjadwal (streak, Tantangan, masa Centang Biru) | Notifikasi muncul di HP, batal bila sudah check-in |
| 10 | S19 | Midtrans: `create-payment`, Snap di webview, webhook dengan verifikasi signature | Pembayaran sandbox memicu webhook yang sah |
| 10 | S20 | Centang Biru: `verified_until`, ikon, kuota chat 10, prioritas pencarian, harga IDR/USD/JPY | Webhook ganda tidak memperpanjang dua kali |
| 11 | S21 | Saran & Kesan, menu pojok, Setting, rapikan state loading/error/empty | Tidak ada layar yang kosong tanpa penjelasan |
| 11 | S22 | Tes RLS dua akun penuh dan checklist keamanan (plan bagian 13) | Semua centang keamanan lulus |
| 12 | S23 | Tes seluruh fitur di HP fisik, perbaiki bug | Daftar bug kosong untuk alur demo |
| 12 | S24 | Data demo (akun, tangkapan, soal), screenshot untuk laporan | Skenario demo berjalan dari awal sampai akhir |
| 13–14 | cadangan | Latihan demo, perbaikan, dan Tingkat 3 yang sempat | — |

## 4. Urutan pemotongan jika molor

1. Seluruh Tingkat 3.
2. Badge dari 8 menjadi 3–4.
3. Pencarian spesies dan Peta Koleksi disederhanakan.
4. Tantangan Hari Ini dibuat paling sederhana (satu soal dari bank kuis).

## 5. Yang tidak dipotong

- Semua kriteria wajib dosen.
- RLS dengan tes dua akun.
- Secret (Gemini, Midtrans, service role) hanya di secrets Edge Function.
- Kuota, skor, streak, hash-chain, dan `verified_until` hanya diubah di server.
- Verifikasi signature webhook Midtrans.

## 6. Pekerjaan manual (agen tidak bisa)

- Membuat akun dan kunci: Brevo, Gemini (plus kunci cadangan), Midtrans Sandbox, proyek Supabase.
- Mengatur SMTP dan secrets di dashboard Supabase.
- Tes di HP fisik: kamera, GPS, kompas, accelerometer, biometrik, notifikasi.
- Meninjau SQL dan RLS yang ditulis agen.
- Meninjau soal kuis buatan AI.
