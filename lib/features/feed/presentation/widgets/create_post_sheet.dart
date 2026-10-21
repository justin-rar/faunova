// ==============================================================================
// FAUNOVA WIDGET: CreatePostSheet
// Lembar modal pembuatan postingan publik dari tangkapan satwa koleksi
// Sesuai Plan 5.7, 5.9, 18 & AGENTS.md (Sesi S9)
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/post_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../camera/models/capture_model.dart';
import '../../models/post_model.dart';

class CreatePostSheet extends StatefulWidget {
  final CaptureModel capture;
  final ValueChanged<PostModel>? onPostCreated;

  const CreatePostSheet({
    super.key,
    required this.capture,
    this.onPostCreated,
  });

  static Future<PostModel?> show(
    BuildContext context, {
    required CaptureModel capture,
    ValueChanged<PostModel>? onPostCreated,
  }) {
    return showModalBottomSheet<PostModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreatePostSheet(
        capture: capture,
        onPostCreated: onPostCreated,
      ),
    );
  }

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  String _visibility = 'coarse'; // 'coarse' atau 'hidden'
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _areaController.text = widget.capture.latitude != null
        ? 'Wilayah Observasi Lapangan'
        : '';
  }

  @override
  void dispose() {
    _captionController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      setState(() {
        _errorMessage = 'Tuliskan catatan atau takarir observasi satwa.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final post = await PostService.instance.createPost(
        captureId: widget.capture.id,
        caption: caption,
        visibility: _visibility,
        areaLabel: _visibility == 'coarse' ? _areaController.text.trim() : null,
        demoSpeciesName: widget.capture.speciesName,
        demoCategory: widget.capture.category,
        demoPhotoPath: widget.capture.photoObjectPath,
        demoBlockSeq: widget.capture.seq,
        demoBlockHash: widget.capture.blockHash,
        demoPhotoSha256: widget.capture.photoSha256,
        demoRawLat: widget.capture.latitude,
        demoRawLng: widget.capture.longitude,
      );

      if (mounted) {
        widget.onPostCreated?.call(post);
        Navigator.pop(context, post);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Observasi berhasil dibagikan ke linimasa publik!'),
            backgroundColor: AppColors.sageTua,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    Widget imageThumbnail;
    if (widget.capture.photoObjectPath.isNotEmpty &&
        File(widget.capture.photoObjectPath).existsSync()) {
      imageThumbnail = Image.file(
        File(widget.capture.photoObjectPath),
        width: 72,
        height: 72,
        fit: BoxFit.cover,
      );
    } else {
      imageThumbnail = Container(
        width: 72,
        height: 72,
        color: AppColors.sageMuda,
        child: const Icon(Icons.pets_rounded, color: AppColors.sageTua, size: 36),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header title
            const Row(
              children: [
                Icon(Icons.share_outlined, color: AppColors.sageTua, size: 22),
                SizedBox(width: 8),
                Text(
                  'Publikasikan Observasi ke Linimasa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teksGelap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Card Ringkasan Satwa
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageThumbnail,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.emas,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${widget.capture.seq}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.teksGelap,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.capture.speciesName,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teksGelap,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (widget.capture.category != null && widget.capture.category!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.capture.category!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.emasTua,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Hash: ${widget.capture.shortBlockHash}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.teksGelap.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Form Caption
            TextField(
              controller: _captionController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Tuliskan catatan lapangan atau cerita perjumpaan dengan satwa ini...',
                hintStyle: TextStyle(fontSize: 12.5, color: AppColors.teksGelap.withValues(alpha: 0.5)),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.sage.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Pengaturan Privasi Lokasi (Plan 5.7)
            const Text(
              'Privasi Lokasi Publik (Plan 5.7):',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.blur_circular_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Area Kasar (Grid)'),
                      ],
                    ),
                    selected: _visibility == 'coarse',
                    onSelected: (val) {
                      if (val) setState(() => _visibility = 'coarse');
                    },
                    selectedColor: AppColors.sageTua,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _visibility == 'coarse' ? AppColors.teksPutih : AppColors.teksGelap,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_off_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Sembunyikan'),
                      ],
                    ),
                    selected: _visibility == 'hidden',
                    onSelected: (val) {
                      if (val) setState(() => _visibility = 'hidden');
                    },
                    selectedColor: AppColors.sageTua,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _visibility == 'hidden' ? AppColors.teksPutih : AppColors.teksGelap,
                    ),
                  ),
                ),
              ],
            ),

            if (_visibility == 'coarse') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: 'Label Wilayah (Kecamatan/Kota, bukan jalan)',
                  labelStyle: const TextStyle(fontSize: 12, color: AppColors.teksGelap),
                  hintText: 'Contoh: Taman Nasional Bali Barat',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.sage.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '• Grid snapping server 0.01° mengaburkan koordinat asli demi keselamatan satwa liar.',
                style: TextStyle(fontSize: 11, color: AppColors.emasTua, height: 1.3),
              ),
            ] else ...[
              const SizedBox(height: 6),
              const Text(
                '• Postingan tidak akan memuat koordinat, radius peta, atau label wilayah apa pun.',
                style: TextStyle(fontSize: 11, color: AppColors.merahStatus, height: 1.3),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.merahStatus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.merahStatus, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.merahStatus),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Tombol Kirim
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emas,
                  foregroundColor: AppColors.teksGelap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teksGelap),
                      )
                    : const Text(
                        'Bagikan ke Linimasa Komunitas',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
