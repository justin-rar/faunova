import 'dart:io';
import '../config/app_config.dart';

/// Utilitas penyelesaian media terpadu untuk Faunova.
/// Memastikan foto observasi diselesaikan secara akurat:
/// - URL internet atau asset aplikasi dirender langsung.
/// - File lokal di perangkat saat ini dirender apa adanya.
/// - Path Supabase Storage (captures/) diselesaikan ke URL publik penyimpanan.
/// - Jika file lokal milik perangkat lain tidak ditemukan di perangkat saat ini,
///   kembalikan string kosong ('') agar antarmuka menampilkan placeholder jujur (Icons.pets_rounded),
///   BUKAN foto kurasi/stok pengganti satwa lain yang salah.
class MediaResolver {
  MediaResolver._();

  /// Menyelesaikan path foto menjadi URL atau file path yang valid
  static String resolvePhotoUrl(String? rawPath, {String? speciesName, String? category}) {
    if (rawPath == null || rawPath.trim().isEmpty) {
      return '';
    }

    final trimmed = rawPath.trim();

    // 1. URL internet valid (dummy post atau storage publik)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // 2. Asset lokal aplikasi
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }

    // 3. File lokal yang benar-benar ada di perangkat saat ini
    try {
      if (File(trimmed).existsSync()) {
        return trimmed;
      }
    } catch (_) {}

    // 4. Path relatif Supabase Storage (mis. captures/{user}/{id}.jpg)
    if (trimmed.startsWith('captures/') || trimmed.startsWith('scans/')) {
      final baseUrl = AppConfig.supabaseUrl;
      return '$baseUrl/storage/v1/object/public/$trimmed';
    }

    // 5. File lokal dari perangkat pengunggah lain yang tidak ada di perangkat ini:
    // Hapus fallback gambar kurasi/stok agar tidak menampilkan satwa yang salah.
    // Kembalikan string kosong sehingga UI merender placeholder jujur.
    return '';
  }
}
