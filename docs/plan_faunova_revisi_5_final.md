# Plan Final: Faunova — Aplikasi Sosial Koleksi Hewan (Revisi 5)

**Tugas Akhir — Pemrograman Aplikasi Mobile (kelompok, 3 orang)**
Status dokumen: Revisi 5 — baseline desain final untuk implementasi MVP. Dokumen ini mengunci keputusan produk, model akses, status proses, perilaku kegagalan, dan kriteria penerimaan. Detail yang bergantung pada akun layanan, rubrik dosen, perangkat, atau versi SDK tetap wajib diverifikasi melalui pengujian nyata; dokumen tidak mengklaim fitur sudah berjalan sebelum diuji.

> Menggantikan kandidat sebelumnya: Travel Alarm (`plan_travel_alarm.md`) dan WildGuard.
> Prinsip: fitur yang secara eksplisit diwajibkan dosen diprioritaskan. Jika waktu tidak cukup, fitur dekoratif dan fitur tambahan ditunda; jangan mengorbankan autentikasi, aturan akses, atau pengujian alur inti demi mengejar jumlah fitur.
> Prinsip keamanan: **server adalah sumber kebenaran untuk aturan bisnis**, tetapi data GPS, foto, dan sensor yang berasal dari perangkat tetap merupakan klaim klien dan tidak otomatis terbukti autentik.

---

## 1. Konsep

Faunova adalah aplikasi sosial bergaya Instagram versi ringan, khusus untuk memamerkan hewan. User memotret hewan lewat kamera aplikasi, AI mengidentifikasi spesies dan menjelaskannya, dan user bisa bertanya lebih lanjut. Foto disimpan ke koleksi pribadi beserta lokasi dan waktu pengambilan, lalu user memilih mana yang dibagikan ke feed. User lain dapat follow dan like. Aplikasi juga punya mini game (kuis, shake-to-quiz) dan badge pencapaian.

Pembeda dari aplikasi sosial biasa: MVP menyediakan alur kamera dalam aplikasi tanpa pemilih galeri, pencatatan waktu penerimaan server, lokasi dan arah kompas yang dikirim perangkat, serta hash-chain untuk mendeteksi perubahan data setelah pencatatan. Ini **bukan bukti mutlak** bahwa foto pasti diambil dari kamera atau bahwa GPS yang dikirim benar.

## 2. Alur Utama (MVP)

1. User membuka kamera di aplikasi dan memotret hewan (**wajib online**). Foto dikompres ulang di klien dengan EXIF dibuang. Pada saat yang sama klien membaca GPS dan arah kompas.
2. Foto beserta lat/lng, arah kompas, dan indikator mock-location dari perangkat dikirim ke Edge Function `ai-gateway` (mode `scan`). Server mencatat `received_at` segera setelah permintaan diterima, melakukan validasi ukuran/tipe foto dan autentikasi, mencadangkan kuota secara atomik, menghitung SHA-256 dari byte foto yang diterima, lalu memanggil Gemini. Hasil terstruktur dan metadata disimpan ke `scans`; server mengembalikan `scan_id` dan hasil identifikasi. `received_at` adalah waktu penerimaan server, bukan bukti waktu rana kamera yang mutlak.
   - Jika bukan hewan: AI memberi peringatan, deskripsi dikosongkan, tombol Simpan ke Koleksi dan Chat dikunci.
3. User dapat tanya jawab (chat) dengan AI soal hewan tersebut lewat `ai-gateway` (mode *chat*). Kuota **5 pertanyaan** per scan, **10** untuk Centang Biru aktif; dipaksakan di server.
4. User menyimpan ke koleksi lewat Edge Function `save-capture`. Fungsi memverifikasi kepemilikan scan, status hewan, status foto sementara, dan apakah scan sudah dipakai. Operasi Storage dilakukan melalui Storage API; setelah file tersedia di lokasi permanen, fungsi memanggil RPC database untuk membuat capture dan hash-chain secara atomik. Jika salah satu langkah gagal, status proses memungkinkan retry/pemulihan dan tidak menganggap operasi lintas Storage+Postgres sebagai satu transaksi atomik. Data spesies, hash foto, koordinat, heading, dan `received_at` berasal dari record scan server.
5. Dari koleksi, user dapat **membagikan** tangkapan yang valid menjadi postingan di feed (privasi lokasi: area kasar atau sembunyikan).
6. User lain melihat di feed, lalu follow dan like.
7. Di tab **Game**, user check-in streak harian, bermain kuis, menyelesaikan Tantangan Hari Ini, dan menggoyang HP untuk soal kejutan. Aktivitas ini menambah progres **badge pencapaian**.
8. **Centang Biru (Verified)** dibeli bulanan lewat **Midtrans Sandbox**.

Koleksi dan postingan adalah dua hal terpisah: tidak semua tangkapan otomatis publik.

## 3. Fitur dan Keputusan

| Area | Keputusan (MVP) |
|---|---|
| Login | Supabase Auth: register, verifikasi email, login email+password, lupa password. **SMTP kustom diperlukan untuk pengujian email di luar tim; Brevo dipilih sebagai provider awal, tetapi dapat diganti jika kuota/verifikasi akun tidak sesuai** (lihat 5.1) |
| Biometrik | Sidik jari opsional, toggle on/off di Setting (rincian di 5.1) |
| Kamera | Upload hanya lewat kamera aplikasi, tanpa galeri. Pengambilan foto wajib online. EXIF dibuang sebelum upload |
| AI | Semua panggilan Gemini lewat **Edge Function `ai-gateway`** (scan Structured Output + chat tanya jawab). Kuota chat 5x / 10x dan **batas 20 scan/hari** dipaksakan server |
| Koleksi | Arsip pribadi: foto, deskripsi AI, lokasi tepat, arah kompas, dan waktu penerimaan server (ditampilkan dalam WIB/WITA/WIT/London). Cache Hive dapat dibaca offline. Capture dapat disembunyikan; kebijakan hapus akun dan penghapusan data mengikuti retensi yang dijelaskan di 5.2 |
| Sosial | Postingan, follow/unfollow, like, ikon Centang Biru |
| Feed | Dua tab: **Untuk Kamu** (publik, terbaru) dan **Mengikuti** (terbaru) |
| Postingan | Hanya gambar: foto, nama spesies, caption, waktu tangkap, tanggal upload, area lokasi, like, share (menu share bawaan HP), ikon "rantai terverifikasi" (cek per blok) |
| Peta | `flutter_map` (OpenStreetMap). Mengetuk lokasi di postingan membuka halaman peta + tombol Buka di Google Maps. Peta Koleksi di profil |
| Privasi lokasi | Dipilih per postingan: **Area kasar** (default, grid snapping dihitung server) / **Sembunyikan** |
| Game | Kuis game (10 soal, timer 15 dtk, 3 nyawa, combo, skor tertinggi — skor dihitung ulang server), shake-to-quiz (kuota server, jawaban dicek server), Tantangan Hari Ini (jawaban dicek server), check-in streak harian |
| Badge | Badge Gelar **didapat dari pencapaian**, tampil di profil (terbuka/terkunci + progres). Total 8 badge MVP |
| Centang Biru | **Bulanan**, **Rp 15.000/bulan**, dibeli lewat **Midtrans Sandbox**. Harga tampil di 3 mata uang (IDR, USD, JPY). Perpanjangan manual tiap bulan |
| Blockchain | Hash-chain (SHA-256) di tiap tangkapan koleksi, dihitung dan diverifikasi di server |
| Sensor | Accelerometer (shake-to-quiz) + magnetometer (arah kompas). GPS tidak dihitung sebagai sensor |
| Notifikasi | Notifikasi lokal terjadwal (pengingat streak, Tantangan Hari Ini, masa berlaku Centang Biru), pop-up lokal saat badge baru terbuka |
| Pencarian | Cari user (akun Centang Biru diprioritaskan di atas) dan cari spesies |
| Moderasi | Filter kata terlarang + batas panjang untuk username, bio, caption (di RPC). Tombol Laporkan di Tahap 2 |

## 4. Navigasi (bottom bar)

| Tab | Isi |
|---|---|
| Beranda | Feed: Untuk Kamu / Mengikuti |
| Cari | Kolom pencarian dengan tab Akun (prioritas Centang Biru) dan Spesies |
| Kamera (tengah) | Kamera layar penuh tanpa tombol galeri, lalu halaman hasil: identifikasi AI, tanya jawab, simpan ke koleksi |
| Game | Kartu Check-in Streak, Tantangan Hari Ini, tombol main kuis (skor tertinggi), banner shake-to-quiz |
| Profil | Foto profil, username + ikon Centang Biru, bio, jumlah postingan/follower/following, 2 sub-tab (**Postingan**, **Koleksi Privat + Peta Koleksi** + tombol Verifikasi Rantai), grid badge, tombol **Dapatkan / Perpanjang Centang Biru**. **Menu pojok atas:** Saran & Kesan, Setting (biometrik), Logout — semuanya satu ketukan dari Profil |

Bottom bar memakai efek kaca (glassmorphism), berbentuk bar penuh (bukan melayang).

## 5. Rincian Teknis Keputusan Penting

### 5.1 Login, biometrik, dan penyimpanan lokal
- Alur: register, verifikasi email, login email+password.
- **SMTP kustom digunakan untuk pengujian email di luar tim.** Provider email bawaan Supabase saat ini dibatasi dan ditujukan untuk pengembangan, bukan pengiriman produksi; batas dapat berubah. Brevo menjadi pilihan awal, bukan ketergantungan arsitektur. Sebelum demo, verifikasi domain/alamat pengirim, konfigurasi SPF/DKIM bila diminta, kuota akun, rate limit Supabase, serta pengiriman ke Gmail/Outlook. Jika Brevo tidak dapat diverifikasi atau kuotanya tidak cukup, gunakan provider SMTP lain yang kompatibel. Jangan menganggap angka limit yang tertulis di dokumen akan selalu tetap.
- Fingerprint hanya membuka **sesi yang tersimpan** di `flutter_secure_storage`. Password tidak disimpan.
- Toggle fingerprint di Setting: saat dinyalakan, user diminta verifikasi sidik jari dulu.
- Gagal 5 kali berturut-turut: tombol fingerprint disembunyikan, tampil form email+password. Counter di-reset saat berhasil.
- Logout manual menghapus sesi tersimpan, jadi login berikutnya wajib email+password.
- Pengaturan on/off disimpan lokal per perangkat, bukan di Supabase.
- Toggle dinonaktifkan jika perangkat tidak punya sensor atau belum ada sidik jari terdaftar.
- Database lokal: **Hive terenkripsi (`HiveAesCipher`)** dengan kunci AES-256 di `flutter_secure_storage`. Isi: cache koleksi (dibaca offline), cache kurs mata uang, cache skor tertinggi (hanya tampilan; sumber kebenaran di server), dan pengaturan perangkat.

### 5.2 Hash-chain (simple blockchain)
Setiap tangkapan yang disimpan ke koleksi mendapat hash yang menyambung ke tangkapan sebelumnya milik user yang sama. Hash dibuat oleh fungsi database tepercaya ketika capture dibuat; Flutter tidak pernah mengirim nilai hash final. Hash-chain ini mendeteksi perubahan relatif terhadap rantai yang tersimpan, tetapi bukan blockchain terdistribusi dan tidak dapat menjamin kejujuran data awal atau menahan administrator yang dapat mengubah seluruh database.

