// ==============================================================================
// FAUNOVA WIDGET: EditProfileSheet
// Lembar modal pengeditan profil kolektor (Nama tampilan, bio, avatar)
// Sesuai Plan 5.2, 5.7, 18 & AGENTS.md (Sesi S11 & S22)
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/profile_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
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
  String? _selectedAvatarPath;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.displayName);
    _bioController = TextEditingController(text: widget.initialProfile.bio);
    _selectedAvatarPath = widget.initialProfile.avatarPath;
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
        avatarPath: _selectedAvatarPath != widget.initialProfile.avatarPath
            ? (_selectedAvatarPath ?? '__clear__')
            : widget.initialProfile.avatarPath,
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
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedAvatarPath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.merahStatus,
            content: Text('Gagal memilih gambar: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _showFaunaPresetsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Material(
          color: AppColors.gading,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const Row(
                  children: [
                    Icon(Icons.pets_rounded, color: AppColors.sageTua, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Avatar Satwa Endemik',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teksGelap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih maskot satwa Nusantara sebagai identitas penjelajah Anda.',
                  style: TextStyle(fontSize: 12, color: AppColors.teksGelap),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: AppAvatar.presets.length,
                  itemBuilder: (context, index) {
                    final preset = AppAvatar.presets[index];
                    final isSelected = _selectedAvatarPath == preset.id;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAvatarPath = preset.id;
                        });
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: preset.backgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.emas : Colors.white,
                                width: isSelected ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isSelected ? 0.2 : 0.08),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              preset.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preset.name.split(' ').first,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.sageTua : AppColors.teksGelap,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAvatarOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Material(
          color: AppColors.gading,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const Text(
                  'Ubah Foto Profil Kolektor',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teksGelap,
                  ),
                ),
                const SizedBox(height: 14),

                // Opsi 1: Preset Avatar Satwa
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.sageMuda.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🦏', style: TextStyle(fontSize: 22)),
                  ),
                  title: const Text(
                    'Pilih Avatar Satwa Endemik',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.teksGelap),
                  ),
                  subtitle: const Text(
                    '10 maskot fauna khas Indonesia (Badak, Harimau, Jalak Bali, dll.)',
                    style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showFaunaPresetsDialog();
                  },
                ),
                const Divider(height: 16),

                // Opsi 2: Dari Galeri
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.sageMuda.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.sageTua, size: 22),
                  ),
                  title: const Text(
                    'Pilih dari Galeri Foto',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.teksGelap),
                  ),
                  subtitle: const Text(
                    'Unggah foto profil dari penyimpanan perangkat Anda',
                    style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(height: 16),

                // Opsi 3: Ambil dari Kamera
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.sageMuda.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.sageTua, size: 22),
                  ),
                  title: const Text(
                    'Ambil Foto dengan Kamera',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.teksGelap),
                  ),
                  subtitle: const Text(
                    'Bidikan langsung untuk foto potret kolektor lapangan',
                    style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),

                // Opsi 4: Hapus foto / Reset ke Inisial (jika ada avatar kustom)
                if (_selectedAvatarPath != null) ...[
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.merahStatus.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.merahStatus, size: 22),
                    ),
                    title: const Text(
                      'Gunakan Inisial Huruf',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.merahStatus),
                    ),
                    subtitle: const Text(
                      'Hapus foto/avatar dan tampilkan inisial nama',
                      style: TextStyle(fontSize: 11.5, color: AppColors.teksGelap),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _selectedAvatarPath = null;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewDisplayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : widget.initialProfile.displayName;

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

            // Pratinjau Avatar Interaktif
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showAvatarOptionsModal,
                    child: Stack(
                      children: [
                        AppAvatar(
                          avatarPath: _selectedAvatarPath,
                          displayName: previewDisplayName,
                          radius: 42,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.emas,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.gading, width: 2.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.teksGelap),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showAvatarOptionsModal,
                    icon: const Icon(Icons.edit_rounded, size: 15, color: AppColors.sageTua),
                    label: const Text(
                      'Ubah Foto / Avatar Satwa',
                      style: TextStyle(
                        color: AppColors.sageTua,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

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
