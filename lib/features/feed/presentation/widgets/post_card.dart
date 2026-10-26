// ==============================================================================
// FAUNOVA WIDGET: PostCard
// Kartu jurnal observasi postingan publik linimasa komunitas
// Sesuai Plan 5.7, 5.9, 18 & AGENTS.md (Sesi S9)
// Catatan Keras: Koordinat mentah privat TIDAK PERNAH ditampilkan di feed publik.
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../../profile/presentation/public_profile_page.dart';
import '../../models/post_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/trash_service.dart';
import 'report_post_sheet.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/media_resolver.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final bool isLiking;
  final void Function(String postId)? onReported;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.isLiking = false,
    this.onReported,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  PostModel get post => widget.post;

  late AnimationController _likeController;
  late Animation<double> _likeScaleAnimation;

  late AnimationController _doubleTapController;
  late Animation<double> _doubleTapScale;
  late Animation<double> _doubleTapOpacity;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.45).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.45, end: 0.88).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_likeController);

    _doubleTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _doubleTapScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.2, end: 1.3).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_doubleTapController);
    _doubleTapOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_doubleTapController);
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.post.isLikedByMe && widget.post.isLikedByMe) {
      _likeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    _doubleTapController.dispose();
    super.dispose();
  }

  void _handleLikeButtonTapped() {
    HapticFeedback.lightImpact();
    _likeController.forward(from: 0.0);
    widget.onLike?.call();
  }

  void _handleDoubleTapPhoto() {
    HapticFeedback.mediumImpact();
    _doubleTapController.forward(from: 0.0);
    _likeController.forward(from: 0.0);
    if (!widget.post.isLikedByMe) {
      widget.onLike?.call();
    }
  }

  Future<void> _openCoarseLocation(BuildContext context) async {
    if (!post.hasLocation) return;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${post.displayLatitude},${post.displayLongitude}',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka peta: $e'),
            backgroundColor: AppColors.merahStatus,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceContainerHighest,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.teksGelap.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Author Header
            _buildAuthorHeader(context),

            // 2. Foto Satwa & Snapped Location
            _buildPhotoSurface(context),

            // 3. Taksonomi & Catatan Lapangan (Caption)
            _buildBodyContent(context),

            // 4. Tombol Aksi (Suka, Verifikasi Blok, Lokasi)
            _buildActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PublicProfilePage(
                      userId: post.authorId,
                      initialAuthorName: post.authorName,
                      initialAuthorUsername: post.authorUsername,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  AppAvatar(
                    avatarPath: post.authorAvatar,
                    displayName: post.authorName,
                    radius: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.teksGelap,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.isAuthorVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF1E88E5),
                                size: 15,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '@${post.authorUsername} • ${post.timeAgo}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.teksGelap.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Badge Blok Rantai Kanonis
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.sageTua,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link_rounded, size: 12, color: AppColors.teksPutih),
                const SizedBox(width: 4),
                Text(
                  '#${post.blockSeq}',
                  style: const TextStyle(
                    color: AppColors.teksPutih,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          // Tombol Opsi / Laporkan Postingan / Pindahkan ke Sampah
          Builder(
            builder: (ctx) {
              String? myId;
              try {
                myId = Supabase.instance.client.auth.currentUser?.id;
              } catch (_) {}

              final isMyPost = (myId != null && myId == post.authorId) ||
                  post.authorId == '00000000-0000-0000-0000-000000000001' ||
                  post.authorUsername == 'arya_wallacea' ||
                  post.authorName == 'Saya (Kolektor)';

              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: AppColors.teksGelap.withValues(alpha: 0.7),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) async {
                  if (val == 'report') {
                    ReportPostSheet.show(
                      context,
                      post: post,
                      onReportSuccess: widget.onReported,
                    );
                  } else if (val == 'trash') {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: AppColors.gading,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: AppColors.merahStatus, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pindahkan ke Sampah?',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.teksGelap),
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Postingan ini akan disembunyikan dari linimasa publik dan dipindahkan ke Sampah selama 30 hari.',
                          style: AppTypography.bodyDefault(color: AppColors.teksGelap),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: Text('Batal', style: AppTypography.labelProminent(color: AppColors.teksGelap)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.merahStatus,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Pindahkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await TrashService.instance.trashPost(post.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Postingan dipindahkan ke Sampah (dapat dipulihkan dalam 30 hari).'),
                              backgroundColor: AppColors.sageTua,
                            ),
                          );
                          widget.onReported?.call(post.id);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.merahStatus,
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (isMyPost)
                    PopupMenuItem<String>(
                      value: 'trash',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.merahStatus),
                          const SizedBox(width: 10),
                          Text(
                            'Pindahkan ke Sampah',
                            style: AppTypography.bodyCompact(
                              fontSize: 13,
                              color: AppColors.merahStatus,
                            ),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 18, color: AppColors.merahStatus),
                        const SizedBox(width: 10),
                        Text(
                          'Laporkan Postingan',
                          style: AppTypography.bodyCompact(
                            fontSize: 13,
                            color: AppColors.merahStatus,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSurface(BuildContext context) {
    Widget imageWidget;
    final resolvedUrl = MediaResolver.resolvePhotoUrl(
      post.photoUrl,
      speciesName: post.speciesName,
      category: post.category,
    );

    if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
      imageWidget = Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.sageMuda.withValues(alpha: 0.5),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.sageTua),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.sage,
          child: const Center(
            child: Icon(Icons.pets_rounded, size: 48, color: AppColors.gading),
          ),
        ),
      );
    } else if (resolvedUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        resolvedUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.sage,
          child: const Center(
            child: Icon(Icons.pets_rounded, size: 48, color: AppColors.gading),
          ),
        ),
      );
    } else if (resolvedUrl.isNotEmpty && File(resolvedUrl).existsSync()) {
      imageWidget = Image.file(
        File(resolvedUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      imageWidget = Container(
        color: AppColors.sage,
        child: const Center(
          child: Icon(Icons.pets_rounded, size: 48, color: AppColors.gading),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        FullScreenImageViewer.open(
          context,
          imageUrl: resolvedUrl,
          title: post.speciesName,
          subtitle: '@${post.authorUsername} • ${post.category}',
          description: post.caption,
        );
      },
      onDoubleTap: _handleDoubleTapPhoto,
      child: Container(
        height: 220,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageWidget,

              // Indikator Layar Penuh
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fullscreen_rounded, size: 15, color: Colors.white),
                ),
              ),

              // Gradient halus bawah
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Top-right short hash
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    post.shortBlockHash,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),

              // Animasi Pop Big Heart saat Double Tap
              AnimatedBuilder(
                animation: _doubleTapController,
                builder: (context, child) {
                  if (_doubleTapController.isDismissed) return const SizedBox.shrink();
                  return Center(
                    child: Opacity(
                      opacity: _doubleTapOpacity.value,
                      child: Transform.scale(
                        scale: _doubleTapScale.value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.35),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.merahStatus.withValues(alpha: 0.45),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 68,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
}

  Widget _buildBodyContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Taksonomi: Nama Satwa & Nama Latin
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                post.speciesName,
                style: AppTypography.headlineSpecies(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.teksGelap,
                ),
              ),
              if (post.category != null && post.category!.isNotEmpty)
                Text(
                  post.category!,
                  style: AppTypography.subheadSpecies(
                    fontSize: 13.5,
                    color: AppColors.sageTua,
                  ),
                ),
            ],
          ),
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              post.caption,
              style: AppTypography.bodyDefault(
                fontSize: 13.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (post.hasLocation) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openCoarseLocation(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.emasTua),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        post.areaLabel ?? 'Area Kasar Terverifikasi (Grid)',
                        style: AppTypography.labelCaption(
                          color: AppColors.teksGelap,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceContainerHighest,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Tombol Like dengan Animasi Pop & Bounce
          InkWell(
            onTap: widget.isLiking ? null : _handleLikeButtonTapped,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _likeScaleAnimation,
                    child: Icon(
                      post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 21,
                      color: post.isLikedByMe ? AppColors.merahStatus : AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Text(
                      '${post.likesCount}',
                      key: ValueKey('like_${post.id}_${post.likesCount}'),
                      style: AppTypography.labelProminent(
                        color: post.isLikedByMe ? AppColors.merahStatus : AppColors.teksGelap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Label Verifikasi Rantai
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.gading,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 12, color: AppColors.sageTua),
                SizedBox(width: 4),
                Text(
                  'Koleksi Sah',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sageTua,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Tombol Buka Peta Kasar (hanya jika ada lokasi)
          if (post.hasLocation)
            InkWell(
              onTap: () => _openCoarseLocation(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emas,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_rounded, size: 13, color: AppColors.teksGelap),
                    SizedBox(width: 4),
                    Text(
                      'Peta Area',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
