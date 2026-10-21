import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.resetPassword(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _isSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal mengirim instruksi pemulihan: $e';
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
          // Bokeh emas
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
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
            bottom: 60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
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
                // AppBar transparan
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
                        'Pemulihan Kata Sandi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isSent
                      ? _buildSuccessView()
                      : _buildFormView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Lupa Kata Sandi?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan alamat email yang terdaftar pada akun Faunova Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              // Kartu glassmorphism
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(22),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          _buildErrorBanner(_errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Alamat Email',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          cursorColor: AppColors.emas,
                          decoration: InputDecoration(
                            hintText: 'nama@domain.com',
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13.5),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.10),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(
                                  color: AppColors.emas.withValues(alpha: 0.9),
                                  width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                  color: Color(0xFFFF8A80), width: 1.2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                  color: Color(0xFFFF8A80), width: 1.5),
                            ),
                            prefixIcon: Icon(Icons.email_outlined,
                                color: Colors.white.withValues(alpha: 0.65),
                                size: 20),
                            errorStyle: const TextStyle(
                              color: Color(0xFFFFCDD2),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Alamat email wajib diisi';
                            }
                            if (!value.contains('@') ||
                                !value.contains('.')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        // Tombol kirim
                        GestureDetector(
                          onTap: _isLoading ? null : _handleResetPassword,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: _isLoading
                                  ? LinearGradient(colors: [
                                      AppColors.emas.withValues(alpha: 0.5),
                                      AppColors.emas.withValues(alpha: 0.4),
                                    ])
                                  : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.emas,
                                        Color(0xFFDDB96E)
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppColors.emas
                                            .withValues(alpha: 0.38),
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
                                            AlwaysStoppedAnimation<Color>(
                                                AppColors.teksGelap),
                                      ),
                                    )
                                  : const Text(
                                      'Kirim Tautan Pemulihan',
                                      style: TextStyle(
                                        fontSize: 15,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.92 + 0.08 * value, child: child),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon berhasil
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.sageTua,
                      const Color(0xFF3D5E3A),
                    ],
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sageTua.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.mark_email_read_rounded,
                    size: 44, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tautan Terkirim',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Instruksi untuk mengatur ulang kata sandi telah dikirimkan ke ${_emailController.text}. Silakan periksa kotak masuk atau folder Spam.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => Navigator.pop(context),
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
}
