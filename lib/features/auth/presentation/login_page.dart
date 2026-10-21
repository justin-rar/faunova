import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
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
  String? _errorMessage;

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

    if (msg.contains('Invalid login credentials')) {
      return 'Email atau kata sandi tidak cocok. Silakan periksa kembali.';
    } else if (msg.contains('Email not confirmed')) {
      return 'Email belum diverifikasi. Buka tautan verifikasi di kotak masuk email Anda.';
    } else if (msg.contains('Koneksi Supabase belum aktif')) {
      return 'Koneksi ke server sedang disiapkan. Silakan coba masuk kembali.';
    } else if (msg.contains('Network') || msg.contains('SocketException')) {
      return 'Gagal terhubung ke internet. Periksa koneksi data atau Wi-Fi Anda.';
    }

    final cleaned = msg
        .replaceAll(RegExp(r'^AuthException\(message:\s*'), '')
        .replaceAll(RegExp(r',?\s*statusCode:.*$'), '')
        .replaceAll('Exception:', '')
        .trim();
    return cleaned.isNotEmpty
        ? cleaned
        : 'Gagal masuk ke akun. Silakan periksa kembali data Anda.';
  }

  InputDecoration _glassInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.emas.withValues(alpha: 0.9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
      ),
      prefixIcon: Icon(prefixIcon, color: Colors.white.withValues(alpha: 0.7), size: 20),
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
    final isConfigured =
        AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized;

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
          // Layer 2: Bokeh emas kanan atas
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
                    AppColors.emas.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Layer 2: Bokeh sage kiri bawah
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sageTua.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Layer 2: Bokeh putih kiri tengah
          Positioned(
            top: 200,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Layer 3: Konten scrollable
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 28),
                        child: child,
                      ),
                    );
                  },
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emblem
                        _buildEmblem(),
                        const SizedBox(height: 22),
                        // Judul
                        const Text(
                          'Faunova',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Arsip biodiversitas satwa nusantara',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.65),
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Kartu Glassmorphism
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.18),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  if (!isConfigured || !AppConfig.isSupabaseInitialized) ...[
                                    _buildDemoBanner(),
                                    const SizedBox(height: 16),
                                  ],
                                  if (_errorMessage != null) ...[
                                    _buildErrorBanner(_errorMessage!),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildFieldLabel('Alamat Email'),
                                  const SizedBox(height: 7),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType:
                                        TextInputType.emailAddress,
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
                                        return 'Format alamat email tidak valid';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildFieldLabel('Kata Sandi'),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ForgotPasswordPage(),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Lupa kata sandi?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.emas
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _isObscured,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                    cursorColor: AppColors.emas,
                                    decoration: _glassInputDecoration(
                                      hintText: 'Minimal 6 karakter',
                                      prefixIcon:
                                          Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isObscured
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
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
                                  const SizedBox(height: 24),
                                  _buildLoginButton(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Link Daftar Baru
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Belum memiliki akun? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterPage()),
                                );
                              },
                              child: Text(
                                'Daftar Baru',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emas,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmblem() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sageTua, Color(0xFF3D5E3A)],
        ),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.sageTua.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.pets_rounded, color: Colors.white, size: 40),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.85),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildDemoBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.emas.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.emas.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kredensial Supabase (.env) belum diisi. Coba tampilan UI dengan Mode Demo.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withValues(alpha: 0.8),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.emas.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.emas.withValues(alpha: 0.5), width: 1),
                  ),
                  child: const Text(
                    'Mode Demo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emas,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
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
                    color: AppColors.emas.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
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
                  'Masuk ke Akun',
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
