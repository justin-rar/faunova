# BAB PENGUJIAN SISTEM: LAPORAN PENGUJIAN BLACK BOX
## Proyek Akhir: Faunova — Jurnal Sosial Satwa & Buku Besar Kriptografis
**Mata Kuliah:** Teori Pemrograman Aplikasi Mobile (PAM) — Semester 5  
**Tim Pengembang:**
1. Daniel Roby Maldini (NIM: 124240044)
2. Kanza Widi Bagaskara (NIM: 124240059)
3. Justin (NIM: 124240074)

---

## 1. Metodologi & Lingkungan Pengujian

Pengujian sistem pada aplikasi **Faunova** dilakukan menggunakan metode **Black Box Testing** (berfokus pada fungsionalitas antarmuka dan keluaran sistem tanpa mengamati struktur internal kode). Teknik pengujian mencakup *Equivalence Partitioning* dan *Boundary Value Analysis* untuk memastikan validasi input, responsivitas sensor fisik, pemrosesan AI, transaksi pembayaran, serta alur bisnis server berjalan tepat.

### Lingkungan Pengujian:
* **Perangkat Fisik Pengujian:** Samsung Galaxy M31 (Android 12 / One UI Core 4.1)
* **Framework:** Flutter SDK (Channel stable)
* **Backend & Database:** Supabase PostgreSQL, GoTrue Auth, Storage Bucket, Edge Functions (Deno)
* **Layanan Eksternal:** Google Gemini 1.5 Flash Vision AI, Midtrans Payment Sandbox
* **Total Kasus Uji:** 35 Test Cases
* **Hasil Keseluruhan:** 35 Valid (Tingkat Keberhasilan 100%)

---

## 2. Tabel Rincian Pengujian Black Box

### Modul 1: Autentikasi Pengguna & Keamanan Biometrik (Auth & Security)

| ID Uji | Fitur / Skenario Pengujian | Data Masukan (Test Case / Input) | Hasil yang Diharapkan | Hasil Pengujian Nyata | Status |
|:---:|---|---|---|---|:---:|
| **TC-01** | Validasi pendaftaran email kosong & format salah | Email: `danielrobikeren`, Sandi: `12345678` | Sistem menampilkan pesan kesalahan format email tidak valid | Pesan validasi email tidak valid muncul di bawah kolom teks | **Valid** |
| **TC-02** | Validasi konfirmasi kata sandi tidak cocok | Sandi: `Password123!`, Konfirmasi: `PasswordBerbeda!` | Sistem menolak proses daftar dan memberi tanda sandi tidak cocok | Muncul peringatan *“Konfirmasi kata sandi tidak cocok”* | **Valid** |
| **TC-03** | Pendaftaran akun baru (*Register*) | Nama: `Daniel`, Email valid, Sandi valid $\ge$ 8 karakter | Akun berhasil didaftarkan ke Supabase Auth dan diarahkan ke beranda | Akun terdaftar di database dan otomatis masuk ke linimasa | **Valid** |
| **TC-04** | Masuk akun dengan kata sandi salah (*Login Fail*) | Email: `gustinmr7@gmail.com`, Sandi: `SalahTotal123` | Sistem menolak masuk dan menampilkan dialog peringatan | Muncul snackbar error *“Email atau kata sandi tidak sesuai”* | **Valid** |
| **TC-05** | Masuk akun dengan data valid (*Login Success*) | Email & sandi terdaftar yang benar | Autentikasi berhasil, token JWT tersimpan, masuk ke beranda | Pengguna berhasil diarahkan ke beranda dengan sesi tersimpan | **Valid** |
| **TC-06** | Akses cepat Mode Demo (*Guest / Offline Mode*) | Mengetuk tombol *“Mode Demo (Jelajah Cepat)”* | Masuk langsung ke aplikasi menggunakan data mock tanpa internet | Masuk ke beranda dengan data satwa demo lokal tanpa error | **Valid** |
| **TC-07** | Alur Lupa Kata Sandi (*Forgot Password Step 1*) | Masukkan email terdaftar lalu klik *Kirim OTP* | Kode OTP terkirim melalui Brevo SMTP dan form OTP terbuka | Email OTP terkirim dan form verifikasi 6 digit aktif | **Valid** |
| **TC-08** | Verifikasi OTP & Reset Sandi (*Forgot Password Step 2*) | Input kode OTP yang benar dan input sandi baru | Sandi berhasil diperbarui di server dan pengguna diarahkan login | Sandi akun ter-update dan berhasil login dengan sandi baru | **Valid** |
| **TC-09** | Kunci Aplikasi Biometrik (*Fingerprint / Face ID*) | Mengaktifkan App Lock lalu membuka kembali aplikasi | Layar terkunci dan memunculkan dialog sensor biometrik HP | Sensor sidik jari merespons dan membuka aplikasi seketika | **Valid** |
| **TC-10** | Fallback Sandi saat Biometrik Gagal/Dibatalkan | Mengetuk opsi *“Gunakan Kata Sandi”* pada layar kunci | Memunculkan kolom sandi akun sebagai alternatif biometrik | Berhasil membuka kunci aplikasi setelah memasukkan kata sandi | **Valid** |

