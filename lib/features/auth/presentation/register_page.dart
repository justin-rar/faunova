// ==============================================================================
// FAUNOVA PRESENTATION: RegisterPage
// Halaman pendaftaran akun pengguna penjelajah fauna nusantara
// Diselaraskan dengan Sistem Desain Stitch & AGENTS.md
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'verify_email_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.instance.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        username: _usernameController.text,
      );

      if (mounted) {
        if (response?.session != null) {
          // Email auto-confirm aktif: langsung masuk ke dashboard
          Navigator.pop(context);
        } else {
          // Memerlukan verifikasi email
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  VerifyEmailPage(email: _emailController.text.trim()),
            ),
          );
        }
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

  String _getReadableErrorMessage(dynamic error) {
    final String msg = error is AuthException ? error.message : error.toString();

    if (msg.contains('User already registered')) {
      return 'Alamat email ini sudah terdaftar. Silakan gunakan email lain atau masuk.';
    } else if (msg.contains('Password should be at least')) {
      return 'Kata sandi minimal 6 karakter.';
    } else if (msg.contains('over_email_send_rate_limit') ||
        msg.contains('rate limit')) {
      return 'Batas pengiriman email Supabase tercapai. Silakan coba beberapa saat lagi.';
    } else if (msg.contains('Error sending confirmation email') ||
        msg.contains('unexpected_failure')) {
      return 'Gagal mengirim email konfirmasi. Pastikan "Sender email" di SMTP Settings Supabase menggunakan email yang sama persis dengan email akun Brevo Anda.';
    }

    final cleaned = msg
        .replaceAll(RegExp(r'^AuthException\(message:\s*'), '')
        .replaceAll(RegExp(r',?\s*statusCode:.*$'), '')
        .replaceAll('Exception:', '')
        .trim();
    return cleaned.isNotEmpty ? cleaned : 'Gagal mendaftar. Silakan periksa kembali data Anda.';
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
    return Scaffold(
      backgroundColor: AppColors.gading,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.sageTua, size: 20),
        ),
        title: Text(
          'Daftar Akun Baru',
          style: AppTypography.titleUi(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.teksGelap,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              // Judul Editorial
              Text(
                'Bergabung dengan Faunova',
                style: AppTypography.headlineSpecies(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teksGelap,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mulai petualangan observasi satwa liar dan bangun portofolio koleksimu.',
                style: AppTypography.bodyMedium(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Kartu Form Solid Naturalis
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner error
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(_errorMessage!),
                        const SizedBox(height: 16),
                      ],

                      // Nama Lengkap
                      _buildLabel('Nama Lengkap'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        style: AppTypography.bodyMedium(
                          color: AppColors.teksGelap,
                          fontSize: 14,
                        ),
                        cursorColor: AppColors.sageTua,
                        decoration: _inputDecoration(
                          hintText: 'Misal: Budi Satria Wibowo',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }
                          if (value.trim().length < 2) {
                            return 'Nama terlalu pendek (minimal 2 karakter)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Username
                      _buildLabel('Username (Unik)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _usernameController,
                        style: AppTypography.bodyMedium(
                          color: AppColors.teksGelap,
                          fontSize: 14,
                        ),
                        cursorColor: AppColors.sageTua,
                        decoration: _inputDecoration(
                          hintText: 'budi_satria (huruf kecil, angka, _)',
                          prefixIcon: Icons.alternate_email_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username wajib diisi';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length < 3) {
                            return 'Username minimal 3 karakter';
                          }
                          if (trimmed.length > 20) {
                            return 'Username maksimal 20 karakter';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
                            return 'Hanya huruf, angka, dan garis bawah (_)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email
                      _buildLabel('Alamat Email'),
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
                      const SizedBox(height: 14),

                      // Kata Sandi
                      _buildLabel('Kata Sandi'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
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
                              _isPasswordObscured
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
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
                      const SizedBox(height: 14),

                      // Konfirmasi Kata Sandi
                      _buildLabel('Konfirmasi Kata Sandi'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _isConfirmObscured,
                        style: AppTypography.bodyMedium(
                          color: AppColors.teksGelap,
                          fontSize: 14,
                        ),
                        cursorColor: AppColors.sageTua,
                        decoration: _inputDecoration(
                          hintText: 'Ulangi kata sandi Anda',
                          prefixIcon: Icons.lock_reset_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmObscured
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmObscured = !_isConfirmObscured;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi kata sandi wajib diisi';
                          }
                          if (value != _passwordController.text) {
                            return 'Konfirmasi kata sandi tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      // Tombol Daftarkan Akun
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Navigasi Kembali ke Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah memiliki akun? ',
                    style: AppTypography.bodyMedium(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Masuk',
                      style: AppTypography.labelProminent(
                        fontSize: 13,
                        color: AppColors.emasTua,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTypography.labelProminent(
        fontSize: 12.5,
        color: AppColors.teksGelap,
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

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
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
                'Daftarkan Akun',
                style: AppTypography.labelProminent(
                  fontSize: 14,
                  color: AppColors.teksGelap,
                ),
              ),
      ),
    );
  }
}
