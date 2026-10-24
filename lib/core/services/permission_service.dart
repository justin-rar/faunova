// ==============================================================================
// FAUNOVA SERVICE: PermissionService
// Layanan izin runtime terpusat: Kamera, Lokasi, Notifikasi, Penyimpanan
// Sesuai AGENTS.md — Sesi S14
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

class PermissionService {
  static final PermissionService instance = PermissionService._internal();
  PermissionService._internal();

  // ─── Kamera ────────────────────────────────────────────────────────────────

  /// Meminta izin kamera. Kembalikan true jika diizinkan.
  Future<bool> requestCamera(BuildContext context) async {
    return _request(
      context: context,
      permission: Permission.camera,
      title: 'Izin Kamera',
      description:
          'Faunova membutuhkan akses kamera untuk memfoto satwa liar yang kamu temukan. '
          'Foto ini digunakan untuk identifikasi spesies dan dicatat dalam koleksimu.',
      icon: Icons.camera_alt_rounded,
    );
  }

  // ─── Lokasi ────────────────────────────────────────────────────────────────

  /// Meminta izin lokasi presisi tinggi. Kembalikan true jika diizinkan.
  Future<bool> requestLocation(BuildContext context) async {
    return _request(
      context: context,
      permission: Permission.locationWhenInUse,
      title: 'Izin Lokasi',
      description:
          'Faunova menggunakan lokasimu untuk mencatat area observasi satwa. '
          'Koordinat tepat tidak pernah dibagikan ke publik — hanya grid kasar (±1 km) yang ditampilkan.',
      icon: Icons.location_on_rounded,
    );
  }

  // ─── Kamera + Lokasi sekaligus (untuk fitur Scan) ─────────────────────────

  /// Meminta kamera dan lokasi berurutan. Kembalikan true hanya jika keduanya diizinkan.
  Future<bool> requestCameraAndLocation(BuildContext context) async {
    final camera = await requestCamera(context);
    if (!camera) return false;
    if (!context.mounted) return false;
    final location = await requestLocation(context);
    return location;
  }

  // ─── Notifikasi ────────────────────────────────────────────────────────────

  /// Meminta izin notifikasi (Android 13+). Kembalikan true jika diizinkan.
  Future<bool> requestNotification(BuildContext context) async {
    return _request(
      context: context,
      permission: Permission.notification,
      title: 'Izin Notifikasi',
      description:
          'Aktifkan notifikasi untuk mendapatkan pengingat klaim streak harian, '
          'hasil kuis, dan update observasi dari penjelajah yang kamu ikuti.',
      icon: Icons.notifications_rounded,
    );
  }

  // ─── Cek status tanpa meminta ──────────────────────────────────────────────

  Future<bool> isCameraGranted() async =>
      (await Permission.camera.status).isGranted;

  Future<bool> isLocationGranted() async =>
      (await Permission.locationWhenInUse.status).isGranted;

  Future<bool> isNotificationGranted() async =>
      (await Permission.notification.status).isGranted;

  // ─── Helper utama ──────────────────────────────────────────────────────────

  Future<bool> _request({
    required BuildContext context,
    required Permission permission,
    required String title,
    required String description,
    required IconData icon,
  }) async {
    final status = await permission.status;

    // Sudah diizinkan sebelumnya
    if (status.isGranted) return true;

    // Ditolak permanen → arahkan ke pengaturan
    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await _showPermanentlyDeniedDialog(
        context: context,
        title: title,
        icon: icon,
      );
      return false;
    }

    // Belum pernah diminta atau bisa diminta ulang → tampilkan rationale dulu
    if (!context.mounted) return false;
    final proceed = await _showRationaleDialog(
      context: context,
      title: title,
      description: description,
      icon: icon,
    );
    if (!proceed) return false;

    // Minta izin sistem
    final result = await permission.request();
    return result.isGranted;
  }

  /// Dialog rationale: menjelaskan mengapa izin dibutuhkan, sebelum dialog sistem muncul
  Future<bool> _showRationaleDialog({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.gading,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.sageTua,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teksGelap,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.teksGelap,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.teksGelap,
                        side: const BorderSide(color: AppColors.sage),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Nanti',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sageTua,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Izinkan',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  /// Dialog ketika izin ditolak permanen → arahkan ke pengaturan sistem
  Future<void> _showPermanentlyDeniedDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.gading,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.merahStatus.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.merahStatus),
              ),
              const SizedBox(height: 16),
              Text(
                '$title Ditolak',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teksGelap,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Izin ini telah ditolak sebelumnya. Untuk mengaktifkannya, '
                'buka Pengaturan > Aplikasi > Faunova > Izin, lalu aktifkan izin yang diperlukan.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.teksGelap,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.teksGelap,
                        side: const BorderSide(color: AppColors.sage),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sageTua,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Buka Pengaturan',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
