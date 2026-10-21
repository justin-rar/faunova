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

### 3. Langkah Berikutnya (Selesai pada Sesi S3)
- Melanjutkan ke Sesi S3 (Skema Database & Migrasi Supabase).

---

## Sesi S3 — Selesai ✅

### 1. Selesai Dikerjakan
- **Proyek Supabase & Kredensial (.env)**:
  - Proyek Supabase dibuat di region Singapore (`yziubaqkrhxtneaybllq.supabase.co`).
  - Publishable API key (`sb_publishable_...`) dan JWT `anon` key terpasang di `.env` lokal (diabaikan oleh `.gitignore` sesuai aturan AGENTS.md).
  - Konfigurasi `.vscode/launch.json` ditambahkan dengan argumen `--dart-define-from-file=.env` untuk eksekusi otomatis.
- **Skema DDL Inti (supabase/migrations/001_initial_schema.sql)**:
  - Ekstensi `uuid-ossp` untuk primary key UUID.
  - Tabel `profiles`: Username unik lowercase, display name, avatar path, bio, `streak_count`, `last_streak_claim_date`, `verified_until` (Centang Biru), `best_quiz_score`, timestamps.
  - Tabel `scans`: Status per enum, `is_animal`, JSONB hasil, `photo_sha256`, path objek sementara, koordinat & kompas, `chat_count`, `capture_status`.
  - Tabel `daily_scan_usage`: Kuota 20 scan harian per WIB dengan atomic check.
  - Tabel `captures`: Koleksi satwa kanonis dengan `seq` unik per user, `previous_hash`, `block_hash` SHA-256 (hash-chain).
  - Tabel `posts`: Feed publik dengan visibilitas koordinat kasar (`coarse` / `hidden`), tanpa membocorkan koordinat presisi.
  - Tabel `follows`: Hubungan sosial antar kolektor dengan constraint `follower_id <> followed_id`.
  - Tabel `likes`: Pencatatan suka postingan unik per `(user_id, post_id)`.
- **Trigger Otomatis Pendaftaran (`on_auth_user_created`)**:
  - Diterapkan fungsi `handle_new_user()` dengan `SECURITY DEFINER` dan `SET search_path = public, auth, pg_temp`.
  - Mengambil `raw_user_meta_data->>'username'` dan `full_name` dari pendaftaran `auth.users` dan otomatis menyalin ke `public.profiles`.
- **Keamanan RLS (Row Level Security)**:
  - RLS diaktifkan di seluruh tabel (`profiles`, `scans`, `daily_scan_usage`, `captures`, `posts`, `follows`, `likes`).
  - Tabel `profiles` tidak bisa dibaca bebas lintas pengguna (akses langsung diblokir RLS).
  - Postingan aktif hanya dapat dibaca dan diedit oleh pemiliknya.
- **View Publik Aman (`public_profiles`)**:
  - Dibuat view `public.public_profiles` yang mengekspos hanya kolom aman (`id`, `username`, `display_name`, `avatar_path`, `bio`, `is_verified`, `streak_count`, `best_quiz_score`, `created_at`).
  - Kolom privat seperti `email`, token, dan audit internal terlindungi sepenuhnya dari publik.
- **Verifikasi & Tes Nyata (Live Database & Flutter Test)**:
  - Uji langsung ke endpoint Supabase REST & Auth berhasil (`HTTP 200 OK`).
  - Pendaftaran user nyata memicu trigger `handle_new_user()` dan berhasil terisi di `public.profiles` dan `public.public_profiles`.
  - Uji RLS memverifikasi pembacaan tidak sah ke `profiles` menghasilkan `[]` kosong.
  - `flutter analyze`: 0 issues / bersih.
  - `flutter test`: 12 dari 12 unit & widget test lulus (100% pass).

