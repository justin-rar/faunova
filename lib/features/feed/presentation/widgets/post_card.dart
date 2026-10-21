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
import '../../../profile/presentation/public_profile_page.dart';
import '../../models/post_model.dart';

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
          color: AppColors.sageMuda,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.sage.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
            _buildBodyContent(),

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
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: AppColors.sageTua,
                    child: Text(
                      post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.teksPutih,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
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
    if (post.photoUrl.isNotEmpty && File(post.photoUrl).existsSync()) {
      imageWidget = Image.file(
        File(post.photoUrl),
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

    return Container(
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

            // Snapped Location Pill (Hanya jika coarse, jika hidden TIDAK ADA)
            if (post.hasLocation)
              Positioned(
                bottom: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => _openCoarseLocation(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: AppColors.emas),
                        const SizedBox(width: 4),
                        Text(
                          post.areaLabel ?? 'Area Perkiraan (Grid 0.01°)',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.speciesName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teksGelap,
                  ),
                ),
              ),
            ],
          ),
          if (post.category != null && post.category!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              post.category!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: AppColors.emasTua,
              ),
            ),
          ],
          if (post.caption.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.caption,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.teksGelap.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 14, 12),
      child: Row(
        children: [
          // Tombol Like
          InkWell(
            onTap: isLiking ? null : onLike,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: post.isLikedByMe ? AppColors.merahStatus : AppColors.teksGelap,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
