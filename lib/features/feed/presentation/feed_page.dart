// ==============================================================================
// FAUNOVA PRESENTATION: FeedPage
// Halaman Linimasa Komunitas Dua Tab: "Mengikuti" dan "Untuk Kamu"
// Sesuai Plan 5.7, 5.9, 18 & AGENTS.md (Sesi S9 & S10)
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/social_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../models/post_model.dart';
import 'widgets/post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AppViewStatus _currentStatus = AppViewStatus.content;

  List<PostModel> _forYouPosts = [];
  List<PostModel> _followingPosts = [];
  bool _isLoadingFeed = false;
  String? _feedError;

  @override
  void initState() {
    super.initState();
    // Default aktif di tab 'Untuk Kamu' (index 1), persis seperti referensi desain
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoadingFeed = true;
      _feedError = null;
    });

    try {
      final results = await Future.wait([
        PostService.instance.fetchForYouFeed(),
        SocialService.instance.fetchFollowingFeed(),
      ]);

      if (mounted) {
        setState(() {
          _forYouPosts = results[0];
          _followingPosts = results[1];
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedError = e.toString();
          _isLoadingFeed = false;
        });
      }
    }
  }

  Future<void> _toggleLike(PostModel post) async {
    // Sinkronisasi status like di kedua tab (idempoten)
    final forYouIdx = _forYouPosts.indexWhere((p) => p.id == post.id);
    final followingIdx = _followingPosts.indexWhere((p) => p.id == post.id);

    final currentLiked = post.isLikedByMe;
    final newLiked = !currentLiked;
    final newCount = newLiked ? post.likesCount + 1 : (post.likesCount > 0 ? post.likesCount - 1 : 0);

    setState(() {
      if (forYouIdx != -1) {
        _forYouPosts[forYouIdx] = _forYouPosts[forYouIdx].copyWith(
          isLikedByMe: newLiked,
          likesCount: newCount,
        );
      }
      if (followingIdx != -1) {
        _followingPosts[followingIdx] = _followingPosts[followingIdx].copyWith(
          isLikedByMe: newLiked,
          likesCount: newCount,
        );
      }
    });

    try {
      final result = await PostService.instance.togglePostLike(post.id);
      if (mounted && result['likes_count'] != null) {
        final serverLiked = result['is_liked'] == true;
        final serverCount = (result['likes_count'] as num).toInt();

        setState(() {
          if (forYouIdx != -1) {
            _forYouPosts[forYouIdx] = _forYouPosts[forYouIdx].copyWith(
              isLikedByMe: serverLiked,
              likesCount: serverCount,
            );
          }
          if (followingIdx != -1) {
            _followingPosts[followingIdx] = _followingPosts[followingIdx].copyWith(
              isLikedByMe: serverLiked,
              likesCount: serverCount,
            );
          }
        });
      }
    } catch (_) {
      // Rollback jika server gagal
      if (mounted) {
        setState(() {
          if (forYouIdx != -1) {
            _forYouPosts[forYouIdx] = _forYouPosts[forYouIdx].copyWith(
              isLikedByMe: currentLiked,
              likesCount: post.likesCount,
            );
          }
          if (followingIdx != -1) {
            _followingPosts[followingIdx] = _followingPosts[followingIdx].copyWith(
              isLikedByMe: currentLiked,
              likesCount: post.likesCount,
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.label,
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.white),
            insets: EdgeInsets.symmetric(horizontal: 10),
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.60),
          labelStyle: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          tabs: const [
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Mengikuti'),
              ),
            ),
            Tab(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Untuk Kamu'),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowingFeed(),
          _buildForYouFeed(),
        ],
      ),
    );
  }

  Widget _buildFollowingFeed() {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 12;
    return AppStateView(
      status: _currentStatus,
      loadingMessage: 'Sinkronisasi feed akun yang diikuti...',
      emptyTitle: 'Belum Mengikuti Penjelajah',
      emptyMessage: 'Cari kolektor satwa dan ikuti jurnal observasi lapangan mereka!',
      errorMessage: 'Gagal memuat feed mengikuti. Periksa sambungan data Anda.',
      offlineMessage: 'Mode luring. Menampilkan postingan tersimpan dari cache terenkripsi.',
      onRetry: _loadFeed,
      child: RefreshIndicator(
        onRefresh: _loadFeed,
        color: AppColors.sageTua,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 110),
          children: [
            _buildStateSwitcherCard(),
            const SizedBox(height: 16),
            if (_isLoadingFeed && _followingPosts.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: AppColors.sageTua),
              )
            else if (_feedError != null && _followingPosts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.merahStatus, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _feedError!,
                      style: const TextStyle(fontSize: 12, color: AppColors.teksGelap),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _loadFeed,
                      child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )
            else if (_followingPosts.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sageMuda.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_outline_rounded, size: 36, color: AppColors.sageTua),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum Mengikuti Penjelajah',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ikuti penjelajah satwa lain untuk melihat observasi lapangan terbaru mereka di sini.',
                      style: TextStyle(fontSize: 12, color: AppColors.teksGelap.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _tabController.animateTo(1); // Beralih ke tab 'Untuk Kamu'
                      },
                      icon: const Icon(Icons.explore_rounded, size: 16, color: AppColors.teksGelap),
                      label: const Text('Jelajahi Tab "Untuk Kamu"'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emas,
                        foregroundColor: AppColors.teksGelap,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (int i = 0; i < _followingPosts.length; i++) ...[
                PostCard(
                  post: _followingPosts[i],
                  onLike: () => _toggleLike(_followingPosts[i]),
                ),
                if (i < _followingPosts.length - 1) const SizedBox(height: 18),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildForYouFeed() {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 12;
    return AppStateView(
      status: _currentStatus,
      loadingMessage: 'Sinkronisasi feed observasi satwa...',
      emptyTitle: 'Belum Ada Observasi',
      emptyMessage: 'Ikuti penjelajah lain atau potret satwa liar pertamamu untuk memulai rantai!',
      errorMessage: 'Gagal memuat feed lapangan. Periksa sambungan data Anda.',
      offlineMessage: 'Mode luring. Menampilkan postingan tersimpan dari cache terenkripsi.',
      onRetry: _loadFeed,
      child: RefreshIndicator(
        onRefresh: _loadFeed,
        color: AppColors.sageTua,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, topPadding, 16, 110),
          children: [
            _buildStateSwitcherCard(),
            const SizedBox(height: 16),
            if (_isLoadingFeed && _forYouPosts.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: AppColors.sageTua),
              )
            else if (_feedError != null && _forYouPosts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.merahStatus, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _feedError!,
                      style: const TextStyle(fontSize: 12, color: AppColors.teksGelap),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _loadFeed,
                      child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )
            else if (_forYouPosts.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.sageMuda.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.dynamic_feed_rounded, size: 36, color: AppColors.sageTua),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum Ada Postingan Publik',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jadilah yang pertama membagikan observasi satwa ke linimasa komunitas Faunova!',
                      style: TextStyle(fontSize: 12, color: AppColors.teksGelap.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              for (int i = 0; i < _forYouPosts.length; i++) ...[
                PostCard(
                  post: _forYouPosts[i],
                  onLike: () => _toggleLike(_forYouPosts[i]),
                ),
                if (i < _forYouPosts.length - 1) const SizedBox(height: 18),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateSwitcherCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: AppColors.teksGelap),
              SizedBox(width: 8),
              Text(
                'Pengujian State Fitur (AGENTS.md)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.teksGelap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildStateChip('Normal', AppViewStatus.content),
              _buildStateChip('Memuat', AppViewStatus.loading),
              _buildStateChip('Kosong', AppViewStatus.empty),
              _buildStateChip('Galat', AppViewStatus.error),
              _buildStateChip('Luring', AppViewStatus.offline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateChip(String label, AppViewStatus status) {
    final isSelected = _currentStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _currentStatus = status;
        });
      },
      selectedColor: AppColors.sageTua,
      backgroundColor: AppColors.gading,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.teksPutih : AppColors.teksGelap,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}
