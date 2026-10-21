// ==============================================================================
// FAUNOVA WIDGET: BadgeCelebrationDialog & BadgeDetailSheet
// Dialog pop-up perayaan & lembar detail lencana gelar pencapaian (Plan 204)
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/badge_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/badge_model.dart';

class BadgeCelebrationDialog extends StatelessWidget {
  final BadgeModel badge;

  const BadgeCelebrationDialog({super.key, required this.badge});

  static Future<void> show(BuildContext context, {required BadgeModel badge}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BadgeCelebrationDialog(badge: badge),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconData = BadgeService.getBadgeIcon(badge.iconName);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.gading,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.emas.withValues(alpha: 0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emblem Emas & Lingkaran Sage
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.sageTua,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.emas, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emas.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                iconData,
                color: AppColors.emas,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),

            // Judul Perayaan
            const Text(
              'Lencana Baru Terbuka! 🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.teksGelap,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Nama Badge
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.emasTua,
                letterSpacing: 0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Deskripsi Syarat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.sageMuda,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.teksGelap,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),

            // Tombol Konfirmasi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  BadgeService.instance.markBadgeCelebrated(badge.id);
                  Navigator.of(context).pop();
                },
                child: const Text('Klaim & Lanjutkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BadgeDetailSheet extends StatelessWidget {
  final BadgeModel badge;

  const BadgeDetailSheet({super.key, required this.badge});

  static Future<void> show(BuildContext context, {required BadgeModel badge}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BadgeDetailSheet(badge: badge),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconData = BadgeService.getBadgeIcon(badge.iconName);
    final progressFraction = (badge.actualProgress / badge.targetCount).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 18),

          // Icon Emblem
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: badge.isUnlocked ? AppColors.sageTua : AppColors.sageMuda,
              shape: BoxShape.circle,
              border: Border.all(
                color: badge.isUnlocked ? AppColors.emas : AppColors.sage.withValues(alpha: 0.5),
                width: 2.5,
              ),
            ),
            child: Icon(
              badge.isUnlocked ? iconData : Icons.lock_rounded,
              color: badge.isUnlocked ? AppColors.emas : AppColors.sage,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            badge.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 4),

          // Kategori & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge.category,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.teksGelap),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badge.isUnlocked ? AppColors.sageTua : AppColors.merahStatus.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge.isUnlocked ? 'Terbuka' : 'Terkunci',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badge.isUnlocked ? AppColors.teksPutih : AppColors.merahStatus,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Deskripsi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.35), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Syarat Pembukaan:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.teksGelap, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres Capaian',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teksGelap),
              ),
              Text(
                '${badge.actualProgress} / ${badge.targetCount}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emasTua),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 8,
              backgroundColor: AppColors.sageMuda,
              valueColor: AlwaysStoppedAnimation<Color>(
                badge.isUnlocked ? AppColors.sageTua : AppColors.emas,
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }
}
