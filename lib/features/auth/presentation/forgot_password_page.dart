// ==============================================================================
// FAUNOVA PRESENTATION: ForgotPasswordPage
// Halaman pemulihan kata sandi via kode OTP email & tautan pemulihan
// Alur 2 Langkah: 
// 1. Langkah 1/2: Input Email & Kirim Tautan/Kode Pemulihan
// 2. Langkah 2/2: Verifikasi Kode OTP -> Setelah terverifikasi baru muncul input Kata Sandi Baru
// Diselaraskan dengan Sistem Desain Stitch & AGENTS.md (Palet Faunova)
// ==============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'login_page.dart';

enum ResetStep {
  requestEmail,
  enterOtpAndNewPassword,
  success,
}

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;
  final bool isDirectRecovery;

  const ForgotPasswordPage({
    super.key,
    this.initialEmail,
    this.isDirectRecovery = false,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late ResetStep _currentStep;
  bool _isOtpVerified = false;
  bool _isLoading = false;
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;
  String? _errorMessage;

  Timer? _countdownTimer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }

    if (widget.isDirectRecovery) {
      _currentStep = ResetStep.enterOtpAndNewPassword;
      _isOtpVerified = true;
    } else {
      _currentStep = ResetStep.requestEmail;
      _isOtpVerified = false;
      // Requirement 3: Reset alur pemulihan kata sandi ke kondisi segar & bersihkan sesi menggantung
      AuthService.instance.clearRecoverySession();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 60]) {
    _countdownTimer?.cancel();
    setState(() {
      _resendCooldown = seconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldown = 0;
        });
      } else {
        setState(() {
          _resendCooldown--;
        });
      }
    });
  }

  String _getReadableErrorMessage(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('token has expired') || msg.contains('expired')) {
        return 'Kode verifikasi telah kedaluwarsa. Silakan ketuk "Kirim Ulang Kode OTP".';
      }
      if (msg.contains('invalid token') || msg.contains('token') || msg.contains('otp')) {
        return 'Kode OTP tidak sesuai. Pastikan kode yang Anda masukkan benar.';
      }
      if (msg.contains('same password') || msg.contains('should be different')) {
        return 'Kata sandi baru tidak boleh sama dengan kata sandi sebelumnya.';
      }
      if (msg.contains('too many requests') || msg.contains('rate limit')) {
        return 'Terlalu banyak percobaan. Mohon tunggu beberapa saat sebelum mencoba kembali.';
      }
      if (msg.contains('user not found')) {
        return 'Alamat email tidak terdaftar di Faunova. Periksa kembali email Anda.';
      }
      return error.message;
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('socketexception') || raw.contains('failed host lookup') || raw.contains('network')) {
      return 'Koneksi jaringan terputus. Pastikan perangkat Anda terhubung ke internet.';
    }

    final cleaned = error.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
    return cleaned.isNotEmpty ? cleaned : 'Terjadi kendala saat memproses permintaan.';
  }

  /// Step 1: Kirim Email Pemulihan
  Future<void> _handleSendEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Pastikan sesi recovery lama dibersihkan
      await AuthService.instance.clearRecoverySession();

      await AuthService.instance.resetPassword(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _otpController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _isOtpVerified = false;
          _currentStep = ResetStep.enterOtpAndNewPassword;
        });
        _startResendCooldown(60);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kode pemulihan dikirim ke ${_emailController.text.trim()}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppColors.sageTua,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Step 2a: Verifikasi Kode OTP (Hanya OTP)
  Future<void> _handleVerifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.verifyRecoveryOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isOtpVerified = true;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kode OTP berhasil diverifikasi! Silakan tentukan kata sandi baru.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppColors.sageTua,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Step 2b: Simpan Kata Sandi Baru (Setelah OTP Lolos)
  Future<void> _handleSaveNewPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.updatePasswordOnly(
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() {
          _currentStep = ResetStep.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Kirim Ulang Kode OTP
  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.resetPassword(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        _startResendCooldown(60);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kode OTP baru berhasil dikirimkan ke email Anda.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            backgroundColor: AppColors.sageTua,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Ubah Email -> Kembali ke Langkah 1 dan reset data pemulihan
  void _handleChangeEmail() {
    setState(() {
      _currentStep = ResetStep.requestEmail;
      _isOtpVerified = false;
      _otpController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _errorMessage = null;
    });
    AuthService.instance.clearRecoverySession();
  }

  /// Navigasi langsung dan bersih ke LoginPage dengan membawa email dan banner konfirmasi
  void _navigateToLogin() {
    final resetEmail = _emailController.text.trim();
    LoginPage.pendingInitialEmail = resetEmail.isNotEmpty ? resetEmail : null;
    LoginPage.pendingBannerMessage = 'Kata sandi berhasil diperbarui! Silakan masuk dengan kata sandi baru Anda.';
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodyMedium(
        color: AppColors.onSurfaceVariant,
        fontSize: 13.5,
      ),
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.merahStatus, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.merahStatus, width: 1.5),
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.sageTua, size: 20),
      suffixIcon: suffixIcon,
      errorStyle: AppTypography.labelCaption(
        color: AppColors.merahStatus,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep != ResetStep.success,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep == ResetStep.success) {
          _navigateToLogin();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.gading,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () {
              if (_currentStep == ResetStep.success) {
                _navigateToLogin();
              } else if (_currentStep == ResetStep.enterOtpAndNewPassword && !widget.isDirectRecovery) {
                if (_isOtpVerified) {
                  setState(() {
                    _isOtpVerified = false;
                    _errorMessage = null;
                  });
                } else {
                  _handleChangeEmail();
                }
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.sageTua, size: 20),
          ),
          title: Text(
            'Pemulihan Akun',
            style: AppTypography.titleUi(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.teksGelap,
            ),
          ),
          actions: [
            if (_currentStep != ResetStep.success)
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sageMuda.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentStep == ResetStep.requestEmail ? 'Langkah 1/2' : 'Langkah 2/2',
                      style: AppTypography.labelCaption(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderTexts(),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.surfaceContainerHighest,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teksGelap.withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(22),
                  child: _buildCurrentContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTexts() {
    switch (_currentStep) {
      case ResetStep.requestEmail:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lupa Kata Sandi?',
              style: AppTypography.headlineSpecies(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Masukkan alamat email yang terdaftar untuk menerima kode verifikasi pemulihan kata sandi.',
              style: AppTypography.bodyMedium(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        );
      case ResetStep.enterOtpAndNewPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isOtpVerified ? 'Buat Kata Sandi Baru' : 'Verifikasi Kode OTP',
              style: AppTypography.headlineSpecies(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isOtpVerified
                  ? (widget.isDirectRecovery
                      ? 'Sesi pemulihan terverifikasi. Masukkan kata sandi baru untuk akun Anda.'
                      : 'Kode OTP berhasil diverifikasi. Silakan tentukan kata sandi baru untuk akun Anda.')
                  : 'Masukkan kode OTP yang dikirim ke ${_emailController.text.trim()}.',
              style: AppTypography.bodyMedium(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        );
      case ResetStep.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pemulihan Berhasil',
              style: AppTypography.headlineSpecies(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.teksGelap,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kata sandi Anda kini telah diperbarui dengan aman di server Faunova.',
              style: AppTypography.bodyMedium(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildCurrentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.onErrorContainer, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodyCompact(fontSize: 12, color: AppColors.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_currentStep == ResetStep.requestEmail)
          _buildRequestEmailForm()
        else if (_currentStep == ResetStep.enterOtpAndNewPassword)
          _isOtpVerified ? _buildNewPasswordForm() : _buildOtpVerificationForm()
        else
          _buildSuccessView(),
      ],
    );
  }

  /// Form Langkah 1/2: Hanya Email dan Tombol Kirim Tautan Pemulihan (Requirement 1)
  Widget _buildRequestEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Alamat Email',
            style: AppTypography.labelProminent(
              fontSize: 12.5,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppTypography.bodyMedium(
              color: AppColors.teksGelap,
              fontSize: 14,
            ),
            cursorColor: AppColors.sageTua,
            decoration: _inputDecoration(
              hintText: 'nama@domain.com',
              prefixIcon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Alamat email wajib diisi';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Format alamat email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emas,
                foregroundColor: AppColors.teksGelap,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.teksGelap),
                      ),
                    )
                  : Text(
                      'Kirim Tautan Pemulihan',
                      style: AppTypography.labelProminent(
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Form Langkah 2/2 (Tahap 1): Hanya Input Kode OTP, Tombol Verifikasi, Opsi Ubah Email, dan Kirim Ulang OTP (Requirement 2)
  Widget _buildOtpVerificationForm() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kode Verifikasi (OTP)',
            style: AppTypography.labelProminent(
              fontSize: 12.5,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.text,
            maxLength: 12,
            style: AppTypography.titleUi(
              color: AppColors.teksGelap,
              fontSize: 16,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
            cursorColor: AppColors.sageTua,
            decoration: _inputDecoration(
              hintText: 'Kode OTP dari email',
              prefixIcon: Icons.pin_outlined,
            ).copyWith(
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Kode verifikasi wajib diisi';
              }
              if (value.trim().length < 6 || value.trim().length > 12) {
                return 'Kode OTP minimal 6 digit';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emas,
                foregroundColor: AppColors.teksGelap,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.teksGelap),
                      ),
                    )
                  : Text(
                      'Verifikasi Kode OTP',
                      style: AppTypography.labelProminent(
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _isLoading ? null : _handleChangeEmail,
                child: Text(
                  'Ubah Email',
                  style: AppTypography.labelProminent(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: _resendCooldown > 0 || _isLoading ? null : _handleResendOtp,
                child: Text(
                  _resendCooldown > 0
                      ? 'Kirim ulang (${_resendCooldown}s)'
                      : 'Kirim Ulang Kode OTP',
                  style: AppTypography.labelProminent(
                    fontSize: 12.5,
                    color: _resendCooldown > 0 ? AppColors.onSurfaceVariant : AppColors.emasTua,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Form Langkah 2/2 (Tahap 2): Input Kata Sandi Baru & Konfirmasi (Hanya muncul setelah OTP lolos) (Requirement 2)
  Widget _buildNewPasswordForm() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.sageMuda.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sageTua.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.sageTua, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kode OTP terverifikasi. Masukkan kata sandi baru akun Anda di bawah ini.',
                    style: AppTypography.bodyCompact(
                      fontSize: 12,
                      color: AppColors.teksGelap,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Kata Sandi Baru',
            style: AppTypography.labelProminent(
              fontSize: 12.5,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _isObscureNew,
            style: AppTypography.bodyMedium(
              color: AppColors.teksGelap,
              fontSize: 14,
            ),
            cursorColor: AppColors.sageTua,
            decoration: _inputDecoration(
              hintText: 'Minimal 6 karakter',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isObscureNew = !_isObscureNew;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Kata sandi baru wajib diisi';
              }
              if (value.length < 6) {
                return 'Kata sandi minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Konfirmasi Kata Sandi Baru',
            style: AppTypography.labelProminent(
              fontSize: 12.5,
              color: AppColors.teksGelap,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _isObscureConfirm,
            style: AppTypography.bodyMedium(
              color: AppColors.teksGelap,
              fontSize: 14,
            ),
            cursorColor: AppColors.sageTua,
            decoration: _inputDecoration(
              hintText: 'Ulangi kata sandi baru',
              prefixIcon: Icons.lock_reset_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isObscureConfirm = !_isObscureConfirm;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Konfirmasi kata sandi wajib diisi';
              }
              if (value != _newPasswordController.text) {
                return 'Konfirmasi kata sandi tidak cocok';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSaveNewPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emas,
                foregroundColor: AppColors.teksGelap,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.teksGelap),
                      ),
                    )
                  : Text(
                      'Simpan Kata Sandi Baru',
                      style: AppTypography.labelProminent(
                        fontSize: 14,
                        color: AppColors.teksGelap,
                      ),
                    ),
            ),
          ),
          if (!widget.isDirectRecovery) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _handleChangeEmail,
                child: Text(
                  'Ubah Email',
                  style: AppTypography.labelProminent(
                    fontSize: 12.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: ContainerCircle(
            size: 64,
            color: AppColors.sageMuda,
            child: Icon(Icons.check_circle_rounded, color: AppColors.sageTua, size: 44),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Kata Sandi Berhasil Diperbarui!',
          style: AppTypography.headlineSpecies(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.teksGelap,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Akun Anda telah diamankan dengan kata sandi baru. Silakan masuk kembali dengan kata sandi baru Anda.',
          style: AppTypography.bodyMedium(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _navigateToLogin,
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
    );
  }
}

class ContainerCircle extends StatelessWidget {
  final double size;
  final Color color;
  final Widget child;

  const ContainerCircle({
    super.key,
    required this.size,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
}
