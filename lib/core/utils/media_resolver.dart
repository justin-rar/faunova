import 'dart:io';
import '../config/app_config.dart';
import '../services/search_service.dart';

/// Utilitas penyelesaian media terpadu untuk Faunova.
/// Memastikan foto dari akun asli yang tersimpan sebagai path lokal di HP uploader
/// atau storage path tetap dapat dirender secara sempurna di feed perangkat lain.
class MediaResolver {
  MediaResolver._();

  /// Menyelesaikan path foto menjadi URL atau file path yang valid
  static String resolvePhotoUrl(String? rawPath, {String? speciesName, String? category}) {
    if (rawPath == null || rawPath.trim().isEmpty) {
      return SearchService.instance.getCuratedPhotoForSpecies(speciesName, category) ?? '';
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

    // 5. File lokal dari perangkat uploader lain (mis. /data/user/0/.../cache/CAP_xxx.jpg)
    // Selesaikan secara cerdas ke foto kurasi spesies berkualitas tinggi
    final curated = SearchService.instance.getCuratedPhotoForSpecies(speciesName, category);
    if (curated != null && curated.isNotEmpty) {
      return curated;
    }

    return trimmed;
  }
}