Format kanonis sebelum hashing harus didefinisikan satu kali dan dipakai oleh fungsi pembuatan serta verifikasi. Gunakan encoding UTF-8, separator yang tidak ambigu atau serialisasi kanonis, representasi `NULL` yang eksplisit, koordinat dengan 6 angka desimal, heading dengan format tetap, dan waktu ISO-8601 UTC. Jangan menggabungkan nilai mentah tanpa aturan separator/escaping.

```
block_hash = SHA-256(canonical_encode(
  seq, previous_hash, photo_sha256, latitude, longitude,
  camera_heading, received_at, user_id
))
```

- **Format baku:** lat/lng sebagai string 6 desimal, heading sebagai nilai numerik ternormalisasi dengan presisi tetap atau `NULL`, `received_at` sebagai ISO-8601 UTC. Semua nilai dienkode melalui fungsi serialisasi kanonis yang sama; format yang berbeda menghasilkan hash berbeda.
- **`seq`:** nomor urut per user, `UNIQUE(user_id, seq)`.
- **Genesis:** blok pertama memakai `previous_hash = SHA-256(user_id)`.
- **Concurrency:** RPC mengambil `pg_advisory_xact_lock(hashtextextended(user_id::text, 0))` sebelum membaca blok terakhir, sehingga dua penyimpanan bersamaan milik user yang sama diserialisasi. Semua operasi pembuatan blok harus memakai satu fungsi database yang sama. Hash lock adalah mekanisme serialisasi, bukan bukti integritas; constraint `UNIQUE(user_id, seq)` tetap wajib.
- **`photo_sha256`, `received_at`, lat/lng, dan heading** dibaca dari tabel `scans`, bukan dari permintaan simpan. `received_at` berarti waktu server menerima scan. GPS dan heading tetap berasal dari sensor/perangkat klien dan tidak dijamin autentik.
- **Lokasi** berasal dari GPS klien. Jika platform melaporkan mock location, scan ditolak; jika status tidak tersedia, simpan sebagai `unknown` dan jangan menyatakan lokasi telah terverifikasi. Flag dari klien dapat dimanipulasi, sehingga ini hanya pemeriksaan dasar, bukan jaminan anti-spoofing.
- **Integritas dan privasi:** penghapusan capture secara logis tidak boleh mengubah blok berikutnya. Tetapkan kebijakan penghapusan akun dan retensi: data yang diperlukan untuk rantai dapat dihapus atau dipseudonimkan melalui prosedur terkontrol, dengan konsekuensi verifikasi rantai dan batasannya dijelaskan. Jangan menjanjikan data tidak pernah dihapus secara permanen tanpa dasar kebutuhan dan kebijakan privasi yang jelas. Postingan dapat dihapus terpisah dari capture.
- **Imutabel:** trigger database menolak perubahan kolom rantai (`seq`, `previous_hash`, `block_hash`, `photo_sha256`, koordinat, `camera_heading`, `received_at`, `user_id`). Operasi koreksi metadata tidak boleh mengubah nilai yang di-hash; RLS bukan pengganti trigger. Akses administratif tetap merupakan batas kepercayaan yang harus dicatat.
- **Dua level verifikasi:**
  1. **`verify_chain()`** menghitung ulang seluruh rantai user dan mengembalikan `seq` pertama yang rusak (atau OK). Dipakai oleh tombol **"Verifikasi Rantai"** di tab Koleksi.
  2. **`verify_block(capture_id)`** menghitung ulang `block_hash` satu blok dan mengecek `previous_hash`-nya sama dengan `block_hash` blok sebelumnya. Ringan, dipakai untuk ikon "terverifikasi" di postingan feed. Cek per blok **tidak** mendeteksi kerusakan di blok lain; itulah gunanya verifikasi penuh.
- **Demo:** ubah satu baris lewat dashboard Supabase, tekan Verifikasi Rantai, tunjukkan rantainya putus.

Tujuannya tamper-evident: kalau satu entri diubah, rantai setelahnya tidak cocok lagi saat diverifikasi. Ini bukan blockchain terdistribusi (tanpa mining/konsensus), sesuai syarat "simple blockchain".

Keterbatasan yang dicantumkan di laporan:
- User tetap bisa memotret layar HP lain yang menampilkan foto hewan.
- GPS bisa dipalsukan di level sistem (mock location terdeteksi di Android, tapi bukan jaminan mutlak).
- Aturan "kamera saja" hanya ditegakkan di klien; klien yang dimodifikasi bisa mengirim gambar apa saja ke `ai-gateway` dan server tidak bisa membedakannya.

### 5.3 Validasi objek non-hewan dan konsistensi Storage
- Jika scan mendeteksi objek bukan hewan (`isAnimal: false`), `ai-gateway` hanya mengembalikan pesan peringatan tanpa deskripsi, dan tombol Simpan ke Koleksi serta Chat dikunci.
- `save_capture` menolak `scan_id` dengan `is_animal = false` di sisi server, jadi mengakali tombol di klien tidak berguna.
- Karena pengambilan foto wajib online di MVP, tidak ada capture offline yang belum diverifikasi. Namun, scan sementara dan operasi Storage yang gagal tetap harus ditangani melalui status proses dan retry.
- Offline capture (versi hemat) ada di Tahap 2 (bagian 9).

### 5.4 Centang Biru bulanan, Midtrans, dan konversi mata uang
- **Centang Biru (Verified Account)** berlangganan **bulanan**, dibeli lewat **Midtrans Sandbox**. Midtrans Snap adalah pembayaran sekali bayar, jadi **perpanjangan manual** tiap bulan (tanpa auto-charge).
- **Status:** kolom `profiles.verified_until TIMESTAMPTZ`. Aktif jika `verified_until > now()`. Tidak perlu cron; kedaluwarsa terhitung otomatis saat dibaca.
- **Setiap pembayaran yang telah diverifikasi sukses:** dalam satu transaksi database yang idempotent, `verified_until = greatest(verified_until, now()) + interval '30 days'`. Perpanjangan saat masih aktif menambah masa aktif; jangan mengaktifkan status hanya berdasarkan halaman redirect atau respons klien.
- **Harga:** **Rp 15.000/bulan** (final), ditampilkan juga dalam USD dan JPY. Pastikan format desimal USD/JPY enak dibaca (nilai USD di bawah satu dolar).
- **Keuntungan Centang Biru (MVP):**
  1. Ikon Centang Biru di samping username.
  2. Kuota tanya jawab AI naik dari 5 menjadi 10 pertanyaan per scan.
  3. Prioritas urutan teratas di pencarian akun.
- **Konversi Mata Uang:** harga tampil di 3 mata uang (**IDR, USD, JPY**) memakai kurs dari API gratis yang di-cache di Hive agar tetap tampil saat offline. Transaksi ke Midtrans tetap dikirim dalam IDR.
- **Keamanan Midtrans:** server key disimpan hanya di secrets Edge Function; tidak pernah ditaruh di Flutter, repo, atau log. Pembuatan Snap Token dan webhook diproses di Edge Function. Sebelum memperpanjang status, validasi signature, `order_id`, nominal IDR, identitas user, status transaksi yang memang sukses/settlement sesuai alur yang digunakan, dan cocokkan ke Status API jika dibutuhkan.
  - Webhook di-deploy dengan `--no-verify-jwt` (Midtrans tidak mengirim JWT). Keamanannya dari **verifikasi signature key** (`SHA512(order_id + status_code + gross_amount + server_key)`) dan, opsional, pengecekan ulang ke Midtrans Status API.
  - Webhook **idempotent**: `order_id` unik; simpan event/status dan pembaruan `verified_until` dalam transaksi database yang sama atau melalui pola pemrosesan yang aman terhadap retry. Event duplikat, terlambat, atau berurutan berbeda tidak boleh memperpanjang masa aktif dua kali.
  - Endpoint webhook publik memakai `--no-verify-jwt` karena Midtrans tidak mengirim JWT Supabase; verifikasi signature dan validasi transaksi wajib dilakukan di dalam fungsi. Jangan menganggap URL yang sulit ditebak sebagai pengamanan.
- **Alur kembali ke app:** Snap dibuka lewat `webview_flutter`. Setelah selesai, app polling status profil tiap ~2 detik hingga ~30 detik (webhook bersifat asinkron) dengan tampilan "menunggu konfirmasi pembayaran". Halaman Centang Biru menampilkan "Aktif sampai tgl X" dan riwayat transaksi.
- **Notifikasi lokal:** pengingat 3 hari sebelum `verified_until`.

### 5.5 Konversi waktu
Simpan `received_at` sebagai `TIMESTAMPTZ` UTC. UI mengonversinya ke zona waktu `Asia/Jakarta`, `Asia/Makassar`, `Asia/Jayapura`, dan `Europe/London`. Gunakan database/ICU time-zone database agar perubahan daylight saving London ditangani otomatis. Semua pengertian hari untuk streak, Tantangan Hari Ini, kuota shake, dan batas scan memakai tanggal WIB dari waktu server, bukan jam perangkat.

### 5.6 AI (Edge Function `ai-gateway`)
Semua panggilan Gemini lewat satu Supabase Edge Function. API key Gemini (Google AI Studio) disimpan di secrets Edge Function, tidak ada di aplikasi. `firebase_ai` / Firebase tidak dipakai lagi.

- **Mode scan:** terima foto (sudah dikompres, EXIF dibuang) + lat/lng + heading + flag mock, lalu:
  1. Validasi JWT dan kepemilikan akun.
  2. Validasi tipe MIME dari byte, ukuran maksimum, dimensi yang masuk akal, dan batas payload; jangan percaya ekstensi file saja.
  3. Tolak jika status mock location yang tersedia menyatakan mock; simpan status pemeriksaan sebagai `reported_mock`, `reported_not_mock`, atau `unknown` dan jangan menyebutnya bukti autentik.
  4. **Cadangkan kuota atomik** lewat tabel `daily_scan_usage` dengan unique key `(user_id, date_wib)` dan update bersyarat. Setiap request membawa `request_id` UUID yang unik per user; retry dengan `request_id` sama mengembalikan status/hasil request sebelumnya dan tidak memanggil Gemini ulang. Kegagalan sebelum panggilan provider dimulai boleh melepas cadangan; setelah panggilan provider dimulai, kuota tetap terpakai agar retry tidak menggandakan biaya. Permintaan paralel tidak boleh melewati batas 20 scan per hari WIB.
  5. Catat `received_at` dari server, hitung `photo_sha256` atas byte foto yang benar-benar diterima, lalu panggil Gemini dengan Structured Output (`isAnimal`, `name`, `categoryOrSpecies`, `description`, `additionalFact`).
  6. Simpan hasil, lokasi/heading yang dikirim klien, status validasi, dan referensi foto pada bucket privat sementara. Kembalikan `scan_id` dan hasil. `save-capture` mengatur Storage API dan RPC database sesuai alur pemulihan di 5.3.
