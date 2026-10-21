// ==============================================================================
// FAUNOVA SERVICE: CurrencyService
// Konversi kurs mata uang (IDR, USD, JPY) dengan cache Hive terenkripsi
// Sesuai Plan 78, 127, 398, 418, 562 & AGENTS.md (Sesi S12)
// ==============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'encrypted_storage_service.dart';

class CurrencyService {
  static final CurrencyService instance = CurrencyService._internal();
  CurrencyService._internal();

  /// Harga patokan langganan Centang Biru per 30 hari (Rp15.000 integer IDR, Plan 418 & 562)
  static const int blueBadgePriceIdr = 15000;

  /// Default rates fallback (1 IDR = x USD / JPY) jika offline & cache kosong
  static const double defaultIdrToUsd = 0.000062; // ~Rp16.129 / USD
  static const double defaultIdrToJpy = 0.0095;   // ~Rp105 / JPY

  Map<String, double> _rates = {
    'IDR': 1.0,
    'USD': defaultIdrToUsd,
    'JPY': defaultIdrToJpy,
  };

  DateTime? _lastUpdatedAt;
  bool _isUsingCachedRates = false;
  bool _isInitialized = false;

  Map<String, double> get rates => Map.unmodifiable(_rates);
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  bool get isUsingCachedRates => _isUsingCachedRates;
  List<String> get availableCurrencies => const ['IDR', 'USD', 'JPY'];

  /// Inisialisasi awal membaca cache Hive terenkripsi
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final cached = EncryptedStorageService.instance.getCurrencyRates();
      if (cached != null) {
        final cachedRatesRaw = cached['rates'] as Map?;
        if (cachedRatesRaw != null) {
          _rates = cachedRatesRaw.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          );
          _rates['IDR'] = 1.0;
        }
        final lastUpdatedStr = cached['last_updated_at'] as String?;
        if (lastUpdatedStr != null) {
          _lastUpdatedAt = DateTime.tryParse(lastUpdatedStr);
        }
        _isUsingCachedRates = true;
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('CurrencyService init error: $e');
      _isInitialized = true;
    }
  }

  /// Memuat kurs terbaru dari API gratis atau fallback ke cache Hive
  Future<void> fetchRates({bool forceRefresh = false}) async {
    await init();

    // Jika baru saja diperbarui (<1 jam) dan bukan paksa refresh, gunakan cache
    if (!forceRefresh && _lastUpdatedAt != null) {
      final diff = DateTime.now().difference(_lastUpdatedAt!);
      if (diff.inHours < 1) {
        return;
      }
    }

    try {
      final uri = Uri.parse('https://api.exchangerate-api.com/v4/latest/IDR');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final apiRates = data['rates'] as Map<String, dynamic>?;

        if (apiRates != null) {
          final usd = (apiRates['USD'] as num?)?.toDouble() ?? defaultIdrToUsd;
          final jpy = (apiRates['JPY'] as num?)?.toDouble() ?? defaultIdrToJpy;

          _rates = {
            'IDR': 1.0,
            'USD': usd,
            'JPY': jpy,
          };
          _lastUpdatedAt = DateTime.now();
          _isUsingCachedRates = false;

          // Simpan ke Hive terenkripsi
          await EncryptedStorageService.instance.saveCurrencyRates(
            rates: _rates,
            lastUpdatedAt: _lastUpdatedAt!,
            baseCurrency: 'IDR',
          );

          debugPrint('CurrencyService: Kurs berhasil diperbarui dari API online.');
          return;
        }
      }
      throw Exception('Format respons API tidak valid: ${response.statusCode}');
    } catch (e) {
      debugPrint('CurrencyService fetchRates offline / error: $e. Menggunakan cache Hive.');
      _isUsingCachedRates = true;

      // Pastikan jika cache lokal belum ada, fallback default tetap aktif
      if (_rates['USD'] == null || _rates['USD']! <= 0) {
        _rates['USD'] = defaultIdrToUsd;
      }
      if (_rates['JPY'] == null || _rates['JPY']! <= 0) {
        _rates['JPY'] = defaultIdrToJpy;
      }
      _lastUpdatedAt ??= DateTime.now();
    }
  }

  /// Konversi nominal IDR ke mata uang target
  double convertFromIdr(int amountIdr, String targetCurrency) {
    final currency = targetCurrency.toUpperCase();
    if (currency == 'IDR') return amountIdr.toDouble();

    final rate = _rates[currency];
    if (rate == null || rate <= 0) {
      if (currency == 'USD') return amountIdr * defaultIdrToUsd;
      if (currency == 'JPY') return amountIdr * defaultIdrToJpy;
      return amountIdr.toDouble();
    }

    return amountIdr * rate;
  }

  /// Format harga lengkap untuk tampilan UI (Plan 127 & 418)
  String formatPrice(int amountIdr, String currency) {
    final code = currency.toUpperCase();
    final converted = convertFromIdr(amountIdr, code);

    switch (code) {
      case 'IDR':
        final str = amountIdr.toString();
        final buffer = StringBuffer();
        int count = 0;
        for (int i = str.length - 1; i >= 0; i--) {
          buffer.write(str[i]);
          count++;
          if (count % 3 == 0 && i != 0) {
            buffer.write('.');
          }
        }
        return 'Rp${buffer.toString().split('').reversed.join('')}';

      case 'USD':
        return '\$${converted.toStringAsFixed(2)} USD';

      case 'JPY':
        return '¥${converted.round()} JPY';

      default:
        return '$amountIdr $code';
    }
  }

  /// String waktu pembaruan kurs dalam bahasa Indonesia
  String getLastUpdatedLabel() {
    if (_lastUpdatedAt == null) return 'Default Estimasi';
    final dt = _lastUpdatedAt!;
    final day = dt.day.toString().padLeft(2, '0');
    final mon = dt.month.toString().padLeft(2, '0');
    final yr = dt.year;
    final hr = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$mon/$yr $hr:$min';
  }

  @visibleForTesting
  void setMockRates({required double usd, required double jpy, DateTime? time}) {
    _rates = {
      'IDR': 1.0,
      'USD': usd,
      'JPY': jpy,
    };
    _lastUpdatedAt = time ?? DateTime.now();
    _isUsingCachedRates = false;
  }
}
