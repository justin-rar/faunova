// ==============================================================================
// FAUNOVA WIDGET: BiometricSettingSheet
// Lembar pengaturan biometrik (Fingerprint) sesuai Plan 5.1 & Sesi S17
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/theme/app_colors.dart';

class BiometricSettingSheet extends StatefulWidget {
  const BiometricSettingSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BiometricSettingSheet(),
    );
  }

  @override
  State<BiometricSettingSheet> createState() => _BiometricSettingSheetState();
}

class _BiometricSettingSheetState extends State<BiometricSettingSheet> {
  bool _isLoading = true;
  bool _isHardwareAvailable = false;
  bool _hasEnrolledBiometrics = false;
  bool _isEnabled = false;
  bool _isLockedOut = false;
  int _failedAttempts = 0;
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    setState(() => _isLoading = true);

    final hw = await BiometricService.instance.isHardwareAvailable();
    final enrolled = await BiometricService.instance.hasEnrolledBiometrics();
    final enabled = BiometricService.instance.isBiometricEnabled();
    final locked = BiometricService.instance.isLockedOut();
    final attempts = BiometricService.instance.getFailedAttempts();
    final email = await BiometricService.instance.getSavedUserEmail();

    if (mounted) {
      setState(() {
        _isHardwareAvailable = hw;
        _hasEnrolledBiometrics = enrolled;
        _isEnabled = enabled;
        _isLockedOut = locked;
        _failedAttempts = attempts;
        _savedEmail = email;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleToggle(bool value) async {
    if (value) {
      // Saat dinyalakan, wajib verifikasi sidik jari dulu (Plan 73)
      final authenticated = await BiometricService.instance.authenticate(
        reason: 'Pindai sidik jari Anda untuk mengaktifkan fitur masuk cepat',
      );

      if (authenticated) {
        await BiometricService.instance.setBiometricEnabled(true);
        await BiometricService.instance.saveCurrentSession();
        if (mounted) {
          setState(() {
            _isEnabled = true;
            _isLockedOut = false;
            _failedAttempts = 0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autentikasi sidik jari berhasil diaktifkan.'),
              backgroundColor: AppColors.sageTua,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi sidik jari dibatalkan atau tidak cocok.'),
              backgroundColor: AppColors.merahStatus,
            ),
          );
        }
      }
    } else {
      // Nonaktifkan
      await BiometricService.instance.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _isEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Autentikasi sidik jari dinonaktifkan.'),
            backgroundColor: AppColors.sageTua,
          ),
        );
      }
    }
  }

  Future<void> _resetLockout() async {
    await BiometricService.instance.resetFailedAttempts();
    if (mounted) {
      setState(() {
        _isLockedOut = false;
        _failedAttempts = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Counter percobaan gagal telah di-reset.'),
          backgroundColor: AppColors.sageTua,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Toggle dinonaktifkan jika perangkat tidak punya sensor atau belum ada sidik jari (Plan 77)
    final bool canToggle = _isHardwareAvailable && _hasEnrolledBiometrics;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.sageMuda,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sageTua.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.sageTua,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengaturan & Sidik Jari',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teksGelap,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Keamanan biometrik lokal perangkat (Plan 5.1)',
                      style: TextStyle(fontSize: 12, color: AppColors.sage),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.sageTua),
              ),
            )
          else ...[
            // 1. Status Sensor Hardware & OS
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sageMuda, width: 1.2),
              ),
              child: Column(
                children: [
                  _buildStatusRow(
                    icon: Icons.hardware_rounded,
                    title: 'Sensor Biometrik',
                    status: _isHardwareAvailable ? 'Tersedia' : 'Tidak Ditemukan',
                    isPositive: _isHardwareAvailable,
                  ),
                  const Divider(height: 18),
                  _buildStatusRow(
                    icon: Icons.fingerprint_rounded,
                    title: 'Pendaftaran Sidik Jari',
                    status: _hasEnrolledBiometrics ? 'Terdaftar di HP' : 'Belum Didaftarkan',
                    isPositive: _hasEnrolledBiometrics,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Kartu Toggle Utama
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sageMuda,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isEnabled ? AppColors.emas : AppColors.sage.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Masuk dengan Sidik Jari',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teksGelap,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _isEnabled,
                        activeThumbColor: AppColors.emas,
                        activeTrackColor: AppColors.sageTua,
                        onChanged: canToggle ? _handleToggle : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    canToggle
                        ? 'Buka sesi akun Faunova secara instan menggunakan sensor biometrik perangkat tanpa mengetik kata sandi.'
                        : !_isHardwareAvailable
                            ? 'Fitur dinonaktifkan karena perangkat ini tidak memiliki sensor biometrik.'
                            : 'Fitur dinonaktifkan karena belum ada sidik jari yang didaftarkan di pengaturan sistem HP.',
                    style: TextStyle(
                      fontSize: 12,
                      color: canToggle ? AppColors.teksGelap.withValues(alpha: 0.8) : AppColors.merahStatus,
                      height: 1.35,
                    ),
                  ),
                  if (_savedEmail != null && _isEnabled) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Sesi tersimpan untuk: $_savedEmail',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sageTua,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Status Percobaan Gagal (Plan 74)
            if (_failedAttempts > 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isLockedOut ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isLockedOut ? AppColors.merahStatus : AppColors.emas,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isLockedOut ? Icons.lock_clock_rounded : Icons.warning_amber_rounded,
                      color: _isLockedOut ? AppColors.merahStatus : AppColors.emasTua,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isLockedOut
                            ? 'Terkunci: Batas 5 kali percobaan gagal telah tercapai. Tombol sidik jari dinonaktifkan.'
                            : 'Tercatat $_failedAttempts kali kegagalan autentikasi berturut-turut.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _isLockedOut ? AppColors.merahStatus : AppColors.emasTua,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _resetLockout,
                      child: const Text('Reset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Tombol Tutup
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageTua,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String status,
    required bool isPositive,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isPositive ? AppColors.sageTua : AppColors.merahStatus),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.teksGelap),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isPositive ? AppColors.sageTua : AppColors.merahStatus,
            ),
          ),
        ),
      ],
    );
  }
}