- **Mode chat:** satu query atomik untuk kuota:
  `UPDATE scans SET chat_count = chat_count + 1 WHERE id = :scan_id AND user_id = :uid AND chat_count < :limit RETURNING ...`
  dengan `limit` = 10 jika `verified_until > now()`, selain itu 5. Tidak ada baris kembali = kuota habis. Konteks ke Gemini cukup hasil identifikasi dan riwayat teks (`scan_chats`), tanpa mengirim foto lagi (lebih hemat kuota free tier).
- Kuota dihitung per `scan`; membuka ulang dari Koleksi memakai scan yang sama.
- **Cleanup scan sementara:** file foto pada bucket privat sementara dihapus setelah 3 hari jika belum menjadi capture, menggunakan Storage API, bukan menghapus baris internal Storage secara langsung. `photo_deleted_at` mencatat pembersihan. Setelah file dihapus, `save-capture` menolak scan tersebut. Data kuota dipindah ke `daily_scan_usage`, sehingga baris scan tidak perlu dipertahankan hanya untuk menghitung kuota. Terapkan masa retensi metadata scan/chat yang tidak disimpan, lalu hapus atau anonimisasi data sensitif sesuai kebijakan. Jadwalkan cleanup dan pantau hasilnya; jangan mengandalkan cron tanpa uji operasional.
- Tampilkan *disclaimer* bahwa hasil AI bukan kepastian mutlak, terutama untuk satwa liar/berbahaya.
- Catatan: kuota free tier Gemini bisa habis saat demo; siapkan API key cadangan, dan cek limit terbaru model yang dipakai sebelum menetapkan angka 20.

### 5.7 Peta dan lokasi
- Setiap postingan menampilkan area tempat hewan ditangkap. Mengetuknya membuka halaman peta (`flutter_map`, OpenStreetMap) dengan lingkaran radius dan tombol "Buka di Google Maps".
- Privasi dipilih per postingan: **Area kasar** (default) atau **Sembunyikan** (tidak ada peta).
- **Pengaburan koordinat: grid snapping deterministik, dihitung di server** saat `create_post`. Gunakan grid deterministik server-side dengan ukuran 0,01° lintang dan 0,01° bujur, lalu tampilkan pusat sel. Karena jarak fisik derajat bujur berubah menurut lintang, jangan menyatakan grid selalu berukuran tepat 1,1 km atau lingkaran selalu menjamin lokasi asli berada di dalam radius tetap. UI menyebutnya “area perkiraan”, bukan jaminan radius presisi. Pada lintang yang lebih tinggi, ukuran sel di arah timur-barat mengecil. Jangan mengirim koordinat privat ke peta atau respons publik.
- **Label area** (kecamatan/kota, bukan jalan) dibuat dari reverse geocoding dengan cache dan pembatasan request. Alamat lengkap hanya privat dan tidak ditampilkan di feed. Jika layanan geocoding gagal atau tidak tersedia, simpan label sebagai belum tersedia; jangan gagalkan penyimpanan capture hanya karena geocoding gagal. Patuhi kebijakan layanan geocoding yang dipakai.
- Koordinat tepat hanya tersimpan di `scans` dan `captures` (privat, RLS ketat `auth.uid() = user_id`). Tabel `posts` hanya menyimpan koordinat hasil grid (`display_latitude`, `display_longitude`).
- **EXIF:** foto dikompres ulang di klien dengan `keepExif: false`, dan metadata gambar diperiksa/dibersihkan di server bila memungkinkan. Jangan menganggap pemrosesan klien sebagai batas keamanan; foto publik tetap harus dipastikan tidak membawa EXIF sensitif.
- **Peta Koleksi** di profil menampilkan semua tangkapan sebagai penanda (hanya terlihat pemilik).

### 5.8 Game, streak, dan badge

**Check-in Streak**
- Kartu Streak di tab Game dengan tombol **"Check-in Hari Ini"** yang memanggil RPC `claim_daily_streak()`.
- Streak naik `+1` jika diklaim di hari berikutnya (WIB via `wib_today()`), reset ke `1` jika terlewat satu hari. Tanpa bonus milestone.
- Pengingat sebelum streak putus dikirim lewat notifikasi lokal pada malam hari. **Notifikasi hari itu dibatalkan jika user sudah check-in.**

**Kuis Game**
- Pilihan ganda (4 opsi, 1 benar, penjelasan singkat) dengan **timer per soal**, **3 nyawa**, **skor + combo** jawaban benar beruntun, dan **skor tertinggi**. Efek getar (*haptic feedback*) dan animasi benar/salah.
- **Rumus skor baku (flat, tanpa bonus kecepatan):**
  - **10 soal per sesi**, **timer 15 detik** per soal, **3 nyawa**. Sesi berakhir saat 10 soal habis atau nyawa habis.
  - **Benar:** `skor = round(100 × multiplier)`, dengan `multiplier = min(1 + 0.1 × combo_sebelumnya, 1.5)`. Jawaban benar pertama ×1.0, kedua ×1.1, dst., mentok ×1.5 mulai benar ke-6 beruntun.
  - **Salah atau waktu habis:** nyawa berkurang 1, combo reset ke 0, dan jawaban tersebut tidak menambah skor (skor yang sudah didapat tidak dihapus).
  - **Skor maksimal: 1350** (10 benar beruntun; multiplier 1.0 + 1.1 + 1.2 + 1.3 + 1.4 + lima kali 1.5 = 13.5).
- **Ambang badge Juara Kuis: 1000** (estimasi; 8 jawaban benar beruntun menghasilkan 1050 poin menurut rumus ini). **Uji dengan beberapa kali main sebelum dikunci.** Ambang disimpan sebagai data di tabel `badges`, bukan hardcode.
- Bank soal (~100 soal beragam kategori fauna) dibuat sekali dengan bantuan Gemini, ditinjau tim, lalu disimpan di tabel `quiz_questions`.
- **Server sebagai sumber kebenaran:**
  1. `start_quiz_session()` membuat sesi di server dan mengembalikan pertanyaan serta empat opsi **tanpa kunci jawaban**.
  2. Kuis berjalan di Flutter untuk timer, nyawa, combo, animasi, dan haptic. UI dapat merespons cepat, tetapi hasil akhir tetap divalidasi server.
  3. Di akhir, klien mengirim daftar jawaban `(question_id, pilihan, elapsed_ms)` ke `finish_quiz_session(session_id, answers)`. `pilihan = null` berarti waktu habis. Server memeriksa bahwa sesi milik user, sesi belum selesai, question ID cocok dengan soal sesi, tidak ada jawaban ganda, dan jumlah soal tidak melebihi jumlah yang diberikan. Server menghitung ulang skor dan mengabaikan skor dari klien. Sesi hanya dapat diselesaikan sekali.
  4. `elapsed_ms` dari klien tidak dapat dipercaya sebagai bukti waktu. Server memvalidasi durasi total menggunakan waktu mulai/selesai server dan aturan batas wajar, tetapi tidak mengklaim dapat membuktikan waktu per soal dengan presisi.
  5. Skor tertinggi dihitung dari sesi valid di server; `profiles.best_quiz_score` merupakan nilai turunan/cache yang harus diperbarui konsisten. Hive hanya cache tampilan dan server selalu menjadi sumber kebenaran.
  6. Sesi untuk badge Si Pintar dihitung hanya setelah sesi selesai dan tervalidasi.
- Keterbatasan (dicantumkan di laporan): karena timer dan sebagian alur kuis berjalan di klien, server tidak dapat membuktikan secara mutlak bahwa pengguna tidak memanipulasi aplikasi atau waktu per soal. Kunci jawaban tidak dikirim bersama sesi kuis.

**Shake-to-Quiz**
- Listener `sensors_plus` (accelerometer) **hanya aktif saat user membuka tab Game** (dengan haptic feedback dan *debounce*).
- Menggoyang HP memanggil RPC `claim_shake_quiz()` yang mengembalikan 1 soal kejutan atau "kuota habis". Server **mencatat soal mana yang diberikan** per klaim.
- Jawaban dikirim lewat RPC **`answer_shake_quiz(claim_id, pilihan)`**: server mengecek benar/salah ke `quiz_questions`, mencatat `is_correct`, dan menolak jika klaim itu sudah dijawab.
- Kuota harian seragam untuk semua user (3x/hari), dihitung dari jumlah baris `shake_log` per `date_wib`. Butuh online.
- Hadiahnya lewat badge (lihat tabel badge): jawaban benar dihitung untuk **Si Goyang**.

**Tantangan Hari Ini**
- 1 soal kuis harian yang sama untuk semua user (dipilih berdasarkan `wib_today()`).
- Jawaban dikirim lewat RPC **`answer_daily_challenge(pilihan)`**: server mengecek benar/salah, mencatat `is_correct` di `daily_challenge_log`, dan hanya menerima satu jawaban per user per hari.
- Hadiahnya lewat badge: jawaban benar dihitung untuk **Rutin Menantang**.

**Badge Gelar (pencapaian)**
- Tabel `badges` + `user_badges`. Pengecekan syarat dilakukan di server (RPC/trigger) setelah aksi relevan, bukan di Flutter.
- Di profil tampil grid badge: terbuka berwarna, terkunci abu-abu dengan progres (misal 4/10). Pop-up lokal saat badge baru terbuka.
- Daftar badge MVP (8):

| Badge | Syarat |
|---|---|
| Pemula | 1 tangkapan pertama disimpan |
| Kolektor | 10 tangkapan hewan |
| Rajin | Streak check-in 7 hari |
| Si Pintar | Selesaikan 5 sesi kuis |
| Juara Kuis | Skor satu sesi kuis mencapai 1000 (ambang di tabel `badges`) |
| Sosialita | 5 follower atau 10 like diterima |
| Rutin Menantang | Jawab benar Tantangan Hari Ini sebanyak 5 kali |
| Si Goyang | Jawab benar 10 soal shake-to-quiz |

**Anti-curang (ringkas)**
- `is_animal`, spesies, `photo_sha256`, lokasi, dan heading berasal dari tabel `scans` (diisi server), bukan dari klien saat simpan. Foto dihitung hanya jika `is_animal = true` dan `photo_sha256` belum pernah ada untuk user tersebut.
- Streak, badge, kuota chat, batas scan, kuota shake, jawaban shake/Tantangan Hari Ini, skor kuis, `verified_until`, dan hash-chain hanya bisa diubah lewat fungsi server (RPC / Edge Function), tidak pernah langsung dari Flutter.

### 5.9 Notifikasi
- **Notifikasi lokal terjadwal** (`flutter_local_notifications`): pengingat klaim streak (malam hari sebelum 24.00 WIB; dibatalkan bila sudah check-in), pengingat Tantangan Hari Ini, dan pengingat 3 hari sebelum Centang Biru berakhir. Berjalan tanpa internet.
- Pop-up lokal saat badge baru terbuka.
- Notifikasi dalam aplikasi (Realtime) ditunda ke Tahap 2.

### 5.10 Sensor arah kompas
- Fitur disebut **arah kompas**, bukan "arah hadap kamera". Disimpan dalam derajat (`camera_heading`), ditampilkan sebagai 8 mata angin (misal "menghadap Barat Laut"). Dibaca di klien saat foto diambil dan dikirim bersama foto ke `ai-gateway`.
- Awalnya pakai `flutter_compass`. **Uji di HP asli di minggu pertama** dengan HP dipegang tegak dan bandingkan dengan kompas bawaan HP. Jika selisih konsisten lebih dari sekitar 20°, ganti ke perhitungan manual dari accelerometer + magnetometer (`sensors_plus`) untuk arah sumbu belakang kamera.
- Tampilkan hint "gerakkan HP membentuk angka 8" jika akurasi rendah. Emulator tidak punya sensor, jadi pengujian wajib di perangkat fisik.