---

### Modul 2: Beranda Sosial & Linimasa Observasi Satwa (Social Feed)

| ID Uji | Fitur / Skenario Pengujian | Data Masukan (Test Case / Input) | Hasil yang Diharapkan | Hasil Pengujian Nyata | Status |
|:---:|---|---|---|---|:---:|
| **TC-11** | Tampilan Linimasa "Untuk Kamu" | Membuka tab Beranda pertama kali | Menampilkan kartu jurnal observasi satwa lengkap dengan foto & status | Kartu satwa termuat rapi, foto jelas, IUCN badge & waktu tampil | **Valid** |
| **TC-12** | Perlindungan Privasi Lokasi Satwa (Grid Snapping) | Memeriksa koordinat lokasi satwa pada kartu postingan | Koordinat presisi tidak muncul ke publik, hanya grid 0.01° | Tampilan lokasi menunjukkan nama area dan grid aman 0.01° | **Valid** |
| **TC-13** | Interaksi Menyukai Postingan (*Like Post*) | Mengetuk ikon hati pada postingan satwa | Ikon hati berubah warna emas, jumlah suka bertambah +1 | Jumlah suka bertambah 1 dan status tersimpan di server | **Valid** |
| **TC-14** | Pembatalan Suka (*Unlike Post*) | Mengetuk kembali ikon hati yang sudah aktif | Ikon hati kembali normal, jumlah suka berkurang 1 | Jumlah suka berkurang 1 secara idempoten | **Valid** |
| **TC-15** | Pengiriman Komentar Satwa | Mengetik komentar: *“Keren sekali observasinya!”* | Komentar baru muncul seketika di bagian paling bawah daftar | Komentar langsung ter-render dengan nama pengirim dan waktu | **Valid** |
| **TC-16** | Pembuktian Integritas Kriptografi (*Verify Chain*) | Mengetuk tombol *“Verifikasi Rantai”* pada kartu postingan | Dialog modal memverifikasi SHA-256 (`photo_hash`, `prev_hash`) | Dialog menampilkan status *“Valid (Rantai Utuh Kriptografi)”* | **Valid** |
| **TC-17** | Pelaporan Konten (*Report Post*) | Ketuk menu `...` -> Pilih alasan: *Bukan Satwa Liar* | Sistem mencatat laporan ke server dan memberi konfirmasi | Muncul pesan *“Laporan berhasil dikirim untuk ditinjau”* | **Valid** |

---

### Modul 3: Penjelajahan & Pencarian Satwa (Search & Explore)

| ID Uji | Fitur / Skenario Pengujian | Data Masukan (Test Case / Input) | Hasil yang Diharapkan | Hasil Pengujian Nyata | Status |
|:---:|---|---|---|---|:---:|
| **TC-18** | Pencarian Nama Satwa Spesifik | Kata kunci: *“Jalak”* pada kolom pencarian | Menampilkan spesies Jalak Bali dan postingan terkait | Daftar hasil pencarian hanya menampilkan satwa bertema Jalak | **Valid** |
| **TC-19** | Filter Kategori Taksonomi Satwa | Memilih chip filter: *“Aves”* | Menampilkan satwa yang tergolong dalam kelas burung/Aves | Seluruh satwa berlabel non-Aves disaring keluar dari daftar | **Valid** |
| **TC-20** | Prioritas Pencarian Akun Centang Biru | Mencari nama akun pengguna di tab jelajah | Akun yang berlangganan Centang Biru muncul di posisi paling atas | Akun terverifikasi (`verified_until` aktif) menempati ranking atas | **Valid** |