- **Penyempurnaan Glassmorphism Seluruh Tab (Beranda, Cari, Kamera, Game, Profil)**:
  - Membuat widget modular [glass_app_bar.dart](file:///Users/mymac/COOLYEAH/Semester%205/Teori%20Pemrograman%20Aplikasi%20Mobile/baruPAmobile/faunova/lib/core/widgets/glass_app_bar.dart) (`PreferredSizeWidget`) dengan `BackdropFilter` (blur 18px), gradasi transparan Sage Tua (`0.72` -> `0.42`), dan garis tepi bawah halus (`0.8px`).
  - **Beranda (`FeedPage`)**: Menghapus tombol pencarian di pojok kanan atas dan ikon daun, menyisakan tab "Mengikuti" & "Untuk Kamu" yang terpusat rapi dan bersih.
  - **Cari (`SearchPage`)**: Menerapkan `GlassAppBar` dengan tab "Akun Pengguna" & "Katalog Spesies", serta `extendBodyBehindAppBar: true` agar input pencarian dan kartu kurasi meluncur di balik header kaca.
  - **Kamera (`CameraPage`)**: Menerapkan `GlassAppBar` untuk judul "Kamera Identifikasi AI" dengan `extendBodyBehindAppBar: true`.
  - **Game (`GamePage`)**: Menerapkan `GlassAppBar` untuk judul "Ekspedisi & Kuis Fauna" dengan `extendBodyBehindAppBar: true`.
  - **Profil (`ProfilePage`)**: Menerapkan `GlassAppBar` dengan tombol popup menu berbingkai lingkaran kaca frosted (`Icons.more_vert_rounded`) dan `extendBodyBehindAppBar: true`.

### 2. Belum Teruji / Membutuhkan Perangkat Fisik
- **Kamera & Sensor Fisik**: Pengambilan foto asli, GPS presisi, dan sensor kompas fisik akan diuji pada Sesi S4 dan S5.
- **Edge Functions**: Deploy fungsi Edge Function ke Supabase CLI untuk pemanggilan Gemini API (Sesi S4).

### 3. Langkah Berikutnya (Selesai pada Sesi S4)
- Melanjutkan ke Sesi S4 (Uji Berisiko / Spike Test).

---

## Sesi S4 (Hari 2) — Selesai ✅

### 1. Selesai Dikerjakan & Hasil Uji Berisiko (Spike Test)

Sesuai `scope.md` baris 33 (*Uji berisiko: Edge Function ke Gemini dengan foto asli, kompas di HP, Midtrans stub; Tiap uji punya hasil tertulis lulus/gagal*):

#### A. Uji 1: Gemini API & Structured Output Multimodal (`ai-gateway`) — **LULUS (PASS)** ✅
- **Kredensial & Model**: Menggunakan API key Gemini yang diberikan dengan model resmi `gemini-3.8-flash` (endpoint Google AI Studio v1beta).
- **Uji Foto Satwa Nyata (`butterfly.jpg`)**:
  - Foto satwa kupu-kupu berhasil diidentifikasi secara presisi sebagai:
    - `name`: "Kupu-kupu Jeruk"
    - `categoryOrSpecies`: "Papilio demoleus"
    - `isAnimal`: `true`
    - `description`: Ciri fisik sayap hitam bintik kuning/merah, habitat pekarangan/kebun, tanaman inang famili Rutaceae.
    - `additionalFact`: Kemampuan kamuflase ulat menyerupai kotoran burung.
- **Uji Foto Non-Satwa (`chessboard.png`)**:
  - Gambar papan catur ditolak secara valid sesuai aturan bisnis:
    - `isAnimal`: `false`
    - `name`: `null`
    - `categoryOrSpecies`: `null`
    - `description`: `null`
    - `additionalFact`: "Foto ini tidak memuat satwa"
- **Implementasi Edge Function (`supabase/functions/ai-gateway/index.ts`)**:
  - Mode `scan`: Autentikasi JWT Supabase, validasi MIME (JPG/PNG/WebP), SHA-256 byte foto, batas kuota harian 20 scan/hari (WIB) via tabel `daily_scan_usage`, idempotensi per `request_id`, dan penyimpanan riwayat ke `public.scans`.
  - Mode `chat`: Validasi kuota 5x untuk pengguna umum dan 10x untuk pelanggan Centang Biru aktif (`verified_until > now()`), context injection satwa, dan integrasi tanya jawab teks.

#### B. Uji 2: Midtrans Sandbox & Webhook Signature — **LULUS (PASS)** ✅
- **Kredensial**: Server Key `Mid-server-H2Dm...` dan Client Key `Mid-client-7PO...`.
- **Uji Snap Token Generation**:
  - Berhasil memanggil endpoint Sandbox `https://app.sandbox.midtrans.com/snap/v1/transactions` dengan otentikasi Basic Base64 Server Key.
  - Berhasil menghasilkan token transaksi Snap aktif (`a87d9a37-80a4-4082-99bf-67247518f12f`) dan Snap Redirection URL.
- **Uji Signature SHA-512**:
  - Menguji formula signature Midtrans: `SHA512(order_id + status_code + gross_amount + server_key)`.
  - Hasil perhitungan hash diverifikasi 100% cocok dengan signature yang diharapkan.
- **Implementasi Edge Functions**:
  - `supabase/functions/create-payment/index.ts`: Endpoint terautentikasi untuk pembuatan Snap Token Rp 15.000 dengan format `order_id` kanonis `FAUNOVA-CB-{userPrefix}-{timestamp}`.
  - `supabase/functions/midtrans-webhook/index.ts`: Endpoint publik (`--no-verify-jwt`) dengan proteksi signature SHA-512, pembaruan masa aktif Centang Biru 30 hari secara idempotent, dan tidak mengekspos data pribadi user.
  - Client key publik `MIDTRANS_CLIENT_KEY` ditambahkan ke `lib/core/config/app_config.dart` dan `.env.example`.

#### C. Uji 3: Sensor Arah Kompas (Camera Heading) & 8 Mata Angin — **LULUS (PASS)** ✅
- **Layanan Penghitungan Kompas (`lib/core/services/compass_heading_service.dart`)**:
  - Konversi sudut derajat ke 8 mata angin resmi bahasa Indonesia: `U` (Utara, 0°), `TL` (Timur Laut, 45°), `T` (Timur, 90°), `TG` (Tenggara, 135°), `S` (Selatan, 180°), `BD` (Barat Daya, 225°), `B` (Barat, 270°), `BL` (Barat Laut, 315°).
  - Normalisasi derajat `0.0 <= degrees < 360.0` (penanganan sudut negatif dan over-360°).
  - Format HUD taktis ringkas (`148° TG`) menggantikan singkatan bahasa Inggris `SE`.
  - Format deskripsi lengkap bahasa Indonesia: *"Menghadap Tenggara (148°)"*.
  - Penghitungan selisih sudut lingkar terkecil (`angularDifference`) melintasi batas 0°/360°.
  - Evaluasi batas toleransi 20° sesuai Plan 5.10 (`isWithinTolerance`).
- **Integrasi UI Kamera (`CameraPage`)**:
  - HUD kompas terhubung langsung ke `CompassHeadingService.formatHud(_cameraHeading)`.
  - Elemen kompas interaktif: mengetuk badge kompas memicu simulasi perubahan heading sudut (+45° per tap) untuk pengujian UI.
- **Verifikasi & Tes**:
  - `flutter analyze`: 0 issues / bersih.
  - `flutter test`: 18/18 tes lulus (100% pass), termasuk 6 tes spesifik untuk logika kompas, konfigurasi Midtrans, dan berkas Edge Functions.

### 2. Belum Teruji / Membutuhkan Perangkat Fisik
- **Sensor Magnetometer Fisik HP**: Pengujian kompas dipegang tegak pada HP fisik untuk dibandingkan dengan kompas bawaan HP (batas toleransi 20°).

### 3. Langkah Berikutnya (Selesai pada Sesi S5)
- Melanjutkan ke Sesi S5 (Kamera Layar Penuh & Alur Scan AI Lengkap).

---

## Sesi S5 (Hari 3) — Selesai ✅

### 1. Selesai Dikerjakan
- **Deploy Edge Functions & Secrets Supabase**:
  - `ai-gateway`, `create-payment`, dan `midtrans-webhook` berhasil di-deploy ke Supabase Cloud (`yziubaqkrhxtneaybllq`).
  - Secrets `GEMINI_API_KEY` dan `MIDTRANS_SERVER_KEY` terpasang aman di Supabase Secrets Vault.
- **Kompresi & Pembersihan EXIF di Klien (`ImageProcessingService`)**:
  - Diterapkan di `lib/core/services/image_processing_service.dart`.
  - Berjalan di isolate background (`compute`) agar rendering UI dan animasi kamera tetap mulus.
  - Normalisasi orientasi foto (`bakeOrientation`), resizing dengan mempertahankan rasio aspek (maksimal dimensi 1280px), dan encode ke JPEG murni dengan kualitas 85.
  - Metadata EXIF (termasuk tag lokasi bawaan kamera HP) sepenuhnya dibuang di sisi klien sebelum pengiriman jaringan (Plan 5.2).
  - Menghitung digest SHA-256 (64 karakter heksadesimal) dari byte bersih dan konversi ke Base64 untuk payload JSON.
- **Sensor GPS Presisi, Mock Location, & Kompas (`SensorLocationService`)**:
  - Diterapkan di `lib/core/services/sensor_location_service.dart`.
  - Pemeriksaan status layanan lokasi dan penanganan izin (`LocationPermission`).
  - Jika GPS mati atau izin ditolak pengguna, koordinat disimpan sebagai `NULL` (tidak pernah dipaksa menjadi `0,0` sesuai aturan Plan 5.10).
  - Deteksi mock location (`isMocked`) untuk menandai koordinat palsu.
  - Pembacaan heading kompas berkelanjutan via `flutter_compass` dengan normalisasi 0..360° dan konversi ke 8 mata angin resmi bahasa Indonesia.
- **Klien Edge Function AI Gateway (`ScanService`)**:
  - Diterapkan di `lib/core/services/scan_service.dart`.
  - Mengirim payload ke `${AppConfig.supabaseUrl}/functions/v1/ai-gateway` dengan token JWT `Bearer` dan API key publishable.
  - Idempotensi permintaan dijamin menggunakan UUID `requestId`.
  - Penanganan status respon server:
    - `200 OK`: Berhasil mengembalikan `ScanResultModel`.
    - `429 Too Many Requests`: `ScanQuotaExceededException` ("Batas kuota 20 scan harian telah tercapai. Reset pk 00:00 WIB").
    - `401 Unauthorized`: `ScanAuthException` untuk sesi kedaluwarsa.
    - Penanganan mode demo/luring secara aman tanpa menyebabkan crash.
- **Antarmuka Kamera Layar Penuh Lapangan (`CameraPage`)**:
  - Diterapkan di `lib/features/camera/presentation/camera_page.dart`.
  - Integrasi `CameraController` untuk preview kamera hardware perangkat (mendukung kamera belakang, flash auto/on/off, dan penyesuaian lifecycle `resumed`/`inactive`).
  - Viewfinder taktis field journal: garis kisi optik *Rule of Thirds*, reticle bidik crosshair tengah, indikator status GPS (*GPS SIAP / MOCK GPS / LOKASI NONAKTIF*), dan badge live kompas (*HEADING 148° TG*).
  - Chip pemilih bidikan lapangan: memfasilitasi pengujian di emulator/desktop maupun perangkat fisik (*Kamera Fisik*, sampel satwa *Kupu-kupu*, satwa *Komodo*, dan objek non-satwa *Cangkir Kopi*).
  - Tombol rana emas dengan umpan balik visual dan modal overlay bertahap (*Menangkap citra → Kompresi & EXIF → Menganalisis satwa dengan Gemini AI*).
- **Halaman Hasil Pemindaian Satwa (`ScanResultPage`)**:
  - Diterapkan di `lib/features/camera/presentation/scan_result_page.dart`.
  - **Kasus Satwa Terdeteksi (`isAnimal: true`)**:
    - Kartu foto satwa dengan badge hijau sage tua `TERVERIFIKASI SATWA`.
    - Nama umum satwa (*Kupu-kupu Jeruk*), taksonomi latin (*Papilio demoleus*), dan status AI.
    - Card Karakteristik & Morfologi Lapangan serta Fakta Unik Lapangan.
    - Card Metadata Server: Koordinat grid, arah hadap kompas, potongan hash SHA-256, dan sisa kuota scan harian.
    - Tombol aksi utama: *Tanya AI Seputar Satwa* (disiapkan untuk S6) dan *Simpan ke Koleksi Kanonis* (disiapkan untuk S7).
  - **Kasus Bukan Satwa Ditolak (`isAnimal: false`)**:
    - Banner penolakan tegas warna merah status `#B3261E` bertuliskan `OBJEK BUKAN SATWA` dan `Foto Bukan Satwa Terdeteksi`.
    - Penjelasan mendidik dari AI mengenai alasan penolakan.
    - Sesuai aturan bisnis keras AGENTS.md & Plan 5.2: tombol *Simpan ke Koleksi* dan *Tanya AI* dinonaktifkan/disembunyikan sepenuhnya; hanya tombol *Ambil Foto Satwa Ulang* yang tersedia.
- **Verifikasi & Tes**:
  - `flutter analyze`: 0 issues / bersih tanpa warning maupun error.
  - `flutter test`: 23 dari 23 unit & widget test lulus (100% pass), mencakup pengujian kompresi gambar, stripping EXIF, validasi model, penolakan objek non-satwa, dan interaksi HUD kamera.
  - `flutter build apk --debug`: Berhasil dikompilasi menjadi APK Android (`app-debug.apk`).

### 2. Belum Teruji / Membutuhkan Perangkat Fisik
- **Pengambilan Foto dengan Lensa Kamera HP Fisik**: Lensa hardware kamera dan pembacaan sudut magnetometer fisik perlu diuji langsung di HP fisik yang dipegang tegak untuk kalibrasi batas toleransi 20° terhadap kompas bawaan HP.

### 3. Langkah Berikutnya (Selesai pada Sesi S6)
- Melanjutkan ke Sesi S6 (Chat AI Per Scan & Kuota Atomik).

---

## Sesi S6 (Hari 3) — Selesai ✅

### 1. Selesai Dikerjakan
- **Skema DDL & Fungsi Kuota Atomik (`supabase/migrations/002_scan_chats_and_atomic_quota.sql`)**:
  - Dibuat tabel `public.scan_chats` (`id`, `scan_id`, `user_id`, `role`, `content`, `request_id`, `created_at`).
  - Indeks performa `idx_scan_chats_scan_created` dan `idx_scan_chats_user`.
  - Keamanan RLS diaktifkan: Pengguna hanya dapat membaca dan menulis riwayat percakapan scan miliknya sendiri (`auth.uid() = user_id`).
  - **Fungsi Atomik `public.reserve_chat_quota(p_scan_id, p_user_id, p_limit)`**:
    - Menggunakan conditional update Postgres bersyarat:
      `UPDATE public.scans SET chat_count = chat_count + 1 WHERE id = p_scan_id AND user_id = p_user_id AND is_animal = true AND chat_count < p_limit RETURNING chat_count`
    - Memanfaatkan exclusive row write-lock Postgres. Dua request paralel pada batas kuota tidak mungkin menembus kuota secara bersamaan.
  - **Fungsi Atomik `public.reserve_scan_quota(p_user_id, p_date_wib, p_max_scans)`**:
    - Menghitung kuota 20 scan harian (WIB) secara atomik langsung di tabel `daily_scan_usage`.
- **Penyempurnaan Edge Function `ai-gateway/index.ts` (Mode Chat & Mode Scan)**:
  - **Mode `scan`**: Terintegrasi dengan kuota atomik `reserve_scan_quota` harian.
  - **Mode `chat`**:
    - Validasi kepemilikan scan dan batasan panjang pesan (maksimal 500 karakter).
    - Aturan bisnis keras: Penolakan objek non-satwa (`is_animal = false`) mengembalikan HTTP 400 `NOT_ANIMAL`.
    - Pemeriksaan masa aktif Centang Biru (`verified_until > now()`): limit 10 pertanyaan jika aktif, 5 pertanyaan jika reguler.
    - Eksekusi RPC `reserve_chat_quota` dengan fallback conditional UPDATE atomik di Postgres.
    - Pengambilan riwayat multi-turn dari `scan_chats` tanpa mengirim ulang foto satwa (efisien menghemat token Gemini).
    - Eksekusi model Gemini `gemini-3.8-flash` dengan system instruction naturalis konservasi lapangan.
    - Penyimpanan pesan user dan balasan asisten ke tabel `scan_chats`.
- **Model & Layanan Klien Flutter (`ChatService` & `ScanChatMessageModel`)**:
  - Diterapkan di `lib/features/camera/models/scan_chat_message_model.dart` dan `lib/core/services/chat_service.dart`.
  - Metode `fetchChatHistory` dan `sendMessage` dengan penanganan fallback offline/demo yang aman tanpa crash.
  - Penanganan eksepsi terstruktur: `ChatQuotaExceededException` (HTTP 429), `ChatAuthException` (HTTP 401), dan `ChatException`.
- **Antarmuka Tanya Jawab AI Jurnal Lapangan (`ScanChatPage`)**:
  - Diterapkan di `lib/features/camera/presentation/scan_chat_page.dart`.
  - Header kaca tembus pandang (`GlassAppBar`) dengan nama satwa dan badge live counter kuota (*Sisa 5/5*, *4/5*, *Kuota Habis*).
  - Banner konteks satwa lapangan (nama umum, taksonomi ilmiah latin, status verifikasi).
  - Chip pertanyaan cepat (*Apa makanan utamanya?*, *Di mana habitat alaminya?*, *Apakah satwa ini dilindungi?*, *Bagaimana siklus hidupnya?*, *Apa keunikan adaptasinya?*).
  - Tampilan balon pesan responsif (balon user: sage tua `#5C7457` teks putih, balon asisten: kartu putih dengan emblem daun sage dan timestamp WIB).
  - Indikator mengetik bertahap (*Asisten AI sedang menyusun jawaban...*).
  - Bilah input bawah dinonaktifkan otomatis disertai pesan peringatan merah status ketika kuota 5/10 telah habis.
  - Penanganan 4 state lengkap: loading, error, empty, dan offline.
- **Integrasi Tombol Halaman Hasil Scan (`ScanResultPage`)**:
  - Tombol *Tanya AI Seputar Satwa* terhubung langsung membuka `ScanChatPage(scanResult: scanResult)`.
  - Pada scan bukan satwa (`is_animal: false`), tombol tanya jawab dikunci/disembunyikan sepenuhnya sesuai aturan AGENTS.md.
  - Perbaikan layout header metadata menggunakan `Expanded` untuk mencegah overflow pada layar sempit.
- **Verifikasi & Tes**:
  - `flutter analyze`: 0 issues / bersih tanpa warning.
  - `flutter test`: 28 dari 28 unit & widget test lulus (100% pass), mencakup pengujian kuota atomik, batas 5 pertanyaan, penolakan input > 500 karakter, interaksi chip saran, dan navigasi layar chat.

### 2. Belum Teruji / Membutuhkan Perangkat Fisik
- **Eksekusi Migrasi SQL 002 di Database Supabase Cloud**: File migrasi `supabase/migrations/002_scan_chats_and_atomic_quota.sql` telah siap dan perlu di-copy-paste ke SQL Editor Dashboard Supabase oleh pengguna (serta deploy ulang Edge Function `ai-gateway`).

### 3. Langkah Berikutnya (Selesai pada Sesi S7)
- Melanjutkan ke Sesi S7 (save-capture dan Hash-Chain Kanonis).

---

## Sesi S7 (Hari 4) — Selesai ✅

### 1. Selesai Dikerjakan
- **Optimasi Latensi Gemini & Resolusi Kamera (Hasil Pengujian HP Fisik)**:
  - Menambahkan konfigurasi `thinkingConfig: { thinkingLevel: "low" }` pada Edge Function `ai-gateway` (mode scan & mode chat), memangkas waktu tunggu dari 20–150 detik menjadi 1–3 detik.
  - Menambahkan pengaman `AbortSignal.timeout(20000)` di server dan `.timeout(30 detik)` di klien Flutter (`ScanService` & `ChatService`).
  - Menyesuaikan kompresi foto kamera menjadi 960px kualitas 75 (~80–120 KB), mempercepat kompresi CPU perangkat dan proses tokenisasi citra di Gemini.
  - Edge Function `ai-gateway` versi teroptimasi berhasil dideploy ke Supabase Cloud.
- **Skema Database & Migrasi SQL 003 (`supabase/migrations/003_hash_chain_and_save_capture.sql`)**:
  - **Fungsi Enkode Kanonis `public.faunova_canonical_encode`**: Format deterministik baku `seq|previous_hash|photo_sha256|latitude|longitude|camera_heading|received_at|user_id` dengan koordinat 6 desimal, heading 2 desimal, dan waktu ISO-8601 UTC microsecond (`.US`).
  - **Fungsi Hashing `public.faunova_calculate_block_hash`**: Menghitung SHA-256 (64 hex characters) via ekstensi `pgcrypto`.
  - **Trigger Imutabilitas Rantai `public.prevent_capture_chain_tamper`**: Menolak secara keras setiap upaya UPDATE pada kolom-kolom rantai kanonis di tabel `captures` (`seq`, `previous_hash`, `block_hash`, `photo_sha256`, koordinat, heading, `received_at`, `user_id`).
  - **RPC Atomik `public.save_capture_with_chain`**:
    - Serialisasi transaksi dengan advisory lock per user: `pg_advisory_xact_lock(hashtextextended(v_user_id::TEXT, 0))`.
    - Validasi keras: kepemilikan scan (`user_id = auth.uid()`), hanya menerima hasil satwa terverifikasi (`is_animal = true`), serta mencegah duplikasi simpan (`capture_status = 'saved'`).
    - Penentuan sambungan rantai: Blok Genesis (`seq = 1`) memakai `previous_hash = SHA-256(user_id)`, sedangkan blok berikutnya (`seq > 1`) menyambung ke `block_hash` blok sebelumnya.
    - Penyisipan atomik ke tabel `public.captures` dan pembaruan status `scans`.
  - **Fungsi Verifikasi Rantai Database (`verify_chain` & `verify_block`)**:
    - `verify_chain(p_user_id)`: Memeriksa seluruh rantai user dari blok 1 sampai N, mendeteksi baris atau kolom yang dimanipulasi, dan mengembalikan nomor blok yang cacat (`broken_seq`).
    - `verify_block(p_capture_id)`: Verifikasi cepat integritas satu blok terhadap blok pendahulunya.
- **Model & Layanan Klien Flutter (`CaptureService`, `CaptureModel`, `ChainVerificationResult`)**:
  - Diterapkan di `lib/features/camera/models/capture_model.dart`, `lib/features/camera/models/chain_verification_result.dart`, dan `lib/core/services/capture_service.dart`.
  - Mendukung eksekusi RPC online via Supabase serta generator rantai deterministik untuk mode demo/offline.
  - Format pembantu tampilan ramah pengguna: `shortBlockHash` dan `shortPreviousHash`.
- **Integrasi Tombol "Simpan ke Koleksi" di `ScanResultPage`**:
  - Mengubah `ScanResultPage` menjadi stateful untuk melacak status proses penyimpanan (`_isSaving`) dan hasil blok (`_savedCapture`).
  - Tampilan tombol responsif: animasi loading saat menghubungkan ke rantai kanonis, dan tombol terverifikasi bertuliskan `Tersimpan di Koleksi (Blok #X)` setelah sukses.
  - Dialog modal konfirmasi elegan dengan rincian: Nomor Blok, Previous Hash, Block Hash SHA-256, dan status "Sah & Tamper-Evident".
  - Pada scan bukan satwa (`is_animal = false`), tombol simpan dikunci secara permanen.
- **Verifikasi & Rangkaian Tes**:
  - `flutter analyze`: 0 issues / bersih tanpa warning.
  - `flutter test`: 32 dari 32 tes unit & widget lulus 100%, termasuk pengujian serialisasi kanonis, determinisme hash genesis, pengujian tamper detection (memanipulasi 1 kolom koordinat membatalkan validitas rantai), dan pengujian UI tombol simpan serta dialog konfirmasi.

### 2. Belum Teruji / Membutuhkan Konfigurasi Database
- **Eksekusi SQL Migrasi 003 di Supabase Dashboard**: Berkas `supabase/migrations/003_hash_chain_and_save_capture.sql` telah disiapkan dan perlu disalin (copy-paste) ke SQL Editor Supabase Dashboard lalu dijalankan (klik **Run**).

### 3. Langkah Berikutnya (Sesi S8)
- **Sesi S8 (Koleksi Satwa, Peta, dan Verifikasi Rantai)**:
  - Antarmuka Grid Koleksi Satwa dan Halaman Detail Tangkapan.
  - Peta OpenStreetMap dengan penanda lokasi tangkapan satwa.
  - Tombol aksi **"Verifikasi Rantai"** di profil/koleksi dengan indikator visual integritas blockchain kanonis.