## 6. Tech Stack

| Kebutuhan | Pilihan |
|---|---|
| App & State Management | Flutter (`ChangeNotifier` & `ListenableBuilder` bawaan Flutter) |
| Backend Utama | Supabase (Auth, Postgres, Storage, Edge Functions: `ai-gateway`, Midtrans token + webhook, cleanup foto terjadwal) |
| AI Engine | Gemini API (API key di secrets Edge Function), dipanggil hanya dari `ai-gateway` |
| Email Auth | SMTP pihak ketiga **Brevo** |
| DB lokal | **Hive Terenkripsi (`HiveAesCipher`)** |
| Biometrik | `local_auth` + `flutter_secure_storage` |
| Sensor | `sensors_plus` (accelerometer), `flutter_compass` (magnetometer), `geolocator` (GPS untuk lokasi) |
| Kamera & gambar | `camera`, `flutter_image_compress` (buang EXIF) |
| Hash | SHA-256 di server (Postgres `pgcrypto` / Edge Function); `crypto` di klien bila perlu |
| Kurs mata uang | API kurs gratis + cache di Hive |
| Peta | `flutter_map` + `latlong2` (OpenStreetMap), `url_launcher` untuk Buka di Google Maps |
| Geocoding | Nominatim (1 req/detik, wajib User-Agent) atau package `geocoding` |
| Share | `share_plus` |
| Pembayaran | Midtrans Sandbox lewat Supabase Edge Function, `webview_flutter` untuk Snap |
| Notifikasi | `flutter_local_notifications` |

## 6.1 Kontrak keamanan, akses data, dan penanganan kegagalan (wajib sebelum implementasi)

### Aturan RLS dan RPC
- Aktifkan RLS untuk seluruh tabel yang dapat diakses melalui Supabase API. Tabel internal seperti `daily_scan_usage`, `transactions`, `scan_chats`, `scans`, `captures`, `quiz_sessions`, `shake_log`, dan `daily_challenge_log` tidak boleh dapat ditulis bebas dari klien.
- Kebijakan per tabel harus membatasi akses dengan `auth.uid()`. Data profil publik hanya mengekspos kolom yang memang aman untuk publik; jangan membuka email, koordinat tepat, metadata privat, atau riwayat pembayaran.
- Semua RPC yang mengubah kuota, capture, hash-chain, skor, badge, streak, atau status verifikasi harus memvalidasi user dan input di server. Batasi hak `EXECUTE` kepada role yang diperlukan. Jika memakai `SECURITY DEFINER`, tetapkan `search_path` secara eksplisit dan gunakan nama skema tabel yang memenuhi syarat.
- Jangan memasukkan `service_role` key atau secret provider ke aplikasi Flutter, repositori, log, maupun file konfigurasi yang dikirim ke pengguna. Kunci publik Supabase boleh digunakan di klien hanya bersama RLS yang benar.
- Tambahkan constraint database: foreign key, `NOT NULL` yang sesuai, unique constraint, validasi rentang nilai, dan indeks untuk kolom pencarian/relasi yang sering digunakan. Jangan mengandalkan validasi UI saja.

### Idempotensi, retry, dan status proses
- Semua aksi yang dapat diulang karena jaringan putus harus mempunyai kunci idempotensi atau constraint unik yang sesuai. Retry tidak boleh menggandakan capture, like, transaksi, badge, atau klaim hadiah.
- Untuk alur `save-capture`, gunakan status proses yang eksplisit, misalnya `pending_storage`, `storage_ready`, `committed`, dan `failed`. RPC database harus memeriksa status serta kepemilikan scan. Buat mekanisme retry/rekonsiliasi untuk file yang sudah dipindahkan tetapi transaksi database gagal, dan untuk record yang dibuat tanpa file yang tersedia.
- Untuk pemanggilan Gemini, gunakan timeout, tangani respons JSON yang tidak valid, batasi ukuran input, dan berikan pesan error yang dapat dipahami. Jangan mengulang panggilan mahal tanpa batas otomatis.
- Jangan menampilkan kegagalan provider sebagai hasil `is_animal = false`. Bedakan hasil identifikasi bukan hewan dari kegagalan jaringan/provider.

### Retensi, penghapusan, dan privasi
- Kebijakan retensi MVP: foto scan sementara tanpa capture dihapus setelah 3 hari; metadata scan dan chat AI yang tidak disimpan ke koleksi dihapus atau dianonimkan paling lambat 30 hari; lokasi tepat tidak dipertahankan hanya untuk menghitung kuota. Data pembayaran dipertahankan hanya selama diperlukan untuk rekonsiliasi/kewajiban yang relevan. Data kuota disimpan terpisah dalam `daily_scan_usage`.
- Penghapusan akun menjalankan proses server terkontrol dan menghapus foto, koordinat tepat, profil, relasi sosial, chat, dan data pribadi yang tidak wajib dipertahankan. Saat penghapusan dimulai, tandai rantai sebagai `terminated_by_account_deletion` dalam audit operasional sementara; setelah penghapusan data akun selesai, jangan mempertahankan identitas atau koordinat hanya demi rantai. Verifikasi penuh rantai akun tersebut tidak lagi tersedia. Data transaksi yang wajib dipertahankan untuk rekonsiliasi/ketentuan hukum dipisahkan dan diminimalkan sesuai kebutuhan, tanpa menyimpan data lokasi/foto.
- Koordinat tepat tidak boleh disertakan dalam respons feed, pencarian publik, notifikasi, log aplikasi, atau analitik yang tidak memerlukannya. Lokasi publik dihitung server dan hanya menyimpan hasil grid atau status tersembunyi.

### Kontrak tabel tambahan dan constraint penting
- Tambahkan `daily_scan_usage(user_id, date_wib, used_count, updated_at)` dengan `UNIQUE(user_id, date_wib)` untuk pencadangan kuota atomik. Scan harian tidak dihitung dengan `COUNT(*)` dari tabel scan setelah alur dibersihkan.
- `captures.scan_id` harus unik agar satu scan tidak dapat disimpan berulang menjadi beberapa capture. `scans` juga menyimpan `request_id` unik per user untuk mencegah retry request scan memanggil Gemini berulang kali.
- `likes` memakai `UNIQUE(user_id, post_id)`; `follows` memakai `UNIQUE(follower_id, followed_id)` dan constraint agar user tidak mengikuti dirinya sendiri.
- `daily_challenge_log` memakai `UNIQUE(user_id, date_wib)`. `shake_log` perlu membedakan klaim dari jawaban dan mencegah klaim dipakai lebih dari sekali. `transactions.order_id` unik dan seluruh pembaruan status pembayaran idempotent.
- `quiz_sessions` menyimpan daftar question ID yang benar-benar diberikan, status sesi, waktu mulai dan selesai server. Jawaban harus terikat pada sesi dan tidak dapat mengubah sesi yang sudah selesai.

### Definisi perilaku UI saat gagal
- Tanpa internet: pengguna boleh membaca cache koleksi yang sudah tersimpan; scan, chat, like/follow, kuis online, dan pembayaran menampilkan status offline dan tidak berpura-pura berhasil.
- Jika izin kamera ditolak, scan tidak dapat dilakukan. Jika izin lokasi ditolak/GPS tidak tersedia, scan boleh tetap berjalan tetapi lokasi disimpan sebagai `NULL` dan UI menandai “lokasi tidak tersedia”; pengguna tidak boleh dipaksa memberi koordinat palsu. Jika heading tidak tersedia, simpan `NULL`. Fitur peta untuk tangkapan tanpa koordinat disembunyikan. Jangan mengubah nilai kosong menjadi nol.
- Jika Gemini gagal: beri opsi coba lagi yang tidak menggandakan kuota/tagihan tanpa aturan; simpan status error yang terpisah dari hasil identifikasi.
- Jika pembayaran menunggu: tampilkan status menunggu konfirmasi; hanya webhook/status server yang valid dapat mengaktifkan Centang Biru.
- Jika cache lokal tidak dapat didekripsi atau rusak: tangani dengan pesan pemulihan yang jelas; jangan menyimpan kunci enkripsi di source code atau nilai hardcoded.

---

## 7. Daftar Entitas Database

| Entitas | Keterangan |
|---|---|
| profiles | Username, foto profil, bio, `streak_count`, `last_streak_claim_date`, `verified_until` (Centang Biru bulanan), `best_quiz_score` |
| scans | Hasil scan AI: `user_id`, `photo_sha256`, `result` JSON, `is_animal`, koordinat/heading yang dikirim perangkat, status pemeriksaan lokasi, `received_at` (waktu penerimaan server), `chat_count`, status foto, `photo_deleted_at`, status proses capture |
| scan_chats | Riwayat tanya jawab AI per scan |
| captures | Tangkapan koleksi privat: `scan_id` unik, referensi foto permanen, hash foto, spesies/deskripsi, koordinat tepat, label/alamat privat, `camera_heading`, `received_at`, kolom rantai (`seq`, `previous_hash`, `block_hash`), `is_hidden`, status penghapusan |
| posts | Postingan publik yang merujuk ke satu capture: caption, tanggal upload, visibilitas lokasi (`coarse`/`hidden`), label area kasar, koordinat tampilan hasil grid (`display_latitude`, `display_longitude`) |
| follows | Relasi follow antar user |
| likes | Like pada postingan |
| quiz_questions | Bank soal kuis (dibuat dengan bantuan AI, ditinjau tim) |
| quiz_sessions | Sesi kuis per user: dibuat server, skor dihitung ulang server, waktu mulai/selesai, status selesai |
| shake_log | Satu baris per klaim shake: `user_id`, `date_wib`, `question_id`, `answered_at`, `is_correct`. Kuota = jumlah baris per hari |
| daily_challenge_log | Jawaban Tantangan Hari Ini per user per hari, termasuk `is_correct` |
| badges / user_badges | Daftar badge + syarat/ambang (data), dan badge yang sudah terbuka per user |
| transactions | Riwayat pembayaran Midtrans (`order_id` unik, `user_id`, status, nominal IDR, status verifikasi provider, waktu pemrosesan, masa aktif yang ditambahkan; pembaruan idempotent) |

## 8. Pemetaan ke Kriteria Dosen

