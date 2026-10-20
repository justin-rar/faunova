# Panduan Konfigurasi Brevo SMTP untuk Supabase Auth (Sesi S2)

Dokumen ini memandu konfigurasi SMTP kustom (Brevo) pada Dashboard Supabase agar email verifikasi pendaftaran dan pemulihan kata sandi dapat dikirimkan ke pengguna (Gmail dan Outlook) tanpa batas bawaan dev Supabase.

---

## 1. Dapatkan Kredensial SMTP dari Brevo

1. Buka [Brevo (dahulu Sendinblue)](https://app.brevo.com/) dan masuk ke akun Anda.
2. Di pojok kanan atas, klik **Nama Akun / Profil** -> pilih **SMTP & API**.
3. Di tab **SMTP**, catat informasi berikut:
   - **SMTP Server**: `smtp-relay.brevo.com`
   - **Port**: `587` (direkomendasikan) atau `465`
   - **Login / Username**: *Alamat email akun Brevo Anda*
   - **Master Password**: Klik **Generate a new SMTP key** -> beri nama (misal: `supabase-faunova`) -> salin kuncinya.

> [!IMPORTANT]
> Pastikan email pengirim (*Sender*) di Brevo (menu **Senders & IP**) telah berstatus **Verified**. Gunakan domain atau alamat email yang telah diverifikasi tersebut sebagai Sender di Supabase.

---

## 2. Masukkan ke Dashboard Supabase

1. Buka [Dashboard Supabase](https://supabase.com/dashboard) -> pilih proyek **Faunova**.
2. Masuk ke menu **Authentication** (ikon gembok di kiri) -> klik **Configuration** -> **SMTP Settings**.
3. Aktifkan saklar **Enable Custom SMTP**.
4. Isi data sebagai berikut:
   - **Sender email**: Alamat email yang sudah terverifikasi di Brevo (misal: `no-reply@domainanda.com` atau email akun Brevo Anda).
   - **Sender name**: `Faunova`
   - **Host**: `smtp-relay.brevo.com`
   - **Port number**: `587`
   - **Minimum TLS version**: `TLSv1.2`
   - **Username**: *Login Brevo Anda*
   - **Password**: *SMTP Key Brevo Anda*
5. Klik **Save Changes**.

---

## 3. Atur Template Email di Supabase

1. Di menu **Authentication** -> **Email Templates**:
   - Pilih template **Confirm signup** (Verifikasi pendaftaran):
     - Subjek: `[Faunova] Konfirmasi Pendaftaran Akun Anda`
     - Isi pesan dapat menggunakan bahasa Indonesia yang ramah, menyertakan link: `{{ .ConfirmationURL }}`.
   - Pilih template **Reset password** (Lupa kata sandi):
     - Subjek: `[Faunova] Atur Ulang Kata Sandi Akun Anda`
     - Link pemulihan: `{{ .ConfirmationURL }}`.
2. Klik **Save** pada masing-masing template.

---

## 4. Checklist Pengujian Selesai S2
- [ ] Daftarkan akun baru dengan alamat email **Gmail**.
- [ ] Daftarkan akun baru dengan alamat email **Outlook / Hotmail**.
- [ ] Periksa bahwa email konfirmasi tiba di Kotak Masuk (atau Spam) dalam 1–2 menit.
- [ ] Klik tautan konfirmasi di email.
- [ ] Masuk (Login) berhasil dengan email & kata sandi baru.
- [ ] Coba alur Lupa Password dan pastikan email reset tiba di Gmail/Outlook.
- [ ] Coba tombol Logout di menu pojok kanan atas Profil dan pastikan sesi terhapus.
