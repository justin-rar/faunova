import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../navigation/main_navigation_scaffold.dart';
import 'biometric_lock_page.dart';
import 'login_page.dart';

/// Gerbang autentikasi utama (AuthGate).
/// Memeriksa status sesi Supabase Auth & proteksi Biometrik (App Lock):
/// - Belum login -> LoginPage
/// - Sudah login & biometrik nonaktif -> Langsung ke MainNavigationScaffold tanpa password
/// - Sudah login & biometrik aktif -> BiometricLockPage (sidik jari / fallback kata sandi)
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        // Kunci kembali jika aplikasi ditinggalkan di latar belakang lebih dari 2 menit
        if (elapsed > const Duration(minutes: 2)) {
          if (BiometricService.instance.isBiometricEnabled()) {
            BiometricService.instance.setAppUnlocked(false);
          }
        }
      }
      _pausedTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.isAuthenticated,
      builder: (context, snapshot) {
        final isAuthenticated = snapshot.data ?? false;

        if (!isAuthenticated) {
          return const LoginPage();
        }

        // Cek apakah proteksi biometrik diaktifkan oleh pengguna
        final isBioEnabled = BiometricService.instance.isBiometricEnabled();
        if (!isBioEnabled) {
          return const MainNavigationScaffold();
        }

        // Jika biometrik aktif, periksa status buka kunci sesi saat ini
        return ValueListenableBuilder<bool>(
          valueListenable: BiometricService.instance.isAppUnlockedNotifier,
          builder: (context, isUnlocked, _) {
            if (isUnlocked) {
              return const MainNavigationScaffold();
            } else {
              return const BiometricLockPage();
            }
          },
        );
      },
    );
  }
}

