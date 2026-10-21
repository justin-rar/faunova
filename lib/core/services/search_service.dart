// ==============================================================================
// FAUNOVA SERVICE: SearchService
// Layanan pencarian akun pengguna dan katalog taksonomi spesies satwa
// Sesuai Plan 5.2, 5.4, 5.7 & AGENTS.md (Sesi S11)
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../features/profile/models/public_profile_model.dart';
import '../../features/search/models/species_catalog_model.dart';

class SearchException implements Exception {
  final String message;
  final String code;

  const SearchException(this.message, {this.code = 'SEARCH_ERROR'});

  @override
  String toString() => message;
}

class SearchService {
  static final SearchService instance = SearchService._internal();
  SearchService._internal();

  SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Data akun kurasi demo untuk pengujian & pencarian luring
  final List<PublicProfileModel> _demoAccounts = [
    PublicProfileModel(
      id: 'acc-bksda',
      username: 'bksda_official',
      displayName: 'Balai Konservasi Sumber Daya Alam',
      avatarPath: null,
      bio: 'Otoritas konservasi keanekaragaman hayati & pengawasan kawasan suaka alam Indonesia.',
      isVerified: true,
      streakCount: 45,
      bestQuizScore: 100,
      capturesCount: 520,
      postsCount: 140,
      followersCount: 1250,
      followingCount: 15,
      isFollowedByMe: false,
      isMyProfile: false,
    ),
    PublicProfileModel(
      id: 'acc-anindya',
      username: 'anindya_vet',
      displayName: 'drh. Anindya Putri',
      avatarPath: null,
      bio: 'Dokter satwa liar & peneliti primata endemik Jawa-Sumatera.',
      isVerified: true,
      streakCount: 30,
      bestQuizScore: 96,
      capturesCount: 84,
      postsCount: 22,
      followersCount: 380,
      followingCount: 65,
      isFollowedByMe: false,
      isMyProfile: false,
    ),
    PublicProfileModel(
      id: 'user-budi',
      username: 'budi_satria',
      displayName: 'Budi Satria Wibowo',
      avatarPath: null,
      bio: 'Pencinta ornitologi & penjelajah hutan tropis Indonesia. Mengamati burung endemik Wallacea.',
      isVerified: true,
      streakCount: 14,
      bestQuizScore: 92,
      capturesCount: 18,
      postsCount: 5,
      followersCount: 142,
      followingCount: 38,
      isFollowedByMe: true,
      isMyProfile: false,
    ),
    PublicProfileModel(
      id: 'user-siti',
      username: 'siti_flora_fauna',
      displayName: 'Siti Rahmawati',
      avatarPath: null,
      bio: 'Pemerhati mamalia karnivora kecil & pegiat konservasi satwa liar Taman Nasional.',
      isVerified: true,
      streakCount: 21,
      bestQuizScore: 98,
      capturesCount: 24,
      postsCount: 8,
      followersCount: 230,
      followingCount: 56,
      isFollowedByMe: false,
      isMyProfile: false,
    ),
    PublicProfileModel(
      id: 'acc-faunawatch',
      username: 'faunawatch_id',
      displayName: 'Fauna Watch Indonesia',
      avatarPath: null,
      bio: 'Komunitas pengamat aves & satwa liar berbasis sains warga.',
      isVerified: true,
      streakCount: 35,
      bestQuizScore: 94,
      capturesCount: 312,
      postsCount: 95,
      followersCount: 850,
      followingCount: 110,
      isFollowedByMe: false,
      isMyProfile: false,
    ),
    PublicProfileModel(
      id: 'user-dewi',
      username: 'dewi_papua',
      displayName: 'Dewi Lestari',
      avatarPath: null,
      bio: 'Pengamat Aves tanah Papua & pegiat edukasi keanekaragaman hayati nusantara.',
      isVerified: false,
      streakCount: 7,
      bestQuizScore: 85,
      capturesCount: 9,
      postsCount: 3,
      followersCount: 88,
      followingCount: 42,
      isFollowedByMe: false,
      isMyProfile: false,
    ),
    PublicProfileModel(
      id: 'acc-farhan',
      username: 'farhan_explorer',
      displayName: 'Farhan Rimba',
      avatarPath: null,
      bio: 'Fotografer satwa liar hutan hujan tropis & pengarsip jejak mamalia.',
      isVerified: false,
      streakCount: 5,
      bestQuizScore: 78,
      capturesCount: 22,
      postsCount: 7,
      followersCount: 65,
      followingCount: 34,
      isFollowedByMe: false,
      isMyProfile: false,
    ),
  ];

