import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi aplikasi dan Supabase Client.
/// Menangani pembacaan kredensial dari environment (--dart-define) secara aman
/// dan memastikan aplikasi tidak crash jika kredensial belum diisi pada sesi S1.
class AppConfig {
  AppConfig._();

  /// URL Supabase didapatkan dari compile-time define
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Anon Key publik Supabase (bukan service_role!)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool _isSupabaseInitialized = false;
  static bool get isSupabaseInitialized => _isSupabaseInitialized;

  /// Memeriksa apakah kredensial Supabase sudah diisi dengan benar
  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('your-project-ref') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('your-anon-public-key');
  }

  /// Inisialisasi Supabase secara aman.
  /// Jika kredensial belum ada, lewati inisialisasi tanpa menyebabkan crash pada aplikasi.
  static Future<void> initializeSupabase() async {
    if (!isSupabaseConfigured) {
      developer.log(
        'Supabase belum dikonfigurasi. Menggunakan mode demonstrasi/kerangka S1. '
        'Untuk menghubungkan, jalankan dengan --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
        'atau lengkapi file .env',
        name: 'FaunovaConfig',
      );
      _isSupabaseInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      _isSupabaseInitialized = true;
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
