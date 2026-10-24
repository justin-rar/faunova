// ==============================================================================
// FAUNOVA WIDGET: CollectionGridView
// Menampilkan daftar tangkapan satwa koleksi dalam format grid 2 kolom
// Sesuai Plan 5.2, 5.3 & AGENTS.md (Sesi S8)
// ==============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
          border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sageMuda.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets_rounded, size: 40, color: AppColors.sageTua),
            ),
            const SizedBox(height: 14),
            const Text(
              'Koleksi Masih Kosong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Anda belum memiliki tangkapan satwa yang tersimpan. Gunakan kamera untuk memindai fauna di sekitar Anda!',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.teksGelap.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.sageTua),
                label: const Text(
                  'Segarkan Koleksi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
        childAspectRatio: 0.76,
      ),
      itemBuilder: (context, index) {
        final capture = captures[index];
        return _buildCaptureCard(context, capture);
      },
    );
  }

  Widget _buildCaptureCard(BuildContext context, CaptureModel capture) {
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
        color: AppColors.sageMuda,
        child: const Center(
          child: Icon(Icons.pets_rounded, size: 40, color: AppColors.sageTua),
        ),
      );
    }

    // Format tanggal
    final wib = capture.receivedAt.toUtc().add(const Duration(hours: 7));
    final dateStr = '${wib.day} ${_getNamaBulan(wib.month)} ${wib.year}';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaptureDetailPage(capture: capture),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Foto + Badge Blok
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageWidget,
                    // Gradient overlay di bagian atas foto
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Badge Nomor Blok Hash
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.sageTua.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.emas.withValues(alpha: 0.7), width: 1),
                        ),
                        child: Text(
                          '#${capture.seq}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bagian Teks & Taksonomi
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capture.speciesName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teksGelap,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      capture.category ?? 'Fauna',
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: AppColors.emasTua,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.teksGelap.withValues(alpha: 0.6),
                          ),
                        ),
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: AppColors.sageTua,
                        ),
                      ],
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
