// ==============================================================================
// FAUNOVA WIDGET: AppSettingsSheet
// Lembar modal pengaturan aplikasi Faunova (Keamanan, Notifikasi, Privasi, dan Info App)
// Sesuai Plan baris 63, 73, Scope.md S21 & AGENTS.md
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/notification_service.dart';
import 'biometric_setting_sheet.dart';
import 'notification_setting_sheet.dart';

class AppSettingsSheet extends StatefulWidget {
  const AppSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppSettingsSheet(),
    );
  }

  @override
  State<AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends State<AppSettingsSheet> {
  bool _isBiometricSupported = false;
  bool _isBiometricEnrolled = false;
  bool _isBiometricEnabled = false;

  bool _isStreakNotifActive = true;
  bool _isChallengeNotifActive = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsStatus();
  }

  Future<void> _loadSettingsStatus() async {
    final bioService = BiometricService.instance;
    final notifService = NotificationService.instance;

    final supported = await bioService.isHardwareAvailable();
    final enrolled = await bioService.hasEnrolledBiometrics();
    final enabled = bioService.isBiometricEnabled();

    final streakOn = notifService.isStreakReminderEnabled();
    final challengeOn = notifService.isChallengeReminderEnabled();

    if (mounted) {
      setState(() {
        _isBiometricSupported = supported;
        _isBiometricEnrolled = enrolled;
        _isBiometricEnabled = enabled;
        _isStreakNotifActive = streakOn;
        _isChallengeNotifActive = challengeOn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4.5,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.teksGelap.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: AppColors.sageTua,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Aplikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teksGelap,
                        ),
                      ),
                      Text(
                        'Keamanan, notifikasi, privasi & informasi sistem',
                        style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.teksGelap),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.sageMuda),

          // Konten Gulir
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              physics: const ClampingScrollPhysics(),
              children: [
                // 1. Seksi Keamanan & Biometrik
                _buildSectionHeader('Keamanan Akun & Biometrik', Icons.fingerprint_rounded),
                const SizedBox(height: 8),
                _buildSettingTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Masuk dengan Sidik Jari',
                  subtitle: _isBiometricEnabled
                      ? 'Status: Aktif (Terhubung ke sesi terenkripsi)'
                      : (_isBiometricSupported
                          ? (_isBiometricEnrolled
                              ? 'Tersedia dan terdaftar di perangkat'
                              : 'Tersedia tapi sidik jari belum didaftarkan di OS')
                          : 'Hardware sensor tidak terdeteksi'),
                  trailingText: _isBiometricEnabled ? 'Aktif' : 'Atur',
                  trailingColor: _isBiometricEnabled ? AppColors.sageTua : AppColors.emasTua,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await BiometricSettingSheet.show(context);
                  },
                ),
                const SizedBox(height: 8),
                _buildSettingTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Enkripsi Penyimpanan Lokal',
                  subtitle: 'Kunci AES-256 tersimpan di FlutterSecureStorage & box Hive terenkripsi.',
                  trailingText: '256-Bit',
                  trailingColor: AppColors.sageTua,
                ),
                const SizedBox(height: 18),

                // 2. Seksi Notifikasi
                _buildSectionHeader('Notifikasi & Pengingat Terjadwal', Icons.notifications_active_outlined),
                const SizedBox(height: 8),
                _buildSettingTile(
                  icon: Icons.access_time_rounded,
                  title: 'Pengingat Lapangan & Streak',
                  subtitle: 'Pengingat streak (19:00 WIB) & Tantangan Harian (08:00 WIB)',
                  trailingText: (_isStreakNotifActive && _isChallengeNotifActive) ? 'Aktif' : 'Kelola',
                  trailingColor: AppColors.sageTua,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await NotificationSettingSheet.show(context);
                  },
                ),
                const SizedBox(height: 18),

                // 3. Seksi Privasi & Perlindungan Data
                _buildSectionHeader('Privasi & Keamanan Lapangan (Plan 5.2, 5.7)', Icons.security_rounded),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sageMuda),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPrivacyBullet(
                        'Grid Snapping 0.01° di Server',
                        'Koordinat publik postingan feed selalu diburamkan ke sel grid ~1.1 km untuk melindungi posisi sarang satwa liar terancam punah.',
                      ),
                      const Divider(height: 16, color: AppColors.sageMuda),
                      _buildPrivacyBullet(
                        'Pembersihan Metadata EXIF di Klien',
                        'Tag lokasi GPS dan data identitas kamera pada file citra dibuang langsung di isolate background sebelum transmisi jaringan.',
                      ),
                      const Divider(height: 16, color: AppColors.sageMuda),
                      _buildPrivacyBullet(
                        'Buku Besar Kanonis Anti-Manipulasi',
                        'Setiap tangkapan satwa dikunci dalam rantai blok SHA-256 tamper-evident dengan verifikasi deterministik.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Seksi Info Aplikasi
                _buildSectionHeader('Informasi Aplikasi & Lisensi', Icons.info_outline_rounded),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sageMuda),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.sageMuda.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pets_rounded, color: AppColors.sageTua, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Faunova — Jurnal Sosial Satwa',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.teksGelap,
                                  ),
                                ),
                                Text(
                                  'Versi 1.0.0 (Release Build Semester 5)',
                                  style: TextStyle(fontSize: 11, color: AppColors.teksGelap),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Teknologi: Flutter, Supabase (Auth, RLS, Storage, Edge Functions), Gemini 3.8 Flash, Midtrans Sandbox, OpenStreetMap & Hive.',
                        style: TextStyle(fontSize: 11, color: AppColors.teksGelap, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dikembangkan untuk Tugas Besar Kuliah Pemrograman Aplikasi Mobile (PAM). Hak cipta terarsip.',
                        style: TextStyle(fontSize: 10.5, color: AppColors.teksGelap.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.sageTua),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.teksGelap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailingText,
    required Color trailingColor,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sageMuda),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sageMuda.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.sageTua),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teksGelap,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.teksGelap.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: trailingColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trailingText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: trailingColor,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.sage),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyBullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.sageTua),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teksGelap,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.teksGelap.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
