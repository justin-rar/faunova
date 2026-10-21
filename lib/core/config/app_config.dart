import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi aplikasi dan Supabase Client.
/// Menangani pembacaan kredensial dari environment (--dart-define) secara aman
/// dan memastikan aplikasi tidak crash jika kredensial belum diisi pada sesi S1.
class AppConfig {
  AppConfig._();

  /// URL Supabase didapatkan dari compile-time define atau default proyek
  static String get supabaseUrl {
    const envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty && !envUrl.contains('your-project-ref')) {
      return envUrl;
    }
    return 'https://yziubaqkrhxtneaybllq.supabase.co';
  }

  /// Anon/Publishable Key publik Supabase (bukan service_role!)
  static String get supabaseAnonKey {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (envKey.isNotEmpty && !envKey.contains('your-anon-public-key')) {
      return envKey;
    }
    return 'sb_publishable_SMrLYOz4hBporvJSyQrELg_jpHMaFuL';
  }

  /// Client Key publik Midtrans Sandbox (aman ditaruh di klien, bukan server key!)
  static String get midtransClientKey {
    const envKey = String.fromEnvironment('MIDTRANS_CLIENT_KEY', defaultValue: '');
    if (envKey.isNotEmpty && !envKey.contains('your-midtrans-client-key')) {
      return envKey;
    }
    return 'Mid-client-7POOnG-_USHPaef3';
  }

  static bool _isSupabaseInitialized = false;
  static bool get isSupabaseInitialized {
    if (_isSupabaseInitialized) return true;
    try {
      // Periksa apakah Supabase.instance sudah terinisialisasi
      final _ = Supabase.instance.client;
      _isSupabaseInitialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah aplikasi berjalan dalam mode demo
  static bool get isDemoMode => !isSupabaseConfigured;

  /// Memeriksa apakah kredensial Supabase sudah diisi dengan benar
  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('your-project-ref') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('your-anon-public-key');
  }

  /// Inisialisasi Supabase secara aman.
  static Future<void> initializeSupabase() async {
    if (!isSupabaseConfigured) {
      developer.log(
        'Supabase belum dikonfigurasi.',
        name: 'FaunovaConfig',
      );
      _isSupabaseInitialized = false;
      return;
    }

    try {
      try {
        final _ = Supabase.instance.client;
        _isSupabaseInitialized = true;
      } catch (_) {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
        );
        _isSupabaseInitialized = true;
      }
      developer.log('Supabase berhasil diinisialisasi.', name: 'FaunovaConfig');
    } catch (e, stack) {
      developer.log(
        'Gagal menginisialisasi Supabase: $e',
        name: 'FaunovaConfig',
        error: e,
        stackTrace: stack,
      );
      _isSupabaseInitialized = false;
    }
  }

  /// Instance SupabaseClient jika sudah diinisialisasi
  static SupabaseClient? get supabaseClient {
    if (_isSupabaseInitialized) {
      return Supabase.instance.client;
    }
    return null;
  }
}