---

### Modul 4: Kamera Pengamatan Lapangan & AI Vision (Camera & AI)

| ID Uji | Fitur / Skenario Pengujian | Data Masukan (Test Case / Input) | Hasil yang Diharapkan | Hasil Pengujian Nyata | Status |
|:---:|---|---|---|---|:---:|
| **TC-21** | Tampilan HUD Viewfinder Kamera | Membuka tab tengah (Kamera) | Menampilkan bidikan optik, pita kompas aktif, status GPS | Crosshair, indikator live heading kompas, dan GPS aktif tampil | **Valid** |
| **TC-22** | Identifikasi Satwa Liar Otomatis (Gemini AI) | Memotret foto hewan (misal burung atau kucing) | AI mengembalikan nama taksonomi, nama ilmiah, dan status IUCN | Hasil identifikasi AI menampilkan nama spesies lengkap dan akurat | **Valid** |
| **TC-23** | Proteksi Anti-Spam Benda Mati | Memotret benda bukan hewan (misal meja, botol, buku) | Sistem menolak simpan dan memberi peringatan bukan fauna | Muncul pesan bahwa objek bukan hewan dan ditolak masuk feed | **Valid** |
| **TC-24** | Chatbot Tanya-Jawab Satwa (Multi-Turn Chat) | Mengetik: *“Apa makanan utama hewan ini di alam?”* | AI membalas dengan penjelasan biologis sesuai satwa tersebut | AI merespons dalam bahasa Indonesia dengan fakta biologi tepat | **Valid** |
| **TC-25** | Pembatasan Kuota Pertanyaan AI | Mengirim pertanyaan hingga melampaui kuota (5x reguler) | Sistem menghentikan pengiriman dan menampilkan sisa kuota 0 | Kuota berkurang tiap chat; saat habis muncul opsi upgrade | **Valid** |

---

### Modul 5: Gamifikasi, Sensor Fisik, & Kuis (Game Arena)

| ID Uji | Fitur / Skenario Pengujian | Data Masukan (Test Case / Input) | Hasil yang Diharapkan | Hasil Pengujian Nyata | Status |
|:---:|---|---|---|---|:---:|
| **TC-26** | Klaim Streak Observasi Harian | Mengetuk tombol check-in harian pada tab Game | Streak bertambah +1 hari dan tombol nonaktif untuk hari ini | Streak bertambah dan klaim berulang di hari yang sama ditolak | **Valid** |
| **TC-27** | Sensor Guncang HP (*Shake-to-Quiz*) | Menggoyangkan perangkat fisik HP (Accelerometer) | Terdeteksi guncangan $\ge$ threshold dan pop-up kuis muncul | Pop-up kuis kejutan langsung terbuka saat HP digoyang | **Valid** |
| **TC-28** | Batas Kuota Harian Shake-to-Quiz | Melakukan shake kuis sebanyak 3 kali berturut-turut | Kuota shake habis (3/3) dan guncangan ke-4 menampilkan pesan kuota | Sistem memberi info kuota shake hari ini telah habis | **Valid** |
| **TC-29** | Sesi Arena Kuis 10 Soal Biologi | Memilih salah satu jawaban kuis biologi satwa | Timer berjalan mundur; jawaban diverifikasi di server | Jawaban benar menambah skor & kombo; jawaban salah mengurangi hati | **Valid** |
| **TC-30** | Dialog Perayaan Pembukaan Lencana (**SS-28**) | Akun meraih skor $\ge$ 1000 atau streak $\ge$ 7 hari | Muncul modal dialog animasi berlatar emas ucapan selamat lencana | Pop-up *"Lencana Baru Terbuka! 🎉"* tampil dengan ikon emas | **Valid** |

