---
name: Faunova
description: Jurnal Observasi Lapangan Satwa Terverifikasi & Jejaring Sosial Komunitas
colors:
  primary: "#5C7457"
  secondary: "#8FA28A"
  surface: "#C7D3C0"
  neutral-bg: "#F7F4ED"
  accent: "#C8A96B"
  accent-dark: "#7F6326"
  neutral-text: "#1F2A1E"
  error: "#B3261E"
  text-light: "#FFFFFF"
typography:
  display:
    fontFamily: "Noto Serif, Georgia, serif"
    fontSize: "30px"
    fontWeight: 600
    lineHeight: 1.27
  headline:
    fontFamily: "Noto Serif, Georgia, serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1.27
  subhead:
    fontFamily: "Noto Serif, Georgia, serif"
    fontSize: "15px"
    fontWeight: 400
    fontStyle: "italic"
    lineHeight: 1.47
  title:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.33
  body:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.45
  label:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.23
  caption:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: "11px"
    fontWeight: 500
    lineHeight: 1.27
rounded:
  sm: "6px"
  md: "12px"
  lg: "18px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "14px"
  lg: "16px"
  xl: "24px"
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.neutral-text}"
    rounded: "{rounded.pill}"
    padding: "12px 24px"
  card-observation:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "16px"
---

## Overview

Faunova adalah aplikasi jurnal observasi satwa terverifikasi dan linimasa sosial komunitas. Desain mengadopsi standar kategori *Canon* (The Category Standard), terinspirasi dari iNaturalist dan Seek, mengutamakan integritas ilmiah, kejelasan visual tanpa ornamen artifisial ("anti-slop"), dan kemudahan eksplorasi di lapangan maupun saat bersosialisasi.

Setiap elemen antarmuka berpijak pada palet warna alam organik: sage tua, sage, sage muda, gading, dan aksen emas. Kontras keterbacaan mematuhi aturan tegas AGENTS.md, memastikan kenyamanan visual dan aksesibilitas tinggi.

## Colors

Palet warna resmi Faunova diturunkan langsung dari spesifikasi ketat proyek:

- **Sage Tua (`#5C7457`)**: Warna primer aplikasi. Digunakan pada header solid (AppBar), ikon aktif navigasi, dan tombol terpilih.
- **Sage (`#8FA28A`)**: Warna sekunder. Digunakan untuk ikon non-aktif, garis pembatas lembut, dan teks keterangan sekunder.
- **Sage Muda (`#C7D3C0`)**: Warna kontainer kartu observasi satwa dan panel konten utama.
- **Gading (`#F7F4ED`)**: Warna latar belakang utama seluruh layar aplikasi.
- **Emas (`#C8A96B`)**: Warna aksen tombol aksi utama (CTA / bidik kamera / konfirmasi) dan pill lencana terverifikasi.
- **Emas Tua (`#7F6326`)**: Digunakan untuk teks beraksen emas di atas latar terang agar rasio kontras WCAG terpenuhi.
- **Teks Gelap (`#1F2A1E`)**: Warna teks primer pada seluruh latar gading, sage muda, sage, dan emas.
- **Merah Status (`#B3261E`)**: Warna indikator galat, penolakan verifikasi AI, dan peringatan bahaya.
- **Teks Putih (`#FFFFFF`)**: HANYA digunakan di atas latar Sage Tua (`#5C7457`).

## Typography

Faunova memadukan dua keluarga huruf untuk memisahkan ranah ilmiah taksonomi dengan ranah operasional antarmuka:

- **Noto Serif**: Digunakan khusus untuk nama satwa, judul taksonomi, dan nama latin ilmiah (*italic binomial nomenclature*). Memberikan bobot kredibilitas buku lapangan dan publikasi ilmiah.
- **Plus Jakarta Sans**: Digunakan untuk seluruh elemen antarmuka pengguna (UI), header, tombol, label status, metadata observasi, dan teks tubuh. Menyediakan keterbacaan instan yang tajam pada layar perangkat genggam.

## Layout