| Kriteria | Pemenuhan |
|---|---|
| Konsep proyek | Aplikasi sosial koleksi hewan (Faunova) |
| Login terenkripsi + session, bukan Firebase | Supabase Auth (hash password + sesi JWT), sudah dikonfirmasi boleh |
| Biometric login | Fingerprint opsional (`local_auth` + `flutter_secure_storage`) |
| DB lokal + online | Hive terenkripsi (cache koleksi, kurs, skor tertinggi, setting) + Supabase Postgres |
| Web service/API + LBS | Gemini API (via Edge Function), Supabase, Midtrans Sandbox, API kurs, lokasi tiap tangkapan, peta OpenStreetMap |
| Payment | Centang Biru bulanan via Midtrans Sandbox |
| Bottom nav: profil (foto), saran & kesan, logout | Ada. Saran & Kesan dan Logout langsung di menu pojok atas Profil (berisi profil 3 anggota & kesan pesan kuliah PAM). Sudah dikonfirmasi aman |
| Konversi mata uang (min. 3) | Harga Centang Biru (IDR, USD, JPY) |
| Konversi waktu | Jam tangkapan di koleksi dan feed (WIB, WITA, WIT, London) |
| AI/LLM | Identifikasi spesies (Structured Output) + chat tanya jawab per scan |
| Mini game | Kuis game (timer, nyawa, combo, skor tertinggi) + shake-to-quiz + Tantangan Hari Ini |
| Pencarian dan pemilihan | Cari user/spesies, pilih tangkapan untuk dibagikan |
| Notifikasi | Notifikasi lokal (streak, Tantangan Hari Ini, masa berlaku Centang Biru, badge baru) |
| Simple blockchain | Hash-chain SHA-256 pada tiap tangkapan koleksi + verifikasi rantai (penuh dan per blok) |
| Min. 2 sensor | Accelerometer (shake-to-quiz) + magnetometer (arah kompas) |

## 9. Tahap 2 (dikerjakan jika MVP sudah stabil)

Urutan prioritas:
1. **Komentar** pada postingan.
2. **Offline capture (versi hemat):** saat offline simpan ke Hive foto, lokasi, kompas, waktu, dan `photo_sha256` dengan status `pending` (tanpa `block_hash`). Saat sync, urut berdasarkan waktu tangkap: upload → scan di `ai-gateway` → jika hewan baru hitung `block_hash` dan sambungkan ke rantai; jika bukan hewan, dibuang dari antrean. Tampilkan notifikasi lokal bila ada foto yang ditolak. Catatan: waktu tangkap di mode ini berasal dari klien, jadi perlu batas toleransi atau penanda "offline" pada blok.
3. **Tebak Hewan:** foto hewan diblur (`ImageFiltered`) yang makin jelas seiring timer, user menebak 1 dari 4 spesies; makin cepat makin tinggi skornya. Bank awal 30-50 foto berlisensi bebas (catat sumber dan lisensi), mode dari koleksi pribadi sebagai bonus. Menambah badge "Mata Elang". Ini jenis permainan paling berbeda dari kuis, jadi layak dinaikkan prioritas jika waktu sisa.
4. **Notifikasi dalam aplikasi** versi murah (tabel `notifications` + halaman lonceng, tanpa Realtime).
5. **Tombol Laporkan** postingan (tabel `reports`, auto-sembunyikan setelah beberapa laporan).
6. Bookmark postingan + sub-tab Tersimpan.
7. Login Google.

## 10. Dibuang dari Rencana

Sistem poin, misi harian, toko Badge Gelar (badge kini dari pencapaian), Active Badge, perks Centang Biru selain 3 di atas, kuota shake berbeda per tipe user, sortir "terpopuler", mode lokasi "Tepat", milestone streak, grid Jelajah, riwayat pencarian, Firebase AI Logic (`firebase_ai`), auto-charge langganan, SMTP bawaan Supabase, **bonus kecepatan di kuis**.

## 11. Catatan Risiko dan Laporan

- **Hash-chain:** cantumkan keterbatasan (memotret layar HP lain, mock location, aturan kamera-saja hanya di klien) dan bahwa ini bukan blockchain terdistribusi. Cantumkan juga bahwa verifikasi per blok di feed tidak mendeteksi kerusakan blok lain.
- **Kuota Gemini:** chat 5-10 pertanyaan per scan dan maksimal 20 scan/hari/user bisa cepat menghabiskan free tier. Siapkan API key cadangan untuk presentasi. Satu titik kegagalan: jika `ai-gateway` atau key Gemini bermasalah, scan dan chat berhenti total.
- **Midtrans:** kerjakan lebih awal (Edge Function → halaman bayar → webhook + signature → `verified_until`) karena debug webhook memakan waktu. Ingat `--no-verify-jwt` untuk webhook.
- **Email:** Brevo harus siap dan teruji ke beberapa provider sebelum testing dengan orang di luar tim.
- **Kompas:** uji di HP asli di minggu pertama; siapkan fallback perhitungan manual.
- **Kuis:** kunci jawaban tidak dikirim ke klien. Timer per soal tetap dijalankan klien; server memvalidasi sesi, jawaban, jumlah soal, dan durasi total secara defensif, tetapi tidak menjamin anti-cheat mutlak.
- **Storage:** foto sementara dibersihkan setelah 3 hari agar free tier Supabase tidak penuh.
- **Moderasi konten:** hanya foto yang lolos validasi AI sebagai hewan yang bisa dibagikan; teks dijaga filter kata terlarang. Cantumkan sebagai batasan.
- **Laporan:** tiap fitur menambah diagram RBPL, penjelasan source code, screenshot, dan test case. Hitung ini saat membagi beban kerja.

## 12. Keputusan dan Pekerjaan yang Masih Terbuka

Sudah diputuskan: nama kerja (Faunova), harga (Rp 15.000), provider SMTP awal (Brevo, dapat diganti), rumus kuis, batas scan awal (20/hari sebagai batas aplikasi, bukan jaminan limit Gemini), dan penggunaan hash-chain. Detail teknis dalam dokumen ini adalah keputusan desain, bukan bukti fitur sudah diimplementasikan. Jangan mulai integrasi sebelum bagian 15–20 dipahami dan disepakati oleh tim.

Validasi eksternal sebelum demo/rilis (tidak mengubah keputusan desain kecuali hasilnya memang mengharuskan):
- Periksa penggunaan nama Faunova dan nama pengirim email sebelum publikasi.
- Jalankan test unit rumus skor: 8 jawaban benar beruntun harus menghasilkan 1050; 10 benar beruntun harus menghasilkan 1350.
- Uji kompas di HP fisik; jika package tidak memberi heading yang dapat dipakai, gunakan implementasi sensor alternatif dan dokumentasikan hasil kalibrasi.
- Periksa limit aktual Gemini dan sesuaikan konfigurasi kuota/anggaran demo; 20 scan/hari adalah batas produk, bukan jaminan bahwa free tier provider mencukupi.
- Konfigurasikan dan uji jadwal cleanup melalui Supabase Cron (`pg_cron` + `pg_net`) atau mekanisme terjadwal yang tersedia di proyek; verifikasi autentikasi panggilan, log, retry, dan hasil penghapusan.


## 13. Checklist penerimaan MVP (wajib lulus sebelum demo)

### Keamanan dan akses
- [ ] User A tidak dapat membaca atau mengubah scan, chat, capture, transaksi, atau sesi kuis milik User B dengan mengubah ID di request.
- [ ] Tidak ada server key, Gemini API key, atau service-role key di source Flutter, APK, repository, atau log.
- [ ] Pengujian RLS dilakukan memakai sesi user biasa, bukan hanya SQL Editor/service role.
- [ ] Koordinat tepat tidak muncul dalam respons feed, halaman publik, atau log.

### Kamera, AI, dan koleksi
- [ ] Foto bukan hewan tidak bisa disimpan atau diajak chat, termasuk jika request dibuat manual di luar UI.
- [ ] Kegagalan Gemini dibedakan dari hasil “bukan hewan”.
- [ ] Dua permintaan scan paralel pada kuota terakhir tidak bisa melewati batas harian.
- [ ] Satu scan tidak bisa membuat capture duplikat.
- [ ] Kegagalan Storage/RPC dan retry tidak meninggalkan capture tanpa foto atau file tanpa status pemulihan.
- [ ] Foto sementara yang melewati masa retensi dihapus, dan metadata sensitif mengikuti kebijakan retensi.

### Hash-chain dan lokasi
- [ ] Mengubah kolom yang di-hash menyebabkan verifikasi gagal.
- [ ] Mengubah `camera_heading` juga terdeteksi oleh verifikasi.
- [ ] Dua save bersamaan pada user yang sama tetap menghasilkan urutan rantai yang valid.
- [ ] Scan dengan status mock location terdeteksi ditolak; status tidak diketahui tidak dipresentasikan sebagai lokasi terverifikasi.
- [ ] Mode lokasi tersembunyi tidak menampilkan koordinat atau peta; mode area kasar hanya mengeluarkan koordinat hasil grid.

### Kuis dan progres
- [ ] Respons `start_quiz_session()` tidak memuat kunci jawaban.
- [ ] Sesi yang sama tidak dapat diselesaikan dua kali atau mengirim question ID yang tidak diberikan.
- [ ] Skor dihitung ulang di server; skor yang dikirim klien diabaikan.
- [ ] Badge, streak, Tantangan Hari Ini, dan shake tidak dapat diklaim berulang lewat request duplikat.

### Pembayaran dan demo
- [ ] Redirect sukses saja tidak mengaktifkan Centang Biru.
- [ ] Webhook duplikat tidak menambah masa aktif dua kali.
- [ ] Nominal/order ID/user diverifikasi sebelum masa aktif diperbarui.
- [ ] Jika kurs API gagal, harga IDR dan alur aplikasi tetap berfungsi.
- [ ] Uji email verifikasi dan reset password ke beberapa provider sebelum demo.
- [ ] Uji kamera, GPS, kompas, accelerometer, notifikasi, dan biometrik pada perangkat Android fisik yang akan dipakai presentasi.

## 14. Catatan keputusan teknis yang masih harus diuji

- Batas 20 scan/hari dan kuota Gemini harus disesuaikan dengan limit aktual provider dan anggaran demo. Jangan menjadikan angka kuota provider yang belum diverifikasi sebagai jaminan ketersediaan.
- Brevo, Supabase, Midtrans Sandbox, API kurs, Nominatim/geocoding, dan Gemini adalah layanan eksternal. Uji limit, syarat penggunaan, dan perilaku error aktual sebelum rilis demo; sediakan pesan kegagalan yang jelas.
- Hash-chain tidak menjamin kebenaran foto/GPS saat awal diterima, tidak melindungi dari administrator yang dapat mengubah seluruh database, dan bukan blockchain terdistribusi.
- “Kamera saja” merupakan pembatasan UI, bukan bukti kriptografis sumber foto. Jangan memasarkan ikon rantai sebagai bukti bahwa foto pasti asli.
- Kriteria dosen dan fitur wajib harus dicocokkan kembali dengan rubrik resmi. Jika ada konflik antara rencana ini dan rubrik, rubrik dosen yang berlaku.


## 15. Spesifikasi Database Final (kontrak sebelum migration)

Bagian ini adalah kontrak struktur, bukan SQL migration. Nama kolom boleh disesuaikan kecil saat implementasi, tetapi makna, constraint, dan aturan akses tidak boleh berubah tanpa memperbarui dokumen serta pengujian.

### 15.1 Aturan umum

