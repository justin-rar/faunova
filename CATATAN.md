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

### 3. Langkah Berikutnya
- Melanjutkan ke Sesi S2 (Autentikasi Supabase & SMTP Brevo).

---

## Sesi S2 — Selesai ✅

### 1. Selesai Dikerjakan
- **Gerbang Autentikasi (`AuthGate`)**:
  - Diterapkan di `lib/features/auth/presentation/auth_gate.dart`.
  - Berbasis stream `AuthService.instance.authStateChanges` dan initial state `AuthService.instance.isAuthenticated`.
  - Mengarahkan ke `MainNavigationScaffold` jika pengguna sudah login, atau ke `LoginPage` jika belum memiliki sesi aktif.
- **Halaman Masuk (`LoginPage`)**:
  - Diterapkan di `lib/features/auth/presentation/login_page.dart`.
  - Desain elegan sesuai palet Faunova (latar gading, emblem sage tua, tombol utama emas `#C8A96B` dengan teks gelap).
  - Validasi formulir lengkap (email kosong, format email tidak valid, kata sandi minimal 6 karakter).
  - Tombol pengalih visibilitas kata sandi (obscure text toggle).
  - Integrasi pesan kesalahan terjemahan bahasa Indonesia untuk kredensial salah dan email belum dikonfirmasi.
  - Banner peringatan mode demo yang aman dan interaktif jika kredensial `.env` belum diisi pengguna.
- **Halaman Pendaftaran (`RegisterPage`)**:
  - Diterapkan di `lib/features/auth/presentation/register_page.dart`.
  - Formulir pendaftaran akun kolektor: Nama Lengkap, Nama Pengguna (username huruf kecil/angka), Alamat Email, Kata Sandi, dan Konfirmasi Kata Sandi.
  - Validasi field real-time: Nama pengguna tanpa spasi, minimal 3 karakter, kesesuaian konfirmasi kata sandi.
  - Setelah berhasil, pengguna diarahkan ke layar instruksi verifikasi email (`VerifyEmailPage`).
- **Halaman Verifikasi Email Brevo (`VerifyEmailPage`)**:
  - Diterapkan di `lib/features/auth/presentation/verify_email_page.dart`.
  - Menampilkan instruksi verifikasi email sesuai Plan 5.1 (panduan kotak masuk Gmail/Outlook dan pengecekan folder Spam).
  - Tautan kembali ke layar login setelah verifikasi dilakukan.
- **Halaman Lupa Kata Sandi (`ForgotPasswordPage`)**:
  - Diterapkan di `lib/features/auth/presentation/forgot_password_page.dart`.
  - Validasi alamat email dan pengiriman instruksi reset kata sandi melalui Supabase Auth / SMTP Brevo.
  - Layar konfirmasi keberhasilan pengiriman tautan pemulihan.
- **Layanan Autentikasi (`AuthService`)**:
  - Diterapkan di `lib/core/services/auth_service.dart`.
  - Metode `signUp`, `signIn`, `resetPassword`, `signOut`, dan `enterDemoMode`.
  - Integrasi logging aman tanpa kebocoran data rahasia.
  - Penanganan mode demo untuk pengujian UI tanpa server backend.
- **Integrasi Keluar Akun (`ProfilePage`)**:
  - Popup menu pojok kanan atas Profil (`Icons.more_vert_rounded`) terhubung dengan dialog konfirmasi keluar.
  - Memanggil `AuthService.instance.signOut()` yang membersihkan sesi dan seketika merespons AuthGate kembali ke `LoginPage`.
  - Penyesuaian layout PopupMenuItem dengan `Expanded` untuk mencegah overflow RenderFlex.
- **Panduan Pengaturan SMTP Brevo**:
  - Dibuat di `docs/brevo_smtp_setup.md` dengan instruksi langkah-demi-langkah integrasi Brevo SMTP ke Dashboard Supabase Auth (Host `smtp-relay.brevo.com`, Port `587`, Sender `noreply@faunova.id`, Rate limit, Template email pendaftaran & reset password).
- **Verifikasi & Tes**:
  - `flutter analyze`: 0 issues / bersih tanpa error lint.
  - `flutter test`: 10 tes unit & widget test lulus (100% pass) mencakup S1 palet/navigasi/state dan S2 alur AuthGate, validasi form login, register, forgot password, verify email, serta alur keluar akun.

### 2. Belum Teruji / Membutuhkan Konfigurasi Nyata
- **Pengiriman Email Nyata ke Inbox**: Memerlukan pengisian kredensial SMTP Brevo di dashboard Supabase milik pengguna serta kredensial `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di file `.env`. (Panduan lengkap tersedia di `docs/brevo_smtp_setup.md`).
- **Verifikasi Tautan Email Eksternal**: Membutuhkan pembukaan tautan verifikasi pada browser perangkat fisik atau aplikasi Gmail/Outlook.

### 3. Langkah Berikutnya (Sesi S3)
- **Skema Database & Migrasi Supabase (Postgres & RLS)**:
  - Membuat tabel `profiles` (kolektor, lencana, status langganan centang biru, streak, kuota).
  - Menyiapkan RLS (Row Level Security) ketat sesuai aturan `AGENTS.md`.
  - Trigger otomatis pendaftaran user baru: menyalin `auth.users` ke tabel publik `profiles` dengan profil dasar dan kuota awal.
  - View publik & RPC grid snapping untuk koordinat aman.
