import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppViewStatus {
  content,
  loading,
  empty,
  error,
  offline,
}

/// Widget serbaguna untuk menangani 4 state wajib (AGENTS.md):
/// loading (memuat), error (galat), kosong (empty), dan offline (luring).
class AppStateView extends StatelessWidget {
  final AppViewStatus status;
  final Widget child;
  final String? loadingMessage;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? errorMessage;
  final String? offlineMessage;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const AppStateView({
    super.key,
    required this.status,
    required this.child,
    this.loadingMessage,
    this.emptyTitle,
    this.emptyMessage,
    this.errorMessage,
    this.offlineMessage,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AppViewStatus.content:
        return child;

      case AppViewStatus.loading:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.sageTua),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  loadingMessage ?? 'Sedang memuat data...',
                  style: const TextStyle(
                    color: AppColors.teksGelap,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case AppViewStatus.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.sageMuda,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inbox_outlined,
                    size: 38,
                    color: AppColors.sageTua,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyTitle ?? 'Belum Ada Data',
                  style: const TextStyle(
                    color: AppColors.teksGelap,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage ?? 'Data yang Anda cari saat ini belum tersedia.',
                  style: const TextStyle(
                    color: AppColors.teksGelap,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: Text(retryLabel ?? 'Segarkan'),
                  ),
                ],
              ],
            ),
          ),
        );

      case AppViewStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.merahStatus.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    size: 38,
                    color: AppColors.merahStatus,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Terjadi Kendala',
                  style: TextStyle(
                    color: AppColors.teksGelap,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage ?? 'Gagal memproses permintaan. Periksa koneksi Anda dan coba lagi.',
                  style: const TextStyle(
                    color: AppColors.teksGelap,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18, color: AppColors.teksGelap),
                    label: Text(retryLabel ?? 'Coba Lagi'),
                  ),
                ],
              ],
            ),
          ),
        );

      case AppViewStatus.offline:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.sageMuda,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 38,
                    color: AppColors.sageTua,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mode Luring (Offline)',
                  style: TextStyle(
                    color: AppColors.teksGelap,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  offlineMessage ??
                      'Perangkat tidak terhubung ke internet. Menampilkan data tersimpan dari penyimpanan lokal.',
                  style: const TextStyle(
                    color: AppColors.teksGelap,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.wifi, size: 18, color: AppColors.teksGelap),
                    label: Text(retryLabel ?? 'Coba Hubungkan'),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }
}
