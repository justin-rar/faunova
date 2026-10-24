// ==============================================================================
// FAUNOVA PRESENTATION: ForgotPasswordPage
// Halaman pemulihan kata sandi via email konfirmasi
// Diselaraskan dengan Sistem Desain Stitch & AGENTS.md
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

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

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                'Masukkan alamat email yang terdaftar untuk menerima tautan pemulihan kata sandi.',
                style: AppTypography.bodyMedium(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

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
                child: _isSent ? _buildSuccessView() : _buildFormView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
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
              onPressed: _isLoading ? null : _handleResetPassword,
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

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Icon(Icons.mark_email_read_rounded, color: AppColors.sageTua, size: 48),
        ),
        const SizedBox(height: 12),
        Text(
          'Tautan Terkirim!',
          style: AppTypography.headlineSpecies(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.teksGelap,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Silakan periksa kotak masuk atau folder spam di ${_emailController.text} untuk tautan pemulihan kata sandi Anda.',
          style: AppTypography.bodyMedium(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emas,
              foregroundColor: AppColors.teksGelap,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Kembali ke Halaman Masuk',
              style: AppTypography.labelProminent(
                fontSize: 13.5,
                color: AppColors.teksGelap,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
