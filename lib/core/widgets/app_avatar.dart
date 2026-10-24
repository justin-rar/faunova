import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FaunovaAvatarPreset {
  final String id;
  final String name;
  final String emoji;
  final Color backgroundColor;

  const FaunovaAvatarPreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.backgroundColor,
  });
}

class AppAvatar extends StatelessWidget {
  final String? avatarPath;
  final String displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const AppAvatar({
    super.key,
    required this.avatarPath,
    required this.displayName,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  static const List<FaunovaAvatarPreset> presets = [
    FaunovaAvatarPreset(id: 'preset:badak', name: 'Badak Jawa', emoji: '🦏', backgroundColor: Color(0xFF5C7457)),
    FaunovaAvatarPreset(id: 'preset:harimau', name: 'Harimau Sumatera', emoji: '🐯', backgroundColor: Color(0xFFB5762A)),
    FaunovaAvatarPreset(id: 'preset:jalak', name: 'Jalak Bali', emoji: '🐦', backgroundColor: Color(0xFF4A7C59)),
    FaunovaAvatarPreset(id: 'preset:penyu', name: 'Penyu Hijau', emoji: '🐢', backgroundColor: Color(0xFF3B6B55)),
    FaunovaAvatarPreset(id: 'preset:komodo', name: 'Komodo', emoji: '🦎', backgroundColor: Color(0xFF6E7D4E)),
    FaunovaAvatarPreset(id: 'preset:orangutan', name: 'Orangutan', emoji: '🦧', backgroundColor: Color(0xFF9E5727)),
    FaunovaAvatarPreset(id: 'preset:cenderawasih', name: 'Cenderawasih', emoji: '🦜', backgroundColor: Color(0xFF836239)),
    FaunovaAvatarPreset(id: 'preset:rusa', name: 'Rusa Bawean', emoji: '🦌', backgroundColor: Color(0xFF706B4F)),
    FaunovaAvatarPreset(id: 'preset:gajah', name: 'Gajah Sumatera', emoji: '🐘', backgroundColor: Color(0xFF56655A)),
    FaunovaAvatarPreset(id: 'preset:kucing', name: 'Kucing Kuwuk', emoji: '🐆', backgroundColor: Color(0xFF8A6B3A)),
  ];

  static FaunovaAvatarPreset? findPreset(String? path) {
    if (path == null || !path.startsWith('preset:')) return null;
    return presets.firstWhere(
      (p) => p.id == path,
      orElse: () => presets.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.sageTua;
    final effectiveText = textColor ?? AppColors.teksPutih;
    final size = radius * 2;
    final calcFontSize = fontSize ?? (radius * 0.85);

    // 1. Preset Satwa Endemik
    if (avatarPath != null && avatarPath!.startsWith('preset:')) {
      final preset = findPreset(avatarPath);
      if (preset != null) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: preset.backgroundColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            preset.emoji,
            style: TextStyle(fontSize: calcFontSize * 1.1),
          ),
        );
      }
    }

    // 2. Berkas Foto Lokal (File Picker / Galeri / Kamera)
    if (avatarPath != null &&
        (avatarPath!.startsWith('/') || avatarPath!.startsWith('file:'))) {
      final cleanPath = avatarPath!.replaceFirst('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildInitialFallback(effectiveBg, effectiveText, size, calcFontSize),
          ),
        );
      }
    }

    // 3. Foto dari Jaringan / Supabase Storage (URL)
    if (avatarPath != null &&
        (avatarPath!.startsWith('http://') || avatarPath!.startsWith('https://'))) {
      return ClipOval(
        child: Image.network(
          avatarPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialFallback(effectiveBg, effectiveText, size, calcFontSize),
        ),
      );
    }

    // 4. Default Fallback: Inisial Huruf Pertama
    return _buildInitialFallback(effectiveBg, effectiveText, size, calcFontSize);
  }

  Widget _buildInitialFallback(Color bg, Color textCol, double size, double fSize) {
    final letter = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'P';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: textCol,
          fontWeight: FontWeight.w800,
          fontSize: fSize,
        ),
      ),
    );
  }
}
