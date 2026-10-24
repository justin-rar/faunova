// ==============================================================================
// FAUNOVA WIDGET: FollowListSheet
// Lembar modal interaktif untuk melihat daftar Pengikut (Followers)
// dan akun yang Mengikuti (Following) milik akun sendiri maupun profil orang lain.
// Sesuai AGENTS.md (Palet Faunova, RLS, Penanganan Loading/Error/Empty)
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/social_service.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../models/public_profile_model.dart';
import '../public_profile_page.dart';

enum FollowTab { followers, following }

class FollowListSheet extends StatefulWidget {
  final String userId;
  final String displayName;
  final String username;
  final FollowTab initialTab;
  final VoidCallback? onFollowStatusChanged;

  const FollowListSheet({
    super.key,
    required this.userId,
    required this.displayName,
    required this.username,
    this.initialTab = FollowTab.followers,
    this.onFollowStatusChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String displayName,
    required String username,
    FollowTab initialTab = FollowTab.followers,
    VoidCallback? onFollowStatusChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FollowListSheet(
        userId: userId,
        displayName: displayName,
        username: username,
        initialTab: initialTab,
        onFollowStatusChanged: onFollowStatusChanged,
      ),
    );
  }

  @override
  State<FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends State<FollowListSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<PublicProfileModel> _followers = [];
  List<PublicProfileModel> _following = [];

  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;
  String? _followersError;
  String? _followingError;