---

### Modul 6: Profil Kolektor, Peta, & 4 Zona Waktu (Profile & Tools)

| ID Uji | Fitur / Skenario Pengujian | Data Masukan (Test Case / Input) | Hasil yang Diharapkan | Hasil Pengujian Nyata | Status |
|:---:|---|---|---|---|:---:|
| **TC-31** | Kartu Konversi 4 Zona Waktu Lapangan | Membuka tab Profil | Menampilkan jam real-time sinkron untuk WIB, WITA, WIT, dan GMT | Jam berdetik akurat dengan selisih zona waktu tertera jelas | **Valid** |
| **TC-32** | Peta Persebaran Satwa (OpenStreetMap) | Mengetuk ikon Peta Sebaran pada profil koleksi | Peta interaktif merender titik marker lokasi observasi satwa | Peta OSM terbuka mulus dengan pin koordinat hasil observasi | **Valid** |
| **TC-33** | Tempat Sampah & Pemulihan Data (*Trash*) | Memindahkan 1 tangkapan ke Trash lalu klik *Pulihkan* | Tangkapan tersembunyi dari feed, lalu kembali tampil saat dipulihkan | Data berhasil di-trash dan saat di-restore muncul kembali ke grid | **Valid** |

---

### Modul 7: Transaksi Pembayaran Midtrans & Halaman Tim (Payment & About)

| ID Uji | Fitur / Skenario Pengujian | Data Masukan (Test Case / Input) | Hasil yang Diharapkan | Hasil Pengujian Nyata | Status |
|:---:|---|---|---|---|:---:|
| **TC-34** | Pembayaran Midtrans Centang Biru (Sandbox) | Klik *Upgrade* -> Pilih bayar -> Selesaikan simulasi Snap | Transaksi berstatus sukses (*settlement*) dan badge biru aktif 30 hari | Lencana Centang Biru aktif di profil dan masa aktif bertambah 30 hari | **Valid** |
| **TC-35** | Layar Saran & Kesan Kuliah PAM | Menu profil `...` -> Pilih *Saran & Kesan Kuliah PAM* | Menampilkan profil 3 anggota tim, NIM, dan pesan kesan kuliah | Nama Daniel, Kanza (NIM: 124240059), Justin tampil rapi | **Valid** |

---

## 3. Rekapitulasi Hasil Pengujian

Berdasarkan seluruh pengujian fungsionalitas yang telah dijalankan pada 7 modul utama sistem:

$$\text{Persentase Keberhasilan} = \left( \frac{\text{Jumlah Kasus Uji Valid}}{\text{Total Kasus Uji}} \right) \times 100\% = \left( \frac{35}{35} \right) \times 100\% = 100\%$$

* **Total Skenario Uji:** 35 Kasus Uji (*Test Cases*)
* **Jumlah Skenario Valid:** 35 Kasus Uji
* **Jumlah Skenario Gagal:** 0 Kasus Uji
* **Analisis Otomatis (`flutter test`):** 216 unit dan widget tests lulus (*100% Passed*).
* **Analisis Kode (`flutter analyze`):** 0 issues (bersih dari warning dan error).

---

## 4. Kesimpulan Pengujian

1. Seluruh fungsi inti aplikasi **Faunova** (Autentikasi, Jurnal Sosial Kriptografi, Sensor Perangkat Keras, Gamifikasi Kuis, AI Vision, Pembayaran Midtrans, serta Konversi 4 Zona Waktu) telah diuji dan terbukti bekerja sesuai spesifikasi kebutuhan.
2. Mekanisme keamanan arsitektur (aturan bisnis di server, perlindungan privasi satwa dengan grid 0.01°, penyimpanan lokal Hive terenkripsi AES-256, dan RLS Supabase) berhasil menangani skenario input tidak valid dan kondisi offline secara stabil tanpa mengalami crash.
3. Aplikasi dinyatakan **Valid, Andal, dan Siap Digunakan (Production / Demo Ready)** untuk evaluasi proyek akhir mata kuliah Teori Pemrograman Aplikasi Mobile.