  /// Data katalog spesies satwa nusantara kurasi demo
  final List<SpeciesCatalogModel> _demoSpecies = const [
    SpeciesCatalogModel(
      speciesName: 'Jalak Bali',
      scientificName: 'Leucopsar rothschildi',
      taxonomyClass: 'Aves',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'assets/images/jalak_bali.jpg',
      observationsCount: 38,
      description: 'Burung pengicau berbulu putih dengan pelupuk mata biru cerah, endemik Pulau Bali bagian barat.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Kucing Kuwuk (Kucing Hutan)',
      scientificName: 'Prionailurus bengalensis',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Risiko Rendah (LC)',
      samplePhotoPath: 'assets/images/coffee.jpg',
      observationsCount: 114,
      description: 'Kucing liar berukuran sedang dengan pola totol khas tutul macan, sangat gesit memanjat dahan.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Cenderawasih Kuning-Kecil',
      scientificName: 'Paradisaea minor',
      taxonomyClass: 'Aves',
      conservationStatus: 'Risiko Rendah (LC)',
      samplePhotoPath: 'assets/images/butterfly.jpg',
      observationsCount: 52,
      description: 'Burung surga berbulu kuning keemasan memukau dengan tarian pamer bulu di kanopi rimba Papua.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Komodo',
      scientificName: 'Varanus komodoensis',
      taxonomyClass: 'Reptilia',
      conservationStatus: 'Terancam (EN)',
      samplePhotoPath: 'assets/images/komodo.jpg',
      observationsCount: 76,
      description: 'Kadal terbesar di bumi peninggalan zaman purba, hanya hidup di kepulauan Nusa Tenggara Timur.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Orangutan Sumatera',
      scientificName: 'Pongo abelii',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'assets/images/coffee.jpg',
      observationsCount: 43,
      description: 'Kera besar arboreal berbulu cokelat kemerahan, penjaga keseimbangan hutan hujan Leuser.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Katak Pohon Jawa',
      scientificName: 'Rhacophorus margaritifer',
      taxonomyClass: 'Amfibi',
      conservationStatus: 'Rentan (VU)',
      samplePhotoPath: 'assets/images/chessboard.png',
      observationsCount: 29,
      description: 'Katak endemik hutan pegunungan basah Pulau Jawa dengan selaput jari lebar untuk meluncur.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Rusa Bawean',
      scientificName: 'Axis kuhlii',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'assets/images/jalak_bali.jpg',
      observationsCount: 19,
      description: 'Spesies rusa langka berukuran kecil nokturnal yang hanya dapat ditemukan di Pulau Bawean, Jawa Timur.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Penyu Hijau',
      scientificName: 'Chelonia mydas',
      taxonomyClass: 'Reptilia',
      conservationStatus: 'Terancam (EN)',
      samplePhotoPath: 'assets/images/komodo.jpg',
      observationsCount: 64,
      description: 'Penyu laut pemakan lamun pesisir yang bermigrasi ribuan kilometer melintasi samudera nusantara.',
    ),
  ];

  /// Pencarian akun pengguna dengan Aturan Keras Plan 5.4 & 126:
  /// Akun centang biru (isVerified) selalu diprioritaskan di atas
  Future<List<PublicProfileModel>> searchAccounts(String query, {int limit = 20}) async {
    final client = _getSupabaseClient();
    final cleanQuery = query.trim().toLowerCase();

    if (AppConfig.isDemoMode || client == null) {
      final results = _demoAccounts.where((acc) {
        if (cleanQuery.isEmpty) return true;
        return acc.displayName.toLowerCase().contains(cleanQuery) ||
            acc.username.toLowerCase().contains(cleanQuery) ||
            acc.bio.toLowerCase().contains(cleanQuery);
      }).toList();

      // Urutkan: Centang Biru di urutan paling atas!
      results.sort((a, b) {
        if (a.isVerified && !b.isVerified) return -1;
        if (!a.isVerified && b.isVerified) return 1;
        return a.displayName.compareTo(b.displayName);
      });

      return results.take(limit).toList();
    }

    try {
      final response = await client.rpc(
        'search_accounts',
        params: {'p_query': query.trim(), 'p_limit': limit},
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => PublicProfileModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      debugPrint('SearchService searchAccounts error: $e');
      // Fallback ke demo accounts jika server offline
      final results = _demoAccounts.where((acc) {
        if (cleanQuery.isEmpty) return true;
        return acc.displayName.toLowerCase().contains(cleanQuery) ||
            acc.username.toLowerCase().contains(cleanQuery);
      }).toList();
      results.sort((a, b) {
        if (a.isVerified && !b.isVerified) return -1;
        if (!a.isVerified && b.isVerified) return 1;
        return a.displayName.compareTo(b.displayName);
      });
      return results.take(limit).toList();
    }
  }

  /// Pencarian spesies satwa berdasarkan kata kunci dan kelas taksonomi
  Future<List<SpeciesCatalogModel>> searchSpecies(String query, {String category = 'Semua', int limit = 20}) async {
    final client = _getSupabaseClient();
    final cleanQuery = query.trim().toLowerCase();

    if (AppConfig.isDemoMode || client == null) {
      final results = _demoSpecies.where((sp) {
        final matchesQuery = cleanQuery.isEmpty ||
            sp.speciesName.toLowerCase().contains(cleanQuery) ||
            sp.scientificName.toLowerCase().contains(cleanQuery) ||
            sp.description.toLowerCase().contains(cleanQuery);

        final matchesCat = category == 'Semua' ||
            sp.taxonomyClass.toLowerCase().contains(category.toLowerCase().split(' ').first);

        return matchesQuery && matchesCat;
      }).toList();

      return results.take(limit).toList();
    }

    try {
      final response = await client.rpc(
        'search_species',
        params: {
          'p_query': query.trim(),
          'p_category': category,
          'p_limit': limit,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty && _demoSpecies.isNotEmpty) {
        return _demoSpecies.where((sp) {
          final matchesQuery = cleanQuery.isEmpty ||
              sp.speciesName.toLowerCase().contains(cleanQuery) ||
              sp.scientificName.toLowerCase().contains(cleanQuery);
          final matchesCat = category == 'Semua' ||
              sp.taxonomyClass.toLowerCase().contains(category.toLowerCase().split(' ').first);
          return matchesQuery && matchesCat;
        }).toList();
      }

      return data.map((item) => SpeciesCatalogModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      debugPrint('SearchService searchSpecies error: $e');
      return _demoSpecies.where((sp) {
        final matchesQuery = cleanQuery.isEmpty ||
            sp.speciesName.toLowerCase().contains(cleanQuery) ||
            sp.scientificName.toLowerCase().contains(cleanQuery);
        final matchesCat = category == 'Semua' ||
            sp.taxonomyClass.toLowerCase().contains(category.toLowerCase().split(' ').first);
        return matchesQuery && matchesCat;
      }).toList();
    }
  }
}
