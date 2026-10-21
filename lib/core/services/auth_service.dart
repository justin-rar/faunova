import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'biometric_service.dart';
import 'encrypted_storage_service.dart';

/// Layanan autentikasi Supabase Auth untuk Faunova.
/// Menangani pendaftaran (register), login (email/password), lupa password, dan logout.
/// Dilengkapi fallback demo mode jika kredensial .env belum diisi oleh pengguna.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Controller untuk mensimulasikan auth state changes pada mode demo
  final StreamController<bool> _demoAuthStreamController = StreamController<bool>.broadcast();
  bool _isDemoAuthenticated = false;

  /// Memeriksa apakah user sedang dalam sesi login aktif
  bool get isAuthenticated {
    if (AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized) {
      return Supabase.instance.client.auth.currentSession != null;
    }
    return _isDemoAuthenticated;
  }

  /// Mendapatkan data user yang sedang aktif
  User? get currentUser {
    if (AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized) {
      return Supabase.instance.client.auth.currentUser;
    }
    return null;
  }

  /// Stream perubahan status autentikasi
  Stream<bool> get authStateChanges {
    if (AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized) {
      return Supabase.instance.client.auth.onAuthStateChange.map((data) => data.session != null);
    }
    return _demoAuthStreamController.stream;
  }

  Future<void> _ensureInitialized() async {
    if (!AppConfig.isSupabaseInitialized && AppConfig.isSupabaseConfigured) {
      await AppConfig.initializeSupabase();
    }
  }

  /// Mendaftarkan pengguna baru dengan email dan password
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    await _ensureInitialized();
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      throw const AuthException(
        'Koneksi Supabase belum aktif. Silakan mulai ulang aplikasi.',
      );
    }

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'username': username.trim().toLowerCase(),
        },
      );
      return response;
    } on AuthException catch (e) {
      developer.log('AuthException saat signUp: ${e.message}', name: 'AuthService', error: e);
      rethrow;
    } catch (e, stack) {
      developer.log('Error tak terduga saat signUp', name: 'AuthService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Masuk dengan email dan password
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      throw const AuthException(
        'Koneksi Supabase belum aktif. Gunakan tombol Mode Demo untuk simulasi offline.',
      );
    }

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      // Jika berhasil masuk, reset kegagalan biometrik & perbarui sesi jika biometrik aktif
      if (response.session != null) {
        await BiometricService.instance.resetFailedAttempts();
        if (BiometricService.instance.isBiometricEnabled()) {
          await BiometricService.instance.saveCurrentSession(
            email: response.user?.email,
            refreshToken: response.session?.refreshToken,
          );
        }
      }

      return response;
    } on AuthException catch (e) {
      developer.log('AuthException saat signIn: ${e.message}', name: 'AuthService', error: e);
      rethrow;
    } catch (e, stack) {
      developer.log('Error tak terduga saat signIn', name: 'AuthService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Mengirimkan email pemulihan/reset password via SMTP Brevo
  Future<void> resetPassword({required String email}) async {
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      developer.log('Mode Demo: Simulasi reset password untuk $email', name: 'AuthService');
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.trim(),
      );
    } on AuthException catch (e) {
      developer.log('AuthException saat resetPassword: ${e.message}', name: 'AuthService', error: e);
      rethrow;
    } catch (e, stack) {
      developer.log('Error tak terduga saat resetPassword', name: 'AuthService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Keluar dari akun (logout) dan menghapus sesi tersimpan serta cache privat (Plan 75, 563)
  Future<void> signOut() async {
    try {
      await EncryptedStorageService.instance.clearPrivateCacheOnSignOut();
      await BiometricService.instance.clearSavedSession();
    } catch (_) {}

    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      developer.log('Mode Demo: Simulasi logout', name: 'AuthService');
      _isDemoAuthenticated = false;
      _demoAuthStreamController.add(false);
      return;
    }

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e, stack) {
      developer.log('Error saat signOut: $e', name: 'AuthService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Masuk dengan mode demo (untuk pengujian antarmuka tanpa server)
  void enterDemoMode() {
    _isDemoAuthenticated = true;
    BiometricService.instance.resetFailedAttempts();
    if (BiometricService.instance.isBiometricEnabled()) {
      BiometricService.instance.saveCurrentSession(
        email: 'demo@faunova.app',
        refreshToken: 'faunova_demo_session_token',
      );
    }
    _demoAuthStreamController.add(true);
  }
}
