// ==============================================================================
// FAUNOVA WIDGET: EditProfileSheet
// Lembar modal pengeditan profil kolektor (Nama tampilan, bio, avatar)
// Sesuai Plan 5.2, 5.7, 18 & AGENTS.md (Sesi S11)
// ==============================================================================

import 'package:flutter/material.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/public_profile_model.dart';

class EditProfileSheet extends StatefulWidget {
  final PublicProfileModel initialProfile;
  final ValueChanged<PublicProfileModel>? onSaved;

  const EditProfileSheet({
    super.key,
    required this.initialProfile,
    this.onSaved,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.displayName);
    _bioController = TextEditingController(text: widget.initialProfile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.length < 2) {
      setState(() {
        _errorMessage = 'Nama tampilan minimal 2 karakter.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await ProfileService.instance.updateMyProfile(
        displayName: name,
        bio: bio,
      );

      if (mounted) {
        widget.onSaved?.call(updated);
        Navigator.of(context).pop(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.sageTua,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Text(
              'Profil kolektor berhasil diperbarui!',
              style: TextStyle(color: AppColors.teksPutih, fontSize: 13),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.gading,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.sage.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Judul
            Row(
              children: [
                const Icon(Icons.badge_rounded, color: AppColors.sageTua, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Edit Profil Kolektor',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teksGelap,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.teksGelap, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pratinjau Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.sageTua,
                    child: Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text[0].toUpperCase()
                          : widget.initialProfile.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teksPutih,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.emas,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gading, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded, size: 14, color: AppColors.teksGelap),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.merahStatus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.merahStatus.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.merahStatus),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.merahStatus),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Input Nama Tampilan
            const Text(
              'Nama Tampilan',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              maxLength: 60,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Nama lengkap Anda',
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.sageMuda),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.sageMuda.withValues(alpha: 0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Username (Read-only dengan penjelasan)
            const Text(
              'Nama Pengguna (@username)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sageMuda.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Text(
                    '@${widget.initialProfile.username}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teksGelap.withValues(alpha: 0.65),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.sage),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nama pengguna permanen demi validitas riwayat hash rantai observasi.',
              style: TextStyle(fontSize: 11, color: AppColors.teksGelap.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 14),

            // Input Bio / Catatan Lapangan
            const Text(
              'Bio / Minat Satwa',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.teksGelap),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Tuliskan sedikit tentang minat konservasi atau observasi Anda...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.sageMuda),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.sageMuda.withValues(alpha: 0.8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.sageTua, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Simpan
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emas,
                foregroundColor: AppColors.teksGelap,
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.teksGelap),
                    )
                  : const Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
