import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../../features/camera/models/scan_result_model.dart';

class ScanException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  const ScanException(this.message, {this.code = 'SCAN_ERROR', this.statusCode});

  @override
  String toString() => message;
}

class ScanQuotaExceededException extends ScanException {
  const ScanQuotaExceededException([super.message = 'Batas kuota 20 scan harian telah tercapai. Reset pk 00:00 WIB.'])
      : super(code: 'QUOTA_EXCEEDED', statusCode: 429);
}

class ScanAuthException extends ScanException {
  const ScanAuthException([super.message = 'Autentikasi diperlukan untuk melakukan pemindaian AI.'])
      : super(code: 'AUTH_REQUIRED', statusCode: 401);
}

class ScanService {
  static final ScanService instance = ScanService._internal();
  ScanService._internal();

  final _uuid = const Uuid();

  /// Mengirim foto satwa ke Edge Function `ai-gateway` (mode: scan)
  Future<ScanResultModel> scanAnimal({
    required String imageBase64,
    required String photoSha256,
    double? latitude,
    double? longitude,
    double? heading,
    bool? isMock,
    String? localPhotoPath,
  }) async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final accessToken = session?.accessToken;

    final requestId = _uuid.v4();

    // Jika berjalan dalam mode offline / demo tanpa kredensial Supabase
    if (AppConfig.isDemoMode || accessToken == null) {
      if (accessToken == null && !AppConfig.isDemoMode) {
        throw const ScanAuthException('Sesi masuk tidak ditemukan. Silakan login terlebih dahulu.');
      }
      return _generateDemoScanResult(
        requestId: requestId,
        photoSha256: photoSha256,
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        isMock: isMock,
        localPhotoPath: localPhotoPath,
        imageBase64: imageBase64,
      );
    }

    final endpoint = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/ai-gateway');

    final payload = {
      'mode': 'scan',
      'requestId': requestId,
      'imageBase64': imageBase64,
      'mimeType': 'image/jpeg',
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'isMock': isMock,
    };

    try {
      final response = await http.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'apikey': AppConfig.supabaseAnonKey,
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw const ScanException(
            'Identifikasi AI membutuhkan waktu lebih dari 45 detik. Silakan coba bidik kembali.',
            code: 'TIMEOUT',
            statusCode: 504,
          );
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ScanResultModel.fromJson(
          responseData,
          requestId: requestId,
          latitude: latitude,
          longitude: longitude,
          cameraHeading: heading,
          isMock: isMock,
          localPhotoPath: localPhotoPath,
          imageBase64: imageBase64,
        );
      } else if (response.statusCode == 429) {
        throw ScanQuotaExceededException(
          responseData['message']?.toString() ??
              'Batas kuota 20 scan harian Anda telah tercapai.',
        );
      } else if (response.statusCode == 401) {
        throw ScanAuthException(
          responseData['message']?.toString() ??
              'Sesi autentikasi telah berakhir. Silakan masuk kembali.',
        );
      } else {
        var errorMsg = responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            'Gagal memproses pemindaian di server (${response.statusCode}).';
        try {
          if (errorMsg.contains('{"error"') || errorMsg.contains('{\n')) {
            final start = errorMsg.indexOf('{');
            final parsedInner = jsonDecode(errorMsg.substring(start));
            if (parsedInner['error']?['message'] != null) {
              errorMsg = 'Layanan AI: ${parsedInner['error']['message']}';
            } else if (parsedInner['message'] != null) {
              errorMsg = parsedInner['message'];
            }
          }
        } catch (_) {}
        throw ScanException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ScanException) rethrow;
      debugPrint('ScanService network error: $e');
      throw ScanException(
        'Sambungan ke server AI gagal: Periksa koneksi internet Anda.',
      );
    }
  }

  /// Generator hasil simulasi demo untuk pengujian tanpa server
  ScanResultModel _generateDemoScanResult({
    required String requestId,
    required String photoSha256,
    double? latitude,
    double? longitude,
    double? heading,
    bool? isMock,
    String? localPhotoPath,
    String? imageBase64,
  }) {
    return ScanResultModel(
      scanId: 'demo-scan-${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      status: 'completed',
      isAnimal: true,
      name: 'Kupu-kupu Jeruk (Demo)',
      categoryOrSpecies: 'Papilio demoleus',
      description:
          'Kupu-kupu dengan bentang sayap bercorak kuning dan hitam yang anggun. Sering dijumpai di perkebunan jeruk dan vegetasi tropis Indonesia.',
      additionalFact:
          'Larva kupu-kupu ini memiliki organ khusus bernama osmeterium yang mengeluarkan bau menyengat untuk mengusir predator.',
      photoSha256: photoSha256,
      latitude: latitude ?? -6.2088,
      longitude: longitude ?? 106.8456,
      cameraHeading: heading ?? 148.0,
      isMock: isMock ?? false,
      quotaUsed: 1,
      quotaMax: 20,
      receivedAt: DateTime.now(),
      localPhotoPath: localPhotoPath,
      imageBase64: imageBase64,
      aiProvider: 'Google Gemini Flash',
    );
  }
}
