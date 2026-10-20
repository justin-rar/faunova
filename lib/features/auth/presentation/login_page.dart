import 'package:flutter/material.dart';
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
      // Jika berhasil, AuthGate akan otomatis mengarahkan ke MainNavigationScaffold
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getReadableErrorMessage(e.toString());
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

  String _getReadableErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email atau kata sandi tidak cocok. Silakan periksa kembali.';
    } else if (error.contains('Email not confirmed')) {
      return 'Email belum diverifikasi. Buka tautan verifikasi di kotak masuk email Anda.';
    }
    return 'Terjadi kendala saat masuk: $error';
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized;

    return Scaffold(
      backgroundColor: AppColors.gading,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Logo / Emblem
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.sageTua,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.sageTua.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: AppColors.teksPutih, // Putih di atas sage tua
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Judul & Subjudul
                  const Text(
                    'Faunova',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teksGelap,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Buku besar observasi dan arsip biodiversitas satwa nusantara',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.teksGelap.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Banner status konfigurasi Supabase
                  if (!isConfigured) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.sageMuda,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sage, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.sageTua, size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Kredensial Supabase (.env) belum diisi. Anda dapat mencoba UI dengan Mode Demo.',
                              style: TextStyle(fontSize: 12, color: AppColors.teksGelap),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              AuthService.instance.enterDemoMode();
                            },
                            child: const Text('Mode Demo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.emasTua)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Pesan Galat jika ada
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.merahStatus.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.merahStatus, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.teksGelap,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. Input Email
                  const Text(
                    'Alamat Email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teksGelap,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'nama@domain.com',
                      hintStyle: TextStyle(color: AppColors.teksGelap.withValues(alpha: 0.5), fontSize: 14),
                      filled: true,
                      fillColor: AppColors.sageMuda.withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sage),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.sage.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.sageTua),
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

                  // 4. Input Kata Sandi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kata Sandi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teksGelap,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                          );
                        },
                        child: const Text(
                          'Lupa kata sandi?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                    decoration: InputDecoration(
                      hintText: 'Minimal 6 karakter',
                      hintStyle: TextStyle(color: AppColors.teksGelap.withValues(alpha: 0.5), fontSize: 14),
                      filled: true,
                      fillColor: AppColors.sageMuda.withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sage),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.sage.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.sageTua),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.sageTua,
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

                  // 5. Tombol Masuk (Emas #C8A96B, teks gelap)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.teksGelap),
                            ),
                          )
                        : const Text(
                            'Masuk ke Akun',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teksGelap,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // 6. Link Daftar Akun Baru
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum memiliki akun? ',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.teksGelap.withValues(alpha: 0.8),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterPage()),
                          );
                        },
                        child: const Text(
                          'Daftar Baru',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sageTua,
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
}