- **Margin & Padding Halaman**: Standar 16px horizontal untuk layar ponsel.
- **Padding Kartu**: 14–16px internal padding dengan pemisah vertikal antar-kartu 14–16px.
- **Scroll Physics**: `ClampingScrollPhysics` di seluruh halaman untuk interaksi scroll yang solid dan bebas overscroll aneh.
- **Solid Surfaces**: Seluruh header (AppBar), kartu postingan, dan panel lembar geser (BottomSheet) memakai warna latar solid tanpa transparansi palsu. Efek kaca (blur/frosted glassmorphism) secara eksklusif hanya diperbolehkan pada bilah navigasi bawah (`GlassBottomBar`).

## Elevation & Depth

- **Tonal Layering**: Pemisahan hierarki visual dicapai melalui kontras warna bidang (Gading $\rightarrow$ Sage Muda $\rightarrow$ Putih Bersih), bukan tumpukan drop shadow tebal.
- **Subtle Elevation**: Bayangan lembut `BoxShadow(color: #1F2A1E.withOpacity(0.06), blurRadius: 14, offset: (0, 4))` digunakan pada kartu observasi untuk memberi batas fisik tanpa kesan mengambang berlebih.
- **Garis Batas (Border)**: `1px` border berona `AppColors.sage.withOpacity(0.40)` mempertegas tepi kartu pada latar gading.

## Shapes

- **Radius Kartu**: 18px (`rounded.lg`) pada kartu observasi lapangan, menciptakan karakter modern yang ramah namun presisi.
- **Radius Tombol**: Kapsul penuh (`rounded.pill` / 999px) pada tombol aksi utama dan chip taksonomi.
- **Radius Kontainer Sub-Elemen**: 10–12px (`rounded.md`) pada kotak info koordinat grid, blok hash audit, dan preview foto.

## Components

### Buttons
- **Shape:** Kapsul penuh (pill / 999px).
- **Primary:** Latar Emas (`#C8A96B`), teks gelap (`#1F2A1E`), font Plus Jakarta Sans semi-bold 14px.
- **Secondary / Ghost:** Latar transparan atau sage lembut dengan outline 1.2px dan teks gelap.

### Chips & Taxon Badges
- **Status Konservasi IUCN:** Pill kompak (CR / EN / VU / NT / LC) dengan palet kode status internasional.
- **Blok Hash Kriptografis:** Pill berlatar `#FFFFFF` dengan ikon rantai terverifikasi dan `#seq` kanonis.
- **Taksonomi:** Pill horizontal dengan border halus dan teks ringkas.

### Cards (Jurnal Lapangan / PostCard)
- **Corner Style:** Radius 18px dengan clip hard-edge.
- **Background:** Sage muda (`#C7D3C0`).
- **Internal Sections:** Banner taksonomi atas $\rightarrow$ Foto spesimen rasio lapangan $\rightarrow$ Nama ilmiah & deskripsi $\rightarrow$ Baris pengamat $\rightarrow$ Baris audit hash-chain & interaksi sosial.

### Navigation (Bottom Bar)
- **GlassBottomBar:** Desain floating bar dengan latar tembus pandang blur frosted glass `ImageFilter.blur(sigmaX: 25, sigmaY: 25)`.
- **Sliding Pill Indicator:** Kapsul putih glossy yang meluncur fisik dengan kurva halus saat berpindah antar 5 tab (Beranda, Cari, Kamera, Game, Profil).

## Do's and Don'ts

### Do:
- **Do** gunakan teks gelap (`#1F2A1E`) di atas sage, sage muda, gading, dan emas.
- **Do** gunakan teks putih (`#FFFFFF`) HANYA di atas sage tua (`#5C7457`).
- **Do** tampilkan koordinat publik dalam format grid-snapped kasar (privasi lapangan terjaga).
- **Do** selalu tangani 4 state: loading, empty, error, dan offline di setiap fitur.
- **Do** jaga seluruh teks antarmuka dalam bahasa Indonesia yang baku dan komunikatif.

### Don't:
- **Don't** gunakan efek blur/kaca pada AppBar, kartu, atau modal dialog. Blur HANYA untuk GlassBottomBar.
- **Don't** gunakan gradien pelangi artifisial ("AI slop") atau efek glow berlebihan.
- **Don't** tempatkan koordinat GPS mentah desimal presisi tinggi pada tampilan publik linimasa.
- **Don't** mengubah aturan verifikasi hash SHA-256 pada observasi satwa.
