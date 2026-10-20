# CATATAN.md — Faunova Log Perkembangan Sesi

Dokumen ini diperbarui di setiap akhir sesi pengerjaan Faunova untuk mencatat apa yang selesai, apa yang belum teruji / rusak, dan langkah selanjutnya.

---

## Sesi S1 (Hari 1) — Selesai ✅

### 1. Selesai Dikerjakan
- **Inisialisasi Repositori & Kerangka Flutter**:
  - Repositori Git diinisialisasi (`git init`).
  - Struktur folder rapi berbasis fitur (`core/config`, `core/theme`, `core/widgets`, `features/feed`, `features/search`, `features/camera`, `features/game`, `features/profile`, `features/navigation`).
- **Palet Warna & Tipografi (AGENTS.md & Poppins)**:
  - Diterapkan di `lib/core/theme/app_colors.dart` dan `lib/core/theme/app_theme.dart`.
  - Sage tua `#5C7457`, Sage `#8FA28A`, Sage muda `#C7D3C0`, Gading `#F7F4ED`, Emas `#C8A96B`, Emas tua `#7F6326`, Teks gelap `#1F2A1E`, Merah status `#B3261E`.
  - Kontras ditaati: Teks putih hanya di atas sage tua; teks di atas sage, sage muda, gading, dan emas menggunakan teks gelap.
  - Header dan kartu memakai warna solid (tidak blur).
  - Tipografi seluruh aplikasi menggunakan font **Poppins** via `google_fonts` untuk tampilan modern dan estetik.
- **Bottom Bar Kaca (Glassmorphism & Animasi Meluncur)**:
  - Diterapkan di `lib/core/widgets/glass_bottom_bar.dart` dan `lib/features/navigation/main_navigation_scaffold.dart`.
  - Menggunakan arsitektur `Stack` sehingga konten halaman scroll langsung meluncur di belakang bar tanpa terpotong layout.
  - Efek blur `ImageFilter.blur(sigmaX: 25, sigmaY: 25)` dengan transparansi tembus pandang frosted glass `0.60` dan highlight garis putih di tepi atas.
  - **Animasi Kapsul Meluncur (Sliding Pill Indicator)**: Menggunakan `AnimatedPositioned` dengan kurva `Curves.fastOutSlowIn` (300ms) sehingga saat berpindah tab (misal dari Beranda ke Profil), kapsul putih glossy meluncur secara fisik dan dinamis melintasi tab-tab di homebar. Tab yang aktif juga memiliki animasi scale dan fade pada ikon & teks.
- **Scroll Physics & UI Beranda**:
  - Mengganti overscroll stretch bawaan Android 12+ yang melar berlebih dengan `ClampingScrollPhysics` yang solid dan halus di `FaunovaScrollBehavior` (`main.dart`).
  - Menghapus judul teks "Faunova" dari AppBar Beranda, langsung menampilkan tab "Untuk Kamu" dan "Mengikuti" secara rapi dan ringkas.
- **5 Tab Navigasi Berpindah (IndexedStack & Anti-Slop Overhaul)**:
  - Beranda (`FeedPage`): Gaya jurnal observasi lapangan; kartu satwa (*Jalak Bali, Kucing Kuwuk, Cenderawasih, Rusa Bawean*) dengan nama latin ilmiah, status konservasi IUCN (*Kritis / CR, LC*), grid snapping location, catatan lapangan, dan nomor blok hash-chain kanonis `#14`.
  - Cari (`SearchPage`): Filter kategori taksonomi horizontal (*Mamalia, Aves, Reptilia, Amfibi*), kartu akun terverifikasi Centang Biru dengan gelar spesifik konservasi dan jumlah observasi.
  - Kamera (`CameraPage`): Viewfinder optik taktis dengan crosshair center reticle, pita kompas arah heading `148° SE`, status GPS locked, tombol bidik emas, dan kartu spesifikasi alur verifikasi server (tanpa galeri).
  - Game (`GamePage`): Tiket observasi streak dengan pelacak hari Senin-Minggu, Tantangan Hari Ini dengan soal biologi nyata (+50 Poin), Arena Kuis 10 Soal (timer, nyawa, skor server), dan banner Shake-to-Quiz dengan kuota harian.
  - Profil (`ProfilePage`): Portofolio kolektor satwa; metrik observasi, langganan Centang Biru aktif (Midtrans Sandbox), rak 4 lencana MVP, sub-tab koleksi, serta panel verifikasi integritas rantai SHA-256 (`verify_chain`).
- **Penanganan 4 State (AGENTS.md)**:
  - Widget terstandarisasi `AppStateView` di `lib/core/widgets/app_state_view.dart` menangani state: Memuat (Loading), Kosong (Empty), Galat (Error), dan Luring (Offline).
  - Dilengkapi chip pemilih simulasi state di setiap halaman tab untuk pengujian langsung.
  - Seluruh teks antarmuka berbahasa Indonesia.
- **Supabase & `.env.example`**:
  - Dibuat `.env.example` tanpa kunci rahasia/secret (`SUPABASE_URL` dan `SUPABASE_ANON_KEY`).
  - `.env` diabaikan oleh `.gitignore`.
  - Folder migrasi database dibuat di `supabase/migrations/` beserta panduan `supabase/README.md`.
  - Package `supabase_flutter` ditambahkan dengan inisialisasi kondisional aman di `lib/core/config/app_config.dart` (aplikasi tidak crash saat `.env` belum diisi).
- **Verifikasi & Build**:
  - `flutter analyze`: 0 issues / bersih.
  - `flutter test`: 4 unit & widget test lulus (palet warna, tema, navigasi 5 tab, efek kaca, dan pengujian 4 state).
  - `flutter build apk --debug`: Berhasil dikompilasi menjadi APK Android (`app-debug.apk`).

### 2. Belum Teruji / Membutuhkan Perangkat Fisik
- **Sensor Perangkat Fisik**: Kamera fisik, sensor GPS (lokasi & mock location detection), magnetometer kompas (arah kamera), accelerometer (shake gesture), dan biometrik fingerprint belum diuji pada HP fisik (dijadwalkan pada sesi masing-masing: S4, S5, S15, S17).
- **Proyek Supabase**: Menunggu pengisian URL dan Anon Key pada file `.env` oleh pengguna saat proyek Supabase dibuat.

### 3. Langkah Berikutnya (Sesi S2)
- **Autentikasi Supabase Auth**:
  - Form & halaman Register.
  - Verifikasi email via Brevo SMTP kustom.
  - Halaman Login (email + password).
  - Alur Lupa Password / Reset Password.
  - Integrasi Logout dari menu pojok kanan atas Profil.
