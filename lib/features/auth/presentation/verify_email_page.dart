import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class VerifyEmailPage extends StatelessWidget {
  final String email;

  const VerifyEmailPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Gradien hutan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A2E1A),
                  Color(0xFF2E4A2C),
                  Color(0xFF3D5E3A),
                  Color(0xFF4A6E42),
                  Color(0xFF2B4228),
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
          ),
          // Bokeh emas
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emas.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bokeh sage bawah
          Positioned(
            bottom: 40,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sageTua.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Layer 3: Konten
          SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 24),
                    child: child,
                  ),
                );
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ikon amplop
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.sageTua, Color(0xFF3D5E3A)],
                          ),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sageTua.withValues(alpha: 0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.mark_email_read_rounded,
                            color: Colors.white, size: 46),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Cek Kotak Masuk Anda',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tautan konfirmasi pendaftaran telah dikirimkan ke alamat email:',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.65),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      // Badge email
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppColors.emas.withValues(alpha: 0.4),
                                  width: 1),
                            ),
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emas.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Kartu tips glassmorphism
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                                width: 1.1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.tips_and_updates_outlined,
                                        size: 18,
                                        color: AppColors.emas
                                            .withValues(alpha: 0.85)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Petunjuk Pengujian Email (Plan 5.1):',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '1. Buka aplikasi Gmail atau Outlook Anda.\n'
                                  '2. Jika email belum tampak dalam 1 menit, periksa folder Spam / Junk.\n'
                                  '3. Ketuk tautan konfirmasi untuk mengaktifkan akun Anda.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.55,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Tombol kembali ke login
                      GestureDetector(
                        onTap: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.emas, Color(0xFFDDB96E)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emas.withValues(alpha: 0.38),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Kembali ke Halaman Masuk',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teksGelap,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