  String _searchQuery = '';
  final Set<String> _togglingUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == FollowTab.followers ? 0 : 1,
    );
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadFollowers(),
      _loadFollowing(),
    ]);
  }

  Future<void> _loadFollowers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFollowers = true;
      _followersError = null;
    });

    try {
      final list = await SocialService.instance.fetchUserFollowers(widget.userId);
      if (mounted) {
        setState(() {
          _followers = list;
          _isLoadingFollowers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _followersError = 'Gagal memuat pengikut: ${e.toString()}';
          _isLoadingFollowers = false;
        });
      }
    }
  }

  Future<void> _loadFollowing() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFollowing = true;
      _followingError = null;
    });

    try {
      final list = await SocialService.instance.fetchUserFollowing(widget.userId);
      if (mounted) {
        setState(() {
          _following = list;
          _isLoadingFollowing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _followingError = 'Gagal memuat daftar mengikuti: ${e.toString()}';
          _isLoadingFollowing = false;
        });
      }
    }
  }

  Future<void> _handleToggleFollow(PublicProfileModel user) async {
    if (_togglingUserIds.contains(user.id)) return;

    setState(() {
      _togglingUserIds.add(user.id);
    });

    final previousStatus = user.isFollowedByMe;
    final targetId = user.id;

    // Update optimis UI
    _updateLocalFollowState(targetId, !previousStatus);

    try {
      final res = await SocialService.instance.toggleFollow(targetId);
      final isNowFollowing = res['is_following'] == true;
      _updateLocalFollowState(targetId, isNowFollowing);
      widget.onFollowStatusChanged?.call();
    } catch (e) {
      // Rollback jika gagal
      _updateLocalFollowState(targetId, previousStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.merahStatus,
            content: Text(
              'Gagal mengubah status: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _togglingUserIds.remove(targetId);
        });
      }
    }
  }

  void _updateLocalFollowState(String targetId, bool isFollowing) {
    if (!mounted) return;
    setState(() {
      _followers = _followers.map((u) {
        if (u.id == targetId) {
          return u.copyWith(isFollowedByMe: isFollowing);
        }
        return u;
      }).toList();

      final exists = _following.any((u) => u.id == targetId);
      if (isFollowing) {
        if (!exists) {
          final fromFollowers = _followers.where((u) => u.id == targetId).firstOrNull;
          if (fromFollowers != null) {
            _following.insert(0, fromFollowers.copyWith(isFollowedByMe: true));
          }
        } else {
          _following = _following.map((u) {
            if (u.id == targetId) return u.copyWith(isFollowedByMe: true);
            return u;
          }).toList();
        }
      } else {
        _following = _following.map((u) {
          if (u.id == targetId) return u.copyWith(isFollowedByMe: false);
          return u;
        }).toList();
      }
    });
  }

  List<PublicProfileModel> _filterList(List<PublicProfileModel> list) {
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((u) {
      return u.displayName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.bio.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.82;

    return Container(
      height: sheetHeight,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header: Judul & Tombol Tutup
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${widget.username}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.teksGelap.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.teksGelap, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sageMuda.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.sageTua,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: AppColors.teksPutih,
              unselectedLabelColor: AppColors.teksGelap,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(
                  text: _isLoadingFollowers
                      ? 'Pengikut'
                      : 'Pengikut (${_followers.length})',
                ),
                Tab(
                  text: _isLoadingFollowing
                      ? 'Mengikuti'
                      : 'Mengikuti (${_following.length})',
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(fontSize: 13, color: AppColors.teksGelap),
              decoration: InputDecoration(
                hintText: 'Cari penjelajah atau @username...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.teksGelap.withValues(alpha: 0.5),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.sageTua),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.teksGelap),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.sage.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.sage.withValues(alpha: 0.3)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.sageTua, width: 1.4),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(
                  users: _filterList(_followers),
                  isLoading: _isLoadingFollowers,
                  error: _followersError,
                  emptyTitle: 'Belum Ada Pengikut',
                  emptyMessage: _searchQuery.isNotEmpty
                      ? 'Tidak ada pengikut yang cocok dengan "$_searchQuery".'
                      : '${widget.displayName} belum memiliki pengikut.',
                  onRetry: _loadFollowers,
                ),
                _buildUserList(
                  users: _filterList(_following),
                  isLoading: _isLoadingFollowing,
                  error: _followingError,
                  emptyTitle: 'Belum Mengikuti Siapa Pun',
                  emptyMessage: _searchQuery.isNotEmpty
                      ? 'Tidak ada akun yang cocok dengan "$_searchQuery".'
                      : '${widget.displayName} belum mengikuti penjelajah lain.',
                  onRetry: _loadFollowing,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList({
    required List<PublicProfileModel> users,
    required bool isLoading,
    required String? error,
    required String emptyTitle,
    required String emptyMessage,
    required VoidCallback onRetry,
  }) {
    if (isLoading) {
      return const AppStateView(
        status: AppViewStatus.loading,
        loadingMessage: 'Memuat data penjelajah satwa...',
        child: SizedBox.shrink(),
      );
    }

    if (error != null) {
      return AppStateView(
        status: AppViewStatus.error,
        errorMessage: error,
        onRetry: onRetry,
        child: const SizedBox.shrink(),
      );
    }

    if (users.isEmpty) {
      return AppStateView(
        status: AppViewStatus.empty,
        emptyTitle: emptyTitle,
        emptyMessage: emptyMessage,
        child: const SizedBox.shrink(),
      );
    }

    return RefreshIndicator(
      color: AppColors.sageTua,
      backgroundColor: Colors.white,
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 0.8,
          color: Color(0xFFE4ECE0),
        ),
        itemBuilder: (context, index) {
          final user = users[index];
          final isToggling = _togglingUserIds.contains(user.id);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Jika ini bukan profil yang sama dengan yang sedang dibuka
              if (user.id != widget.userId) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => PublicProfilePage(
                      userId: user.id,
                      initialAuthorName: user.displayName,
                      initialAuthorUsername: user.username,
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  AppAvatar(
                    avatarPath: user.avatarPath,
                    displayName: user.displayName,
                    radius: 23,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teksGelap,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isVerifiedActive) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF1E88E5),
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.teksGelap.withValues(alpha: 0.65),
                          ),
                        ),
                        if (user.bio.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            user.bio,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.teksGelap.withValues(alpha: 0.8),
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Tombol Ikuti / Mengikuti
                  if (user.isMyProfile)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.sageMuda.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Anda',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teksGelap,
                        ),
                      ),
                    )
                  else if (user.isFollowedByMe)
                    OutlinedButton(
                      onPressed: isToggling ? null : () => _handleToggleFollow(user),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.sageTua, width: 1.2),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(82, 32),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isToggling
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageTua),
                            )
                          : const Text(
                              'Mengikuti',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sageTua,
                              ),
                            ),
                    )
                  else
                    ElevatedButton(
                      onPressed: isToggling ? null : () => _handleToggleFollow(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emas,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(82, 32),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isToggling
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teksGelap),
                            )
                          : const Text(
                              '+ Ikuti',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teksGelap,
                              ),
                            ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