- Primary key utama menggunakan UUID. Kolom waktu menggunakan `TIMESTAMPTZ` dan disimpan sebagai waktu absolut; UI mengonversi ke zona waktu yang dipilih.
- Kolom uang menggunakan integer satuan rupiah (`amount_idr BIGINT`), bukan `FLOAT`. Kurs konversi hanya untuk tampilan; transaksi Midtrans selalu IDR.
- Semua tabel yang dapat diakses melalui API Supabase mengaktifkan RLS. Tabel internal tidak diberi kebijakan tulis langsung kepada `authenticated`.
- Kolom `user_id` diisi berdasarkan `auth.uid()` di server/RPC, bukan dipercaya dari payload klien. Fungsi yang menerima ID objek wajib memeriksa kepemilikan objek itu.
- Gunakan `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` untuk catatan yang memerlukan waktu pembuatan. Tambahkan `updated_at` hanya pada tabel yang memang dapat berubah.
- `ON DELETE CASCADE` hanya digunakan untuk data turunan yang aman dihapus bersama induknya. Relasi yang harus dipertahankan untuk rekonsiliasi pembayaran tidak boleh ikut terhapus otomatis.
- Hindari menyimpan data yang sama di banyak tempat tanpa alasan. Kolom turunan seperti `best_quiz_score` harus diperbarui di transaksi server yang sama atau diperlakukan sebagai cache yang dapat dibangun ulang.

### 15.2 Tabel dan kolom inti

| Tabel | Kolom minimum dan constraint penting | Tujuan / akses |
|---|---|---|
| `profiles` | `id UUID PK REFERENCES auth.users(id) ON DELETE CASCADE`, `username TEXT UNIQUE`, `display_name`, `avatar_path`, `bio`, `streak_count INT`, `last_streak_claim_date DATE`, `verified_until TIMESTAMPTZ`, `best_quiz_score INT`, `created_at`, `updated_at` | Pemilik boleh mengubah username/display name/avatar/bio yang tervalidasi; kolom progres dan verified hanya server. Jangan mengandalkan RLS untuk membatasi kolom: publik gunakan view/RPC yang hanya mengembalikan kolom aman. |
| `scans` | `id UUID PK`, `user_id UUID FK`, `request_id UUID`, `status TEXT CHECK`, `is_animal BOOLEAN NULL`, `result JSONB NULL`, `photo_sha256 CHAR(64)`, `temp_object_path TEXT`, `latitude/longitude NUMERIC NULL`, `camera_heading NUMERIC NULL`, `location_check TEXT`, `received_at TIMESTAMPTZ`, `provider_started_at TIMESTAMPTZ NULL`, `chat_count INT DEFAULT 0`, `photo_deleted_at TIMESTAMPTZ NULL`, `capture_status TEXT`, `created_at` | Privat. `UNIQUE(user_id, request_id)`. Status scan dibatasi ke enum/constraint yang didefinisikan pada 16. Klien tidak dapat menulis hasil AI, hash, waktu server, kuota, atau status final. |
| `daily_scan_usage` | `user_id UUID FK`, `date_wib DATE`, `used_count INT CHECK (used_count >= 0)`, `updated_at`, `PRIMARY KEY(user_id,date_wib)` | Internal; hanya RPC/Edge Function yang mengubah. Batas maksimum dibandingkan dengan konfigurasi server pada saat reservasi; jangan mengandalkan constraint statis sebagai satu-satunya penjaga kuota. |
| `scan_chats` | `id UUID PK`, `scan_id UUID FK`, `user_id UUID FK`, `role TEXT CHECK (role IN ('user','assistant'))`, `content TEXT`, `created_at`, `request_id UUID NULL` | Privat. Panjang pesan dibatasi server. Kunci idempotensi unik untuk pesan/request yang dapat diulang. Tidak menyimpan foto di riwayat chat. |
| `captures` | `id UUID PK`, `scan_id UUID UNIQUE FK`, `user_id UUID FK`, `photo_object_path TEXT`, `species_name TEXT`, `category TEXT NULL`, `description TEXT`, `latitude/longitude NUMERIC NULL`, `camera_heading NUMERIC NULL`, `received_at TIMESTAMPTZ`, `seq BIGINT`, `previous_hash CHAR(64)`, `block_hash CHAR(64)`, `photo_sha256 CHAR(64)`, `deleted_at TIMESTAMPTZ NULL`, `created_at`; `UNIQUE(user_id,seq)` | Koleksi privat. Dibuat hanya oleh fungsi tepercaya. `deleted_at` menyembunyikan capture dari UI; penghapusan foto dan konsekuensi verifikasi diatur pada 17. |
| `posts` | `id UUID PK`, `capture_id UUID UNIQUE FK`, `user_id UUID FK`, `caption TEXT`, `location_visibility TEXT CHECK IN ('coarse','hidden')`, `display_latitude/longitude NUMERIC NULL`, `area_label TEXT NULL`, `created_at`, `deleted_at TIMESTAMPTZ NULL` | Post publik jika `deleted_at IS NULL` dan capture tidak dihapus. Data lokasi tepat dilarang. Caption dibatasi panjang dan dimoderasi server. |
| `follows` | `follower_id UUID FK`, `followed_id UUID FK`, `created_at`, `PRIMARY KEY(follower_id,followed_id)`, `CHECK(follower_id <> followed_id)` | Relasi sosial; pengguna hanya membuat/menghapus relasinya sendiri. |
| `likes` | `user_id UUID FK`, `post_id UUID FK`, `created_at`, `PRIMARY KEY(user_id,post_id)` | Like unik per pengguna/postingan. Like hanya boleh dibuat untuk postingan yang dapat dilihat. |
| `quiz_questions` | `id UUID PK`, `category TEXT`, `question TEXT`, `options JSONB`, `correct_option SMALLINT`, `explanation TEXT`, `is_active BOOLEAN`, `created_at`; constraint opsi 4 dan jawaban dalam rentang 0–3 divalidasi oleh seed/test | Bank soal hanya dapat dikelola tim/admin melalui proses server; endpoint kuis tidak pernah mengirim `correct_option`. |
| `quiz_sessions` | `id UUID PK`, `user_id UUID FK`, `question_ids UUID[]` atau tabel anak, `status TEXT CHECK`, `started_at TIMESTAMPTZ`, `finished_at TIMESTAMPTZ NULL`, `score INT NULL`, `correct_count INT NULL`, `idempotency_key UUID` | Dibuat server. `UNIQUE(user_id,idempotency_key)` bila request dapat diulang. Sesi selesai tidak bisa dimodifikasi. Pertanyaan yang diberikan tetap terikat ke sesi. |
| `quiz_answers` | `session_id UUID FK`, `question_id UUID FK`, `selected_option SMALLINT NULL`, `elapsed_ms_client INT NULL`, `is_correct BOOLEAN`, `server_received_at TIMESTAMPTZ`, `PRIMARY KEY(session_id,question_id)` | Ditulis server saat penyelesaian sesi. `elapsed_ms_client` hanya data diagnostik, bukan sumber kebenaran timer. |
| `shake_log` | `id UUID PK`, `user_id UUID FK`, `date_wib DATE`, `question_id UUID FK`, `status TEXT CHECK`, `is_correct BOOLEAN NULL`, `claimed_at`, `answered_at NULL`, `idempotency_key UUID` | Satu baris mewakili satu klaim. `UNIQUE(user_id,idempotency_key)`. Klaim dihitung untuk kuota saat soal berhasil diberikan; retry dengan kunci sama mengembalikan klaim yang sama. |
| `daily_challenge_log` | `user_id UUID FK`, `date_wib DATE`, `question_id UUID FK`, `selected_option SMALLINT NULL`, `is_correct BOOLEAN`, `answered_at`, `PRIMARY KEY(user_id,date_wib)` | Satu jawaban per user per tanggal WIB. Jawaban tidak bisa diganti setelah dikirim. |
| `badges` | `id TEXT PK`, `name TEXT`, `description TEXT`, `threshold JSONB`, `is_active BOOLEAN` | Konfigurasi badge; hanya server/admin dapat mengubah. |
| `user_badges` | `user_id UUID FK`, `badge_id TEXT FK`, `unlocked_at`, `progress JSONB NULL`, `PRIMARY KEY(user_id,badge_id)` | Progres dihitung server. Klien hanya membaca badge miliknya atau badge publik sesuai kebijakan profil. |
| `transactions` | `id UUID PK`, `order_id TEXT UNIQUE`, `user_id UUID FK`, `amount_idr BIGINT CHECK > 0`, `currency TEXT CHECK = 'IDR'`, `status TEXT CHECK`, `provider_transaction_id TEXT NULL`, `provider_status TEXT NULL`, `processed_at TIMESTAMPTZ NULL`, `entitlement_days INT CHECK > 0`, `created_at`, `updated_at` | Tidak ada baca/tulis bebas dari klien. Riwayat hanya dapat dibaca pemilik lewat fungsi/view yang tidak membuka secret/provider payload sensitif. |
| `chain_state` | `user_id UUID PK`, `status TEXT CHECK IN ('active','terminated_by_account_deletion')`, `last_seq BIGINT`, `last_hash CHAR(64)`, `updated_at` | Opsional sebagai pointer performa; sumber kebenaran tetap blok/capture dan constraint. Jangan gunakan pointer ini sendiri untuk verifikasi. |
| `app_config` | `key TEXT PK`, `value JSONB`, `updated_at` | Konfigurasi server seperti limit scan awal, kuota shake, dan batas panjang teks. Tidak dapat diubah oleh pengguna. |

**Catatan skema:** bila implementasi memakai tabel anak untuk daftar pertanyaan dan jawaban kuis, itu lebih mudah diberi constraint dibanding array. Pilih satu bentuk saat migration dan gunakan konsisten. Tabel di atas adalah minimum konseptual, bukan keharusan mempertahankan semua nama persis jika ada alasan teknis yang terdokumentasi.

### 15.3 Indeks minimum

- `posts(created_at DESC)` untuk feed terbaru; `posts(user_id, created_at DESC)` untuk profil.
- `captures(user_id, created_at DESC)` untuk koleksi; `scans(user_id, created_at DESC)` untuk riwayat internal.
- `follows(followed_id, follower_id)` untuk jumlah/daftar follower dan `follows(follower_id, followed_id)` untuk following.
- `likes(post_id, created_at DESC)` untuk hitung/daftar like.
- `transactions(user_id, created_at DESC)` untuk riwayat pembayaran.
- `quiz_sessions(user_id, finished_at DESC)` untuk skor/riwayat sesi.
- `scans(status, created_at)` untuk cleanup/reconciliation; `captures(user_id, seq)` unik juga menjadi indeks rantai.
- Gunakan pencarian case-insensitive username dengan indeks yang sesuai (misalnya indeks ekspresi `lower(username)` atau tipe `citext`), tetapi tetapkan aturan normalisasi username satu kali.

## 16. Matriks Akses dan RLS

RLS membatasi baris, bukan secara otomatis menyembunyikan kolom tertentu. Untuk data publik dengan subset kolom, gunakan view/RPC dengan grant yang tepat; jangan menganggap policy pada `profiles` dapat menyembunyikan `email` atau kolom privat jika tabel tersebut memang terekspos ke API.

