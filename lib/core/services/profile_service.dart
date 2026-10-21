// ==============================================================================
// FAUNOVA SERVICE: ProfileService
// Layanan pengelolaan profil sendiri dan sinkronisasi data kolektor
// Sesuai Plan 5.2, 5.7, 18 & AGENTS.md (Sesi S11)
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../features/profile/models/public_profile_model.dart';

class ProfileException implements Exception {
  final String message;
  final String code;

  const ProfileException(this.message, {this.code = 'PROFILE_ERROR'});

  @override
  String toString() => message;
}

class ProfileService {
  static final ProfileService instance = ProfileService._internal();
  ProfileService._internal() {
    initMockDemoMyProfile();
  }

  PublicProfileModel? _myDemoProfile;

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

  /// Inisialisasi data profil pengguna sendiri untuk mode demo/luring
  void initMockDemoMyProfile() {
    _myDemoProfile = PublicProfileModel(
      id: '00000000-0000-0000-0000-000000000001',
      username: 'arya_wallacea',
      displayName: 'Arya Wicaksana',
      avatarPath: null,
      bio: 'Penjelajah biodiversitas Indonesia Timur. Mengarsipkan reptilia dan aves endemik ke dalam rantai kanonis.',
      isVerified: true,
      verifiedUntil: DateTime.now().add(const Duration(days: 30)),
      streakCount: 18,
      bestQuizScore: 95,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      capturesCount: 14,
      postsCount: 4,
      followersCount: 186,
      followingCount: 42,
      isFollowedByMe: false,
      isMyProfile: true,
    );
  }

  /// Mengambil data profil pengguna yang sedang masuk
  Future<PublicProfileModel> getMyProfile() async {
    final client = _getSupabaseClient();
    final myId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || myId == null) {
      if (_myDemoProfile == null) initMockDemoMyProfile();
      return _myDemoProfile!;
    }

    try {
      final response = await client.rpc(
        'get_public_profile',
        params: {'p_target_user_id': myId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      if (data['found'] == false) {
        if (_myDemoProfile == null) initMockDemoMyProfile();
        return _myDemoProfile!;
      }

      return PublicProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('ProfileService getMyProfile error: $e');
      if (_myDemoProfile == null) initMockDemoMyProfile();
      return _myDemoProfile!;
    }
  }

  /// Memperbarui profil sendiri (nama tampilan, bio, avatar)
  Future<PublicProfileModel> updateMyProfile({
    required String displayName,
    required String bio,
    String? avatarPath,
  }) async {
    final cleanName = displayName.trim();
    final cleanBio = bio.trim();

    if (cleanName.length < 2) {
      throw const ProfileException('Nama tampilan minimal 2 karakter.');
    }
    if (cleanName.length > 60) {
      throw const ProfileException('Nama tampilan maksimal 60 karakter.');
    }
    if (cleanBio.length > 300) {
      throw const ProfileException('Bio maksimal 300 karakter.');
    }

    final client = _getSupabaseClient();
    final myId = _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || myId == null) {
      if (_myDemoProfile == null) initMockDemoMyProfile();
      _myDemoProfile = _myDemoProfile!.copyWith(
        displayName: cleanName,
        bio: cleanBio,
        avatarPath: avatarPath ?? _myDemoProfile!.avatarPath,
      );
      return _myDemoProfile!;
    }

    try {
      final response = await client.rpc(
        'update_my_profile',
        params: {
          'p_display_name': cleanName,
          'p_bio': cleanBio,
          'p_avatar_path': avatarPath,
        },
      );

      final data = Map<String, dynamic>.from(response as Map);
      if (data['success'] != true) {
        throw const ProfileException('Gagal memperbarui profil.');
      }

      // Ambil kembali data profil yang sudah teragregat
      return await getMyProfile();
    } catch (e) {
      debugPrint('ProfileService updateMyProfile error: $e');
      throw ProfileException('Gagal menyimpan profil: ${e.toString()}');
    }
  }
}
