import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografi resmi Faunova sesuai Stitch Design System & AGENTS.md:
/// - Noto Serif: Judul satwa, nama latin ilmiah (italic), display editorial
/// - Plus Jakarta Sans: Seluruh teks antarmuka aplikasi (UI, tombol, body, caption)
class AppTypography {
  AppTypography._();

  // ==========================================
  // NOTO SERIF (Editorial & Taksonomi Satwa)
  // ==========================================

  /// Judul editorial besar (30px)
  static TextStyle displayEditorial({
    Color color = AppColors.teksGelap,
    FontWeight fontWeight = FontWeight.w600,
    double? fontSize,
    double? letterSpacing,
  }) {
    final size = fontSize ?? 30.0;
    return GoogleFonts.notoSerif(
      fontSize: size,
      fontWeight: fontWeight,
      height: 38 / 30,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Nama satwa / judul spesies (20-22px)
  static TextStyle headlineSpecies({
    Color color = AppColors.teksGelap,
    FontWeight fontWeight = FontWeight.w600,
    double? fontSize,
    double? letterSpacing,
  }) {
    final size = fontSize ?? 22.0;
    return GoogleFonts.notoSerif(
      fontSize: size,
      fontWeight: fontWeight,
      height: 28 / 22,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Nama latin ilmiah satwa (italic binomial, 14-16px)
  static TextStyle subheadSpecies({
    Color color = AppColors.sageTua,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.italic,
    double? fontSize,
  }) {
    final size = fontSize ?? 15.0;
    return GoogleFonts.notoSerif(
      fontSize: size,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: 22 / 15,
      color: color,
    );
  }

  // ==========================================
  // PLUS JAKARTA SANS (Antarmuka & Konten UI)
  // ==========================================

  /// Judul seksi / Header UI (18px)
  static TextStyle titleUi({
    Color color = AppColors.teksGelap,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = -0.2,
    double? fontSize,
  }) {
    final size = fontSize ?? 18.0;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: fontWeight,
      height: 24 / 18,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// Teks isi standar (15px)
  static TextStyle bodyDefault({
    Color color = AppColors.teksGelap,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.45,
    double? fontSize,
  }) {
    final size = fontSize ?? 15.0;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  /// Teks isi medium / penekanan (14-15px)
  static TextStyle bodyMedium({
    Color color = AppColors.teksGelap,
    FontWeight fontWeight = FontWeight.w500,
    double? fontSize,
    double? height,
  }) {
    final size = fontSize ?? 14.0;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: fontWeight,
      height: height ?? (20 / 14),
      color: color,
    );
  }

  /// Teks isi kompak untuk kartu & deskripsi singkat (13px)
  static TextStyle bodyCompact({
    Color color = AppColors.teksGelap,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.4,
    double? fontSize,
  }) {
    final size = fontSize ?? 13.0;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  /// Label tombol, chip, atau status prominen (13px)
  static TextStyle labelProminent({
    Color color = AppColors.teksGelap,
    FontWeight fontWeight = FontWeight.w600,
    double? fontSize,
  }) {
    final size = fontSize ?? 13.0;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: fontWeight,
      height: 16 / 13,
      color: color,
    );
  }

  /// Keterangan mikro, timestamp, atau metadata (11px)
  static TextStyle labelCaption({
    Color color = AppColors.sage,
    FontWeight fontWeight = FontWeight.w500,
    double? fontSize,
  }) {
    final size = fontSize ?? 11.0;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: fontWeight,
      height: 14 / 11,
      color: color,
    );
  }
}
