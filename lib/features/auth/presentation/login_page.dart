// ==============================================================================
// FAUNOVA PRESENTATION: LoginPage
// Halaman masuk autentikasi pengguna dengan dukungan biometrik (Plan 74)
// Diselaraskan dengan Sistem Desain Stitch & AGENTS.md
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscured = true;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _canUseBiometrics = false;
  bool _isLockedOut = false;
  String? _savedEmail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final enabled = BiometricService.instance.isBiometricEnabled();
    final hasSession = await BiometricService.instance.hasSavedSession();
    final canUseHw = await BiometricService.instance.canUseBiometrics();
    final locked = BiometricService.instance.isLockedOut();
    final email = await BiometricService.instance.getSavedUserEmail();

    if (mounted) {
      setState(() {
        _canUseBiometrics = enabled && hasSession && canUseHw;
        _isLockedOut = locked;
        _savedEmail = email;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_isBiometricLoading) return;

    setState(() {
      _isBiometricLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await BiometricService.instance.performBiometricLogin();
      if (!result.success) {
        if (mounted) {
          setState(() {
            _errorMessage = result.errorMessage;
            _isLockedOut = result.isLockedOut;
            if (result.isLockedOut) {
              _canUseBiometrics = false;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal melakukan autentikasi sidik jari: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkBiometricStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Reset status lockout biometrik bila login email berhasil
      await _checkBiometricStatus();
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

  String _getReadableErrorMessage(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials') ||
          msg.contains('wrong password') ||
          msg.contains('user not found')) {
        return 'Email atau kata sandi tidak sesuai. Silakan periksa kembali.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Alamat email belum diverifikasi. Silakan periksa kotak masuk atau spam email Anda.';
      }
      if (msg.contains('too many requests') || msg.contains('rate limit')) {
        return 'Terlalu banyak percobaan masuk. Mohon tunggu beberapa saat sebelum mencoba kembali.';
      }
      if (msg.contains('network') || msg.contains('connection')) {
        return 'Koneksi internet bermasalah. Pastikan perangkat Anda terhubung ke jaringan.';
      }
      return error.message;
    }

    final raw = error.toString().toLowerCase();
    if (raw.contains('socketexception') || raw.contains('failed host lookup') || raw.contains('network')) {
      return 'Koneksi jaringan terputus. Silakan periksa kembali koneksi internet Anda.';
    }

    final cleaned = error.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
    return cleaned.isNotEmpty
        ? cleaned
        : 'Gagal masuk ke akun. Silakan periksa kembali data Anda.';
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.merahStatus, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
    final isConfigured =
        AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized;

    return Scaffold(
      backgroundColor: AppColors.gading,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emblem Naturalis
                  _buildEmblem(),
                  const SizedBox(height: 16),

                  // Judul Editorial
                  Text(
                    'Faunova',
                    style: AppTypography.displayEditorial(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teksGelap,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Arsip biodiversitas satwa nusantara',
                    style: AppTypography.bodyMedium(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Kartu Form Solid Naturalis (Stitch: surfaceContainerLowest + border 1px surfaceContainerHighest)
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isConfigured || !AppConfig.isSupabaseInitialized) ...[
                          _buildDemoBanner(),
                          const SizedBox(height: 16),
                        ],
                        if (_isLockedOut) ...[
                          _buildLockoutBanner(),
                          const SizedBox(height: 16),
                        ],
                        if (_errorMessage != null) ...[
                          _buildErrorBanner(_errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        if (_canUseBiometrics && !_isLockedOut) ...[
                          _buildBiometricLoginButton(),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: AppColors.surfaceContainerHighest, height: 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'atau gunakan email',
                                  style: AppTypography.labelCaption(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: AppColors.surfaceContainerHighest, height: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],

                        _buildFieldLabel('Alamat Email'),
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
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildFieldLabel('Kata Sandi'),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Lupa kata sandi?',
                                style: AppTypography.labelProminent(
                                  fontSize: 12,
                                  color: AppColors.emasTua,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isObscured,
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
                                _isObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscured = !_isObscured;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kata sandi wajib diisi';
                            }
                            if (value.length < 6) {
                              return 'Kata sandi minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        _buildLoginButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Link Navigasi Daftar Baru
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum memiliki akun? ',
                        style: AppTypography.bodyMedium(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterPage()),
                          );
                        },
                        child: Text(
                          'Daftar Baru',
                          style: AppTypography.labelProminent(
                            fontSize: 13,
                            color: AppColors.emasTua,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmblem() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.sageTua,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.emas,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sageTua.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.pets_rounded, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTypography.labelProminent(
        fontSize: 12.5,
        color: AppColors.teksGelap,
      ),
    );
  }

  Widget _buildDemoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.emas, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.emasTua, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kredensial Supabase (.env) belum diisi. Coba tampilan UI dengan Mode Demo.',
              style: AppTypography.bodyCompact(
                fontSize: 11.5,
                color: AppColors.teksGelap,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              AuthService.instance.enterDemoMode();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.emas,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Mode Demo',
                style: AppTypography.labelProminent(
                  fontSize: 11,
                  color: AppColors.teksGelap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyCompact(
                fontSize: 12,
                color: AppColors.onErrorContainer,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                'Masuk ke Akun',
                style: AppTypography.labelProminent(
                  fontSize: 14,
                  color: AppColors.teksGelap,
                ),
              ),
      ),
    );
  }

  Widget _buildLockoutBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_clock_rounded, color: AppColors.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tombol sidik jari dinonaktifkan sementara karena 5 kali percobaan gagal berturut-turut. Silakan masuk menggunakan email dan kata sandi.',
              style: AppTypography.bodyCompact(
                fontSize: 12,
                color: AppColors.onErrorContainer,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricLoginButton() {
    return GestureDetector(
      onTap: _isBiometricLoading ? null : _handleBiometricLogin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceContainerHighest, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.sageTua,
                shape: BoxShape.circle,
              ),
              child: _isBiometricLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Masuk dengan Sidik Jari',
                    style: AppTypography.titleUi(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teksGelap,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _savedEmail != null && _savedEmail!.isNotEmpty
                        ? 'Buka sesi tersimpan untuk $_savedEmail'
                        : 'Buka sesi akun tersimpan secara instan',
                    style: AppTypography.labelCaption(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.emasTua,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}
