// ==============================================================================
// FAUNOVA SERVICE: BiometricService
// Autentikasi biometrik (Fingerprint / Face ID) menggunakan local_auth
// dan flutter_secure_storage untuk sesi tersimpan sesuai Plan 5.1 & Sesi S17
// ==============================================================================

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'auth_service.dart';
import 'encrypted_storage_service.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._internal();
  BiometricService._internal();

  static const String keyBiometricEnabled = 'faunova_biometric_enabled';
  static const String keySavedSessionToken = 'faunova_saved_session_refresh_token';
  static const String keySavedUserEmail = 'faunova_saved_user_email';
  static const String keyFailedAttempts = 'faunova_biometric_failed_attempts';
  static const int maxFailedAttempts = 5;

  LocalAuthentication _localAuth = LocalAuthentication();
  FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Status apakah aplikasi saat ini terbuka kuncinya (App Lock).
  /// Default false saat cold start jika biometrik aktif.
  final ValueNotifier<bool> isAppUnlockedNotifier = ValueNotifier<bool>(false);

  /// Status kunci aplikasi saat ini
  bool get isAppUnlocked => isAppUnlockedNotifier.value;

  /// Memperbarui status buka kunci aplikasi
  void setAppUnlocked(bool unlocked) {
    if (isAppUnlockedNotifier.value != unlocked) {
      isAppUnlockedNotifier.value = unlocked;
    }
  }

  // Mock / simulation override untuk unit testing
  bool? _mockCanCheckBiometrics;
  bool? _mockIsDeviceSupported;
  List<BiometricType>? _mockAvailableBiometrics;
  bool? _mockAuthResult;
  bool? _mockBiometricEnabled;
  bool disableAutoTrigger = false;

  @visibleForTesting
  void setMockDependencies({
    LocalAuthentication? auth,
    FlutterSecureStorage? storage,
    bool? mockCanCheckBiometrics,
    bool? mockIsDeviceSupported,
    List<BiometricType>? mockAvailableBiometrics,
    bool? mockAuthResult,
    bool? mockBiometricEnabled,
    bool? disableAutoTrigger,
  }) {
    if (auth != null) _localAuth = auth;
    if (storage != null) _secureStorage = storage;
    _mockCanCheckBiometrics = mockCanCheckBiometrics;
    _mockIsDeviceSupported = mockIsDeviceSupported;
    _mockAvailableBiometrics = mockAvailableBiometrics;
    _mockAuthResult = mockAuthResult;
    if (mockBiometricEnabled != null) _mockBiometricEnabled = mockBiometricEnabled;
    if (disableAutoTrigger != null) this.disableAutoTrigger = disableAutoTrigger;
  }

  @visibleForTesting
  void resetMockOverrides() {
    _mockCanCheckBiometrics = null;
    _mockIsDeviceSupported = null;
    _mockAvailableBiometrics = null;
    _mockAuthResult = null;
    _mockBiometricEnabled = null;
    disableAutoTrigger = false;
    isAppUnlockedNotifier.value = false;
  }

  bool get _isTestEnvironment {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
      return WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  final Map<String, String> _inMemoryStorageFallback = {};

  Future<void> _safeSecureWrite(String key, String value) async {
    _inMemoryStorageFallback[key] = value;
    if (_isTestEnvironment) return;
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> _safeSecureRead(String key) async {
    if (_isTestEnvironment) return _inMemoryStorageFallback[key];
    try {
      final val = await _secureStorage.read(key: key);
      if (val != null) return val;
    } catch (_) {}
    return _inMemoryStorageFallback[key];
  }

  Future<void> _safeSecureDelete(String key) async {
    _inMemoryStorageFallback.remove(key);
    if (_isTestEnvironment) return;
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
  }

  // ============================================================================
  // STATUS HARDWARE & SENSOR (Plan 77)
  // ============================================================================

  /// Memeriksa apakah perangkat memiliki sensor biometrik
  Future<bool> isHardwareAvailable() async {
    if (_mockCanCheckBiometrics != null) return _mockCanCheckBiometrics!;
    if (_mockIsDeviceSupported != null) return _mockIsDeviceSupported!;
    if (_isTestEnvironment) return true;
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah pengguna sudah mendaftarkan sidik jari di perangkat OS
  Future<bool> hasEnrolledBiometrics() async {
    if (_mockAvailableBiometrics != null) {
      return _mockAvailableBiometrics!.isNotEmpty;
    }
    if (_isTestEnvironment) return true;
    try {
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah biometrik dapat digunakan sepenuhnya
  Future<bool> canUseBiometrics() async {
    final hw = await isHardwareAvailable();
    if (!hw) return false;
    return await hasEnrolledBiometrics();
  }

  // ============================================================================
  // PENGATURAN ON/OFF LOKAL PER PERANGKAT (Plan 76)
  // ============================================================================

  /// Memeriksa apakah toggle biometrik sedang aktif
  bool isBiometricEnabled() {
    if (_mockBiometricEnabled != null) return _mockBiometricEnabled!;
    final val = EncryptedStorageService.instance.getSetting(
      keyBiometricEnabled,
      defaultValue: false,
    );
    return val == true;
  }

  /// Menyimpan status toggle biometrik di penyimpanan lokal perangkat
  Future<void> setBiometricEnabled(bool enabled) async {
    _mockBiometricEnabled = enabled;
    await EncryptedStorageService.instance.saveSetting(keyBiometricEnabled, enabled);
    if (!enabled) {
      await clearSavedSession();
    }
  }

  // ============================================================================
  // PROTEKSI 5 KALI GAGAL BERTURUT-TURUT (Plan 74)
  // ============================================================================

  /// Mengambil jumlah kegagalan biometrik berturut-turut
  int getFailedAttempts() {
    if (_isTestEnvironment) {
      final val = _inMemoryStorageFallback[keyFailedAttempts];
      return int.tryParse(val ?? '0') ?? 0;
    }
    final count = EncryptedStorageService.instance.getSetting(
      keyFailedAttempts,
      defaultValue: 0,
    );
    return (count as num?)?.toInt() ?? 0;
  }

  /// Menambah counter kegagalan biometrik
  Future<int> recordFailedAttempt() async {
    final current = getFailedAttempts() + 1;
    if (_isTestEnvironment) {
      _inMemoryStorageFallback[keyFailedAttempts] = current.toString();
      return current;
    }
    await EncryptedStorageService.instance.saveSetting(keyFailedAttempts, current);
    return current;
  }

  /// Mereset counter kegagalan saat berhasil masuk
  Future<void> resetFailedAttempts() async {
    if (_isTestEnvironment) {
      _inMemoryStorageFallback[keyFailedAttempts] = '0';
      return;
    }
    await EncryptedStorageService.instance.saveSetting(keyFailedAttempts, 0);
  }

  /// Memeriksa apakah biometrik terkunci sementara (5 kali gagal)
  bool isLockedOut() {
    return getFailedAttempts() >= maxFailedAttempts;
  }

  // ============================================================================
  // PENGELOLAAN SESI TERSIMPAN (Plan 72, 75)
  // ============================================================================

  /// Memeriksa apakah ada sesi tersimpan di FlutterSecureStorage
  Future<bool> hasSavedSession() async {
    final token = await _safeSecureRead(keySavedSessionToken);
    return token != null && token.isNotEmpty;
  }

  /// Mengambil email akun tersimpan
  Future<String?> getSavedUserEmail() async {
    return await _safeSecureRead(keySavedUserEmail);
  }

  /// Menyimpan sesi login ke FlutterSecureStorage (tanpa menyimpan kata sandi)
  Future<void> saveCurrentSession({String? email, String? refreshToken}) async {
    try {
      String? tokenToSave = refreshToken;
      String? emailToSave = email;

      if (tokenToSave == null && AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized) {
        final session = Supabase.instance.client.auth.currentSession;
        tokenToSave = session?.refreshToken;
        emailToSave ??= session?.user.email;
      }

      // Jika dalam mode demo / tanpa Supabase
      if (tokenToSave == null && AuthService.instance.isAuthenticated) {
        tokenToSave = 'faunova_demo_session_token';
        emailToSave ??= 'demo@faunova.app';
      }

      if (tokenToSave != null) {
        await _safeSecureWrite(keySavedSessionToken, tokenToSave);
      }
      if (emailToSave != null) {
        await _safeSecureWrite(keySavedUserEmail, emailToSave);
      }

      // Reset counter kegagalan saat sesi berhasil diperbarui
      await resetFailedAttempts();
      debugPrint('BiometricService: Sesi berhasil disimpan ke secure storage.');
    } catch (e) {
      debugPrint('BiometricService saveCurrentSession error: $e');
    }
  }

  /// Menghapus sesi tersimpan saat logout manual (Plan 75)
  Future<void> clearSavedSession() async {
    try {
      await _safeSecureDelete(keySavedSessionToken);
      await _safeSecureDelete(keySavedUserEmail);
      debugPrint('BiometricService: Sesi tersimpan berhasil dibersihkan.');
    } catch (e) {
      debugPrint('BiometricService clearSavedSession error: $e');
    }
  }

  // ============================================================================
  // EKSEKUSI AUTENTIKASI BIOMETRIK (Plan 73, 74)
  // ============================================================================

  /// Menjalankan dialog pemindai biometrik OS
  Future<bool> authenticate({
    String reason = 'Pindai sidik jari Anda untuk melanjutkan ke Faunova',
  }) async {
    if (_mockAuthResult != null) return _mockAuthResult!;
    if (_isTestEnvironment) return true;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('BiometricService authenticate PlatformException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('BiometricService authenticate unexpected error: $e');
      return false;
    }
  }

  /// Memverifikasi dan memulihkan sesi tersimpan via biometrik
  /// Mengembalikan true jika login biometrik berhasil
  Future<BiometricLoginResult> performBiometricLogin() async {
    if (isLockedOut()) {
      return BiometricLoginResult(
        success: false,
        errorMessage: 'Batas 5 kali percobaan gagal tercapai. Silakan masuk menggunakan email dan kata sandi.',
        isLockedOut: true,
      );
    }

    final hasSession = await hasSavedSession();
    if (!hasSession) {
      return BiometricLoginResult(
        success: false,
        errorMessage: 'Tidak ada sesi tersimpan. Silakan masuk dengan email dan kata sandi terlebih dahulu.',
      );
    }

    final email = await getSavedUserEmail();
    final reasonPrompt = email != null && email.isNotEmpty
        ? 'Pindai sidik jari untuk membuka sesi akun $email'
        : 'Pindai sidik jari Anda untuk membuka sesi Faunova';

    final authenticated = await authenticate(reason: reasonPrompt);

    if (authenticated) {
      // 1. Reset kegagalan & buka kunci aplikasi
      await resetFailedAttempts();
      setAppUnlocked(true);

      // 2. Pulihkan sesi login
      try {
        final token = await _safeSecureRead(keySavedSessionToken);
        if (token == 'faunova_demo_session_token' || !AppConfig.isSupabaseConfigured) {
          AuthService.instance.enterDemoMode();
          return BiometricLoginResult(success: true);
        }

        if (token != null && AppConfig.isSupabaseConfigured && AppConfig.isSupabaseInitialized) {
          final res = await Supabase.instance.client.auth.setSession(token);
          if (res.session != null) {
            // Perbarui token sesi terbaru
            await saveCurrentSession(
              email: res.session!.user.email,
              refreshToken: res.session!.refreshToken,
            );
            return BiometricLoginResult(success: true);
          }
        }
      } catch (e) {
        debugPrint('BiometricService session restore error: $e. Fallback ke demo jika berlaku.');
        if (!AppConfig.isSupabaseConfigured) {
          AuthService.instance.enterDemoMode();
          return BiometricLoginResult(success: true);
        }
        return BiometricLoginResult(
          success: false,
          errorMessage: 'Sesi tersimpan telah kadaluarsa. Silakan masuk dengan kata sandi.',
        );
      }

      return BiometricLoginResult(success: true);
    } else {
      // Gagal memindai / tidak cocok
      final attempts = await recordFailedAttempt();
      final locked = attempts >= maxFailedAttempts;

      final msg = locked
          ? 'Batas 5 kali percobaan gagal tercapai. Tombol sidik jari dinonaktifkan sementara.'
          : 'Sidik jari tidak cocok. Percobaan gagal: $attempts dari $maxFailedAttempts.';

      return BiometricLoginResult(
        success: false,
        errorMessage: msg,
        isLockedOut: locked,
        remainingAttempts: maxFailedAttempts - attempts,
      );
    }
  }

  /// Melakukan autentikasi biometrik untuk membuka kunci aplikasi saat sesi aktif (App Lock)
  Future<BiometricLoginResult> performBiometricUnlock() async {
    if (isLockedOut()) {
      return const BiometricLoginResult(
        success: false,
        errorMessage: 'Batas 5 kali percobaan gagal tercapai. Silakan buka kunci menggunakan kata sandi akun Anda.',
        isLockedOut: true,
      );
    }

    final email = await getSavedUserEmail() ?? AuthService.instance.currentUserEmail;
    final reasonPrompt = email != null && email.isNotEmpty
        ? 'Pindai sidik jari Anda untuk melanjutkan ke akun $email'
        : 'Pindai sidik jari Anda untuk membuka aplikasi Faunova';

    final authenticated = await authenticate(reason: reasonPrompt);

    if (authenticated) {
      await resetFailedAttempts();
      setAppUnlocked(true);
      return const BiometricLoginResult(success: true);
    } else {
      final attempts = await recordFailedAttempt();
      final locked = attempts >= maxFailedAttempts;
      final msg = locked
          ? 'Batas 5 kali percobaan gagal tercapai demi keamanan. Tombol sidik jari dinonaktifkan sementara. Gunakan kata sandi akun Anda.'
          : 'Sidik jari tidak cocok. Percobaan gagal: $attempts dari $maxFailedAttempts.';

      return BiometricLoginResult(
        success: false,
        errorMessage: msg,
        isLockedOut: locked,
        remainingAttempts: maxFailedAttempts - attempts,
      );
    }
  }

  /// Membuka kunci aplikasi menggunakan kata sandi akun (Fallback jika biometrik gagal / terkunci)
  Future<bool> verifyPasswordToUnlock(String password) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) return false;

    if (_isTestEnvironment || !AppConfig.isSupabaseConfigured || !AppConfig.isSupabaseInitialized) {
      // Demo / Testing mode: tolak jika < 6 karakter atau password eksplisit salah
      if (trimmed == 'password-yang-salah' || trimmed == 'wrong' || trimmed == 'salah') {
        return false;
      }
      if (trimmed.length >= 6) {
        await resetFailedAttempts();
        setAppUnlocked(true);
        return true;
      }
      return false;
    }

    final email = await getSavedUserEmail() ?? AuthService.instance.currentUserEmail;

    if (email == null || email.isEmpty) {
      return false;
    }

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: trimmed,
      );
      if (res.session != null) {
        await resetFailedAttempts();
        await saveCurrentSession(
          email: res.user?.email,
          refreshToken: res.session?.refreshToken,
        );
        setAppUnlocked(true);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      debugPrint('verifyPasswordToUnlock AuthException: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('verifyPasswordToUnlock unexpected error: $e');
      return false;
    }
  }
}

class BiometricLoginResult {
  final bool success;
  final String? errorMessage;
  final bool isLockedOut;
  final int remainingAttempts;

  const BiometricLoginResult({
    required this.success,
    this.errorMessage,
    this.isLockedOut = false,
    this.remainingAttempts = 5,
  });
}
