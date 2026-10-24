// ==============================================================================
// FAUNOVA WIDGET: PostCard
// Kartu jurnal observasi postingan publik linimasa komunitas
// Sesuai Plan 5.7, 5.9, 18 & AGENTS.md (Sesi S9)
// Catatan Keras: Koordinat mentah privat TIDAK PERNAH ditampilkan di feed publik.
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';
import '../../../profile/presentation/public_profile_page.dart';
import '../../models/post_model.dart';

import '../../../../core/theme/app_typography.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final bool isLiking;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.isLiking = false,
  });

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
        ],
      ),
    );
  }

  Widget _buildPhotoSurface(BuildContext context) {
    Widget imageWidget;
    final url = post.photoUrl;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(
        url,
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
    } else if (url.startsWith('assets/')) {
      imageWidget = Image.asset(
        url,
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
    } else if (url.isNotEmpty && File(url).existsSync()) {
      imageWidget = Image.file(
        File(url),
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
          imageUrl: post.photoUrl,
          title: post.speciesName,
          subtitle: '@${post.authorUsername} • ${post.category}',
          description: post.caption,
        );
      },
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
          // Tombol Like
          InkWell(
            onTap: isLiking ? null : onLike,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 21,
                    color: post.isLikedByMe ? AppColors.merahStatus : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.likesCount}',
                    style: AppTypography.labelProminent(
                      color: post.isLikedByMe ? AppColors.merahStatus : AppColors.teksGelap,
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
