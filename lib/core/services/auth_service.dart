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

  /// Mendapatkan ID user yang sedang aktif
  String? get currentUserId => currentUser?.id;

  /// Mendapatkan email user yang sedang aktif (atau demo email)
  String? get currentUserEmail {
    if (AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized) {
      return Supabase.instance.client.auth.currentUser?.email;
    }
    if (_isDemoAuthenticated) {
      return 'demo@faunova.app';
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

    final cleanUsername = username.trim();
    final cleanFullName = fullName.trim();
    final displayName = cleanFullName.isNotEmpty ? cleanFullName : cleanUsername;

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': cleanFullName,
          'display_name': displayName,
          'nickname': displayName,
          'raw_username': cleanUsername,
          'username': cleanUsername.toLowerCase(),
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
        BiometricService.instance.setAppUnlocked(true);
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

  /// Membersihkan sesi pemulihan atau token menggantung sebelumnya demi menjamin state bersih (Requirement 3)
  Future<void> clearRecoverySession() async {
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      developer.log('Mode Demo: Reset recovery session state', name: 'AuthService');
      return;
    }

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }

  /// Memverifikasi kode OTP recovery secara mandiri tanpa langsung mengubah kata sandi (Requirement 2)
  Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      developer.log('Mode Demo: Simulasi verifikasi OTP untuk $email', name: 'AuthService');
      await Future.delayed(const Duration(milliseconds: 400));
      if (otp.trim().length < 6) {
        throw const AuthException('Kode OTP minimal 6 digit.');
      }
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email.trim(),
        token: otp.trim(),
        type: OtpType.recovery,
      );

      if (response.session == null && Supabase.instance.client.auth.currentSession == null) {
        throw const AuthException('Verifikasi gagal. Pastikan kode OTP yang dimasukkan benar.');
      }
    } on AuthException catch (e) {
      developer.log('AuthException saat verifyRecoveryOtp: ${e.message}', name: 'AuthService', error: e);
      rethrow;
    } catch (e, stack) {
      developer.log('Error tak terduga saat verifyRecoveryOtp', name: 'AuthService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Memverifikasi kode OTP recovery dan langsung memperbarui kata sandi baru (Plan S2)
  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      developer.log('Mode Demo: Simulasi verifikasi OTP dan reset password untuk $email', name: 'AuthService');
      await Future.delayed(const Duration(milliseconds: 400));
      if (otp.trim().length < 6) {
        throw const AuthException('Kode OTP minimal 6 karakter.');
      }
      if (newPassword.length < 6) {
        throw const AuthException('Kata sandi baru minimal 6 karakter.');
      }
      return;
    }

    try {
      // 1. Verifikasi kode OTP pemulihan
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email.trim(),
        token: otp.trim(),
        type: OtpType.recovery,
      );

      if (response.session == null && Supabase.instance.client.auth.currentSession == null) {
        throw const AuthException('Verifikasi gagal. Pastikan kode OTP yang dimasukkan benar.');
      }

      // 2. Perbarui kata sandi pengguna
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 3. Keluar dari sesi sementara agar login berikutnya bersih
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (e) {
      developer.log('AuthException saat verifyOtpAndResetPassword: ${e.message}', name: 'AuthService', error: e);
      rethrow;
    } catch (e, stack) {
      developer.log('Error tak terduga saat verifyOtpAndResetPassword', name: 'AuthService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Memperbarui kata sandi langsung jika pengguna sudah memiliki sesi pemulihan aktif (misal dari tautan email / deep link)
  Future<void> updatePasswordOnly({required String newPassword}) async {
    if (!AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      developer.log('Mode Demo: Simulasi pembaruan kata sandi langsung', name: 'AuthService');
      await Future.delayed(const Duration(milliseconds: 300));
      if (newPassword.length < 6) {
        throw const AuthException('Kata sandi baru minimal 6 karakter.');
      }
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (e) {
      developer.log('AuthException saat updatePasswordOnly: ${e.message}', name: 'AuthService', error: e);
      rethrow;
    } catch (e, stack) {
      developer.log('Error tak terduga saat updatePasswordOnly', name: 'AuthService', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Keluar dari akun (logout) dan menghapus sesi tersimpan serta cache privat (Plan 75, 563)
  Future<void> signOut() async {
    try {
      await EncryptedStorageService.instance.clearPrivateCacheOnSignOut();
      await BiometricService.instance.clearSavedSession();
      BiometricService.instance.setAppUnlocked(false);
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
    BiometricService.instance.setAppUnlocked(true);
    if (BiometricService.instance.isBiometricEnabled()) {
      BiometricService.instance.saveCurrentSession(
        email: 'demo@faunova.app',
        refreshToken: 'faunova_demo_session_token',
      );
    }
    _demoAuthStreamController.add(true);
  }
}
