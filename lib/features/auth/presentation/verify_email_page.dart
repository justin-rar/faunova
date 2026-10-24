// ==============================================================================
// FAUNOVA PRESENTATION: VerifyEmailPage
// Halaman instruksi verifikasi alamat email via SMTP Brevo
// Diselaraskan dengan Sistem Desain Stitch & AGENTS.md
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class VerifyEmailPage extends StatelessWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gading,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.sageTua, size: 20),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikon amplop naturalis
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.sageTua,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.emas, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sageTua.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.mail_outline_rounded, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Cek Kotak Masuk Anda',
                  style: AppTypography.displayEditorial(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teksGelap,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kami telah mengirimkan tautan konfirmasi pendaftaran akun Faunova ke:',
                  style: AppTypography.bodyMedium(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Pill alamat email
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
                  ),
                  child: Text(
                    email,
                    style: AppTypography.labelProminent(
                      fontSize: 13.5,
                      color: AppColors.sageTua,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Kartu Info Solid
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.emasTua, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Klik tautan di dalam email untuk mengaktifkan akun Anda. Periksa folder spam atau promosi jika email belum masuk dalam beberapa menit.',
                              style: AppTypography.bodyCompact(
                                fontSize: 12,
                                color: AppColors.teksGelap,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Tombol Kembali ke Halaman Masuk
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emas,
                      foregroundColor: AppColors.teksGelap,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Kembali ke Halaman Masuk',
                      style: AppTypography.labelProminent(
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
