// ==============================================================================
// FAUNOVA WIDGET: FullScreenImageViewer
// Penampil Foto Layar Penuh dengan Pinch-to-Zoom, Pan, dan Metadata Satwa
// Sesuai Aturan Desain AGENTS.md & Standar Pengalaman Visual
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/media_resolver.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? heroTag;
  final String? description;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.heroTag,
    this.description,
  });

  /// Membuka penampil foto layar penuh secara instan dengan transisi halus
  static void open(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? subtitle,
    String? heroTag,
    String? description,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FullScreenImageViewer(
              imageUrl: imageUrl,
              title: title,
              subtitle: subtitle,
              heroTag: heroTag,
              description: description,
            ),
          );
        },
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _showControls = true;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _transformationController.value = Matrix4.diagonal3Values(2.5, 2.5, 1.0)
        ..setTranslationRaw(-position.dx * 1.5, -position.dy * 1.5, 0.0);
    }
  }

  Widget _buildImage() {
    final url = MediaResolver.resolvePhotoUrl(
      widget.imageUrl,
      speciesName: widget.title,
      category: widget.subtitle,
    );
    Widget img;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      img = Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gading),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_rounded, color: AppColors.sageMuda, size: 54),
              SizedBox(height: 10),
              Text(
                'Gagal memuat foto satwa resolusi penuh',
                style: TextStyle(color: AppColors.gading, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    } else if (url.startsWith('assets/')) {
      img = Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.sageMuda, size: 54),
        ),
      );
    } else if (url.isNotEmpty && File(url).existsSync()) {
      img = Image.file(
        File(url),
        fit: BoxFit.contain,
      );
    } else {
      img = const Center(
        child: Icon(Icons.pets_rounded, color: AppColors.sageMuda, size: 54),
      );
    }

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: img);
    }
    return img;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Area foto dengan Zoom & Pan
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.8,
              maxScale: 4.5,
              child: Center(
                child: _buildImage(),
              ),
            ),
          ),

          // Header Bar (Tombol Kembali & Judul)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 8, 16, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup Foto',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null)
                          Text(
                            widget.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Footer Info Satwa
          if (widget.description != null && widget.description!.isNotEmpty)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              bottom: _showControls ? 0 : -120,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  widget.description!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
