import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../camera/models/capture_model.dart';
import '../capture_detail_page.dart';

class CollectionGridView extends StatelessWidget {
  final List<CaptureModel> captures;
  final VoidCallback? onRefresh;

  const CollectionGridView({
    super.key,
    required this.captures,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (captures.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets_rounded, size: 40, color: AppColors.sageTua),
            ),
            const SizedBox(height: 14),
            Text(
              'Koleksi Masih Kosong',
              style: AppTypography.titleUi(
                fontSize: 16,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Anda belum memiliki tangkapan satwa yang tersimpan. Gunakan kamera untuk memindai fauna di sekitar Anda!',
              style: AppTypography.bodyCompact(
                fontSize: 12.5,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.sageTua),
                label: Text(
                  'Segarkan Koleksi',
                  style: AppTypography.titleUi(
                    fontSize: 13,
                    color: AppColors.sageTua,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.sageTua),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: captures.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final capture = captures[index];
        return _buildCaptureCard(context, capture);
      },
    );
  }

  Widget _buildCaptureCard(BuildContext context, CaptureModel capture) {
    if (capture.isPurged) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 28, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            Text(
              'Blok #${capture.seq}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF9CA3AF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Purged (Tombstone)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              capture.shortBlockHash,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    Widget imageWidget;
    if (capture.photoObjectPath.isNotEmpty && File(capture.photoObjectPath).existsSync()) {
      imageWidget = Image.file(
        File(capture.photoObjectPath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      imageWidget = Container(
        color: AppColors.surfaceContainerHigh,
        child: const Center(
          child: Icon(Icons.pets_rounded, size: 36, color: AppColors.sageTua),
        ),
      );
    }

    // Format tanggal
    final wib = capture.receivedAt.toUtc().add(const Duration(hours: 7));
    final dateStr = '${wib.day} ${_getNamaBulan(wib.month)} ${wib.year}';

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaptureDetailPage(capture: capture),
          ),
        );
        onRefresh?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Foto + Badge Terverifikasi Stitch
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageWidget,
                    // Badge Terverifikasi Lapangan (Kiri Atas)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.sageTua,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Terverifikasi',
                              style: AppTypography.labelCaption(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teksGelap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Badge Nomor Blok Hash (Kanan Atas)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${capture.seq}',
                          style: AppTypography.labelCaption(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bagian Teks & Taksonomi Editorial
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capture.speciesName,
                      style: AppTypography.headlineSpecies(
                        fontSize: 13,
                        color: AppColors.teksGelap,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      capture.category ?? 'Fauna Tropis',
                      style: AppTypography.subheadSpecies(
                        fontSize: 11,
                        color: AppColors.sageTua,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: AppTypography.labelCaption(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNamaBulan(int month) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (month >= 1 && month <= 12) return bulan[month];
    return '';
  }
}
