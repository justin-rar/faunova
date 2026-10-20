import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.gading,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.sageTua,
        onPrimary: AppColors.teksPutih,
        secondary: AppColors.emas,
        onSecondary: AppColors.teksGelap,
        surface: AppColors.gading,
        onSurface: AppColors.teksGelap,
        error: AppColors.merahStatus,
        onError: AppColors.teksPutih,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.sageTua,
        foregroundColor: AppColors.teksPutih,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.teksPutih,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.teksPutih),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.sageMuda,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emas,
          foregroundColor: AppColors.teksGelap,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.teksGelap,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.sageTua,
          side: const BorderSide(color: AppColors.sageTua, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: AppColors.teksGelap, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.teksGelap, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.teksGelap, fontSize: 12),
        labelLarge: TextStyle(color: AppColors.teksGelap, fontWeight: FontWeight.w600),
      ),
    );
  }
}
