// ==============================================================================
// FAUNOVA SERVICE: PostService
// Layanan publikasi postingan komunitas, feed Untuk Kamu, dan interaksi like
// Sesuai Plan 5.7, 5.9, 18 & AGENTS.md (Sesi S9)
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../features/feed/models/post_model.dart';

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

  /// Mereset data feed demo untuk keperluan pengujian
  void resetDemoPosts() {
    _demoPosts.clear();
  }

  /// Inisialisasi data postingan demo untuk luring / testing
  void initMockDemoPosts() {
    _demoPosts.clear();
    final now = DateTime.now();

    _demoPosts.addAll([
      PostModel(
        id: 'mock-post-1',
        captureId: 'mock-cap-1',
        caption: 'Teramati sepasang Jalak Bali bertengger di dahan pohon beringin pesisir Teluk Brumbun. Jambul tegak sempurna dalam kondisi sangat sehat!',
        locationVisibility: 'coarse',
        displayLatitude: -8.115000,
        displayLongitude: 114.525000,
        areaLabel: 'Taman Nasional Bali Barat (Area Perkiraan)',
        createdAt: now.subtract(const Duration(minutes: 20)),
        speciesName: 'Jalak Bali',
        category: 'Leucopsar rothschildi',
        photoUrl: 'assets/images/jalak_bali.jpg',
        blockSeq: 1,
        blockHash: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
        photoSha256: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
        authorId: 'user-budi',
        authorName: 'Budi Satria Wibowo',
        authorUsername: 'budi_satria',
        authorVerifiedUntil: now.add(const Duration(days: 30)),
        likesCount: 38,
        isLikedByMe: false,
      ),
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
        photoUrl: 'assets/images/kucing_kuwuk.jpg',
        blockSeq: 2,
        blockHash: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
        photoSha256: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
        authorId: 'user-siti',
        authorName: 'Siti Rahmawati',
        authorUsername: 'siti_flora_fauna',
        authorVerifiedUntil: now.add(const Duration(days: 15)),
        likesCount: 114,
        isLikedByMe: true,
      ),
      PostModel(
        id: 'mock-post-3',
        captureId: 'mock-cap-3',
        caption: 'Kupu-kupu anggun tropis bertotol kuning hitam yang diabadikan pada observasi bunga pekarangan.',
        locationVisibility: 'coarse',
        displayLatitude: -6.205000,
        displayLongitude: 106.845000,
        areaLabel: 'Cagar Alam Pegunungan Cycloop (Area Perkiraan)',
        createdAt: now.subtract(const Duration(hours: 5)),
        speciesName: 'Kupu-kupu Jeruk',
        category: 'Papilio demoleus',
        photoUrl: 'assets/images/butterfly.jpg',
        blockSeq: 3,
        blockHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        photoSha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        authorId: 'user-indra',
        authorName: 'drh. Indra Perkasa',
        authorUsername: 'indra_vet',
        authorVerifiedUntil: null,
        likesCount: 205,
        isLikedByMe: false,
      ),
    ]);
  }

  /// Membuat postingan publik dari tangkapan satwa melalui RPC `create_post`
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
      return PostModel(
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
    } on PostgrestException catch (e) {
      debugPrint('createPost PostgrestException: ${e.message} (${e.code})');
      if (e.code == '23505') {
        throw const PostException(
          'Tangkapan ini sudah pernah Anda bagikan ke linimasa publik.',
          code: 'ALREADY_POSTED',
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
      if (data.isEmpty && _demoPosts.isNotEmpty) {
        return List<PostModel>.from(_demoPosts);
      }

      return data.map((item) => PostModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      debugPrint('PostService fetchForYouFeed error: $e');
      if (_demoPosts.isNotEmpty) {
        return List<PostModel>.from(_demoPosts);
      }
      throw PostException('Gagal memuat feed linimasa: ${e.toString()}');
    }
  }

  /// Toggle suka / batal suka postingan
  Future<Map<String, dynamic>> togglePostLike(String postId) async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || userId == null) {
      final idx = _demoPosts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        final current = _demoPosts[idx];
        final newIsLiked = !current.isLikedByMe;
        final newCount = newIsLiked ? current.likesCount + 1 : (current.likesCount > 0 ? current.likesCount - 1 : 0);
        _demoPosts[idx] = current.copyWith(
          isLikedByMe: newIsLiked,
          likesCount: newCount,
        );
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

      return Map<String, dynamic>.from(response as Map);
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
    return newPost;
  }
}
