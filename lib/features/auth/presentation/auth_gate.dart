import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../navigation/main_navigation_scaffold.dart';
import 'login_page.dart';

/// Gerbang autentikasi utama (AuthGate).
/// Memeriksa status sesi Supabase Auth:
/// - Jika terautentikasi (ada sesi aktif) -> MainNavigationScaffold
/// - Jika belum terautentikasi -> LoginPage
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.isAuthenticated,
      builder: (context, snapshot) {
        final isAuthenticated = snapshot.data ?? false;

        if (isAuthenticated) {
          return const MainNavigationScaffold();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
