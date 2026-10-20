import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class VerifyEmailPage extends StatelessWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gading,
      appBar: AppBar(
        title: const Text('Verifikasi Email'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Mail Envelope
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.sageTua,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sageTua.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: AppColors.teksPutih,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Cek Kotak Masuk Anda',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teksGelap,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                Text(
                  'Tautan konfirmasi pendaftaran telah dikirimkan ke alamat email:',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.teksGelap.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.sageMuda,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teksGelap,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Card Tips Pengiriman (Brevo / Gmail / Outlook)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sageMuda.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sage.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.sageTua),
                          SizedBox(width: 8),
                          Text(
                            'Petunjuk Pengujian Email (Plan 5.1):',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teksGelap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Buka aplikasi Gmail atau Outlook Anda.\n'
                        '2. Jika email belum tampak dalam 1 menit, periksa folder Spam / Junk.\n'
                        '3. Ketuk tautan konfirmasi untuk mengaktifkan akun Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.teksGelap.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Kembali ke Login
                ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text(
                    'Kembali ke Halaman Masuk',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teksGelap,
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
