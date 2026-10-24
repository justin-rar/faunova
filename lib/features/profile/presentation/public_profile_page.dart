// ==============================================================================
// FAUNOVA PRESENTATION: PublicProfilePage
// Halaman Profil Publik Pengguna Lain (Plan 5.7, 5.9, 18 & AGENTS.md Sesi S10)
// ==============================================================================

import 'package:flutter/material.dart';

import '../../../core/services/social_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../feed/models/post_model.dart';
import '../../feed/presentation/widgets/post_card.dart';
import '../models/public_profile_model.dart';
import 'widgets/follow_list_sheet.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;
  final String? initialAuthorName;
  final String? initialAuthorUsername;

  const PublicProfilePage({
    super.key,
    required this.userId,
    this.initialAuthorName,
    this.initialAuthorUsername,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  PublicProfileModel? _profile;
  List<PostModel> _publicPosts = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isTogglingFollow = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await SocialService.instance.getPublicProfile(
        widget.userId,
      );
      final posts = await SocialService.instance.fetchUserPublicPosts(
        widget.userId,
      );

      if (mounted) {
        setState(() {
          _profile = profile;
          _publicPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleToggleFollow() async {
    if (_profile == null || _isTogglingFollow) return;

    final currentFollow = _profile!.isFollowedByMe;
    final newFollow = !currentFollow;
    final newFollowers = newFollow
        ? _profile!.followersCount + 1
        : (_profile!.followersCount > 0 ? _profile!.followersCount - 1 : 0);

    // Optimistic Update
    setState(() {
      _isTogglingFollow = true;
      _profile = _profile!.copyWith(
        isFollowedByMe: newFollow,
        followersCount: newFollowers,
      );
    });

    try {
      final result = await SocialService.instance.toggleFollow(widget.userId);
      if (mounted) {
        setState(() {
          _profile = _profile!.copyWith(
            isFollowedByMe: result['is_following'] == true,
            followersCount:
                (result['followers_count'] as num?)?.toInt() ?? newFollowers,
          );
          _isTogglingFollow = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.sageTua,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              newFollow
                  ? 'Sekarang Anda mengikuti ${_profile!.displayName}. Observasi mereka akan tampil di tab Mengikuti!'
                  : 'Berhenti mengikuti ${_profile!.displayName}.',
              style: const TextStyle(color: AppColors.teksPutih, fontSize: 13),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Rollback jika terjadi galat
      if (mounted) {
        setState(() {
          _profile = _profile!.copyWith(
            isFollowedByMe: currentFollow,
            followersCount: currentFollow
                ? _profile!.followersCount + 1
                : (_profile!.followersCount > 0
                      ? _profile!.followersCount - 1
                      : 0),
          );
          _isTogglingFollow = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.merahStatus,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Gagal mengubah status: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 14;

    return Scaffold(
      backgroundColor: AppColors.gading,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.teksPutih,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _profile != null
              ? '@${_profile!.username}'
              : (widget.initialAuthorUsername != null
                    ? '@${widget.initialAuthorUsername}'
                    : 'Profil Penjelajah'),
          style: const TextStyle(
            color: AppColors.teksPutih,
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(topPadding),
    );
  }

  Widget _buildBody(double topPadding) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: const AppStateView(
          status: AppViewStatus.loading,
          loadingMessage: 'Memuat profil penjelajah satwa...',
          child: SizedBox.shrink(),
        ),
      );
    }

    if (_errorMessage != null || _profile == null) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: AppStateView(
          status: AppViewStatus.error,
          errorMessage: _errorMessage ?? 'Profil penjelajah tidak ditemukan.',
          onRetry: _loadProfileData,
          child: const SizedBox.shrink(),
        ),
      );
    }

    final p = _profile!;

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      edgeOffset: topPadding,
      color: AppColors.sageTua,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 40),
        children: [
          // 1. Kartu Header Profil
          _buildProfileHeaderCard(p),

          const SizedBox(height: 16),

          // 2. Baris Metrik Sosial (Observasi, Pengikut, Mengikuti)
          _buildStatsCard(p),

          const SizedBox(height: 16),

          // 3. Tombol Aksi Follow / Profil Sendiri
          _buildFollowActionButton(p),

          const SizedBox(height: 24),

          // 4. Header Observasi Lapangan Publik
          Row(
            children: [
              const Icon(
                Icons.public_rounded,
                size: 20,
                color: AppColors.sageTua,
              ),
              const SizedBox(width: 8),
              Text(
                'Observasi Publik (${_publicPosts.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5. Daftar Observasi / Empty State
          if (_publicPosts.isEmpty)
            _buildEmptyPostsCard(p)
          else
            ..._publicPosts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PostCard(
                  post: post,
                  onLike: () {
                    _loadProfileData();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard(PublicProfileModel p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sageMuda.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar profil
          AppAvatar(
            avatarPath: p.avatarPath,
            displayName: p.displayName,
            radius: 38,
          ),
          const SizedBox(height: 12),

          // Nama & Centang Biru
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  p.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teksGelap,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (p.isVerifiedActive) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF1E88E5),
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // Username
          Text(
            '@${p.username}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.teksGelap.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),

          if (p.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.gading,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                p.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.teksGelap,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Badges Ringkas (Streak & Kuis)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 15,
                      color: Color(0xFFE65100),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${p.streakCount} Hari',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 15,
                      color: AppColors.emasTua,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Skor ${p.bestQuizScore}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(PublicProfileModel p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sageMuda.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Observasi', p.capturesCount.toString()),
          Container(height: 28, width: 1, color: AppColors.sageMuda),
          _buildStatColumn(
            'Pengikut',
            p.followersCount.toString(),
            onTap: () {
              FollowListSheet.show(
                context,
                userId: p.id,
                displayName: p.displayName,
                username: p.username,
                initialTab: FollowTab.followers,
                onFollowStatusChanged: _loadProfileData,
              );
            },
          ),
          Container(height: 28, width: 1, color: AppColors.sageMuda),
          _buildStatColumn(
            'Mengikuti',
            p.followingCount.toString(),
            onTap: () {
              FollowListSheet.show(
                context,
                userId: p.id,
                displayName: p.displayName,
                username: p.username,
                initialTab: FollowTab.following,
                onFollowStatusChanged: _loadProfileData,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {VoidCallback? onTap}) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.teksGelap,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.teksGelap.withValues(alpha: 0.65),
          ),
        ),
      ],
    );

    if (onTap == null) return column;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: column,
      ),
    );
  }

  Widget _buildFollowActionButton(PublicProfileModel p) {
    if (p.isMyProfile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.sageMuda.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.sageMuda),
        ),
        child: const Center(
          child: Text(
            'Ini adalah profil akun Anda',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.teksGelap,
            ),
          ),
        ),
      );
    }

    if (p.isFollowedByMe) {
      return OutlinedButton.icon(
        onPressed: _isTogglingFollow ? null : _handleToggleFollow,
        icon: const Icon(
          Icons.check_rounded,
          size: 18,
          color: AppColors.sageTua,
        ),
        label: Text(
          _isTogglingFollow ? 'Memperbarui...' : 'Mengikuti',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.sageTua,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.sageTua, width: 1.5),
          backgroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isTogglingFollow ? null : _handleToggleFollow,
      icon: const Icon(
        Icons.person_add_rounded,
        size: 18,
        color: AppColors.teksGelap,
      ),
      label: Text(
        _isTogglingFollow ? 'Memproses...' : '+ Ikuti Penjelajah Ini',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: AppColors.teksGelap,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emas,
        minimumSize: const Size(double.infinity, 46),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildEmptyPostsCard(PublicProfileModel p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sageMuda.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: AppColors.sage,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum Ada Observasi Publik',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${p.displayName} belum membagikan catatan observasi lapangannya ke linimasa.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.teksGelap.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
