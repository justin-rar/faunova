// ==============================================================================
// FAUNOVA PAGE: BiometricLockPage
// Layar Kunci Aplikasi (App Lock) dengan Verifikasi Sidik Jari & Fallback Password
// Sesuai Plan 5.1 & Sesi S17/S22
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';

class BiometricLockPage extends StatefulWidget {
  final VoidCallback? onUnlocked;
  final bool? autoTrigger;

  const BiometricLockPage({
    super.key,
    this.onUnlocked,
    this.autoTrigger,
  });

  @override
  State<BiometricLockPage> createState() => _BiometricLockPageState();
}

class _BiometricLockPageState extends State<BiometricLockPage> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isBiometricLoading = false;
  bool _isPasswordVerifying = false;
  bool _isObscured = true;
  bool _showPasswordInput = false;
  bool _isLockedOut = false;
  int _failedAttempts = 0;
  String? _errorMessage;
  String? _userEmail;
  bool _hasAutoTriggered = false;

  @override
  void initState() {
    super.initState();
    _loadStateAndTrigger();
  }

  Future<void> _loadStateAndTrigger() async {
    final locked = BiometricService.instance.isLockedOut();
    final attempts = BiometricService.instance.getFailedAttempts();
    final email = await BiometricService.instance.getSavedUserEmail() ??
        AuthService.instance.currentUserEmail;

    if (mounted) {
      setState(() {
        _isLockedOut = locked;
        _failedAttempts = attempts;
        _userEmail = email;
        if (locked) {
          _showPasswordInput = true;
        }
      });
    }

    // Auto-trigger pemindaian sidik jari pada cold start jika belum locked out (kecuali saat widget testing)
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final shouldAutoTrigger = widget.autoTrigger ?? (!BiometricService.instance.disableAutoTrigger && !isTest);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldAutoTrigger && !_hasAutoTriggered && !_isLockedOut && mounted) {
        _hasAutoTriggered = true;
        _triggerBiometricUnlock();
      }
    });
  }

  Future<void> _triggerBiometricUnlock() async {
    if (_isBiometricLoading || _isLockedOut) return;

    setState(() {
      _isBiometricLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await BiometricService.instance.performBiometricUnlock();
      if (result.success) {
        if (mounted) {
          widget.onUnlocked?.call();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result.errorMessage;
            _isLockedOut = result.isLockedOut;
            _failedAttempts = BiometricService.instance.getFailedAttempts();
            if (result.isLockedOut) {
              _showPasswordInput = true;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan saat memverifikasi sidik jari: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isBiometricLoading = false);
      }
    }
  }

  Future<void> _handlePasswordUnlock() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Silakan masukkan kata sandi akun Anda.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isPasswordVerifying = true;
      _errorMessage = null;
    });

    try {
      final success = await BiometricService.instance.verifyPasswordToUnlock(password);
      if (success) {
        if (mounted) {
          widget.onUnlocked?.call();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Kata sandi tidak sesuai. Silakan periksa kembali kata sandi Anda.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memverifikasi kata sandi: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPasswordVerifying = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.gading,
        title: const Text(
          'Keluar dari Akun?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.teksGelap,
          ),
        ),
        content: const Text(
          'Anda akan diarahkan kembali ke halaman masuk. Sesi lokal di perangkat akan dibersihkan.',
          style: TextStyle(color: AppColors.teksGelap),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.sageTua)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.merahStatus,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.instance.signOut();
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gading,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Ikon Kunci Biometrik
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.sageTua,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.sageTua.withValues(alpha: 0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Judul & Penjelasan
                  const Text(
                    'Faunova Terkunci',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teksGelap,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLockedOut
                        ? 'Demi keamanan akun Anda, silakan masukkan kata sandi akun untuk membuka kunci.'
                        : _failedAttempts > 0
                            ? 'Pindai sidik jari Anda (percobaan gagal: $_failedAttempts/${BiometricService.maxFailedAttempts})'
                            : 'Pindai sidik jari Anda untuk melanjutkan ke aplikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.teksGelap.withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Badge Email Akun Aktif
                  if (_userEmail != null && _userEmail!.isNotEmpty)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.sageMuda.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.sageTua.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_circle_rounded,
                              size: 16,
                              color: AppColors.sageTua,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _userEmail!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.teksGelap,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Banner Peringatan / Error jika ada
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isLockedOut
                            ? AppColors.merahStatus.withValues(alpha: 0.1)
                            : AppColors.emas.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isLockedOut ? AppColors.merahStatus : AppColors.emasTua,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isLockedOut
                                ? Icons.lock_clock_rounded
                                : Icons.warning_amber_rounded,
                            color: _isLockedOut ? AppColors.merahStatus : AppColors.emasTua,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _isLockedOut ? AppColors.merahStatus : AppColors.emasTua,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tombol Utama: Pindai Sidik Jari (jika belum locked out)
                  if (!_isLockedOut) ...[
                    ElevatedButton.icon(
                      onPressed: _isBiometricLoading ? null : _triggerBiometricUnlock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emas,
                        foregroundColor: AppColors.teksGelap,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      icon: _isBiometricLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.teksGelap,
                              ),
                            )
                          : const Icon(Icons.fingerprint_rounded, size: 24),
                      label: Text(
                        _isBiometricLoading ? 'Memverifikasi...' : 'Pindai Sidik Jari',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Fallback: Form Kata Sandi Akun
                  if (_showPasswordInput || _isLockedOut) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.sageMuda, width: 1.5),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Buka Kunci dengan Kata Sandi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teksGelap,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Masukkan kata sandi akun Faunova Anda:',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.teksGelap.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscured,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handlePasswordUnlock(),
                              style: const TextStyle(color: AppColors.teksGelap),
                              decoration: InputDecoration(
                                hintText: 'Kata sandi akun',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.teksGelap.withValues(alpha: 0.4),
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.sageTua,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscured
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.sage,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _isObscured = !_isObscured);
                                  },
                                ),
                                filled: true,
                                fillColor: AppColors.gading,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.sageMuda),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.sageTua,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _isPasswordVerifying ? null : _handlePasswordUnlock,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sageTua,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isPasswordVerifying
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Buka Kunci',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Tombol untuk membuka form password jika user memilih tidak menggunakan sidik jari
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _showPasswordInput = true);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.sageTua,
                        side: const BorderSide(color: AppColors.sageTua, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.password_rounded, size: 20),
                      label: const Text(
                        'Buka dengan Kata Sandi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Pilihan Keluar Akun / Ganti Akun
                  Center(
                    child: TextButton.icon(
                      onPressed: _handleSignOut,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.teksGelap.withValues(alpha: 0.6),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Keluar / Ganti Akun',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
    );
  }
}
