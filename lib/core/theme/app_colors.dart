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
}