| Data | Anon/tanpa login | Pengguna login | Pemilik data | Server/RPC tepercaya |
|---|---|---|---|---|
| Profil publik | Baca kolom publik saja jika produk mengizinkan | Baca kolom publik | Ubah kolom profil yang diizinkan | Mengubah verified, streak, skor, dan kolom sistem |
| Scan, chat, capture | Tidak ada akses | Tidak ada akses lintas pemilik | Baca data sendiri; tidak menulis kolom sistem langsung | Buat/perbarui melalui fungsi terverifikasi |
| Foto sementara | Tidak ada akses | Tidak ada akses lintas pemilik | Tidak mengakses bucket lewat path bebas; melalui flow resmi | Upload/move/delete via Storage API dan validasi path |
| Foto koleksi privat | Tidak ada akses | Tidak ada akses lintas pemilik | Baca foto koleksi sendiri | Menghasilkan signed URL sesuai otorisasi |
| Foto postingan publik | Tidak ada akses ke bucket/path privat langsung | Baca melalui endpoint/URL bertanda tangan sesuai status publik | Kelola postingan sendiri | Memastikan postingan aktif dan foto terkait valid |
| Postingan publik | Baca postingan aktif dan kolom publik saja | Sama | Buat/hapus postingan sendiri melalui RPC; tidak bisa mengganti owner/capture | Menegakkan moderasi dan privasi lokasi |
| Follow/like | Tidak ada perubahan | Buat/hapus relasi milik sendiri | Baca relasi yang diizinkan | Mencegah duplikasi dan aksi pada konten tidak tersedia |
| Kuis, streak, shake, badge | Tidak ada akses tulis | Baca hasil yang diizinkan | Memulai sesi/menjawab melalui RPC | Menentukan soal, jawaban benar, skor, kuota, badge |
| Pembayaran | Tidak ada akses | Memulai pembayaran melalui Edge Function; membaca status sendiri | Tidak mengubah status transaksi | Membuat order, memverifikasi webhook/Status API, memberi entitlement |
| Kuota, konfigurasi, audit internal | Tidak ada akses | Tidak ada akses langsung | Tidak ada akses langsung | Hanya role/function minimum yang diperlukan |

### 16.1 Aturan wajib implementasi

- `profiles` tidak boleh menjadi endpoint publik yang membocorkan seluruh row. Buat `public_profiles` view atau RPC yang hanya mengembalikan `id`, username, display name, avatar, bio, verified flag, serta agregat publik yang disetujui.
- Setiap fungsi `SECURITY DEFINER` menetapkan `search_path` yang aman (misalnya `pg_catalog, public` jika sesuai), memakai nama tabel berkualifikasi skema, memvalidasi `auth.uid()`, dan hanya memberi `EXECUTE` ke role yang dibutuhkan.
- Cabut hak `INSERT/UPDATE/DELETE` langsung terhadap kolom sistem; RLS bukan pengganti constraint, trigger immutable, atau validasi fungsi.
- Semua file path harus dibentuk server berdasarkan UUID dan user ID; jangan menerima object path bebas dari klien. Validasi pemilik, bucket, ukuran, MIME, serta status file sebelum signed URL dibuat.
- Jangan mengembalikan email, koordinat tepat, chat privat, payment payload, server key, atau detail internal error melalui feed, pencarian, atau log klien.
- Jalankan test RLS dengan dua akun normal dan token user, bukan hanya SQL Editor atau service role. Pengujian dengan service role tidak membuktikan RLS aman.

## 17. Kontrak Status, Transaksi, dan Retry

### 17.1 Status scan AI

Gunakan status yang eksplisit dan transisi satu arah:

`received → validating → processing → succeeded | not_animal | failed`

- `received`: request idempotensi dicatat; belum ada pemanggilan provider.
- `validating`: autentikasi, payload, ukuran, kuota, dan input diperiksa.
- `processing`: kuota telah dicadangkan dan pemanggilan Gemini dimulai.
- `succeeded`: hasil AI valid dan tersimpan.
- `not_animal`: Gemini menghasilkan respons valid yang menyatakan objek bukan hewan.
- `failed`: validasi/provider/storage gagal; simpan kode error internal tanpa rahasia.
- Retry dengan `request_id` sama tidak membuat scan baru atau panggilan Gemini kedua secara otomatis. Jika status `processing` macet, reconciliation job menentukan apakah hasil dapat dipulihkan; jangan memulai panggilan provider ulang tanpa kebijakan eksplisit.
- Kuota: reservasi atomik dilakukan sebelum panggilan provider. Jika gagal sebelum provider dipanggil, reservasi dapat dilepas. Setelah provider dipanggil atau statusnya tidak diketahui karena timeout, kuota dianggap terpakai agar retry tidak menciptakan panggilan berbiaya ganda. Catat alasan penggunaan kuota untuk audit internal.

### 17.2 Status penyimpanan capture

Gunakan `pending_storage → storage_ready → committed`; kegagalan dapat menjadi `failed_retryable` atau `failed_terminal`.

1. Server membuat operasi simpan dengan ID idempotensi.
2. Server memindahkan/menyalin foto lewat Storage API ke path permanen privat yang dibentuk server.
3. Server memverifikasi objek permanen tersedia dan ukuran/hash sesuai data scan.
4. RPC database dalam satu transaksi memeriksa kepemilikan, `is_animal = true`, belum kedaluwarsa, scan belum dipakai, status file `storage_ready`, lalu membuat capture dan blok rantai.
5. Jika RPC gagal setelah file permanen tersedia, reconciliation job mencoba ulang RPC atau menghapus file yatim setelah masa tunggu aman. Jika record capture ada tetapi file tidak ada, tandai `repair_required` dan jangan tampilkan seolah foto tersedia.
6. `UNIQUE(captures.scan_id)` dan kunci idempotensi mencegah duplikasi. Jangan menganggap Storage dan Postgres satu transaksi atomik.

### 17.3 Status transaksi pembayaran

Status internal minimum: `pending`, `paid_verified`, `failed`, `expired`, `cancelled`, `refunded`, `review_required`.

- Hanya transisi yang sah boleh diterima. Notifikasi terlambat tidak boleh menurunkan `paid_verified` menjadi `pending` atau menambah entitlement lagi.
- Buat `order_id` unik dan tidak dapat dipilih pengguna; harga, user ID, mata uang, dan entitlement berasal dari data server, bukan payload klien.
- Verifikasi signature sesuai format Midtrans, cocokkan `order_id`, nominal persis (termasuk format `gross_amount`), currency, merchant jika tersedia, status transaksi, dan `fraud_status` jika ada. Gunakan Status API sebagai verifikasi tambahan/rekonsiliasi, terutama bila payload tidak konsisten.
- Simpan penerimaan notifikasi dan hasil pemrosesan secara idempotent. Satu transaksi valid hanya memberi entitlement satu kali. Gunakan constraint unik/ledger `entitlement_grants(transaction_id UNIQUE, user_id, granted_at, days)` atau mekanisme setara.
- Perpanjangan: `verified_until = greatest(coalesce(verified_until, now()), now()) + interval '30 days'` hanya ketika transaksi pertama kali menjadi sukses terverifikasi. Nilai entitlement yang diberikan harus tercatat sehingga refund/review bisa ditangani tanpa menebak.
- Jangan menyebut Centang Biru sebagai verifikasi identitas dunia nyata; fitur ini adalah status berbayar dalam aplikasi, bukan bukti identitas atau keaslian akun.
- Untuk MVP Sandbox, jika provider melaporkan refund/chargeback atau status tidak konsisten setelah entitlement diberikan, ubah transaksi ke `review_required`, hentikan pemberian entitlement baru, dan tampilkan status “sedang ditinjau”; jangan mengubah masa aktif secara otomatis berdasarkan notifikasi yang belum direkonsiliasi. Jika tim memutuskan mengimplementasikan pencabutan otomatis, wajib ada ledger `entitlement_grants` dengan satu grant per transaksi dan perhitungan ulang masa aktif dari grant yang belum dicabut.

### 17.4 Retensi dan penghapusan

- Foto sementara tanpa capture: target penghapusan setelah 3 hari.
- Metadata scan/chat yang tidak disimpan ke koleksi: target hapus/anonymize paling lambat 30 hari, kecuali data minimal yang dibutuhkan untuk kuota/idempotensi masih dalam jangka pendek yang ditetapkan.
- Buat cleanup idempoten, berbatch, dengan log jumlah sukses/gagal dan retry. Jangan log isi chat, koordinat, token, atau foto.
- Penghapusan capture: secara default hapus postingan terkait, hapus foto permanen, tandai capture dihapus dan hapus koordinat tepat; blok rantai dapat berubah menjadi tombstone minimal. Karena data yang di-hash telah dihapus, verifikasi penuh yang menghitung ulang blok itu tidak dapat dijanjikan. UI menyatakan `valid`, `valid_with_tombstones` atau `broken`, bukan hanya centang hijau yang menyiratkan kepastian.
- Penghapusan akun: nonaktifkan sesi terlebih dahulu, hentikan pembuatan konten, hapus file dan data personal melalui job terkontrol, hapus relasi sosial dan cache yang dapat dijangkau, lalu catat bahwa rantai telah diterminasi tanpa mempertahankan lokasi/foto demi rantai. Beri pengguna informasi tentang konsekuensi penghapusan dan data transaksi yang mungkin harus disimpan sesuai aturan yang berlaku.

## 18. Kontrak API/RPC Minimum

| Fungsi | Dipanggil oleh | Validasi utama | Hasil |
|---|---|---|---|
| `ai-gateway` (`scan`) | Flutter dengan JWT | JWT, ukuran/MIME/dimensi, kuota atomik, idempotensi, input lokasi nullable | `scan_id`, status, hasil terstruktur atau error yang aman |
| `ai-gateway` (`chat`) | Flutter dengan JWT | kepemilikan scan, status `succeeded`, limit chat, panjang teks, idempotensi | balasan chat atau kode error |
| `save-capture` | Flutter dengan JWT | kepemilikan scan, status `succeeded`, hewan valid, foto belum dihapus, belum disimpan, file dan hash cocok | `capture_id`, status simpan |
| `create_post` | Flutter dengan JWT | capture milik user, belum dihapus, caption valid, visibility valid, koordinat publik dihitung server | `post_id` dan metadata publik tanpa koordinat tepat |
| `claim_daily_streak` | Flutter dengan JWT | tanggal WIB server, satu klaim/hari, idempotensi | streak terbaru dan apakah klaim baru |
| `start_quiz_session` | Flutter dengan JWT | limit sesi, bank soal aktif, idempotensi | ID sesi dan soal tanpa kunci jawaban |
| `finish_quiz_session` | Flutter dengan JWT | pemilik sesi, sesi belum selesai, question IDs cocok, jawaban tidak ganda, waktu total wajar | skor hasil hitung server, jumlah benar, status sesi |
| `claim_shake_quiz` | Flutter dengan JWT | kuota harian, idempotensi, soal tersedia | `claim_id` dan soal tanpa kunci |
| `answer_shake_quiz` | Flutter dengan JWT | pemilik klaim, klaim belum dijawab, pilihan valid | benar/salah yang dihitung server |
| `answer_daily_challenge` | Flutter dengan JWT | tanggal WIB, satu jawaban/hari, soal harian resmi | benar/salah dan status klaim |
| `create-payment` | Flutter dengan JWT | harga dan user di server, order unik, belum ada order identik aktif yang tak perlu | `order_id`, Snap token/URL yang aman |
| `midtrans-webhook` | Midtrans, endpoint publik | signature, order, nominal, currency, status, idempotensi, Status API bila diperlukan | acknowledgment; tidak membocorkan data user |
| `verify_chain` / `verify_block` | Flutter dengan JWT | pemilik chain/capture, status tombstone, fungsi baca saja | status verifikasi dan batasannya |
| `delete-account` | Flutter dengan JWT + konfirmasi ulang | kepemilikan, konfirmasi, operasi idempotent | status permintaan penghapusan, bukan klaim sukses sebelum selesai |

