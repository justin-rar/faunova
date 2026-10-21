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
- Melanjutkan ke Sesi S8 (Koleksi Satwa Grid, Detail, Peta OpenStreetMap, dan Verifikasi Rantai).

---

## Sesi S8 — Selesai ✅

### 1. Selesai Dikerjakan
- **Koleksi Grid (`CollectionGridView`)**:
  - Diterapkan di `lib/features/profile/presentation/widgets/collection_grid_view.dart`.
  - Tampilan grid 2 kolom dengan kartu satwa elegan: thumbnail foto, badge nomor blok `#seq` berlatar emas, nama spesies, taksonomi latin miring (*scientific name*), tanggal observasi WIB, dan indikator rantai terenkripsi SHA-256.
  - Penanganan state kosong (*empty state*) yang informatif dan ramah ketika pengguna belum menyimpan tangkapan satwa.
  - Navigasi mulus ke `CaptureDetailPage` saat kartu satwa diketuk.
- **Halaman Detail Tangkapan Satwa (`CaptureDetailPage`)**:
  - Diterapkan di `lib/features/profile/presentation/capture_detail_page.dart`.
  - Hero header foto satwa dengan badge nomor urut blok koleksi `#seq` dan status sah kanonis.
  - Kartu taksonomi satwa (nama lokal, nama latin/genus, status konservasi, dan catatan lapangan).
  - Panel Audit Hash-Chain Kanonis SHA-256 (Plan 5.2):
    - Block Hash (#seq) lengkap 64 karakter heksadesimal dengan tombol "Salin".
    - Previous Hash (Genesis atau Blok sebelumnya) lengkap 64 karakter dengan tombol "Salin".
    - Photo SHA-256 byte citra asli lengkap dengan tombol "Salin".
  - Tombol interaktif **"Uji Integritas Blok Ini (`verify_block`)"**: memicu fungsi audit RPC per blok terhadap blok pendahulunya dengan status audit visual real-time.
  - Panel Metadata Sensor & Lapangan: Koordinat GPS 6 desimal, arah bidikan kompas taktis (derajat + 8 mata angin Indonesia), dan waktu pencatatan server (WIB).
  - Tombol aksi **"Buka Lokasi di Google Maps"** menggunakan package `url_launcher` dengan parameter koordinat presisi.
- **Peta Persebaran Koleksi OpenStreetMap (`CollectionMapView`)**:
  - Diterapkan di `lib/features/profile/presentation/widgets/collection_map_view.dart`.
  - Menggunakan `flutter_map: ^8.3.2` dan `latlong2: ^0.10.1` berbasis tile OpenStreetMap resmi tanpa ketergantungan API key berbayar.
  - Menampilkan penanda/pin satwa dinamis pada setiap koordinat tangkapan dengan badge nomor blok `#seq`.
  - Tombol kontrol navigasi peta taktis: perbesar (zoom in), perkecil (zoom out), dan tombol pusatkan kembali ke koordinat tengah koleksi.
  - Interaksi pin: mengetuk pin memunculkan kartu ringkas mengambang (*floating preview card*) di bagian bawah peta berisi foto mini satwa, taksonomi, koordinat, tombol pintasan Google Maps, dan tombol langsung ke halaman detail blok.
  - Penanganan state kosong jika tangkapan belum memiliki metadata GPS.
- **Integrasi Sub-Tab Profil & Verifikasi Rantai Penuh (`ProfilePage`)**:
  - Diterapkan di `lib/features/profile/presentation/profile_page.dart`.
  - Penghitung dinamis total koleksi di hero profil (`Koleksi: N`).
  - Sub-tab 2 "Koleksi & Peta" dilengkapi pengalih mode segmented: `[Grid Koleksi (N)]` dan `[Peta (M)]`.
  - Banner audit integritas rantai dengan tombol **"Verifikasi Rantai (`verify_chain`)"**.
  - Dialog laporan audit komprehensif:
    - Jika rantai utuh: Tampilan perisai hijau, status `VALID (100% Cocok)`, jumlah total blok yang diverifikasi, dan penjelasan teknis rekalkulasi serialisasi kanonis database.
    - Jika rantai terputus: Tampilan perisai merah peringatan, nomor urutan blok pertama yang terputus (`brokenSeq`), serta rincian pesan deteksi manipulasi data.
- **Verifikasi & Rangkaian Pengujian**:
  - `flutter analyze`: 0 issues / bersih tanpa warning.
  - `flutter test`: 38 dari 38 tes unit & widget lulus 100%, memvalidasi pengurutan seq koleksi, RPC `verifyUserChain`, widget `CollectionGridView`, `CaptureDetailPage`, `CollectionMapView`, serta interaksi subtab dan dialog verifikasi rantai di `ProfilePage`.

### 2. Belum Teruji / Membutuhkan Perangkat Fisik
- **Aplikasi Google Maps Eksternal**: Memerlukan pengetukan tombol "Buka Lokasi di Google Maps" pada HP fisik dengan Google Maps terpasang.
- **Tile Cache OSM Luring**: Peta OpenStreetMap memerlukan koneksi internet untuk mengunduh tile peta resolusi tinggi saat pertama kali digeser.

### 3. Langkah Berikutnya (Sesi S9)
- Sesi S9 (`create_post` & Feed Untuk Kamu).

---

## Sesi S9 — Selesai ✅

### 1. Selesai Dikerjakan
- **Fungsi Postgres & Migrasi `004_create_post_and_feed.sql` (Plan 5.7, 5.9, 18)**:
  - `public.faunova_snap_to_grid(lat, lng)`: Fungsi deterministik matematis untuk mengaburkan koordinat publik ke pusat sel grid berukuran 0.01° (~1,1 km): `(floor(coord / 0.01) * 0.01) + 0.005`.
  - RPC `public.create_post(p_capture_id, p_caption, p_location_visibility, p_area_label)`:
    - Memverifikasi kepemilikan tangkapan (`user_id = auth.uid()`).
    - Koordinat asli **tidak pernah disalin** ke tabel publik.
    - Jika `location_visibility = 'coarse'`: `display_latitude` dan `display_longitude` dihitung via `faunova_snap_to_grid` dari koordinat asli tangkapan.
    - Jika `location_visibility = 'hidden'`: `display_latitude`, `display_longitude`, dan `area_label` dipaksa bernilai `NULL`.
  - RPC `public.get_for_you_feed(p_limit, p_cursor)`: Feed linimasa komunitas dengan pagination keyset cursor berbasis `created_at` dan join profil publik & metadata blok kanonis.
  - RPC `public.toggle_post_like(p_post_id)`: Operasi atomik dan idempoten untuk menyukai/batal menyukai postingan.
- **Model Postingan Komunitas (`PostModel`)**:
  - Diterapkan di `lib/features/feed/models/post_model.dart`.
  - Mencegah kebocoran privasi dengan hanya mengekspos `displayLatitude`, `displayLongitude`, `locationVisibility`, dan `areaLabel`.
  - Properti pembantu: `hasLocation`, `shortBlockHash`, format waktu human-readable `timeAgo` (WIB), dan copyWith helper.
- **Layanan Postingan Komunitas (`PostService`)**:
  - Diterapkan di `lib/core/services/post_service.dart`.
  - Metode `createPost`, `fetchForYouFeed`, `togglePostLike`, dan fungsi grid snapping lokal deterministik `snapToGridLocally`.
  - Dukungan fallback cache offline / demo in-memory lengkap dengan 3 postingan komunitas realistis (*Jalak Bali*, *Kucing Kuwuk*, *Cenderawasih Kuning-Kecil*).
- **Komponen Kartu Postingan Komunitas (`PostCard`)**:
  - Diterapkan di `lib/features/feed/presentation/widgets/post_card.dart`.
  - Header author: avatar inisial/foto, nama lengkap, username, centang biru terverifikasi (`isAuthorVerified`), dan waktu unggah.
  - Badge nomor urut blok rantai `#seq` di pojok kanan atas kartu.
  - Area visual foto satwa dengan short hash rantai di pojok foto.
  - Pill lokasi snapped transparan: hanya tampil jika visibilitas lokasi disetel `coarse` (menampilkan nama area dan tombol "Peta Area" menuju Google Maps koordinat grid 0.01°).
  - Taksonomi satwa lengkap: nama spesies, nama latin ilmiah, status konservasi IUCN, dan catatan lapangan/caption.
  - Action bar elegan: tombol Suka dengan animasi toggle hati merah dan penghitung like dinamis, badge validasi blok rantai SHA-256, dan tombol bagikan.
- **Modal Lembar Publikasi (`CreatePostSheet`)**:
  - Diterapkan di `lib/features/feed/presentation/widgets/create_post_sheet.dart`.
  - Disediakan dari tombol aksi di `CaptureDetailPage`: *"Bagikan ke Linimasa (create_post)"*.
  - Menampilkan pratinjau mini satwa dan nomor urut blok rantai kanonis.
  - Input catatan lapangan / caption observasi (maks 500 karakter).
  - Pemilih privasi lokasi:
    - **Area Kasar (Grid 0.01°)**: Koordinat diburamkan ke sel grid ~1.1 km untuk melindungi lokasi persis satwa liar (misal satwa langka terancam punah).
    - **Sembunyikan Penuh**: Menghilangkan seluruh metadata lokasi dan label area dari linimasa publik.
- **Pembaruan Halaman Linimasa (`FeedPage`)**:
  - Diterapkan di `lib/features/feed/presentation/feed_page.dart`.
  - Terintegrasi penuh dengan `PostService.instance.fetchForYouFeed()`.
  - Mendukung `RefreshIndicator` untuk memuat ulang linimasa dengan gestur tarik ke bawah (pull-to-refresh).
  - Penanganan state lengkap: loading skeleton/spinner, linimasa kosong yang ramah, dan penanganan galat.
- **Rangkaian Verifikasi & Pengujian**:
  - `flutter analyze`: 0 issues / bersih tanpa warning.
  - `flutter test`: 44 dari 44 tes unit & widget lulus 100%, memvalidasi perhitungan matematika grid snapping 0.01°, perlindungan koordinat tersembunyi, idempotensi toggle like, rendering `PostCard`, form `CreatePostSheet`, serta interaksi linimasa `FeedPage`.

### 2. Belum Teruji / Membutuhkan Konfigurasi Database Manual
- **Eksekusi SQL Migrasi 004 di Supabase Dashboard**: Berkas `supabase/migrations/004_create_post_and_feed.sql` telah disiapkan dan **wajib dijalankan (copy-paste lalu klik Run)** di SQL Editor Supabase Dashboard pengguna untuk membuat fungsi `faunova_snap_to_grid`, RPC `create_post`, `get_for_you_feed`, dan `toggle_post_like`.

### 3. Langkah Berikutnya (Sesi S10)
- Sesi S10 (Follow, Tab Mengikuti, Like & Profil Publik).

---

## Sesi S10 — Selesai ✅

### 1. Selesai Dikerjakan
- **Fungsi Postgres & Migrasi `005_follow_and_following_feed.sql` (Plan 5.7, 5.9, 18)**:
  - RPC `public.toggle_follow_user(p_target_user_id UUID)`:
    - Operasi atomik & idempoten untuk mengikuti/berhenti mengikuti pengguna lain.
    - Aturan keras: menolak `follower_id = followed_id` (tidak dapat mengikuti diri sendiri).
    - Menghitung dan mengembalikan agregat terbaru `followers_count` dan `following_count`.
  - RPC `public.get_following_feed(p_limit INT, p_cursor TIMESTAMPTZ)`:
    - Mengambil feed linimasa akun yang diikuti oleh pengguna terautentikasi (`WHERE p.user_id IN (SELECT followed_id FROM follows WHERE follower_id = auth.uid())`).
    - Keamanan koordinat publik terjamin dengan grid-snapping 0.01° (`display_latitude` & `display_longitude`).
    - Mendukung pagination cursor keyset.
  - RPC `public.get_public_profile(p_target_user_id UUID)`:
    - Mengembalikan data profil publik yang disetujui (username, nama, avatar, bio, centang biru, streak, skor kuis, tanggal dibuat) serta agregat (`captures_count`, `posts_count`, `followers_count`, `following_count`, `is_followed_by_me`, `is_my_profile`).
    - Aman dari kebocoran kolom sensitif / privat.
  - RPC `public.get_user_public_posts(p_target_user_id UUID, p_limit INT)`:
    - Mengembalikan postingan observasi publik milik author tertentu.
  - Penyelarasan skema pada RPC `get_for_you_feed` (menggunakan `display_name` dan `avatar_path`).
- **Model Profil Publik (`PublicProfileModel`)**:
  - Diterapkan di `lib/features/profile/models/public_profile_model.dart`.
  - Serialisasi, deserialisasi, dan `copyWith` helper untuk metadata profil publik dan agregat sosial.
- **Layanan Sosial Komunitas (`SocialService`)**:
  - Diterapkan di `lib/core/services/social_service.dart`.
  - Mengelola `toggleFollow`, `fetchFollowingFeed`, `getPublicProfile`, `fetchUserPublicPosts`, dan pengecekan cepat `isFollowing`.
  - Dukungan fallback luring & mode demo in-memory lengkap dengan profil realistis (*Budi Satria Wibowo*, *Siti Rahmawati*, *Dewi Lestari*).
- **Halaman Profil Publik (`PublicProfilePage`)**:
  - Diterapkan di `lib/features/profile/presentation/public_profile_page.dart`.
  - AppBar taktis dengan username `@username` dan tombol kembali.
  - Hero profil elegan: avatar inisial, nama lengkap, lencana verifikasi Centang Biru, bio lapangan, badge streak 🔥, dan skor kuis 🏆.
  - Kartu metrik sosial 3 kolom: Observasi, Pengikut, dan Mengikuti.
  - Tombol aksi pintar:
    - Jika profil sendiri: menampilkan informasi "Ini adalah profil akun Anda".
    - Jika belum diikuti: tombol emas `#C8A96B` ("+ Ikuti Penjelajah Ini").
    - Jika sudah diikuti: tombol outlined sage tua ("Mengikuti" dengan centang).
    - Optimistic UI update dengan notifikasi SnackBar informatif dan rollback aman.
  - Bagian linimasa observasi publik author dengan daftar `PostCard` atau kartu kosong ramah jika belum ada tangkapan yang dibagikan.
  - Dukungan gesture *Pull-to-Refresh*.
- **Pembaruan Linimasa Dua Tab (`FeedPage`)**:
  - Diterapkan di `lib/features/feed/presentation/feed_page.dart`.
  - Tab "Mengikuti" terintegrasi penuh dengan `SocialService.instance.fetchFollowingFeed()`.
  - Sinkronisasi status like idempoten di kedua tab ("Untuk Kamu" dan "Mengikuti").
  - Penanganan state kosong di tab Mengikuti ketika pengguna belum mengikuti siapa pun, dilengkapi tombol pintasan untuk menjelajahi tab "Untuk Kamu".
- **Integrasi Interaktif Kartu (`PostCard`)**:
  - Header author (avatar, nama, username) kini dapat diketuk (`InkWell`) untuk langsung membuka `PublicProfilePage` author tersebut.
- **Rangkaian Verifikasi & Pengujian**:
  - `flutter analyze`: **0 issues** / bersih tanpa error lint.
  - `flutter test`: **49 dari 49 tes unit & widget lulus 100%**, memvalidasi idempotensi toggle follow, isolasi tab feed mengikuti, integritas data profil publik, interaksi tombol follow `PublicProfilePage`, dan navigasi profil di `FeedPage`.

### 2. Belum Teruji / Membutuhkan Konfigurasi Database Manual
- **Eksekusi SQL Migrasi 005 di Supabase Dashboard**: Berkas `supabase/migrations/005_follow_and_following_feed.sql` telah disiapkan dan **wajib dijalankan (copy-paste lalu klik Run)** di SQL Editor Supabase Dashboard pengguna untuk membuat RPC `toggle_follow_user`, `get_following_feed`, `get_public_profile`, `get_user_public_posts`, dan penyelarasan `get_for_you_feed`.

### 3. Langkah Berikutnya (Sesi S11)
- Sesi S11 (Profil Sendiri, Edit Profil, Pencarian Akun & Spesies) — Telah dikerjakan di bawah.

---

## Sesi S11 — Selesai ✅

### 1. Selesai Dikerjakan
- **Fungsi Postgres & Migrasi `006_profile_edit_and_search.sql` (Plan 5.2, 5.4, 5.7, 126)**:
  - Expression indexes untuk pencarian cepat:
    - `idx_public_profiles_username_lower`: `lower(username)`
    - `idx_public_profiles_display_name_lower`: `lower(display_name)`
    - `idx_captures_species_name_lower`: `lower(species_name)`
  - RPC `public.update_my_profile(p_display_name TEXT, p_bio TEXT, p_avatar_path TEXT)`:
    - Memvalidasi batas panjang karakter secara ketat di sisi server (nama tampilan 2..60 karakter, bio maksimal 300 karakter).
    - Memperbarui `display_name`, `bio`, `avatar_path`, dan `updated_at` milik `auth.uid()`.
    - Mengembalikan rekaman profil terbaru tanpa mengekspos kolom privat.
  - RPC `public.search_accounts(p_keyword TEXT, p_limit INT)`:
    - Pencarian akun pengguna berdasarkan username dan display name.
    - **Prioritas Centang Biru (Plan 5.4 & 126)**: Akun terverifikasi (`is_verified == true`) diprioritaskan di urutan paling atas (`ORDER BY is_verified DESC, created_at DESC`).
    - Aman dari kebocoran koordinat atau kolom internal.
  - RPC `public.search_species(p_keyword TEXT, p_class TEXT, p_limit INT)`:
    - Mengagregasi katalog taksonomi satwa dari observasi komunitas.
    - Filter berdasarkan kata kunci dan kelas taksonomi (Mamalia, Aves, Reptilia, Amfibi, dsb).
    - **Aturan Keras**: Tidak mengekspos koordinat mentah satwa liar ke publik.
- **Model Taksonomi Spesies (`SpeciesCatalogModel`)**:
  - Diterapkan di `lib/features/search/models/species_catalog_model.dart`.
  - Struktur data taksonomi satwa: nama umum, nama ilmiah/latin, kelas, status konservasi IUCN, dan jumlah total observasi.
- **Layanan Profil Mandiri (`ProfileService`)**:
  - Diterapkan di `lib/core/services/profile_service.dart`.
  - Metode `getMyProfile` dan `updateMyProfile` dengan validasi input ramah pengguna.
  - Dukungan fallback mode demo luring in-memory yang tersinkronisasi.
- **Layanan Pencarian (`SearchService`)**:
  - Diterapkan di `lib/core/services/search_service.dart`.
  - Metode `searchAccounts` dan `searchSpecies` terintegrasi dengan RPC Supabase.
  - Dilengkapi dataset katalog fauna Indonesia realistis (Komodo, Jalak Bali, Orangutan Sumatera, Harimau Sumatera, Cenderawasih, Penyu Hijau, Katak Pohon Jawa) untuk fallback luring instan.
- **Formulir Edit Profil Modal (`EditProfileSheet`)**:
  - Diterapkan di `lib/features/profile/presentation/widgets/edit_profile_sheet.dart`.
  - Bottom sheet interaktif berpalet Faunova (latar gading, kartu sage muda, tombol emas).
  - Validasi panjang teks real-time dengan counter karakter (Nama: 2–60 karakter, Bio: maks 300 karakter).
  - Avatar pratinjau dinamis dengan badge status verifikasi.
- **Pembaruan Halaman Profil Sendiri (`ProfilePage`)**:
  - Terhubung langsung dengan `ProfileService.instance.getMyProfile()`.
  - Nama tampilan, bio, dan inisial avatar tampil dinamis sesuai profil akun pengguna.
  - Tombol "Edit Profil" tersemat rapi pada hero profil dan menu dropdown pojok kanan atas.
- **Pembaruan Halaman Pencarian (`SearchPage`)**:
  - Diterapkan di `lib/features/search/presentation/search_page.dart`.
  - Dua tab navigasi taktis:
    - **Akun Pengguna**: Pencarian akun dengan input debounced, kartu akun menampilkan badge Centang Biru prioritas, gelar biologis, dan dapat diketuk untuk membuka `PublicProfilePage`.
    - **Katalog Spesies**: Filter chip horizontal (Semua, Mamalia, Aves, Reptilia, Amfibi), daftar spesies satwa lengkap dengan nama ilmiah, kelas taksonomi, dan status konservasi IUCN.
  - Penanganan 4 state (`AppStateView`): Memuat, Kosong, Galat, Luring.
- **Rangkaian Verifikasi & Pengujian**:
  - `flutter analyze`: **0 issues** / bersih tanpa error lint.
  - `flutter test`: **54 dari 54 tes unit & widget lulus 100%**, mencakup validasi batas karakter form edit profil, prioritas Centang Biru pada pencarian akun, filter taksonomi spesies fauna, interaksi `EditProfileSheet`, dan interaksi tab `SearchPage`.

### 2. Belum Teruji / Membutuhkan Konfigurasi Database Manual
- **Eksekusi SQL Migrasi 006 di Supabase Dashboard**: Berkas `supabase/migrations/006_profile_edit_and_search.sql` telah disiapkan dan **wajib dijalankan (copy-paste lalu klik Run)** di SQL Editor Supabase Dashboard pengguna untuk membuat expression indexes, RPC `update_my_profile`, `search_accounts`, dan `search_species`.

### 3. Langkah Berikutnya (Sesi S12)
- Sesi S12 (Hive Terenkripsi & Konversi Waktu 4 Zona) — Telah dikerjakan di bawah.

---

## Sesi S12 — Selesai ✅

### 1. Selesai Dikerjakan
- **Database Lokal Hive Terenkripsi AES-256 (`EncryptedStorageService`) (Plan 5.2, 78, 563)**:
  - Diterapkan di `lib/core/services/encrypted_storage_service.dart`.
  - Mengamankan database lokal menggunakan `HiveAesCipher` dengan kunci 256-bit (32 bytes) yang disimpan di `FlutterSecureStorage` (key: `faunova_hive_aes_256_key`).
  - Mengelola 3 box terenkripsi:
    - `faunova_collections_cache_box`: Menyimpan cache koleksi satwa pengguna (`saveUserCaptures` / `getUserCaptures`) sehingga dapat dibaca secara luring (offline) tanpa koneksi internet.
    - `faunova_currency_rates_box`: Menyimpan data kurs mata uang, timestamp pembaruan, dan mata uang dasar.
    - `faunova_app_settings_box`: Menyimpan skor kuis tertinggi lokal (`best_quiz_score`) dan preferensi luring.
  - **Pembersihan Cache Logout (Plan 563)**: Metode `clearPrivateCacheOnSignOut()` terintegrasi di `AuthService.signOut()`, menghapus seluruh data privat koleksi satwa saat pengguna keluar akun.
  - Mekanisme *Graceful Recovery*: Jika kunci enkripsi atau berkas box rusak, sistem otomatis memulihkan dan membuat kunci baru tanpa membuat aplikasi crash.
- **Konversi 4 Zona Waktu Presisi (`TimeZoneService`) (Plan 40, 136, 318)**:
  - Diterapkan di `lib/core/services/timezone_service.dart`.
  - Mengonversi waktu `received_at` UTC dari server secara deterministik ke dalam 4 zona:
    - **WIB (Waktu Indonesia Barat)**: UTC+7 (`Asia/Jakarta`, Sumatra, Jawa, Kalbar, Kalteng).
    - **WITA (Waktu Indonesia Tengah)**: UTC+8 (`Asia/Makassar`, Bali, NTB, NTT, Kalsel, Kaltim, Sulawesi).
    - **WIT (Waktu Indonesia Timur)**: UTC+9 (`Asia/Jayapura`, Maluku, Papua).
    - **London (`Europe/London`)**: Dilengkapi kalkulasi otomatis British Summer Time (**BST**, UTC+1) vs Greenwich Mean Time (**GMT**, UTC+0) berdasarkan kalender Minggu terakhir Maret dan Oktober.
  - Penentuan tanggal kalender resmi server WIB (`getCurrentDateWib`) untuk perhitungan streak dan reset harian tanpa bergantung pada jam lokal perangkat (Plan 136).
- **Layanan Kurs Mata Uang (`CurrencyService`) (Plan 78, 127, 398, 418, 562)**:
  - Diterapkan di `lib/core/services/currency_service.dart`.
  - Menangani 3 mata uang utama: **IDR**, **USD**, dan **JPY**.
  - Mengambil kurs dari API publik dengan timeout 5 detik dan menyimpannya langsung ke Hive terenkripsi.
  - Fallback luring yang tangguh: Jika jaringan putus atau API gagal, kurs otomatis dibaca dari cache Hive, dan harga IDR tetap beroperasi normal (Plan 398).
  - Format harga taktis: IDR Rp15.000 / 30 hari (Resmi Midtrans), USD (Estimasi ~$0.93 USD), JPY (Estimasi ~¥143 JPY).
- **Komponen Tampilan Baru**:
  - `MultiTimeZoneCard`: Menampilkan jam hidup real-time 4 zona (WIB, WITA, WIT, London BST/GMT) di `ProfilePage` serta waktu penerimaan server spesifik di `CaptureDetailPage`.
  - `CurrencyConverterCard`: Kartu interaktif estimasi kurs langganan Centang Biru dalam 3 mata uang dengan indikator cache Hive terenkripsi dan tombol "Perbarui Kurs".
- **Integrasi Layanan & Halaman**:
  - `CaptureService`: `fetchUserCaptures` otomatis menyimpan hasil ke Hive terenkripsi saat online dan membaca dari Hive saat luring/koneksi server bermasalah.
  - `AuthService`: Terintegrasi dengan `clearPrivateCacheOnSignOut()`.
  - `CaptureDetailPage`: Dilengkapi `MultiTimeZoneCard` untuk audit waktu server 4 zona.
  - `ProfilePage`: Dilengkapi `CurrencyConverterCard` dan `MultiTimeZoneCard`.
- **Rangkaian Verifikasi & Pengujian**:
  - `flutter analyze`: **0 issues** / bersih tanpa error lint.
  - `flutter test`: **59 dari 59 tes unit & widget lulus 100%**, mencakup operasi enkripsi Hive, isolasi logout, akurasi konversi waktu 4 zona (WIB, WITA, WIT, London BST/GMT), konversi mata uang, serta rendering widget `MultiTimeZoneCard` dan `CurrencyConverterCard`.

### 2. Belum Teruji / Membutuhkan Konfigurasi Database Manual
- **Tidak ada konfigurasi database manual untuk Sesi S12** ✅ (Seluruh fitur berjalan di sisi klien menggunakan Hive AES-256 lokal dan API publik gratis).

### 3. Langkah Berikutnya (Sesi S13)
- Sesi S13 (Fitur Kuis Biologi Satwa & Skor Server) — Telah dikerjakan di bawah.

---

## Sesi S13 — Selesai ✅

### 1. Selesai Dikerjakan
- **Skema & Database Migrasi 007 (`supabase/migrations/007_quiz_system.sql`) (Plan 46, 180-186, 389, AGENTS.md)**:
  - Diterapkan di `supabase/migrations/007_quiz_system.sql`.
  - Tabel `quiz_questions`: `id`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option` (CHAR(1) A-D), `explanation`, `difficulty`, `is_active`.
  - Keamanan RLS Aktif: Aturan Keras 5 ditaati secara ketat. Publik dan klien tidak memiliki izin membaca kolom `correct_option` secara langsung.
  - Tabel `quiz_sessions`: `id`, `user_id`, `question_ids` (UUID[]), `started_at`, `finished_at`, `score`, `lives_remaining`, `combo_max`, `status` ('in_progress', 'completed', 'abandoned').
  - Tabel `quiz_answers`: Menyimpan catatan audit jawaban per sesi (`session_id`, `question_id`, `selected_option`, `is_correct`, `elapsed_ms`).
  - **RPC `start_quiz_session()` (`SECURITY DEFINER`)**: Mengambil secara acak 10 soal aktif, membuat sesi kuis baru, dan mengembalikan daftar soal dalam format JSON **tanpa** field `correct_option` (kunci jawaban tidak pernah dikirim ke klien).
  - **RPC `finish_quiz_session(p_session_id, p_answers)` (`SECURITY DEFINER`)**:
    - Mengunci baris sesi dengan `FOR UPDATE` untuk mencegah race condition atau manipulasi jawaban berulang.
    - Validasi identitas pengguna (`user_id = auth.uid()`) dan validasi durasi waktu.
    - Menghitung skor secara deterministik di server (Aturan Keras 2): Base 100 poin per jawaban benar + Combo multiplier streak bertingkat + Bonus kecepatan waktu menjawab (`elapsed_ms`).
    - Mengurangi nyawa pengguna (3 nyawa awal; berkurang jika jawaban salah atau waktu habis).
    - Memperbarui rekor `profiles.best_quiz_score` jika skor sesi baru melampaui skor tertinggi sebelumnya.
    - Mengembalikan ulasan lengkap per soal (jawaban pengguna, status benar/salah, kunci jawaban resmi, dan penjelasan ilmiah).
  - **Bank Soal Fauna Nusantara**: Disediakan 12 soal biologi satwa autentik Indonesia (Komodo, Jalak Bali, Orangutan Sumatera, Harimau Sumatera, Anoa, Burung Maleo, dsb.) lengkap dengan opsi dan pembahasan ilmiah.
- **Model Data Kuis (`lib/features/game/models/`)**:
  - `QuizQuestionModel`: Model soal klien (`id`, `questionText`, `optionA`, `optionB`, `optionC`, `optionD`, `difficulty`). Bebas dari field kunci jawaban.
  - `QuizSessionModel` & `QuizAnswerInput`: DTO pengiriman jawaban kuis ke server.
  - `QuizResultModel` & `QuizAnswerSummaryItem`: Model respons hasil evaluasi kuis dari server beserta rekor skor baru.
- **Layanan Kuis (`QuizService`) (`lib/core/services/quiz_service.dart`)**:
  - Terintegrasi dengan RPC Supabase `start_quiz_session` dan `finish_quiz_session`.
  - Dilengkapi engine evaluasi fallback offline/mode demo deterministik dengan aturan penilaian yang identik dengan server.
  - Sinkronisasi skor kuis tertinggi ke Hive terenkripsi (`EncryptedStorageService.instance.saveBestQuizScore`).
- **Layar Arena Kuis Interaktif (`QuizArenaPage`) (`lib/features/game/presentation/quiz_arena_page.dart`)**:
  - Timer hitung mundur 15 detik per soal dengan animasi bilah progress halus (beralih ke merah status saat <4 detik).
  - Indikator 3 Nyawa (`❤️ ❤️ ❤️`) yang berkurang saat jawaban salah atau waktu habis.
  - Indikator Combo Streak dinamis (`🔥 Combo x2`, `x3`).
  - 4 kartu opsi jawaban (A, B, C, D) interaktif berpalet Faunova.
  - Layar Ringkasan Hasil: Skor akhir terverifikasi server, lencana rekor baru, detail statistik (jawaban benar, combo tertinggi, sisa nyawa), dan ulasan jawaban lengkap dengan pembahasan biologi.
- **Pembaruan Halaman Game (`GamePage`)**:
  - Tombol "Mulai Sesi Kuis (10 Soal)" terhubung langsung dengan `QuizService.instance.startQuizSession()` dan navigasi ke `QuizArenaPage`.
  - Tampilan skor tertinggi akun (`best_quiz_score`) diperbarui secara dinamis.
  - Memperbaiki RenderFlex overflow pada judul kartu dengan `Expanded(child: Text(..., overflow: TextOverflow.ellipsis))`.
- **Rangkaian Verifikasi & Pengujian**:
  - `flutter analyze`: **0 issues** / bersih tanpa error lint.
  - `flutter test`: **63 dari 63 tes unit & widget lulus 100%**, mencakup verifikasi Aturan Keras 5 (model tidak memiliki kunci jawaban), kalkulasi skor server, timer 15 detik, sistem 3 nyawa, dan navigasi `QuizArenaPage`.

### 2. Belum Teruji / Membutuhkan Konfigurasi Database Manual
- **Eksekusi SQL Migrasi 007 di Supabase Dashboard**: Berkas `supabase/migrations/007_quiz_system.sql` telah disiapkan dan **wajib dijalankan (copy-paste lalu klik Run)** di SQL Editor Supabase Dashboard pengguna untuk membuat tabel kuis, RPC `start_quiz_session` & `finish_quiz_session`, dan bank soal.

### 3. Langkah Berikutnya (Sesi S14)
- Sesi S14 (Daily Streak Check-in & Tantangan Hari Ini) — Telah dikerjakan di bawah.

---

## Sesi S14 — Selesai ✅

### 1. Selesai Dikerjakan
- **Skema & Database Migrasi 008 (`supabase/migrations/008_streak_and_daily_challenge.sql`) (Plan 5.8, 168-170, 197-200, 392, AGENTS.md)**:
  - Diterapkan di `supabase/migrations/008_streak_and_daily_challenge.sql`.
  - **Fungsi Tanggal Resmi WIB (`public.wib_today()`)**: Mengembalikan tanggal kalender WIB (`Asia/Jakarta`) dari waktu server PostgreSQL secara deterministik (`(now() AT TIME ZONE 'Asia/Jakarta')::DATE`) agar reset hari tidak bergantung pada jam perangkat lokal (Plan 136).
  - **Tabel Log Tantangan Harian (`daily_challenge_log`)**:
    - Kolom: `id`, `user_id` (FK `profiles`), `challenge_date` (DATE), `question_id` (FK `quiz_questions`), `selected_option`, `is_correct`, `answered_at`.
    - Constraint Unik: `CONSTRAINT uq_daily_challenge_user_date UNIQUE (user_id, challenge_date)` untuk mencegah klaim ganda per hari.
    - Keamanan RLS: Pengguna hanya dapat membaca riwayat tantangan milik sendiri (`auth.uid() = user_id`).
  - **RPC `claim_daily_streak()` (`SECURITY DEFINER`) (Plan 168-170, 543)**:
    - Mengunci baris `profiles` pengguna dengan `FOR UPDATE` untuk mencegah race condition.
    - Pengecekan Idempotensi: Jika `last_streak_claim_date = wib_today()`, server mengembalikan status bahwa streak sudah diklaim hari ini (`already_claimed = true, is_new_claim = false`).
    - Jika klaim dilakukan di hari berikutnya (`last_streak_claim_date = wib_today() - 1`), streak bertambah `+1`.
    - Jika terlewat satu hari atau lebih, streak otomatis di-reset ke `1` (Plan 169).
    - Memperbarui `profiles.streak_count` dan `profiles.last_streak_claim_date` secara atomik di server (Aturan Keras 2).
  - **RPC `get_streak_status()` (`SECURITY DEFINER`)**: Mengambil jumlah streak terkini, tanggal klaim terakhir, dan status apakah sudah check-in hari ini.
  - **RPC `get_daily_challenge()` (`SECURITY DEFINER`) (Plan 198, Aturan Keras 5)**:
    - Memilih 1 soal tantangan harian deterministik seragam untuk seluruh pengguna berdasarkan tanggal WIB (`ORDER BY md5(id::text || v_today::text) LIMIT 1`).
    - Jika pengguna **belum menjawab**: Field `correct_option` dan `explanation` dirahasiakan (dikirim `null`) sesuai Aturan Keras 5.
    - Jika pengguna **sudah menjawab**: Menampilkan jawaban yang dipilih, status kebenaran, kunci jawaban resmi, dan pembahasan ilmiah.
  - **RPC `answer_daily_challenge(p_selected_option INT)` (`SECURITY DEFINER`) (Plan 199)**:
    - Memvalidasi bahwa tantangan hari ini belum pernah dijawab sebelumnya (menolak pengiriman duplikat).
    - Memeriksa kebenaran jawaban langsung ke `quiz_questions` di server.
    - Mencatat hasil ke `daily_challenge_log` dan mengembalikan evaluasi, poin bonus (+50 Poin jika benar), serta pembahasan edukatif.
- **Model Data Klien (`lib/features/game/models/`)**:
  - `StreakStatusModel`: Menampung `streakCount`, `lastClaimDate`, `isClaimedToday`, `wibToday`, dan pesan respons server.
  - `DailyChallengeModel`: Menampung data soal tantangan harian tanpa membocorkan kunci sebelum dijawab.
- **Layanan Streak & Tantangan (`StreakService`) (`lib/core/services/streak_service.dart`)**:
  - Terintegrasi dengan RPC Supabase (`claim_daily_streak`, `get_streak_status`, `get_daily_challenge`, `answer_daily_challenge`).
  - Dilengkapi simulasi fallback offline/demo yang akurat berbasis tanggal WIB dan Hive terenkripsi AES-256.
  - Sinkronisasi otomatis cache streak ke `EncryptedStorageService`.
- **Pembaruan Halaman Game (`GamePage`) (`lib/features/game/presentation/game_page.dart`)**:
  - **Kartu Tracker Streak**:
    - Menampilkan jumlah hari berturut-turut secara dinamis (`$streak Hari Berturut-turut 🔥`).
    - Tombol "Klaim" interaktif dengan status loading; otomatis beralih menjadi badge "Sudah Klaim" dengan ikon centang ketika sudah check-in.
    - Indikator 7 hari (Senin–Minggu) yang dipetakan secara akurat dengan hari aktif WIB (`currentWibWeekday`).
  - **Kartu Tantangan Hari Ini**:
    - Menampilkan tag kategori taksonomi satwa, badge `+50 Poin`, dan teks pertanyaan.
    - Sebelum dijawab: 4 kartu pilihan (A, B, C, D) interaktif langsung dapat diketuk dengan satu sentuhan.
    - Setelah dijawab: Menampilkan banner status (hijau/sage jika benar, merah jika salah), perbandingan opsi yang dipilih vs kunci jawaban, dan kotak pembahasan ilmiah berikon bohlam emas.
    - Catatan jadwal reset: "Tantangan baru tersedia besok pukul 00:00 WIB."
  - Penanganan layout responsif dengan `Expanded` untuk mencegah RenderFlex overflow pada teks jadwal kuis.
- **Rangkaian Verifikasi & Pengujian**:
  - `flutter analyze`: **0 issues** / bersih total tanpa error lint.
  - `flutter test`: **67 dari 67 tes unit & widget lulus 100%** (termasuk 4 tes baru untuk S14 yang memverifikasi penambahan streak, penolakan klaim ganda, kerahasiaan kunci jawaban tantangan, penolakan submission kedua, dan rendering interaktif `GamePage`).

### 2. Belum Teruji / Membutuhkan Konfigurasi Database Manual
- **Eksekusi SQL Migrasi 008 di Supabase Dashboard**: Berkas `supabase/migrations/008_streak_and_daily_challenge.sql` telah disiapkan dan **wajib dijalankan (copy-paste lalu klik Run)** di SQL Editor Supabase Dashboard pengguna untuk membuat fungsi `wib_today()`, tabel `daily_challenge_log`, dan RPC `claim_daily_streak`, `get_streak_status`, `get_daily_challenge`, serta `answer_daily_challenge`.

### 3. Langkah Berikutnya (Sesi S15)
- Sesi S15 (Shake-to-Quiz / Goyang HP) — Telah dikerjakan di bawah.

---

## Sesi S15 — Selesai ✅

### 1. Selesai Dikerjakan
- **Skema & Database Migrasi 009 (`supabase/migrations/009_shake_to_quiz.sql`) (Plan 5.8, 190-196, 440, AGENTS.md)**:
  - Diterapkan di `supabase/migrations/009_shake_to_quiz.sql`.
  - **Tabel `shake_log` (Plan 440)**:
    - Kolom: `id`, `user_id` (FK `profiles`), `date_wib` (DATE), `question_id` (FK `quiz_questions`), `status` ('claimed', 'answered', 'expired'), `selected_option`, `is_correct`, `claimed_at`, `answered_at`, `idempotency_key` (UUID).
    - Constraint Unik: `CONSTRAINT uq_shake_log_user_idempotency UNIQUE (user_id, idempotency_key)` untuk memastikan idempotensi request klaim.
    - Keamanan RLS: Hanya pemilik yang dapat membaca riwayat klaim kuis miliknya (`auth.uid() = user_id`).
  - **RPC `get_shake_quota()` (`SECURITY DEFINER`)**:
    - Menghitung kuota shake yang sudah dipakai pada hari ini (`COUNT(*) WHERE user_id = auth.uid() AND date_wib = wib_today()`).
    - Mengembalikan `used_quota`, `max_quota` (3), dan `remaining_quota` (maks 3/hari WIB).
  - **RPC `claim_shake_quiz(p_idempotency_key UUID)` (`SECURITY DEFINER`) (Plan 192, Aturan Keras 5)**:
    - Validasi kuota harian: Menolak klaim jika kuota sudah mencapai 3/3 per hari WIB.
    - Idempotensi: Jika `idempotency_key` yang sama dikirim ulang, server mengembalikan klaim yang sudah ada tanpa mengurangi kuota lagi.
    - Memilih 1 soal acak aktif dari `quiz_questions`.
    - **Aturan Keras 5 Ditaati Ketat**: Kunci jawaban (`correct_option`) dan pembahasan sama sekali **tidak pernah dikirim ke klien** saat soal diklaim.
  - **RPC `answer_shake_quiz(p_claim_id UUID, p_selected_option INT)` (`SECURITY DEFINER`) (Plan 193)**:
    - Mengunci baris klaim dengan `FOR UPDATE`.
    - Menolak jika klaim tersebut sudah pernah dijawab sebelumnya (`status = 'answered'`).
    - Memeriksa kebenaran jawaban langsung ke `quiz_questions` di server database.
    - Memperbarui status klaim menjadi `'answered'` beserta `selected_option`, `is_correct`, dan `answered_at`.
    - Mengembalikan hasil evaluasi, status kebenaran, kunci jawaban resmi, dan pembahasan edukatif.
- **Sensor Akselerometer & Deteksi Goyang HP (`sensors_plus`) (Plan 191)**:
  - Package `sensors_plus 7.1.1` terpasang rapi dan bersih.
  - Metode `listenToShakeEvents()` di `ShakeService`:
    - Menghitung magnitudo akselerasi secara fisik: `sqrt(x^2 + y^2 + z^2)`.
    - Ambang batas (threshold) guncangan nyata: `22.0 m/s²`.
    - **Debounce**: Mencegah pemicu ganda dengan mengabaikan sinyal selama 3 detik setelah goyangan pertama terdeteksi.
    - **Haptic Feedback**: Memicu getaran taktil halus `HapticFeedback.mediumImpact()` saat goyangan valid terdeteksi.
    - **Isolasi Siklus Hidup**: Listener akselerometer **hanya aktif saat tab Game dibuka** dan otomatis di-cancel (`dispose()`) saat pengguna berpindah tab atau keluar halaman.
- **Model & Layanan Kuis Goyang HP (`lib/core/services/shake_service.dart`)**:
  - Model: `ShakeQuotaModel`, `ShakeQuizClaimModel`, dan `ShakeQuizResultModel`.
  - Terintegrasi penuh dengan RPC Supabase (`get_shake_quota`, `claim_shake_quiz`, `answer_shake_quiz`).
  - Fallback simulasi luring/demo yang deterministik, menjaga fungsionalitas aplikasi dan tes widget tetap berjalan optimal.
- **Lembar Interaktif Soal Kejutan (`ShakeQuizSheet`) (`lib/features/game/presentation/widgets/shake_quiz_sheet.dart`)**:
  - Modal bottom sheet anggun berpalet Faunova (latar gading, kartu sage muda, tombol emas).
  - Menampilkan badge kategori fauna dan sisa kuota harian.
  - 4 kartu pilihan (A, B, C, D) interaktif dengan tombol panah.
  - Layar hasil: Banner status keberhasilan (hijau sage jika benar, merah jika salah), perbandingan pilihan vs kunci jawaban, dan kotak pembahasan ilmiah berikon bohlam emas.
- **Pembaruan Banner GamePage (`lib/features/game/presentation/game_page.dart`)**:
  - Terhubung langsung dengan `ShakeService.instance.getShakeQuota()`.
  - Menampilkan indikator kuota real-time: `Kuota $remaining/3`.
  - Banner dapat diketuk langsung sebagai simulator alternatif pengujian di emulator/desktop yang tidak memiliki sensor fisik akselerometer.
- **Rangkaian Verifikasi & Pengujian**:
  - `flutter analyze`: **0 issues** / bersih tanpa error lint.
  - `flutter test`: **72 dari 72 tes unit & widget lulus 100%** (termasuk 5 tes baru untuk S15 yang memverifikasi kuota awal 3/3, kerahasiaan kunci jawaban saat klaim, penolakan klaim ke-4 saat kuota habis, penolakan submit ganda, dan pembukaan `ShakeQuizSheet`).

### 2. Belum Teruji / Membutuhkan Perangkat Fisik & Konfigurasi Database Manual
- **Eksekusi SQL Migrasi 009 di Supabase Dashboard**: Berkas `supabase/migrations/009_shake_to_quiz.sql` telah disiapkan dan **wajib dijalankan (copy-paste lalu klik Run)** di SQL Editor Supabase Dashboard pengguna untuk membuat tabel `shake_log` dan RPC `get_shake_quota`, `claim_shake_quiz`, serta `answer_shake_quiz`.
- **Sensor Akselerometer di HP Fisik**: Goyangan fisik nyata pada perangkat mobile asli (diuji pada tahapan integrasi akhir S23).

### 3. Langkah Berikutnya (Sesi S16)
- **Sesi S16 (Sistem Badge Gelar & Pop-up Pencapaian)**:
  - Tabel `badges` dan `user_badges` di database.
  - Pengecekan syarat badge (Pemula, Kolektor, Rajin, Si Pintar, Juara Kuis, Sosialita, Rutin Menantang, Si Goyang) di server.
  - Grid badge di Profil (terbuka berwarna, terkunci abu-abu dengan progress bar) dan dialog pop-up lokal saat badge baru terbuka.











