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
import 'notification_service.dart';
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

  final Set<String> _followingUserIds = {'user-budi', 'user-wayan', 'user-siti'};
  final Map<String, PublicProfileModel> _demoProfiles = {};
  final Map<String, Set<String>> _mockFollowersMap = {};
  final Map<String, Set<String>> _mockFollowingMap = {};

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
    _followingUserIds.add('user-budi');
    _demoProfiles.clear();
    _mockFollowersMap.clear();
    _mockFollowingMap.clear();

    final now = DateTime.now();
    const myId = '00000000-0000-0000-0000-000000000001';

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
      postsCount: 3,
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
      postsCount: 3,
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
      postsCount: 2,
      followersCount: 88,
      followingCount: 42,
      isFollowedByMe: false,
      isMyProfile: false,
    );

    _demoProfiles['user-wayan'] = PublicProfileModel(
      id: 'user-wayan',
      username: 'wayan_bali',
      displayName: 'Dr. Wayan Suastika, M.Si',
      avatarPath: null,
      bio: 'Dokter satwa & ranger Pulau Komodo. Mengamati keanekaragaman reptil purba nusantara.',
      isVerified: true,
      streakCount: 35,
      bestQuizScore: 100,
      createdAt: now.subtract(const Duration(days: 180)),
      capturesCount: 42,
      postsCount: 3,
      followersCount: 312,
      followingCount: 78,
      isFollowedByMe: false,
      isMyProfile: false,
    );

    _demoProfiles['user-farhan'] = PublicProfileModel(
      id: 'user-farhan',
      username: 'farhan_primata',
      displayName: 'Farhan Pratama',
      avatarPath: null,
      bio: 'Bioakustik & perilaku primata hutan rawa gambut dan hutan dataran rendah.',
      isVerified: true,
      streakCount: 19,
      bestQuizScore: 91,
      createdAt: now.subtract(const Duration(days: 75)),
      capturesCount: 15,
      postsCount: 0,
      followersCount: 174,
      followingCount: 49,
      isFollowedByMe: false,
      isMyProfile: false,
    );

    _demoProfiles['user-ratna'] = PublicProfileModel(
      id: 'user-ratna',
      username: 'ratna_biomarine',
      displayName: 'Ratna Biologi Bahari',
      avatarPath: null,
      bio: 'Eksplorasi biota laut karang Segitiga Karang & mamalia laut Raja Ampat.',
      isVerified: false,
      streakCount: 11,
      bestQuizScore: 88,
      createdAt: now.subtract(const Duration(days: 60)),
      capturesCount: 22,
      postsCount: 0,
      followersCount: 129,
      followingCount: 34,
      isFollowedByMe: false,
      isMyProfile: false,
    );

    _demoProfiles['user-borneo'] = PublicProfileModel(
      id: 'user-borneo',
      username: 'borneo_wildlife',
      displayName: 'Dedi Pratama',
      avatarPath: null,
      bio: 'Pemantau satwa liar Kalimantan sejak 2012. Fokus pada mamalia riparian & pesut sungai.',
      isVerified: false,
      streakCount: 9,
      bestQuizScore: 83,
      createdAt: now.subtract(const Duration(days: 200)),
      capturesCount: 28,
      postsCount: 2,
      followersCount: 198,
      followingCount: 61,
      isFollowedByMe: false,
      isMyProfile: false,
    );

    _demoProfiles['user-faiz'] = PublicProfileModel(
      id: 'user-faiz',
      username: 'faiz_ocean',
      displayName: 'Faiz Alamsyah',
      avatarPath: null,
      bio: 'Freediver & naturalis bawah laut. Mendokumentasikan megafauna laut nusantara sejak 2018.',
      isVerified: true,
      streakCount: 22,
      bestQuizScore: 95,
      createdAt: now.subtract(const Duration(days: 150)),
      capturesCount: 35,
      postsCount: 3,
      followersCount: 445,
      followingCount: 73,
      isFollowedByMe: false,
      isMyProfile: false,
    );

    // Seed relasi followers & following lokal
    _mockFollowersMap[myId] = {'user-budi', 'user-siti', 'user-wayan', 'user-farhan'};
    _mockFollowingMap[myId] = {'user-budi'};

    _mockFollowersMap['user-budi'] = {myId, 'user-siti', 'user-dewi', 'user-wayan'};
    _mockFollowingMap['user-budi'] = {'user-siti', 'user-wayan', 'user-ratna'};

    _mockFollowersMap['user-siti'] = {'user-budi', 'user-dewi', 'user-ratna'};
    _mockFollowingMap['user-siti'] = {'user-budi', 'user-wayan', myId};

    _mockFollowersMap['user-dewi'] = {'user-budi', 'user-farhan'};
    _mockFollowingMap['user-dewi'] = {'user-budi', 'user-siti'};

    _mockFollowersMap['user-wayan'] = {'user-budi', 'user-siti', 'user-farhan', myId};
    _mockFollowingMap['user-wayan'] = {'user-budi', 'user-ratna'};

    _mockFollowersMap['user-farhan'] = {'user-dewi', 'user-wayan'};
    _mockFollowingMap['user-farhan'] = {'user-budi', 'user-wayan', myId};

    _mockFollowersMap['user-ratna'] = {'user-budi', 'user-wayan'};
    _mockFollowingMap['user-ratna'] = {'user-siti', 'user-dewi'};
  }

  /// Mengikuti atau membatalkan ikuti pengguna lain secara idempoten dan atomik
  Future<Map<String, dynamic>> toggleFollow(String targetUserId) async {
    final client = _getSupabaseClient();
    final myId = _getCurrentUserId();

    // Aturan keras: tidak boleh follow diri sendiri
    if (myId != null && myId == targetUserId) {
      throw const SocialException('Pengguna tidak dapat mengikuti diri sendiri.');
    }

    if (AppConfig.isDemoMode || client == null || myId == null || !_isUuid(targetUserId)) {
      // Penanganan Mode Demo / Pengujian Offline
      final wasFollowing = _followingUserIds.contains(targetUserId);
      final newFollowing = !wasFollowing;
      final currentUserId = myId ?? '00000000-0000-0000-0000-000000000001';

      if (newFollowing) {
        _followingUserIds.add(targetUserId);
        _mockFollowersMap.putIfAbsent(targetUserId, () => <String>{}).add(currentUserId);
        _mockFollowingMap.putIfAbsent(currentUserId, () => <String>{}).add(targetUserId);
      } else {
        _followingUserIds.remove(targetUserId);
        _mockFollowersMap[targetUserId]?.remove(currentUserId);
        _mockFollowingMap[currentUserId]?.remove(targetUserId);
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

      if (newFollowing) {
        final followerName = profile?.displayName ?? profile?.username ?? 'Penjelajah Satwa';
        NotificationService.instance.showFollowNotification(followerName: followerName);
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
        final followerName = (result['target_username'] as String?) ??
            (result['target_name'] as String?) ??
            'Penjelajah Satwa';
        NotificationService.instance.showFollowNotification(followerName: followerName);
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
      if (data.isNotEmpty) {
        return data.map((item) => PostModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      }

      // Jika data server masih kosong, gunakan fallback ramah
      if (PostService.instance.demoPosts.isEmpty) {
        PostService.instance.initMockDemoPosts();
      }
      final allPosts = PostService.instance.demoPosts;
      final followingPosts = allPosts.where((p) => _followingUserIds.contains(p.authorId)).toList();
      return List<PostModel>.from(followingPosts);
    } catch (e) {
      debugPrint('fetchFollowingFeed error: $e');
      if (PostService.instance.demoPosts.isEmpty) {
        PostService.instance.initMockDemoPosts();
      }
      final allPosts = PostService.instance.demoPosts;
      final followingPosts = allPosts.where((p) => _followingUserIds.contains(p.authorId)).toList();
      return List<PostModel>.from(followingPosts);
    }
  }

  /// Mengambil data profil publik pengguna lain
  Future<PublicProfileModel> getPublicProfile(String targetUserId) async {
    final client = _getSupabaseClient();
    final myId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || myId == null || !_isUuid(targetUserId)) {
      if (_demoProfiles.containsKey(targetUserId)) {
        final profile = _demoProfiles[targetUserId]!;
        return profile.copyWith(
          isFollowedByMe: _followingUserIds.contains(targetUserId),
          isMyProfile: targetUserId == (myId ?? 'my-user-id'),
        );
      }

      // Cari dari data postingan demo jika profil belum terdaftar
      final demoPosts = PostService.instance.demoPosts;
      final matchingPost = demoPosts.where((p) => p.authorId == targetUserId).toList();
      if (matchingPost.isNotEmpty) {
        final p = matchingPost.first;
        return PublicProfileModel(
          id: targetUserId,
          username: p.authorUsername,
          displayName: p.authorName,
          avatarPath: null,
          bio: 'Penjelajah & pengamat keanekaragaman hayati nusantara.',
          isVerified: p.authorVerifiedUntil != null && p.authorVerifiedUntil!.isAfter(DateTime.now()),
          streakCount: 5,
          bestQuizScore: 75,
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          capturesCount: matchingPost.length * 3,
          postsCount: matchingPost.length,
          followersCount: matchingPost.fold(0, (sum, post) => sum + post.likesCount) ~/ 10,
          followingCount: 20,
          isFollowedByMe: _followingUserIds.contains(targetUserId),
          isMyProfile: false,
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
        postsCount: 0,
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

    if (AppConfig.isDemoMode || client == null || !_isUuid(targetUserId)) {
      if (PostService.instance.demoPosts.isEmpty) {
        PostService.instance.initMockDemoPosts();
      }
      return PostService.instance.demoPosts.where((p) => p.authorId == targetUserId).toList();
    }

    // 1. Coba panggil get_user_posts (RPC teruji di migrasi 014)
    try {
      final response = await client.rpc(
        'get_user_posts',
        params: {
          'p_user_id': targetUserId,
          'p_limit': limit,
        },
      );

      if (response is List) {
        final posts = response.map((item) => PostModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
        return posts;
      }
    } catch (e) {
      debugPrint('fetchUserPublicPosts (get_user_posts) error: $e, mencoba get_user_public_posts...');
    }

    // 2. Coba panggil get_user_public_posts (RPC migrasi 005/022)
    try {
      final response = await client.rpc(
        'get_user_public_posts',
        params: {
          'p_target_user_id': targetUserId,
          'p_limit': limit,
        },
      );

      if (response is List) {
        final posts = response.map((item) => PostModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();
        return posts;
      }
    } catch (e) {
      debugPrint('fetchUserPublicPosts (get_user_public_posts) error: $e');
    }

    // 3. Fallback: ambil dari memory PostService demoPosts
    return PostService.instance.demoPosts.where((p) => p.authorId == targetUserId).toList();
  }

  bool _isUuid(String id) {
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id);
  }

  /// Mengambil daftar akun pengikut (Followers) dari pengguna tertentu
  Future<List<PublicProfileModel>> fetchUserFollowers(
    String targetUserId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final client = _getSupabaseClient();

    if (AppConfig.isDemoMode || client == null || !_isUuid(targetUserId)) {
      return _getMockFollowers(targetUserId);
    }

    try {
      final response = await client.rpc(
        'get_user_followers',
        params: {
          'p_target_user_id': targetUserId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => PublicProfileModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('fetchUserFollowers error: $e');
      return _getMockFollowers(targetUserId);
    }
  }

  /// Mengambil daftar akun yang diikuti (Following) dari pengguna tertentu
  Future<List<PublicProfileModel>> fetchUserFollowing(
    String targetUserId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final client = _getSupabaseClient();

    if (AppConfig.isDemoMode || client == null || !_isUuid(targetUserId)) {
      return _getMockFollowing(targetUserId);
    }

    try {
      final response = await client.rpc(
        'get_user_following',
        params: {
          'p_target_user_id': targetUserId,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => PublicProfileModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('fetchUserFollowing error: $e');
      return _getMockFollowing(targetUserId);
    }
  }

  List<PublicProfileModel> _getMockFollowers(String targetUserId) {
    if (!_demoProfiles.containsKey('user-wayan')) {
      initMockDemoSocial();
    }
    final myId = _getCurrentUserId() ?? '00000000-0000-0000-0000-000000000001';
    final normalizedTarget = (targetUserId == myId) ? '00000000-0000-0000-0000-000000000001' : targetUserId;
    final followerIds = _mockFollowersMap[normalizedTarget] ?? {'user-budi', 'user-siti', 'user-wayan', 'user-farhan'};

    return followerIds.map((id) {
      final base = _demoProfiles[id] ?? _createFallbackMockProfile(id);
      return base.copyWith(
        isFollowedByMe: _followingUserIds.contains(id),
        isMyProfile: id == myId || id == '00000000-0000-0000-0000-000000000001',
      );
    }).toList();
  }

  List<PublicProfileModel> _getMockFollowing(String targetUserId) {
    if (!_demoProfiles.containsKey('user-wayan')) {
      initMockDemoSocial();
    }
    final myId = _getCurrentUserId() ?? '00000000-0000-0000-0000-000000000001';
    final normalizedTarget = (targetUserId == myId) ? '00000000-0000-0000-0000-000000000001' : targetUserId;

    Set<String> followingIds;
    if (normalizedTarget == '00000000-0000-0000-0000-000000000001') {
      followingIds = _followingUserIds;
    } else {
      followingIds = _mockFollowingMap[normalizedTarget] ?? {'user-budi', 'user-siti'};
    }

    return followingIds.map((id) {
      final base = _demoProfiles[id] ?? _createFallbackMockProfile(id);
      return base.copyWith(
        isFollowedByMe: _followingUserIds.contains(id),
        isMyProfile: id == myId || id == '00000000-0000-0000-0000-000000000001',
      );
    }).toList();
  }

  PublicProfileModel _createFallbackMockProfile(String userId) {
    return PublicProfileModel(
      id: userId,
      username: 'kolektor_${userId.replaceAll('-', '_').substring(0, userId.length > 8 ? 8 : userId.length)}',
      displayName: 'Penjelajah Satwa',
      avatarPath: null,
      bio: 'Pemerhati biodiversitas satwa liar Indonesia.',
      isVerified: false,
      streakCount: 5,
      bestQuizScore: 78,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      capturesCount: 8,
      postsCount: 2,
      followersCount: 45,
      followingCount: 20,
      isFollowedByMe: _followingUserIds.contains(userId),
      isMyProfile: false,
    );
  }
}