Semua fungsi mengembalikan kode error stabil seperti `AUTH_REQUIRED`, `NOT_FOUND_OR_FORBIDDEN`, `VALIDATION_ERROR`, `QUOTA_EXCEEDED`, `IDEMPOTENCY_CONFLICT`, `PROVIDER_UNAVAILABLE`, dan `RETRY_LATER`. Pesan ke pengguna ramah dan tidak memuat detail internal. Jangan gunakan `NOT_FOUND_OR_FORBIDDEN` sebagai satu-satunya mekanisme akses; otorisasi tetap diperiksa di server.

## 19. Aturan Produk dan Perilaku UI Final

- **Lokasi:** kamera wajib untuk memulai scan; izin lokasi/heading bersifat opsional. Jika tersedia, simpan nilai yang divalidasi rentangnya. Jika tidak tersedia, simpan `NULL`; tidak boleh memakai `(0,0)` sebagai pengganti. Hasil scan tetap dapat disimpan tanpa lokasi. Tombol peta disembunyikan bila tidak ada koordinat.
- **Privasi posting:** default `coarse`; `hidden` berarti tidak ada koordinat, label lokasi, peta, atau deep link lokasi pada postingan. Ubah visibility hanya melalui server yang membuang/menghitung ulang kolom publik.
- **Feed:** dua tab `Untuk Kamu` dan `Mengikuti`; gunakan pagination cursor/keyset, bukan offset besar. Urutan MVP terbaru dahulu; jangan mengklaim algoritme rekomendasi personal jika yang dipakai hanya urutan terbaru.
- **Follow/like:** hanya untuk akun aktif dan postingan yang tersedia. Unfollow/unlike harus idempotent. Jumlah like/follower dihitung dari relasi server, bukan nilai yang dikirim klien.
- **Centang Biru:** label berarti langganan aktif dalam aplikasi. Tidak menyiratkan verifikasi identitas. Harga final IDR Rp15.000 per 30 hari; USD/JPY hanya estimasi tampilan dari kurs bertimestamp dan bukan harga transaksi.
- **Cache lokal:** cache hanya data yang dibutuhkan untuk baca offline. Logout menghapus kunci sesi dan data cache privat atau menandainya tidak dapat dibaca oleh akun berikutnya. Jika kunci Hive hilang/rusak, hapus cache lokal yang rusak dan unduh ulang setelah login; jangan pernah menaruh kunci hardcoded.
- **Error state:** loading, empty, offline, permission denied, retryable error, terminal error, dan pending payment harus memiliki UI yang berbeda. Tidak ada aksi gagal yang menampilkan sukses optimistis permanen.
- **Moderasi MVP:** batas panjang dan filter kata dilakukan server, tetapi disebut sebagai filter dasar, bukan sistem moderasi lengkap. Karena laporan konten berada di Tahap 2, selama demo postingan hanya untuk pengguna uji dan tim punya prosedur penghapusan manual.
- **Aksesibilitas:** ukuran teks, kontras, label tombol, state loading/error, dan navigasi kembali diperiksa. Glassmorphism tidak boleh mengurangi keterbacaan.

## 20. Rencana Implementasi dan Definition of Done

### Milestone 0 — Konfirmasi persyaratan
- Cocokkan setiap kriteria dengan rubrik resmi dosen. Tandai fitur wajib, opsional, dan penempatan menu yang sudah disetujui.
- Bekukan scope MVP. Tidak ada fitur baru sebelum milestone inti lulus.
- Buat repo, `.env.example` tanpa rahasia, branch, aturan review, dan daftar package dengan versi yang kompatibel.

### Milestone 1 — Fondasi backend
- Buat Supabase project dan migration berurutan; jangan mengubah database hanya lewat dashboard tanpa migration yang disimpan di repo.
- Implementasikan tabel, constraints, RLS, Storage buckets privat, fungsi server, dan seed data.
- Lulus tes dua akun: tidak bisa membaca/mengubah data silang, dan profil publik hanya menampilkan kolom yang diizinkan.

### Milestone 2 — Autentikasi dan UI dasar
- Register, verifikasi email, login, reset password, logout, profil, navigasi, state loading/error.
- Biometrik hanya membuka sesi lokal yang tersimpan aman; bukan pengganti autentikasi server dan tidak menyimpan password.

### Milestone 3 — Kamera → AI → koleksi
- Kamera, permission, kompresi, EXIF cleanup, scan, status AI, chat, kuota, save-capture, cleanup/reconciliation.
- Lulus uji scan valid, bukan hewan, timeout Gemini, request duplikat, kuota terakhir paralel, foto expired, dan kegagalan Storage/RPC.

### Milestone 4 — Hash-chain dan privasi
- Canonical encoding, fungsi create/verify, concurrency lock, tombstone, private collection, coarse/hidden location.
- Lulus uji perubahan satu field, perubahan heading, dua save bersamaan, penghapusan foto, dan verifikasi dengan tombstone.

### Milestone 5 — Sosial dan pencarian
- Posting, feed pagination, follow, like, pencarian akun/spesies, signed URL.
- Lulus uji posting privat/tidak aktif tidak muncul, koordinat tepat tidak pernah keluar ke feed, serta request silang user ditolak.

### Milestone 6 — Game dan fitur wajib akademik
- Kuis, streak, shake, tantangan harian, badge, waktu, mata uang, notifikasi, sensor dan biometrik sesuai rubrik.
- Uji dengan HP Android fisik; emulator hanya untuk UI/alur yang tidak memerlukan sensor.

### Milestone 7 — Pembayaran dan hardening
- Midtrans Sandbox, webhook, Status API, idempotensi, status pending, riwayat transaksi.
- Lulus uji redirect palsu, signature salah, nominal salah, webhook duplikat/terlambat, pembayaran pending/expired, dan refund/review.

### Definition of Done per fitur

Fitur dinyatakan selesai hanya jika:
1. UI utama dan seluruh state error/loading/empty selesai.
2. Validasi klien dan server tersedia; validasi klien bukan batas keamanan.
3. RLS/Storage/RPC diuji dengan akun biasa.
4. Retry/idempotensi diuji untuk aksi yang dapat berulang.
5. Ada test case dan hasil aktual tercatat.
6. Tidak ada secret di repo/log/aplikasi klien.
7. Data privat tidak muncul di response yang tidak berwenang.
8. Fitur diuji pada perangkat/layanan yang benar-benar akan digunakan untuk demo.

### Pembagian kerja kelompok (3 orang)

Pembagian berdasarkan subsistem, dengan satu pemilik integrasi dan review silang:
- **Anggota A — Flutter/UI:** navigasi, auth screens, kamera, koleksi, profil, state management dan cache lokal.
- **Anggota B — Backend/data:** migrations, RLS, Storage, RPC, hash-chain, kuota, cleanup dan test akses.
- **Anggota C — Integrasi/fitur:** Gemini, Midtrans, game/sensor, kurs/waktu, notifikasi dan test integrasi.
- Semua anggota melakukan review silang; tidak ada satu orang yang menjadi satu-satunya pihak yang memahami secrets, deploy, atau cara demo. Urutan dapat disesuaikan kemampuan, tetapi kontrak API dan schema harus disepakati sebelum kerja paralel.

## 21. Risiko, Keputusan Eksternal, dan Batas Finalitas

### Keputusan desain yang sudah dikunci

- Nama kerja: Faunova; aplikasi koleksi hewan sosial.
- Arsitektur: Flutter + Supabase Auth/Postgres/Storage/Edge Functions + Gemini; Midtrans Sandbox untuk simulasi pembayaran.
- Harga Centang Biru: Rp15.000 per 30 hari, perpanjangan manual.
- Batas aplikasi awal: 20 scan per hari WIB; chat 5 pertanyaan per scan atau 10 saat Centang Biru aktif; shake-to-quiz 3 klaim per hari.
- Kuis: 10 soal, 15 detik per soal di UI, 3 nyawa, skor tanpa bonus kecepatan; skor dihitung server dengan keterbatasan anti-cheat yang didokumentasikan.
- Kamera adalah jalur UI, bukan bukti kriptografis sumber foto. GPS/heading adalah data perangkat yang tidak dianggap autentik secara mutlak.
- Hash-chain adalah mekanisme tamper-evident terpusat, bukan blockchain terdistribusi.
- Lokasi boleh tidak tersedia; koordinat kosong tidak diganti nol. Posting lokasi default area kasar.
- Scan sementara ditargetkan dihapus setelah 3 hari; metadata scan/chat yang tidak disimpan ditargetkan dihapus/anonymize paling lambat 30 hari.

### Hal yang harus diverifikasi di dunia nyata (bukan alasan untuk mengubah arsitektur tanpa bukti)

1. Rubrik resmi dosen dan ketentuan demonstrasi; bila bertentangan dengan dokumen ini, rubrik resmi yang berlaku dan perubahan harus dicatat.
2. Limit, harga, region, dan ketersediaan aktual paket Gemini, Supabase, Brevo, Midtrans Sandbox, API kurs, geocoding, serta kebijakan penggunaan layanan pada hari implementasi/demo.
3. Versi Flutter/Dart/package yang kompatibel; API package dapat berubah.
4. Sensor kompas/accelerometer, permission, kamera, biometrik, notifikasi, dan ukuran performa pada HP Android fisik yang akan dipakai demo.
5. Nama “Faunova” sebagai nama aplikasi/pengirim tidak dianggap bebas merek dagang hanya karena lolos pencarian awal; lakukan pemeriksaan nama seperlunya sebelum publikasi.
6. Email verifikasi/reset benar-benar sampai ke beberapa provider dan tidak hanya sukses pada log provider.
7. Kebijakan retensi/penghapusan dan penyimpanan transaksi yang berlaku untuk konteks proyek. Jangan membuat klaim kepatuhan hukum tanpa memeriksa aturan yang relevan.

### Rujukan teknis resmi untuk dicek ulang

- Supabase Auth rate limits: https://supabase.com/docs/guides/auth/rate-limits
- Supabase custom SMTP: https://supabase.com/docs/guides/auth/auth-smtp
- Supabase scheduling Edge Functions: https://supabase.com/docs/guides/functions/schedule-functions
- Supabase Cron: https://supabase.com/docs/guides/cron
- Midtrans HTTP notifications dan signature: https://docs.midtrans.com/docs/https-notification-webhooks
- Midtrans handling notifications: https://docs.midtrans.com/reference/handle-notifications
- Gemini API documentation: https://ai.google.dev/gemini-api/docs

**Status final:** dokumen ini adalah baseline desain final yang cukup lengkap untuk mulai membuat ERD/migrations dan mengimplementasikan MVP. “Final” tidak berarti seluruh integrasi telah diuji atau semua fitur sudah berjalan. Perubahan setelah implementasi harus dilakukan berdasarkan rubrik resmi, hasil uji, atau dokumentasi layanan terkini—bukan asumsi—dan dicatat agar dokumen tetap menjadi sumber kebenaran tim.
