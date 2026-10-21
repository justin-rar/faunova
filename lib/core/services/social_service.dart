// ==============================================================================
// FAUNOVA SERVICE: SocialService
// Layanan relasi sosial: Follow / Unfollow, Feed Mengikuti, dan Profil Publik
// Sesuai Plan 5.7, 5.9, 18 & AGENTS.md (Sesi S10)
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../features/feed/models/post_model.dart';
import '../../features/profile/models/public_profile_model.dart';
import 'post_service.dart';

class SocialException implements Exception {
  final String message;
  final String code;

  const SocialException(this.message, {this.code = 'SOCIAL_ERROR'});

  @override
  String toString() => message;
}

class SocialService {
  static final SocialService instance = SocialService._internal();
  SocialService._internal() {
    initMockDemoSocial();
  }

  final Set<String> _followingUserIds = {'user-budi'};
  final Map<String, PublicProfileModel> _demoProfiles = {};

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

  /// Cek apakah pengguna saat ini sedang mengikuti targetUserId
  bool isFollowing(String targetUserId) {
    return _followingUserIds.contains(targetUserId);
  }

  /// Inisialisasi data sosial tiruan untuk pengujian dan mode demo
  void initMockDemoSocial() {
    _followingUserIds.clear();
    _followingUserIds.add('user-budi'); // Budi diikuti secara bawaan di demo
    _demoProfiles.clear();

    final now = DateTime.now();

    _demoProfiles['user-budi'] = PublicProfileModel(
      id: 'user-budi',
      username: 'budi_satria',
      displayName: 'Budi Satria Wibowo',
      avatarPath: null,
      bio: 'Pencinta ornitologi & penjelajah hutan tropis Indonesia. Mengamati burung endemik Wallacea.',
      isVerified: true,
      streakCount: 14,
      bestQuizScore: 92,
      createdAt: now.subtract(const Duration(days: 90)),
      capturesCount: 18,
      postsCount: 5,
      followersCount: 142,
      followingCount: 38,
      isFollowedByMe: true,
      isMyProfile: false,
    );

    _demoProfiles['user-siti'] = PublicProfileModel(
      id: 'user-siti',
      username: 'siti_flora_fauna',
      displayName: 'Siti Rahmawati',
      avatarPath: null,
      bio: 'Pemerhati mamalia karnivora kecil & pegiat konservasi satwa liar Taman Nasional.',
      isVerified: true,
      streakCount: 21,
      bestQuizScore: 98,
      createdAt: now.subtract(const Duration(days: 120)),
      capturesCount: 24,
      postsCount: 8,
      followersCount: 230,
      followingCount: 56,
      isFollowedByMe: false,
      isMyProfile: false,
    );

    _demoProfiles['user-dewi'] = PublicProfileModel(
      id: 'user-dewi',
      username: 'dewi_papua',
      displayName: 'Dewi Lestari',
      avatarPath: null,
      bio: 'Pengamat Aves tanah Papua & pegiat edukasi keanekaragaman hayati nusantara.',
      isVerified: false,
      streakCount: 7,
      bestQuizScore: 85,
      createdAt: now.subtract(const Duration(days: 45)),
      capturesCount: 9,
      postsCount: 3,
      followersCount: 88,
      followingCount: 42,
      isFollowedByMe: false,
      isMyProfile: false,
    );
  }

  /// Mengikuti atau membatalkan ikuti pengguna lain secara idempoten dan atomik
  Future<Map<String, dynamic>> toggleFollow(String targetUserId) async {
    final client = _getSupabaseClient();
    final myId = _getCurrentUserId();

    // Aturan keras: tidak boleh follow diri sendiri
    if (myId != null && myId == targetUserId) {
      throw const SocialException('Pengguna tidak dapat mengikuti diri sendiri.');
    }

    if (AppConfig.isDemoMode || client == null || myId == null) {
      // Penanganan Mode Demo / Pengujian Offline
      final wasFollowing = _followingUserIds.contains(targetUserId);
      final newFollowing = !wasFollowing;

      if (newFollowing) {
        _followingUserIds.add(targetUserId);
      } else {
        _followingUserIds.remove(targetUserId);
      }

      var profile = _demoProfiles[targetUserId];
      int followers = profile?.followersCount ?? 50;
      followers = newFollowing ? followers + 1 : (followers > 0 ? followers - 1 : 0);

      if (profile != null) {
        _demoProfiles[targetUserId] = profile.copyWith(
          isFollowedByMe: newFollowing,
          followersCount: followers,
        );
      }

      return {
        'success': true,
        'target_user_id': targetUserId,
        'is_following': newFollowing,
        'followers_count': followers,
        'following_count': profile?.followingCount ?? 20,
      };
    }

    try {
      final response = await client.rpc(
        'toggle_follow_user',
        params: {'p_target_user_id': targetUserId},
      );

      final result = Map<String, dynamic>.from(response as Map);
      final isNowFollowing = result['is_following'] == true;

      if (isNowFollowing) {
        _followingUserIds.add(targetUserId);
      } else {
        _followingUserIds.remove(targetUserId);
      }

      return result;
    } catch (e) {
      debugPrint('toggleFollow error: $e');
      throw SocialException('Gagal mengubah status ikuti: ${e.toString()}');
    }
  }

