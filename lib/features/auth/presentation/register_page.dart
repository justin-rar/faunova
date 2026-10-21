import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
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

  InputDecoration _glassInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13.5),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: AppColors.emas.withValues(alpha: 0.9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
      ),
      prefixIcon: Icon(prefixIcon, color: Colors.white.withValues(alpha: 0.65), size: 20),
      suffixIcon: suffixIcon,
      errorStyle: const TextStyle(
        color: Color(0xFFFFCDD2),
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          // Bokeh emas kanan atas
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emas.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bokeh sage kiri bawah
          Positioned(
            bottom: 40,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sageTua.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Layer 3: Konten
          SafeArea(
            child: Column(
              children: [
                // AppBar transparan kustom
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                      Text(
                        'Daftar Akun Baru',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Konten form scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 22),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          // Judul
                          const Text(
                            'Bergabung dengan Faunova',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mulai petualangan observasi satwa liar dan bangun portofolio koleksimu.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Kartu glassmorphism
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 28,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(22),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                      textCapitalization:
                                          TextCapitalization.words,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                      cursorColor: AppColors.emas,
                                      decoration: _glassInputDecoration(
                                        hintText: 'Misal: Budi Satria Wibowo',
                                        prefixIcon:
                                            Icons.person_outline_rounded,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Nama lengkap wajib diisi';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    // Nama Pengguna
                                    _buildLabel('Nama Pengguna'),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _usernameController,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                      cursorColor: AppColors.emas,
                                      decoration: _glassInputDecoration(
                                        hintText: 'budi_satria (huruf kecil & angka)',
                                        prefixIcon:
                                            Icons.alternate_email_rounded,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Nama pengguna wajib diisi';
                                        }
                                        if (value.contains(' ')) {
                                          return 'Nama pengguna tidak boleh mengandung spasi';
                                        }
                                        if (value.length < 3) {
                                          return 'Minimal 3 karakter';
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
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                      cursorColor: AppColors.emas,
                                      decoration: _glassInputDecoration(
                                        hintText: 'nama@domain.com',
                                        prefixIcon: Icons.email_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Alamat email wajib diisi';
                                        }
                                        if (!value.contains('@') ||
                                            !value.contains('.')) {
                                          return 'Format email tidak valid';
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
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                      cursorColor: AppColors.emas,
                                      decoration: _glassInputDecoration(
                                        hintText: 'Minimal 6 karakter',
                                        prefixIcon: Icons.lock_outline_rounded,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordObscured
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.white
                                                .withValues(alpha: 0.55),
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() {
                                            _isPasswordObscured =
                                                !_isPasswordObscured;
                                          }),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Kata sandi wajib diisi';
                                        }
                                        if (value.length < 6) {
                                          return 'Minimal 6 karakter';
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
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                      cursorColor: AppColors.emas,
                                      decoration: _glassInputDecoration(
                                        hintText: 'Ulangi kata sandi',
                                        prefixIcon:
                                            Icons.lock_reset_rounded,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isConfirmObscured
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.white
                                                .withValues(alpha: 0.55),
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() {
                                            _isConfirmObscured =
                                                !_isConfirmObscured;
                                          }),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Konfirmasi kata sandi wajib diisi';
                                        }
                                        if (value !=
                                            _passwordController.text) {
                                          return 'Kata sandi tidak cocok';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    // Tombol Daftar
                                    _buildRegisterButton(),
                                  ],
                                ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Link kembali ke login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah memiliki akun? ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Masuk di Sini',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.emas,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.85),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFB3261E).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFF8A80).withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF8A80), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFFCDD2),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRegister,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(
                  colors: [
                    AppColors.emas.withValues(alpha: 0.5),
                    AppColors.emas.withValues(alpha: 0.4),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.emas, Color(0xFFDDB96E)],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.emas.withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.teksGelap),
                  ),
                )
              : const Text(
                  'Daftarkan Akun',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teksGelap,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
