// ==============================================================================
// FAUNOVA PRESENTATION: FeedPage
// Halaman Linimasa Komunitas Dua Tab: "Mengikuti" dan "Untuk Kamu"
// Sesuai Plan 5.7, 5.9, 18 & AGENTS.md (Sesi S9 & S10)
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/social_service.dart';
import '../../../core/services/trash_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_state_view.dart';
import '../models/post_model.dart';
import 'widgets/post_card.dart';
import 'widgets/social_notification_sheet.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PostModel> _forYouPosts = [];
  List<PostModel> _followingPosts = [];
  bool _isLoadingFeed = false;
  String? _feedError;

  AppViewStatus get _followingFeedStatus {
    if (_isLoadingFeed && _followingPosts.isEmpty) return AppViewStatus.loading;
    if (_feedError != null && _followingPosts.isEmpty) return AppViewStatus.error;
    if (!_isLoadingFeed && _followingPosts.isEmpty) return AppViewStatus.empty;
    return AppViewStatus.content;
  }

  AppViewStatus get _forYouFeedStatus {
    if (_isLoadingFeed && _forYouPosts.isEmpty) return AppViewStatus.loading;
    if (_feedError != null && _forYouPosts.isEmpty) return AppViewStatus.error;
    if (!_isLoadingFeed && _forYouPosts.isEmpty) return AppViewStatus.empty;
    return AppViewStatus.content;
  }

  @override
  void initState() {
    super.initState();
    // Default aktif di tab 'Untuk Kamu' (index 1), persis seperti referensi desain
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    PostService.instance.onPostCreatedNotifier.addListener(_handleNewPostCreated);
    PostService.instance.onPostReportedNotifier.addListener(_handlePostReportedFromNotifier);
    TrashService.instance.onTrashChangedNotifier.addListener(_handleTrashChanged);
    _loadFeed();

    // Inisialisasi listener notifikasi Realtime untuk pengguna yang login
    try {
      final currentUid = Supabase.instance.client.auth.currentUser?.id;
      if (currentUid != null) {
        NotificationService.instance.initRealtimeListener(currentUid);
        NotificationService.instance.fetchServerNotifications();
      }
    } catch (_) {}
  }

  void _handlePostReported(String postId) {
    if (mounted) {
      setState(() {
        _forYouPosts = _forYouPosts.where((p) => p.id != postId).toList();
        _followingPosts = _followingPosts.where((p) => p.id != postId).toList();
      });
    }
  }

  void _handlePostReportedFromNotifier() {
    final reportedId = PostService.instance.onPostReportedNotifier.value;
    if (reportedId != null) {
      _handlePostReported(reportedId);
    }
  }

  void _handleNewPostCreated() {
    final newPost = PostService.instance.onPostCreatedNotifier.value;
    if (newPost != null && mounted) {
      setState(() {
        _forYouPosts = [newPost, ..._forYouPosts.where((p) => p.id != newPost.id)];
        _followingPosts = [newPost, ..._followingPosts.where((p) => p.id != newPost.id)];
      });
    }
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
    final postId = post.id;

    // Ambil data terbaru dari list aktif, bukan dari snapshot parameter yang mungkin out-of-date
    PostModel? currentPost;
    final wi = _followingPosts.indexWhere((p) => p.id == postId);
    if (wi != -1) {
      currentPost = _followingPosts[wi];
    } else {
      final fi = _forYouPosts.indexWhere((p) => p.id == postId);
      if (fi != -1) {
        currentPost = _forYouPosts[fi];
      }
    }
    currentPost ??= post;

    void applyLikeState(bool liked, int count) {
      if (!mounted) return;
      setState(() {
        final fi = _forYouPosts.indexWhere((p) => p.id == postId);
        if (fi != -1) {
          _forYouPosts[fi] = _forYouPosts[fi].copyWith(isLikedByMe: liked, likesCount: count);
        }
        final wi = _followingPosts.indexWhere((p) => p.id == postId);
        if (wi != -1) {
          _followingPosts[wi] = _followingPosts[wi].copyWith(isLikedByMe: liked, likesCount: count);
        }
      });
    }

    final currentLiked = currentPost.isLikedByMe;
    final newLiked = !currentLiked;
    final newCount = newLiked ? currentPost.likesCount + 1 : (currentPost.likesCount > 0 ? currentPost.likesCount - 1 : 0);

    // Optimistic update
    applyLikeState(newLiked, newCount);

    try {
      final result = await PostService.instance.togglePostLike(
        postId,
        targetAuthorId: currentPost.authorId,
        speciesName: currentPost.speciesName,
      );
      if (result['likes_count'] != null) {
        final serverLiked = result['is_liked'] == true;
        final serverCount = (result['likes_count'] as num).toInt();
        applyLikeState(serverLiked, serverCount);
      }
    } catch (e) {
      debugPrint('Error toggling like in feed: $e');
      // Rollback ke state sebelumnya
      applyLikeState(currentLiked, currentPost.likesCount);
    }
  }


  void _handleTrashChanged() {
    if (mounted) {
      _loadFeed();
    }
  }

  @override
  void dispose() {
    PostService.instance.onPostCreatedNotifier.removeListener(_handleNewPostCreated);
    PostService.instance.onPostReportedNotifier.removeListener(_handlePostReportedFromNotifier);
    TrashService.instance.onTrashChangedNotifier.removeListener(_handleTrashChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gading,
      appBar: AppBar(
        backgroundColor: AppColors.sageTua,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/faunova_logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.pets_rounded,
                color: AppColors.teksPutih,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Faunova',
              style: TextStyle(
                color: AppColors.teksPutih,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ValueListenableBuilder<int>(
              valueListenable: NotificationService.instance.unreadCountNotifier,
              builder: (context, unreadCount, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Pusat Notifikasi Sosial',
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.teksPutih,
                        size: 24,
                      ),
                      onPressed: () => SocialNotificationSheet.show(context),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.emas,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.teksGelap.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.gading,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: AppColors.teksGelap,
              unselectedLabelColor: AppColors.teksPutih.withValues(alpha: 0.85),
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Mengikuti'),
                Tab(text: 'Untuk Kamu'),
              ],
            ),
          ),
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
    const topPadding = 12.0;
    return AppStateView(
      status: _followingFeedStatus,
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
                Builder(builder: (context) {
                  final post = _followingPosts[i];
                  return PostCard(
                    key: ValueKey('following_${post.id}'),
                    post: post,
                    onLike: () => _toggleLike(post),
                    onReported: _handlePostReported,
                  );
                }),
                if (i < _followingPosts.length - 1) const SizedBox(height: 18),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildForYouFeed() {
    const topPadding = 12.0;
    return AppStateView(
      status: _forYouFeedStatus,
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
                Builder(builder: (context) {
                  final post = _forYouPosts[i];
                  return PostCard(
                    key: ValueKey('foryou_${post.id}'),
                    post: post,
                    onLike: () => _toggleLike(post),
                    onReported: _handlePostReported,
                  );
                }),
                if (i < _forYouPosts.length - 1) const SizedBox(height: 18),
              ],
          ],
        ),
      ),
    );
  }
}
