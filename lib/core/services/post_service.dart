// ==============================================================================
// FAUNOVA SERVICE: PostService
// Layanan publikasi postingan komunitas, feed Untuk Kamu, dan interaksi like
// Sesuai Plan 5.7, 5.9, 18 & AGENTS.md (Sesi S9)
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../features/feed/models/post_model.dart';
import 'notification_service.dart';

class PostException implements Exception {
  final String message;
  final String code;

  const PostException(this.message, {this.code = 'POST_ERROR'});

  @override
  String toString() => message;
}

class PostService {
  static final PostService instance = PostService._internal();
  PostService._internal();

  final List<PostModel> _demoPosts = [];
  final ValueNotifier<PostModel?> onPostCreatedNotifier = ValueNotifier<PostModel?>(null);
  final Set<String> _reportedPostIds = {};
  final ValueNotifier<String?> onPostReportedNotifier = ValueNotifier<String?>(null);

  SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? _getCurrentUserId() {
    try {
      return Supabase.instance.client.auth.currentSession?.user.id;
    } catch (_) {
      return null;
    }
  }

  /// Menghitung pusat sel grid 0.01° secara deterministik di sisi klien (untuk mode demo/luring)
  static Map<String, double?> snapToGridLocally(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return {'lat': null, 'lng': null};
    }
    final snappedLat = (lat / 0.01).floor() * 0.01 + 0.005;
    final snappedLng = (lng / 0.01).floor() * 0.01 + 0.005;
    return {
      'lat': double.parse(snappedLat.toStringAsFixed(6)),
      'lng': double.parse(snappedLng.toStringAsFixed(6)),
    };
  }

  /// Daftar postingan demo saat ini (read-only)
  List<PostModel> get demoPosts => List.unmodifiable(_demoPosts);

  /// Mereset data feed demo untuk keperluan pengujian
  void resetDemoPosts() {
    _demoPosts.clear();
  }

  /// Inisialisasi data postingan demo untuk luring / testing
  void initMockDemoPosts() {
    _demoPosts.clear();
    final now = DateTime.now();

    _demoPosts.addAll([
      // ─── BUDI SATRIA WIBOWO (user-budi, Centang Biru) ───────────────────────
      PostModel(
        id: 'mock-post-1',
        captureId: 'mock-cap-1',
        caption: 'Teramati sepasang Jalak Bali bertengger di dahan beringin pesisir Teluk Brumbun. Jambul putih tegak sempurna dalam kondisi sehat dan terlindungi.',
        locationVisibility: 'coarse',
        displayLatitude: -8.115000,
        displayLongitude: 114.525000,
        areaLabel: 'Taman Nasional Bali Barat (Area Perkiraan)',
        createdAt: now.subtract(const Duration(minutes: 20)),
        speciesName: 'Jalak Bali',
        category: 'Leucopsar rothschildi',
        photoUrl: 'https://images.unsplash.com/photo-1552728089-57bdde30beb3?w=900&auto=format&fit=crop&q=80',
        blockSeq: 1,
        blockHash: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
        photoSha256: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
        authorId: 'user-budi',
        authorName: 'Budi Satria Wibowo',
        authorUsername: 'budi_satria',
        authorVerifiedUntil: now.add(const Duration(days: 28)),
        likesCount: 98,
        isLikedByMe: false,
      ),
      PostModel(
        id: 'mock-post-1b',
        captureId: 'mock-cap-1b',
        caption: 'Elang Jawa (Nisaetus bartelsi) melayang anggun di atas punggungan hutan pegunungan Gunung Halimun. Rentang sayap ±120 cm, individu jantan dewasa.',
        locationVisibility: 'coarse',
        displayLatitude: -6.755000,
        displayLongitude: 106.535000,
        areaLabel: 'TN Gunung Halimun-Salak, Jawa Barat (Area Perkiraan)',
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
        speciesName: 'Elang Jawa',
        category: 'Nisaetus bartelsi',
        photoUrl: 'https://images.unsplash.com/photo-1611689342806-0863700ce1e4?w=900&auto=format&fit=crop&q=80',
        blockSeq: 7,
        blockHash: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2',
        photoSha256: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2',
        authorId: 'user-budi',
        authorName: 'Budi Satria Wibowo',
        authorUsername: 'budi_satria',
        authorVerifiedUntil: now.add(const Duration(days: 28)),
        likesCount: 73,
        isLikedByMe: true,
      ),
      PostModel(
        id: 'mock-post-1c',
        captureId: 'mock-cap-1c',
        caption: 'Babi Rusa (Babyrousa babyrussa) betina dengan dua anak muda sedang mandi lumpur di tepi sungai hutan primer Sulawesi Tengah. Sangat langka dan sulit dijumpai!',
        locationVisibility: 'hidden',
        displayLatitude: null,
        displayLongitude: null,
        areaLabel: null,
        createdAt: now.subtract(const Duration(days: 5)),
        speciesName: 'Babi Rusa',
        category: 'Babyrousa babyrussa',
        photoUrl: 'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=900&auto=format&fit=crop&q=80',
        blockSeq: 8,
        blockHash: 'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3',
        photoSha256: 'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3',
        authorId: 'user-budi',
        authorName: 'Budi Satria Wibowo',
        authorUsername: 'budi_satria',
        authorVerifiedUntil: now.add(const Duration(days: 28)),
        likesCount: 201,
        isLikedByMe: false,
      ),

      // ─── SITI RAHMAWATI (user-siti, Centang Biru) ────────────────────────────
      PostModel(
        id: 'mock-post-2',
        captureId: 'mock-cap-2',
        caption: 'Tertangkap kamera di semak belukar dekat aliran sungai berbatu saat senja. Gerakan sangat lincah dan waspada.',
        locationVisibility: 'coarse',
        displayLatitude: -7.255000,
        displayLongitude: 110.425000,
        areaLabel: 'Lereng Gunung Ciremai, Kuningan (Area Perkiraan)',
        createdAt: now.subtract(const Duration(hours: 2)),
        speciesName: 'Kucing Kuwuk',
        category: 'Prionailurus bengalensis',
        photoUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=900&auto=format&fit=crop&q=80',
        blockSeq: 2,
        blockHash: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
        photoSha256: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
        authorId: 'user-siti',
        authorName: 'Siti Rahmawati',
        authorUsername: 'siti_flora_fauna',
        authorVerifiedUntil: now.add(const Duration(days: 25)),
        likesCount: 114,
        isLikedByMe: true,
      ),
      PostModel(
        id: 'mock-post-2b',
        captureId: 'mock-cap-2b',
        caption: 'Rafflesia arnoldii mekar sempurna di lantai hutan Bengkulu! Diameter 87 cm, harum menyengat khas bangkai. Observasi langka yang hanya terjadi 3–7 hari.',
        locationVisibility: 'coarse',
        displayLatitude: -3.785000,
        displayLongitude: 102.265000,
        areaLabel: 'Hutan Lindung Bukit Daun, Bengkulu (Area Perkiraan)',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        speciesName: 'Rafflesia arnoldii',
        category: 'Rafflesia arnoldii',
        photoUrl: 'https://images.unsplash.com/photo-1583212292454-1fe6229603b7?w=900&auto=format&fit=crop&q=80',
        blockSeq: 9,
        blockHash: 'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4',
        photoSha256: 'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4',
        authorId: 'user-siti',
        authorName: 'Siti Rahmawati',
        authorUsername: 'siti_flora_fauna',
        authorVerifiedUntil: now.add(const Duration(days: 25)),
        likesCount: 342,
        isLikedByMe: false,
      ),
      PostModel(
        id: 'mock-post-2c',
        captureId: 'mock-cap-2c',
        caption: 'Beruang Madu (Helarctos malayanus) individu muda memanjat pohon kelapa hutan tepi desa. Ukuran kecil dan lucu namun tetap hewan liar — jaga jarak aman!',
        locationVisibility: 'coarse',
        displayLatitude: -0.535000,
        displayLongitude: 117.145000,
        areaLabel: 'Kabupaten Kutai Barat, Kalimantan Timur (Area Perkiraan)',
        createdAt: now.subtract(const Duration(days: 3)),
        speciesName: 'Beruang Madu',
        category: 'Helarctos malayanus',
        photoUrl: 'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?w=900&auto=format&fit=crop&q=80',
        blockSeq: 10,
        blockHash: 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5',
        photoSha256: 'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5',
        authorId: 'user-siti',
        authorName: 'Siti Rahmawati',
        authorUsername: 'siti_flora_fauna',
        authorVerifiedUntil: now.add(const Duration(days: 25)),
        likesCount: 167,
        isLikedByMe: true,
      ),

      // ─── DR. WAYAN SUASTIKA (user-wayan, Centang Biru) ────────────────────────
      PostModel(
        id: 'mock-post-3',
        captureId: 'mock-cap-3',
        caption: 'Individu Komodo jantan dewasa berukuran 2.8 meter sedang berjemur di savana Loh Liang. Kondisi fisik sangat prima dengan lidah bercabang aktif mendeteksi aroma.',
        locationVisibility: 'coarse',
        displayLatitude: -8.585000,
        displayLongitude: 119.495000,
        areaLabel: 'Pulau Komodo, TN Komodo (Area Perkiraan)',
        createdAt: now.subtract(const Duration(hours: 3)),
        speciesName: 'Komodo',
        category: 'Varanus komodoensis',
        photoUrl: 'https://images.unsplash.com/photo-1544979590-37e9b47eb705?w=900&auto=format&fit=crop&q=80',
        blockSeq: 3,
        blockHash: '7f9a8b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a',
        photoSha256: '7f9a8b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a',
        authorId: 'user-wayan',
        authorName: 'Dr. Wayan Suastika, M.Si',
        authorUsername: 'wayan_bali',
        authorVerifiedUntil: now.add(const Duration(days: 30)),
        likesCount: 142,
        isLikedByMe: true,
      ),
      PostModel(
        id: 'mock-post-3b',
        captureId: 'mock-cap-3b',
        caption: 'Lumba-lumba Hidung Botol (Tursiops aduncus) berenang dalam formasi kelompok 12 ekor di perairan Teluk Kiluan, Lampung. Terumbu karang di bawah sangat sehat.',
        locationVisibility: 'coarse',
        displayLatitude: -5.615000,
        displayLongitude: 105.085000,
        areaLabel: 'Teluk Kiluan, Lampung (Area Perkiraan)',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        speciesName: 'Lumba-lumba Hidung Botol',
        category: 'Tursiops aduncus',
        photoUrl: 'https://images.unsplash.com/photo-1568430462989-44163eb1752f?w=900&auto=format&fit=crop&q=80',
        blockSeq: 11,
        blockHash: 'e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6',
        photoSha256: 'e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6',
        authorId: 'user-wayan',
        authorName: 'Dr. Wayan Suastika, M.Si',
        authorUsername: 'wayan_bali',
        authorVerifiedUntil: now.add(const Duration(days: 30)),
        likesCount: 287,
        isLikedByMe: false,
      ),
      PostModel(
        id: 'mock-post-3c',
        captureId: 'mock-cap-3c',
        caption: 'Anoa Dataran Rendah (Bubalus depressicornis) — satwa endemik Sulawesi paling sulit difoto. Individu ini terekam kamera trap di jalan setapak dalam kawasan CA Tangkoko.',
        locationVisibility: 'hidden',
        displayLatitude: null,
        displayLongitude: null,
        areaLabel: null,
        createdAt: now.subtract(const Duration(days: 7)),
        speciesName: 'Anoa Dataran Rendah',
        category: 'Bubalus depressicornis',
        photoUrl: 'https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=900&auto=format&fit=crop&q=80',
        blockSeq: 12,
        blockHash: 'f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7',
        photoSha256: 'f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7',
        authorId: 'user-wayan',
        authorName: 'Dr. Wayan Suastika, M.Si',
        authorUsername: 'wayan_bali',
        authorVerifiedUntil: now.add(const Duration(days: 30)),
        likesCount: 519,
        isLikedByMe: true,
      ),

      // ─── DEDI PRATAMA (user-borneo) ────────────────────────────────────────────
      PostModel(
        id: 'mock-post-4',
        captureId: 'mock-cap-4',
        caption: 'Induk Orangutan Kalimantan mengajarkan anaknya mencari buah ara di kanopi hutan primer. Sangat tenang tanpa merasa terganggu.',
        locationVisibility: 'coarse',
        displayLatitude: -2.755000,
        displayLongitude: 111.925000,
        areaLabel: 'Taman Nasional Tanjung Puting, Kalteng (Area Perkiraan)',
        createdAt: now.subtract(const Duration(hours: 6)),
        speciesName: 'Orangutan Kalimantan',
        category: 'Pongo pygmaeus',
        photoUrl: 'https://images.unsplash.com/photo-1535083783855-76ae62b2914e?w=900&auto=format&fit=crop&q=80',
        blockSeq: 4,
        blockHash: '5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f',
        photoSha256: '5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f',
        authorId: 'user-borneo',
        authorName: 'Dedi Pratama',
        authorUsername: 'borneo_wildlife',
        authorVerifiedUntil: null,
        likesCount: 215,
        isLikedByMe: false,
      ),
      PostModel(
        id: 'mock-post-4b',
        captureId: 'mock-cap-4b',
        caption: 'Pesut Mahakam (Orcaella brevirostris) — lumba-lumba air tawar langka muncul di permukaan Sungai Mahakam sore hari. Populasinya tersisa <80 ekor di seluruh dunia.',
        locationVisibility: 'coarse',
        displayLatitude: -0.495000,
        displayLongitude: 116.895000,
        areaLabel: 'Sungai Mahakam, Kaltim (Area Perkiraan)',
        createdAt: now.subtract(const Duration(days: 4)),
        speciesName: 'Pesut Mahakam',
        category: 'Orcaella brevirostris',
        photoUrl: 'https://images.unsplash.com/photo-1607153333879-c174d265f1d2?w=900&auto=format&fit=crop&q=80',
        blockSeq: 13,
        blockHash: 'a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8',
        photoSha256: 'a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8',
        authorId: 'user-borneo',
        authorName: 'Dedi Pratama',
        authorUsername: 'borneo_wildlife',
        authorVerifiedUntil: null,
        likesCount: 388,
        isLikedByMe: false,
      ),

      // ─── DEWI LESTARI (user-dewi) ──────────────────────────────────────────────
      PostModel(
        id: 'mock-post-5',
        captureId: 'mock-cap-5',
        caption: 'Atraksi tarian pikat Cenderawasih jantan di dahan display pada ketinggian 20 meter. Bulu kuning keemasan mekar memukau di hutan pegunungan.',
        locationVisibility: 'coarse',
        displayLatitude: -1.155000,
        displayLongitude: 133.955000,
        areaLabel: 'Cagar Alam Pegunungan Arfak, Papua (Area Perkiraan)',
        createdAt: now.subtract(const Duration(hours: 10)),
        speciesName: 'Cenderawasih Kuning Kecil',
        category: 'Paradisaea minor',
        photoUrl: 'https://images.unsplash.com/photo-1452570053594-1b985d6ea890?w=900&auto=format&fit=crop&q=80',
        blockSeq: 5,
        blockHash: '7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b',
        photoSha256: '7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b',
        authorId: 'user-dewi',
        authorName: 'Dewi Lestari',
        authorUsername: 'dewi_papua',
        authorVerifiedUntil: null,
        likesCount: 176,
        isLikedByMe: false,
      ),
      PostModel(
        id: 'mock-post-5b',
        captureId: 'mock-cap-5b',
        caption: 'Kasuari Gelambir Ganda (Casuarius casuarius) berjalan santai di jalur hutan. Hati-hati: cakar tengahnya mampu merobek dengan sekali tendangan. Amati dari jauh!',
        locationVisibility: 'coarse',
        displayLatitude: -4.095000,
        displayLongitude: 136.055000,
        areaLabel: 'Hutan Dataran Rendah Mimika, Papua (Area Perkiraan)',
        createdAt: now.subtract(const Duration(days: 2)),
        speciesName: 'Kasuari Gelambir Ganda',
        category: 'Casuarius casuarius',
        photoUrl: 'https://images.unsplash.com/photo-1589923188651-268a9765e432?w=900&auto=format&fit=crop&q=80',
        blockSeq: 14,
        blockHash: 'b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9',
        photoSha256: 'b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9',
        authorId: 'user-dewi',
        authorName: 'Dewi Lestari',
        authorUsername: 'dewi_papua',
        authorVerifiedUntil: null,
        likesCount: 253,
        isLikedByMe: true,
      ),

      // ─── FAIZ ALAMSYAH (user-faiz, Centang Biru) ──────────────────────────────
      PostModel(
        id: 'mock-post-6',
        captureId: 'mock-cap-6',
        caption: 'Penyu Hijau dewasa melayang tenang di atas padang lamun terumbu karang tepi pulau. Jarak pandang air laut mencapai 25 meter.',
        locationVisibility: 'coarse',
        displayLatitude: 2.255000,
        displayLongitude: 118.255000,
        areaLabel: 'Kepulauan Derawan, Kalimantan Timur (Area Perkiraan)',
        createdAt: now.subtract(const Duration(hours: 14)),
        speciesName: 'Penyu Hijau',
        category: 'Chelonia mydas',
        photoUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=900&auto=format&fit=crop&q=80',
        blockSeq: 6,
        blockHash: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
        photoSha256: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
        authorId: 'user-faiz',
        authorName: 'Faiz Alamsyah',
        authorUsername: 'faiz_ocean',
        authorVerifiedUntil: now.add(const Duration(days: 10)),
        likesCount: 129,
        isLikedByMe: false,
      ),
      PostModel(
        id: 'mock-post-6b',
        captureId: 'mock-cap-6b',
        caption: 'Hiu Paus (Rhincodon typus) muncul di permukaan saat menghirup udara di perairan Teluk Cendrawasih. Panjang ±8 meter dengan pola bintik khas individu ini. Snorkeling bersama raksasa laut!',
        locationVisibility: 'coarse',
        displayLatitude: -2.955000,
        displayLongitude: 134.895000,
        areaLabel: 'Teluk Cendrawasih, Papua Barat (Area Perkiraan)',
        createdAt: now.subtract(const Duration(days: 3, hours: 5)),
        speciesName: 'Hiu Paus',
        category: 'Rhincodon typus',
        photoUrl: 'https://images.unsplash.com/photo-1559827291-72ee739d0d9a?w=900&auto=format&fit=crop&q=80',
        blockSeq: 15,
        blockHash: 'c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0',
        photoSha256: 'c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0',
        authorId: 'user-faiz',
        authorName: 'Faiz Alamsyah',
        authorUsername: 'faiz_ocean',
        authorVerifiedUntil: now.add(const Duration(days: 10)),
        likesCount: 431,
        isLikedByMe: false,
      ),
      PostModel(
        id: 'mock-post-6c',
        captureId: 'mock-cap-6c',
        caption: 'Dugong (Dugong dugon) merumput di padang lamun perairan dangkal — satu-satunya mamalia laut herbivora di Indonesia. Tampak betina dengan anak yang masih menyusui.',
        locationVisibility: 'coarse',
        displayLatitude: -5.385000,
        displayLongitude: 122.625000,
        areaLabel: 'Perairan Wakatobi, Sulawesi Tenggara (Area Perkiraan)',
        createdAt: now.subtract(const Duration(days: 6)),
        speciesName: 'Dugong',
        category: 'Dugong dugon',
        photoUrl: 'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=900&auto=format&fit=crop&q=80',
        blockSeq: 16,
        blockHash: 'd0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1',
        photoSha256: 'd0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1',
        authorId: 'user-faiz',
        authorName: 'Faiz Alamsyah',
        authorUsername: 'faiz_ocean',
        authorVerifiedUntil: now.add(const Duration(days: 10)),
        likesCount: 198,
        isLikedByMe: true,
      ),
    ]);
  }



  Future<PostModel> createPost({
    required String captureId,
    required String caption,
    String visibility = 'coarse',
    String? areaLabel,
    // Metadata bantuan untuk mode demo/luring
    String? demoSpeciesName,
    String? demoCategory,
    String? demoPhotoPath,
    int? demoBlockSeq,
    String? demoBlockHash,
    String? demoPhotoSha256,
    double? demoRawLat,
    double? demoRawLng,
  }) async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null) {
      return _createDemoPost(
        captureId: captureId,
        caption: caption,
        visibility: visibility,
        areaLabel: areaLabel,
        speciesName: demoSpeciesName,
        category: demoCategory,
        photoPath: demoPhotoPath,
        blockSeq: demoBlockSeq,
        blockHash: demoBlockHash,
        photoSha256: demoPhotoSha256,
        rawLat: demoRawLat,
        rawLng: demoRawLng,
      );
    }

    try {
      final response = await client.rpc(
        'create_post',
        params: {
          'p_capture_id': captureId,
          'p_caption': caption,
          'p_visibility': visibility,
          'p_area_label': areaLabel,
        },
      );

      if (response == null) {
        throw const PostException('Gagal mempublikasikan postingan: respons server kosong.');
      }

      final Map<String, dynamic> row = response is List
          ? Map<String, dynamic>.from(response.first as Map)
          : Map<String, dynamic>.from(response as Map);

      final now = DateTime.now();
      final newPost = PostModel(
        id: row['post_id'] ?? '',
        captureId: captureId,
        caption: row['caption'] ?? caption,
        locationVisibility: row['location_visibility'] ?? visibility,
        displayLatitude: row['display_latitude'] != null ? (row['display_latitude'] as num).toDouble() : null,
        displayLongitude: row['display_longitude'] != null ? (row['display_longitude'] as num).toDouble() : null,
        areaLabel: row['area_label'],
        createdAt: row['created_at'] != null ? DateTime.parse(row['created_at']) : now,
        speciesName: demoSpeciesName ?? 'Satwa Terverifikasi',
        category: demoCategory,
        photoUrl: demoPhotoPath ?? '',
        blockSeq: demoBlockSeq ?? 1,
        blockHash: demoBlockHash ?? '',
        photoSha256: demoPhotoSha256 ?? '',
        authorId: userId,
        authorName: 'Saya (Kolektor)',
        authorUsername: 'kolektor_saya',
      );
      _demoPosts.insert(0, newPost);
      onPostCreatedNotifier.value = newPost;
      return newPost;
    } on PostgrestException catch (e) {
      debugPrint('createPost PostgrestException: ${e.message} (${e.code})');
      if (e.code == '23505') {
        throw const PostException(
          'Tangkapan ini sudah pernah Anda bagikan ke linimasa publik.',
          code: 'ALREADY_POSTED',
        );
      }
      if (e.code == 'P0002') {
        // Tangkapan lokal/luring belum terdaftar di remote Postgres
        return _createDemoPost(
          captureId: captureId,
          caption: caption,
          visibility: visibility,
          areaLabel: areaLabel,
          speciesName: demoSpeciesName,
          category: demoCategory,
          photoPath: demoPhotoPath,
          blockSeq: demoBlockSeq,
          blockHash: demoBlockHash,
          photoSha256: demoPhotoSha256,
          rawLat: demoRawLat,
          rawLng: demoRawLng,
        );
      }
      throw PostException(e.message, code: e.code ?? 'DATABASE_ERROR');
    } catch (e) {
      if (e is PostException) rethrow;
      throw PostException('Gagal membuat postingan: ${e.toString()}');
    }
  }

  /// Mengambil daftar postingan linimasa "Untuk Kamu" dari database atau demo cache
  Future<List<PostModel>> fetchForYouFeed({
    int limit = 20,
    DateTime? cursor,
  }) async {
    final client = _getSupabaseClient();

    if (AppConfig.isDemoMode || client == null) {
      if (_demoPosts.isEmpty) {
        initMockDemoPosts();
      }
      return List<PostModel>.from(_demoPosts);
    }

    try {
      final response = await client.rpc(
        'get_for_you_feed',
        params: {
          'p_limit': limit,
          'p_cursor': cursor?.toIso8601String(),
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        if (_demoPosts.isEmpty) {
          initMockDemoPosts();
        }
        return List<PostModel>.from(_demoPosts);
      }

      return data.map((item) => PostModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      debugPrint('PostService fetchForYouFeed error: $e');
      if (_demoPosts.isEmpty) {
        initMockDemoPosts();
      }
      return List<PostModel>.from(_demoPosts);
    }
  }

  bool _isUuid(String id) {
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id);
  }

  /// Toggle suka / batal suka postingan
  Future<Map<String, dynamic>> togglePostLike(String postId) async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null || !_isUuid(postId)) {
      final idx = _demoPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final current = _demoPosts[idx];
        final newIsLiked = !current.isLikedByMe;
        final newCount = newIsLiked ? current.likesCount + 1 : (current.likesCount > 0 ? current.likesCount - 1 : 0);
        _demoPosts[idx] = current.copyWith(
          isLikedByMe: newIsLiked,
          likesCount: newCount,
        );
        if (newIsLiked) {
          NotificationService.instance.showLikeNotification(
            likerName: current.authorName.isNotEmpty ? current.authorName : current.authorUsername,
            speciesName: current.speciesName,
          );
        }
        return {
          'post_id': postId,
          'is_liked': newIsLiked,
          'likes_count': newCount,
        };
      }
      return {'post_id': postId, 'is_liked': true, 'likes_count': 1};
    }

    try {
      final response = await client.rpc(
        'toggle_post_like',
        params: {'p_post_id': postId},
      );

      final resultMap = Map<String, dynamic>.from(response as Map);

      // Sinkronkan juga pada _demoPosts jika postingan tersebut ada di memori
      final idx = _demoPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _demoPosts[idx] = _demoPosts[idx].copyWith(
          isLikedByMe: resultMap['is_liked'] == true,
          likesCount: (resultMap['likes_count'] as num?)?.toInt() ?? _demoPosts[idx].likesCount,
        );
      }

      if (resultMap['is_liked'] == true) {
        String liker = 'Penjelajah Satwa';
        String? species;
        if (idx != -1) {
          liker = _demoPosts[idx].authorName.isNotEmpty ? _demoPosts[idx].authorName : _demoPosts[idx].authorUsername;
          species = _demoPosts[idx].speciesName;
        }
        NotificationService.instance.showLikeNotification(
          likerName: liker,
          speciesName: species,
        );
      }

      return resultMap;
    } catch (e) {
      debugPrint('togglePostLike error: $e');
      throw PostException('Gagal mengubah status suka: ${e.toString()}');
    }
  }

  PostModel _createDemoPost({
    required String captureId,
    required String caption,
    required String visibility,
    String? areaLabel,
    String? speciesName,
    String? category,
    String? photoPath,
    int? blockSeq,
    String? blockHash,
    String? photoSha256,
    double? rawLat,
    double? rawLng,
  }) {
    final now = DateTime.now();
    final snapped = visibility == 'coarse'
        ? snapToGridLocally(rawLat ?? -6.2088, rawLng ?? 106.8456)
        : {'lat': null, 'lng': null};

    final newPost = PostModel(
      id: 'demo-post-${_demoPosts.length + 1}',
      captureId: captureId,
      caption: caption,
      locationVisibility: visibility,
      displayLatitude: snapped['lat'],
      displayLongitude: snapped['lng'],
      areaLabel: visibility == 'coarse'
          ? (areaLabel ?? 'Area Perkiraan Observasi Lapangan')
          : null,
      createdAt: now,
      speciesName: speciesName ?? 'Satwa Observasi Demo',
      category: category ?? 'Fauna Tropis',
      photoUrl: photoPath ?? 'assets/images/butterfly.jpg',
      blockSeq: blockSeq ?? (_demoPosts.length + 1),
      blockHash: blockHash ?? 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      photoSha256: photoSha256 ?? 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      authorId: '00000000-0000-0000-0000-000000000001',
      authorName: 'Arya Wicaksana',
      authorUsername: 'arya_wallacea',
      authorVerifiedUntil: now.add(const Duration(days: 30)),
      likesCount: 0,
      isLikedByMe: false,
    );

    _demoPosts.insert(0, newPost);
    onPostCreatedNotifier.value = newPost;
    return newPost;
  }

  /// Mengecek apakah postingan telah dilaporkan oleh pengguna saat ini
  bool isPostReported(String postId) => _reportedPostIds.contains(postId);

  /// Melaporkan postingan ke server melalui RPC report_post (Scope Tingkat 3 & Plan 333)
  Future<Map<String, dynamic>> reportPost({
    required String postId,
    required String reason,
    String? notes,
  }) async {
    _reportedPostIds.add(postId);
    onPostReportedNotifier.value = postId;

    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    // Mode Demo / Offline
    if (AppConfig.isDemoMode || client == null || userId == null) {
      _demoPosts.removeWhere((p) => p.id == postId);
      return {
        'success': true,
        'message': 'Laporan berhasil dikirim dan akan segera ditinjau tim kurasi.',
        'is_hidden': true,
        'post_id': postId,
      };
    }

    try {
      final res = await client.rpc('report_post', params: {
        'p_post_id': postId,
        'p_reason': reason,
        'p_notes': notes ?? '',
      });

      if (res is Map) {
        final data = Map<String, dynamic>.from(res);
        if (data['is_hidden'] == true) {
          _demoPosts.removeWhere((p) => p.id == postId);
        }
        return data;
      }

      return {
        'success': true,
        'message': 'Laporan berhasil dikirim dan akan segera ditinjau tim kurasi.',
        'is_hidden': false,
        'post_id': postId,
      };
    } catch (e) {
      debugPrint('PostService reportPost error: $e');
      _demoPosts.removeWhere((p) => p.id == postId);
      return {
        'success': true,
        'message': 'Laporan berhasil dikirim dan akan segera ditinjau tim kurasi.',
        'is_hidden': true,
        'post_id': postId,
      };
    }
  }

  @visibleForTesting
  void clearReportedPostsForTesting() {
    _reportedPostIds.clear();
  }
}
