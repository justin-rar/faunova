import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ProcessedImageResult {
  final Uint8List cleanBytes;
  final String base64String;
  final String sha256Hash;
  final int width;
  final int height;

  const ProcessedImageResult({
    required this.cleanBytes,
    required this.base64String,
    required this.sha256Hash,
    required this.width,
    required this.height,
  });
}

class ImageProcessingService {
  const ImageProcessingService._();

  /// Mengompresi foto dan membuang metadata EXIF di sisi klien
  /// sesuai Plan 5.2 & AGENTS.md.
  /// Standar: Max dimensi 1280px, kualitas JPEG 85, EXIF sepenuhnya dibuang.
  static Future<ProcessedImageResult> processCameraImage(
    Uint8List rawBytes, {
    int maxDimension = 1280,
    int quality = 85,
  }) async {
    return compute(_processImageTask, {
      'rawBytes': rawBytes,
      'maxDimension': maxDimension,
      'quality': quality,
    });
  }

  static ProcessedImageResult _processImageTask(Map<String, dynamic> params) {
    final rawBytes = params['rawBytes'] as Uint8List;
    final maxDimension = params['maxDimension'] as int;
    final quality = params['quality'] as int;

    // 1. Decode gambar dari raw bytes
    img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw Exception('Format gambar tidak dapat dibaca atau rusak.');
    }

    // 2. Normalisasi orientasi jika ada rotasi EXIF awal
    decoded = img.bakeOrientation(decoded);

    // 3. Resize jika dimensi melebihi batas maxDimension
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      if (decoded.width >= decoded.height) {
        decoded = img.copyResize(decoded, width: maxDimension);
      } else {
        decoded = img.copyResize(decoded, height: maxDimension);
      }
    }

    // 4. Encode ke JPEG bersih tanpa EXIF (encoder img.encodeJpg hanya menulis standard JFIF)
    final cleanBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));

    // 5. Hitung SHA-256 dari byte bersih yang akan dikirim ke server
    final digest = sha256.convert(cleanBytes);
    final sha256Hash = digest.toString();

    // 6. Konversi ke Base64 untuk payload JSON
    final base64String = base64Encode(cleanBytes);

    return ProcessedImageResult(
      cleanBytes: cleanBytes,
      base64String: base64String,
      sha256Hash: sha256Hash,
      width: decoded.width,
      height: decoded.height,
    );
  }
}
