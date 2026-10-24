import 'package:flutter/material.dart';

/// Palet warna resmi Faunova sesuai dengan aturan AGENTS.md:
/// - sage tua #5C7457 (header, ikon aktif)
/// - sage #8FA28A
/// - sage muda #C7D3C0 (kartu)
/// - gading #F7F4ED (latar)
/// - emas #C8A96B (tombol utama)
/// - emas tua #7F6326 (teks beraksen emas)
/// - teks gelap #1F2A1E
/// - merah status #B3261E
/// 
/// Aturan kontras:
/// - Teks di atas sage, sage muda, gading, dan emas memakai teks gelap.
/// - Teks putih hanya di atas sage tua.
/// - Efek kaca (blur) hanya di bottom bar penuh. Header, kartu, dan panel lain memakai warna solid.
class AppColors {
  AppColors._();

  /// Sage tua #5C7457 (header solid, ikon aktif, tombol terpilih)
  static const Color sageTua = Color(0xFF5C7457);

  /// Sage #8FA28A (elemen sekunder, ikon tidak aktif)
  static const Color sage = Color(0xFF8FA28A);

  /// Sage muda #C7D3C0 (kartu solid, container konten)
  static const Color sageMuda = Color(0xFFC7D3C0);

  /// Gading #F7F4ED (latar belakang utama aplikasi)
  static const Color gading = Color(0xFFF7F4ED);

  /// Emas #C8A96B (tombol aksi utama / primary action)
  static const Color emas = Color(0xFFC8A96B);

  /// Emas tua #7F6326 (teks beraksen emas)
  static const Color emasTua = Color(0xFF7F6326);

  /// Teks gelap #1F2A1E (warna teks default pada latar gading, sage muda, sage, dan emas)
  static const Color teksGelap = Color(0xFF1F2A1E);

  /// Merah status #B3261E (status error, peringatan galat, penolakan)
  static const Color merahStatus = Color(0xFFB3261E);

  /// Teks putih #FFFFFF (HANYA diperbolehkan di atas sage tua)
  static const Color teksPutih = Color(0xFFFFFFFF);

  // ==========================================
  // SEMANTIC SURFACE & CONTAINER (Stitch System)
  // ==========================================

  /// Putih solid untuk kartu konten utama (#FFFFFF)
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Kontainer bernuansa gading sangat lembut (#F6F3EC)
  static const Color surfaceContainerLow = Color(0xFFF6F3EC);

  /// Kontainer default (#F0EEE7)
  static const Color surfaceContainer = Color(0xFFF0EEE7);

  /// Kontainer beraksen sedikit lebih kontras (#EBE8E1)
  static const Color surfaceContainerHigh = Color(0xFFEBE8E1);

  /// Kontainer beraksen garis pemisah / border (#E5E2DB)
  static const Color surfaceContainerHighest = Color(0xFFE5E2DB);

  /// Garis tepi lembut / border tipis 1px (#C3C8BE)
  static const Color outlineVariant = Color(0xFFC3C8BE);

  /// Teks sekunder / deskripsi bernuansa natural (#434841)
  static const Color onSurfaceVariant = Color(0xFF434841);

  /// Kontainer pesan bahaya / chip peringatan (#FFDAD6)
  static const Color errorContainer = Color(0xFFFFDAD6);

  /// Teks pada kontainer pesan bahaya (#93000A)
  static const Color onErrorContainer = Color(0xFF93000A);

  /// Chip kepastian AI / taksonomi fixed (#D4E8CE)
  static const Color tertiaryFixed = Color(0xFFD4E8CE);

  /// Teks chip kepastian AI (#101F0F)
  static const Color onTertiaryFixed = Color(0xFF101F0F);

  /// Kontainer aksen sekunder / badge lencana (#FEDB99)
  static const Color secondaryContainer = Color(0xFFFEDB99);

  /// Teks pada kontainer aksen sekunder (#261A00)
  static const Color onSecondaryFixed = Color(0xFF261A00);
}
