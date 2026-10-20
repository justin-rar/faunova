import 'package:flutter/material.dart';
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
      await AuthService.instance.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        username: _usernameController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyEmailPage(email: _emailController.text.trim()),
          ),
        );
      }
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
    if (error.contains('User already registered')) {
      return 'Alamat email ini sudah terdaftar. Silakan gunakan email lain atau masuk.';
    } else if (error.contains('Password should be at least')) {
      return 'Kata sandi minimal 6 karakter.';
    }
    return 'Gagal mendaftar: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gading,
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.teksPutih),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bergabung dengan Faunova',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teksGelap,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mulai petualangan observasi satwa liar dan bangun portofolio koleksimu.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.teksGelap.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 22),

                // Pesan Error jika ada
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

                // 1. Nama Lengkap
                _buildFieldLabel('Nama Lengkap'),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _buildInputDecoration(
                    hintText: 'Misal: Budi Satria Wibowo',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 2. Nama Pengguna (Username)
                _buildFieldLabel('Nama Pengguna (Username)'),
                TextFormField(
                  controller: _usernameController,
                  decoration: _buildInputDecoration(
                    hintText: 'budi_satria (huruf kecil & angka)',
                    icon: Icons.alternate_email_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
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

                // 3. Alamat Email
                _buildFieldLabel('Alamat Email'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    hintText: 'nama@domain.com',
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat email wajib diisi';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 4. Kata Sandi
                _buildFieldLabel('Kata Sandi'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  decoration: _buildInputDecoration(
                    hintText: 'Minimal 6 karakter',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.sageTua,
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

                // 5. Konfirmasi Kata Sandi
                _buildFieldLabel('Konfirmasi Kata Sandi'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _isConfirmObscured,
                  decoration: _buildInputDecoration(
                    hintText: 'Ulangi kata sandi Anda',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.sageTua,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmObscured = !_isConfirmObscured;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Konfirmasi kata sandi tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 6. Tombol Daftar
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'Daftarkan Akun',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teksGelap,
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // 7. Link kembali ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sudah memiliki akun? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.teksGelap.withValues(alpha: 0.8),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Masuk di Sini',
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
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.teksGelap,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.teksGelap.withValues(alpha: 0.5), fontSize: 13.5),
      filled: true,
      fillColor: AppColors.sageMuda.withValues(alpha: 0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
      prefixIcon: Icon(icon, color: AppColors.sageTua, size: 20),
      suffixIcon: suffixIcon,
    );
  }
}
