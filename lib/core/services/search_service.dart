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
    // 1. Aves (Burung)
    SpeciesCatalogModel(
      speciesName: 'Jalak Bali',
      scientificName: 'Leucopsar rothschildi',
      taxonomyClass: 'Aves',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1552728089-57bdde30beb3?w=600&auto=format&fit=crop&q=80',
      observationsCount: 42,
      description: 'Burung pengicau endemik Pulau Bali bagian barat dengan jambul putih halus dan pelupuk mata biru cerah.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Cenderawasih Kuning-Kecil',
      scientificName: 'Paradisaea minor',
      taxonomyClass: 'Aves',
      conservationStatus: 'Risiko Rendah (LC)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1452570053594-1b985d6ea890?w=600&auto=format&fit=crop&q=80',
      observationsCount: 58,
      description: 'Burung surga berbulu kuning keemasan memukau dengan tarian pamer bulu di kanopi rimba Papua.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Elang Jawa',
      scientificName: 'Nisaetus bartelsi',
      taxonomyClass: 'Aves',
      conservationStatus: 'Terancam (EN)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1611689342806-0863700ce1e4?w=600&auto=format&fit=crop&q=80',
      observationsCount: 31,
      description: 'Inspirasi lambang Garuda Pancasila dengan jambul khas, penguasa rantai makanan hutan pegunungan Jawa.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Kasuari Gelambir Ganda',
      scientificName: 'Casuarius casuarius',
      taxonomyClass: 'Aves',
      conservationStatus: 'Risiko Rendah (LC)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1574063413132-355dbfd83e25?w=600&auto=format&fit=crop&q=80',
      observationsCount: 24,
      description: 'Burung purba tak terbang berbobot besar asal Papua dengan ketopong tanduk pelindung dan cakar kuat.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Rangkong Badak',
      scientificName: 'Buceros rhinoceros',
      taxonomyClass: 'Aves',
      conservationStatus: 'Rentan (VU)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1589656966895-2f33e7653819?w=600&auto=format&fit=crop&q=80',
      observationsCount: 39,
      description: 'Burung berparuh besar dengan cula merah-oranye ke atas, penyebar biji pohon utama di hutan Kalimantan.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Maleo Senkawor',
      scientificName: 'Macrocephalon maleo',
      taxonomyClass: 'Aves',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1548509925-18a7a8d5f396?w=600&auto=format&fit=crop&q=80',
      observationsCount: 17,
      description: 'Burung endemik Sulawesi berkepala tonjolan hitam yang mengubur telurnya di pasir hangat geotermal.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Kakatua Jambul Kuning',
      scientificName: 'Cacatua sulphurea',
      taxonomyClass: 'Aves',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1598439210625-5067c578f3f6?w=600&auto=format&fit=crop&q=80',
      observationsCount: 27,
      description: 'Burung cerdas berbulu putih dengan jambul kuning belerang yang mendiami hutan monsun kepulauan Sunda Kecil.',
    ),

    // 2. Mamalia
    SpeciesCatalogModel(
      speciesName: 'Kucing Kuwuk (Kucing Hutan)',
      scientificName: 'Prionailurus bengalensis',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Risiko Rendah (LC)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600&auto=format&fit=crop&q=80',
      observationsCount: 114,
      description: 'Kucing liar berukuran sedang dengan pola totol khas tutul macan, sangat gesit memanjat dahan.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Harimau Sumatera',
      scientificName: 'Panthera tigris sumatrae',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1561731216-c3a4d99437d5?w=600&auto=format&fit=crop&q=80',
      observationsCount: 88,
      description: 'Subspesies harimau terakhir Indonesia dengan loreng paling rapat dan habitat di hutan hujan tropis Sumatera.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Orangutan Kalimantan',
      scientificName: 'Pongo pygmaeus',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1535083783855-76ae62b2914e?w=600&auto=format&fit=crop&q=80',
      observationsCount: 96,
      description: 'Kera besar arboreal cerdas penjaga kanopi hutan gambut Kalimantan, berambut cokelat kemerahan lebat.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Orangutan Sumatera',
      scientificName: 'Pongo abelii',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1579202673506-ca3ce28943ef?w=600&auto=format&fit=crop&q=80',
      observationsCount: 43,
      description: 'Kera besar arboreal berbulu kemerahan terang, penjaga keseimbangan ekosistem hutan hujan Leuser.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Badak Jawa',
      scientificName: 'Rhinoceros sondaicus',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1575550959106-5a7defe28b56?w=600&auto=format&fit=crop&q=80',
      observationsCount: 12,
      description: 'Mamalia paling langka di bumi bercula satu dengan lipatan kulit menyerupai zirah baja di semenanjung Ujung Kulon.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Gajah Sumatera',
      scientificName: 'Elephas maximus sumatranus',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1557050543-4d5f4e07ef46?w=600&auto=format&fit=crop&q=80',
      observationsCount: 65,
      description: 'Herbivora raksasa penjelajah koridor hutan Way Kambas dan Bukit Barisan Selatan, penyeimbang lanskap rimba.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Bekantan',
      scientificName: 'Nasalis larvatus',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Terancam (EN)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1540573133985-87b6da6d54a9?w=600&auto=format&fit=crop&q=80',
      observationsCount: 53,
      description: 'Monyet berhidung panjang menggantung endemik hutan bakau mangrove dan rawa riparian Kalimantan.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Babirusa Sulawesi',
      scientificName: 'Babyrousa celebensis',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Rentan (VU)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1507668077129-56e32842fceb?w=600&auto=format&fit=crop&q=80',
      observationsCount: 21,
      description: 'Satwa purba Wallacea unik dengan taring atas melengkung menembus moncong menyerupai tanduk rusa.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Anoa Pegunungan',
      scientificName: 'Bubalus quarlesi',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Terancam (EN)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1563281577-a7be47e20db9?w=600&auto=format&fit=crop&q=80',
      observationsCount: 19,
      description: 'Banteng kerdil soliter pemalu yang mendiami hutan primer pegunungan tinggi Pulau Sulawesi.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Rusa Bawean',
      scientificName: 'Axis kuhlii',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1484406566174-9da000fda645?w=600&auto=format&fit=crop&q=80',
      observationsCount: 22,
      description: 'Spesies rusa mungil langka nokturnal yang hanya dapat ditemukan di Pulau Bawean, Laut Jawa.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Tarsius Kerdil',
      scientificName: 'Tarsius pumilus',
      taxonomyClass: 'Mamalia',
      conservationStatus: 'Terancam (EN)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1540573133985-87b6da6d54a9?w=600&auto=format&fit=crop&q=80',
      observationsCount: 34,
      description: 'Primata mungil seukuran kepalan tangan dengan mata bulat besar nokturnal pemangsa serangga malam.',
    ),

    // 3. Reptilia
    SpeciesCatalogModel(
      speciesName: 'Komodo',
      scientificName: 'Varanus komodoensis',
      taxonomyClass: 'Reptilia',
      conservationStatus: 'Terancam (EN)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1544979590-37e9b47eb705?w=600&auto=format&fit=crop&q=80',
      observationsCount: 142,
      description: 'Kadal terbesar di bumi peninggalan zaman purba, hanya hidup di kepulauan savana Nusa Tenggara Timur.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Penyu Hijau',
      scientificName: 'Chelonia mydas',
      taxonomyClass: 'Reptilia',
      conservationStatus: 'Terancam (EN)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600&auto=format&fit=crop&q=80',
      observationsCount: 129,
      description: 'Penyu laut pemakan padang lamun pesisir yang bertelur secara setia di pulau karang terpencil Derawan.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Penyu Sisik',
      scientificName: 'Eretmochelys imbricata',
      taxonomyClass: 'Reptilia',
      conservationStatus: 'Kritis (CR)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1437622368342-7a3d73a34c8f?w=600&auto=format&fit=crop&q=80',
      observationsCount: 48,
      description: 'Penyu perenang terumbu karang tropis dengan paruh tajam melengkung dan karapas sisik tumpang-tindih.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Buaya Muara',
      scientificName: 'Crocodylus porosus',
      taxonomyClass: 'Reptilia',
      conservationStatus: 'Risiko Rendah (LC)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1522069169874-c58ec4b76be5?w=600&auto=format&fit=crop&q=80',
      observationsCount: 72,
      description: 'Reptil perairan muara dan mangrove terbesar dengan kekuatan rahang terkuat di perairan tropis nusantara.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Soa-soa Layar',
      scientificName: 'Hydrosaurus amboinensis',
      taxonomyClass: 'Reptilia',
      conservationStatus: 'Rentan (VU)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1508873696983-2df5293cb325?w=600&auto=format&fit=crop&q=80',
      observationsCount: 36,
      description: 'Kadal semi-akuatik berlayar tinggi di punggung dan ekor, mahir meluncur di atas permukaan air Maluku.',
    ),

    // 4. Amfibi
    SpeciesCatalogModel(
      speciesName: 'Katak Pohon Jawa',
      scientificName: 'Rhacophorus margaritifer',
      taxonomyClass: 'Amfibi',
      conservationStatus: 'Rentan (VU)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1559253664-ca249d4608c6?w=600&auto=format&fit=crop&q=80',
      observationsCount: 29,
      description: 'Katak endemik hutan pegunungan basah Pulau Jawa dengan selaput jari lebar untuk meluncur antar ranting.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Katak Bertanduk Kalimantan',
      scientificName: 'Megophrys nasuta',
      taxonomyClass: 'Amfibi',
      conservationStatus: 'Risiko Rendah (LC)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1579380656108-328e1a8a2d1d?w=600&auto=format&fit=crop&q=80',
      observationsCount: 33,
      description: 'Katak lantai hutan dengan kamuflase sempurna menyerupai serasah daun kering berujung tanduk segitiga.',
    ),

    // 5. Biota Air / Ikan
    SpeciesCatalogModel(
      speciesName: 'Ikan Arwana Super Red',
      scientificName: 'Scleropages formosus',
      taxonomyClass: 'Biota Air',
      conservationStatus: 'Terancam (EN)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1524704654690-b56c05c78a00?w=600&auto=format&fit=crop&q=80',
      observationsCount: 61,
      description: 'Ikan naga air tawar purba endemik perairan Danau Sentarum dan Sungai Kapuas bersisik merah delima menyala.',
    ),
    SpeciesCatalogModel(
      speciesName: 'Pari Manta Karang',
      scientificName: 'Mobula alfredi',
      taxonomyClass: 'Biota Air',
      conservationStatus: 'Rentan (VU)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600&auto=format&fit=crop&q=80',
      observationsCount: 75,
      description: 'Ikan pari raksasa ramah pemakan zooplankton yang melayang anggun di perairan karang Raja Ampat dan Komodo.',
    ),

    // 6. Serangga
    SpeciesCatalogModel(
      speciesName: 'Kupu-kupu Sayap Burung Surga',
      scientificName: 'Ornithoptera paradisea',
      taxonomyClass: 'Serangga',
      conservationStatus: 'Rentan (VU)',
      samplePhotoPath: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=600&auto=format&fit=crop&q=80',
      observationsCount: 47,
      description: 'Kupu-kupu megah endemik hutan rimba Papua dengan sayap hijau zamrud menyala dan ekor meliuk anggun.',
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
        if (a.isVerifiedActive && !b.isVerifiedActive) return -1;
        if (!a.isVerifiedActive && b.isVerifiedActive) return 1;
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
      final serverResults = data.map((item) {
        final parsed = SpeciesCatalogModel.fromJson(Map<String, dynamic>.from(item as Map));
        final curated = _demoSpecies.cast<SpeciesCatalogModel?>().firstWhere(
          (d) => d?.speciesName.toLowerCase() == parsed.speciesName.toLowerCase() ||
                 d?.scientificName.toLowerCase() == parsed.scientificName.toLowerCase(),
          orElse: () => null,
        );
        if (curated != null) {
          return SpeciesCatalogModel(
            speciesName: parsed.speciesName,
            scientificName: parsed.scientificName.isNotEmpty ? parsed.scientificName : curated.scientificName,
            taxonomyClass: curated.taxonomyClass,
            conservationStatus: curated.conservationStatus,
            samplePhotoPath: parsed.samplePhotoPath.isNotEmpty ? parsed.samplePhotoPath : curated.samplePhotoPath,
            observationsCount: parsed.observationsCount,
            description: curated.description,
          );
        }
        return parsed;
      }).toList();

      final existingNames = serverResults.map((s) => s.speciesName.toLowerCase()).toSet();
      final extraCurated = _demoSpecies.where((d) => !existingNames.contains(d.speciesName.toLowerCase()));

      final allResults = [...serverResults, ...extraCurated].where((sp) {
        final matchesQuery = cleanQuery.isEmpty ||
            sp.speciesName.toLowerCase().contains(cleanQuery) ||
            sp.scientificName.toLowerCase().contains(cleanQuery) ||
            sp.description.toLowerCase().contains(cleanQuery);

        final matchesCat = category == 'Semua' ||
            sp.taxonomyClass.toLowerCase().contains(category.toLowerCase().split(' ').first);

        return matchesQuery && matchesCat;
      }).toList();

      return allResults.take(limit).toList();
    } catch (e) {
      debugPrint('SearchService searchSpecies error: $e');
      return _demoSpecies.where((sp) {
        final matchesQuery = cleanQuery.isEmpty ||
            sp.speciesName.toLowerCase().contains(cleanQuery) ||
            sp.scientificName.toLowerCase().contains(cleanQuery) ||
            sp.description.toLowerCase().contains(cleanQuery);
        final matchesCat = category == 'Semua' ||
            sp.taxonomyClass.toLowerCase().contains(category.toLowerCase().split(' ').first);
        return matchesQuery && matchesCat;
      }).toList().take(limit).toList();
    }
  }

}