  /// Mengambil linimasa akun yang diikuti (Tab "Mengikuti")
  Future<List<PostModel>> fetchFollowingFeed({DateTime? cursor, int limit = 20}) async {
    final client = _getSupabaseClient();
    final myId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || myId == null) {
      // Pastikan demo post tersedia
      if (PostService.instance.demoPosts.isEmpty) {
        PostService.instance.initMockDemoPosts();
      }

      final allPosts = PostService.instance.demoPosts;
      final followingPosts = allPosts.where((p) => _followingUserIds.contains(p.authorId)).toList();
      return List<PostModel>.from(followingPosts);
    }

    try {
      final response = await client.rpc(
        'get_following_feed',
        params: {
          'p_limit': limit,
          'p_cursor': cursor?.toIso8601String(),
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => PostModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      debugPrint('fetchFollowingFeed error: $e');
      // Fallback ramah jika server belum merespons
      final allPosts = PostService.instance.demoPosts;
      final followingPosts = allPosts.where((p) => _followingUserIds.contains(p.authorId)).toList();
      if (followingPosts.isNotEmpty) {
        return List<PostModel>.from(followingPosts);
      }
      throw SocialException('Gagal memuat linimasa mengikuti: ${e.toString()}');
    }
  }

  /// Mengambil data profil publik pengguna lain
  Future<PublicProfileModel> getPublicProfile(String targetUserId) async {
    final client = _getSupabaseClient();
    final myId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || myId == null) {
      if (_demoProfiles.containsKey(targetUserId)) {
        final profile = _demoProfiles[targetUserId]!;
        return profile.copyWith(
          isFollowedByMe: _followingUserIds.contains(targetUserId),
          isMyProfile: targetUserId == (myId ?? 'my-user-id'),
        );
      }

      // Default mock profile untuk targetUserId yang belum terdaftar di demo
      return PublicProfileModel(
        id: targetUserId,
        username: 'penjelajah_${targetUserId.substring(0, targetUserId.length > 6 ? 6 : targetUserId.length)}',
        displayName: 'Kolektor Satwa Indonesia',
        bio: 'Pengamat keanekaragaman hayati & kolektor jurnal satwa liar.',
        isVerified: false,
        streakCount: 3,
        bestQuizScore: 70,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        capturesCount: 5,
        postsCount: 2,
        followersCount: 15,
        followingCount: 12,
        isFollowedByMe: _followingUserIds.contains(targetUserId),
        isMyProfile: false,
      );
    }

    try {
      final response = await client.rpc(
        'get_public_profile',
        params: {'p_target_user_id': targetUserId},
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(response as Map);
      if (data['found'] == false) {
        throw const SocialException('Profil tidak ditemukan.', code: 'NOT_FOUND');
      }

      return PublicProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('getPublicProfile error: $e');
      if (_demoProfiles.containsKey(targetUserId)) {
        return _demoProfiles[targetUserId]!;
      }
      throw SocialException('Gagal memuat profil publik: ${e.toString()}');
    }
  }

  /// Mengambil daftar postingan publik milik pengguna tertentu
  Future<List<PostModel>> fetchUserPublicPosts(String targetUserId, {int limit = 30}) async {
    final client = _getSupabaseClient();
    final myId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || myId == null) {
      if (PostService.instance.demoPosts.isEmpty) {
        PostService.instance.initMockDemoPosts();
      }
      return PostService.instance.demoPosts.where((p) => p.authorId == targetUserId).toList();
    }

    try {
      final response = await client.rpc(
        'get_user_public_posts',
        params: {
          'p_target_user_id': targetUserId,
          'p_limit': limit,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => PostModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (e) {
      debugPrint('fetchUserPublicPosts error: $e');
      return PostService.instance.demoPosts.where((p) => p.authorId == targetUserId).toList();
    }
  }
}
