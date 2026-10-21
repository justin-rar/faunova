// ==============================================================================
// FAUNOVA SERVICE: CaptureService
// Layanan penyimpanan tangkapan satwa dan verifikasi rantai kanonis SHA-256
// Sesuai Plan 5.2, 5.3 & AGENTS.md (Sesi S7)
// ==============================================================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../features/camera/models/capture_model.dart';
import '../../features/camera/models/chain_verification_result.dart';

class CaptureException implements Exception {
  final String message;
  final String code;

  const CaptureException(this.message, {this.code = 'CAPTURE_ERROR'});

  @override
  String toString() => message;
}

class CaptureService {
  static final CaptureService instance = CaptureService._internal();
  CaptureService._internal();

  // Cache lokal demo rantai koleksi
  final List<CaptureModel> _demoCaptures = [];

  /// Fungsi kanonisasi string sesuai fungsi database `public.faunova_canonical_encode`
  /// Format: seq|previous_hash|photo_sha256|latitude|longitude|camera_heading|received_at|user_id
  static String canonicalEncode({
    required int seq,
    required String previousHash,
    required String photoSha256,
    double? latitude,
    double? longitude,
    double? cameraHeading,
    required DateTime receivedAt,
    required String userId,
  }) {
    final latStr = latitude == null ? 'NULL' : latitude.toStringAsFixed(6);
    final lngStr = longitude == null ? 'NULL' : longitude.toStringAsFixed(6);
    final headingStr = cameraHeading == null ? 'NULL' : cameraHeading.toStringAsFixed(2);
    
    // ISO-8601 UTC dengan microsecond sesuai PostgreSQL to_char
    final utc = receivedAt.toUtc();
    final year = utc.year.toString().padLeft(4, '0');
    final month = utc.month.toString().padLeft(2, '0');
    final day = utc.day.toString().padLeft(2, '0');
    final hour = utc.hour.toString().padLeft(2, '0');
    final minute = utc.minute.toString().padLeft(2, '0');
    final second = utc.second.toString().padLeft(2, '0');
    final micro = (utc.millisecond * 1000 + utc.microsecond).toString().padLeft(6, '0');
    final receivedStr = '$year-$month-${day}T$hour:$minute:$second.${micro}Z';

    return '$seq|$previousHash|$photoSha256|$latStr|$lngStr|$headingStr|$receivedStr|$userId';
  }

  /// Menghitung SHA-256 block hash dari format kanonis
  static String calculateBlockHash({
    required int seq,
    required String previousHash,
    required String photoSha256,
    double? latitude,
    double? longitude,
    double? cameraHeading,
    required DateTime receivedAt,
    required String userId,
  }) {
    final raw = canonicalEncode(
      seq: seq,
      previousHash: previousHash,
      photoSha256: photoSha256,
      latitude: latitude,
      longitude: longitude,
      cameraHeading: cameraHeading,
      receivedAt: receivedAt,
      userId: userId,
    );
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Menghitung Genesis Previous Hash (SHA-256 dari userId)
  static String calculateGenesisHash(String userId) {
    return sha256.convert(utf8.encode(userId)).toString();
  }

  SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? _getCurrentUserId() {
    try {
      return Supabase.instance.client.auth.currentSession?.user.id;
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan hasil pemindaian satwa ke koleksi melalui RPC atomik `save_capture_with_chain`
  Future<CaptureModel> saveCapture({
    required String scanId,
    String? photoPath,
    String? customDescription,
    // Parameter bantuan untuk mode demo/offline
    String? demoSpeciesName,
    String? demoCategory,
    String? demoPhotoSha256,
    double? demoLatitude,
    double? demoLongitude,
    double? demoHeading,
  }) async {
    final client = _getSupabaseClient();
    final userId = _getCurrentUserId();

    // Mode demo / offline tanpa koneksi aktif Supabase
    if (AppConfig.isDemoMode || client == null || userId == null) {
      return _saveDemoCapture(
        scanId: scanId,
        photoPath: photoPath,
        customDescription: customDescription,
        speciesName: demoSpeciesName,
        category: demoCategory,
        photoSha256: demoPhotoSha256,
        latitude: demoLatitude,
        longitude: demoLongitude,
        heading: demoHeading,
      );
    }

    try {
      final response = await client.rpc(
        'save_capture_with_chain',
        params: {
          'p_scan_id': scanId,
          'p_photo_path': photoPath,
          'p_custom_desc': customDescription,
        },
      );

      if (response == null || (response is List && response.isEmpty)) {
        throw const CaptureException('Gagal menyimpan tangkapan: respons server kosong.');
      }

      final Map<String, dynamic> row = response is List
          ? Map<String, dynamic>.from(response.first as Map)
          : Map<String, dynamic>.from(response as Map);

      return CaptureModel.fromJson({
        'id': row['capture_id'],
        'scan_id': scanId,
        'user_id': userId,
        'photo_object_path': photoPath ?? '',
        'species_name': row['species_name'] ?? 'Satwa Terverifikasi',
        'category': row['category'],
        'description': customDescription ?? '',
        'seq': row['seq'],
        'previous_hash': row['previous_hash'],
        'block_hash': row['block_hash'],
        'photo_sha256': row['photo_sha256'],
        'created_at': row['created_at'],
        'received_at': row['created_at'],
      });
    } on PostgrestException catch (e) {
      debugPrint('CaptureService PostgrestException: ${e.message} (${e.code})');
      if (e.code == '23505') {
        throw const CaptureException(
          'Hasil scan ini sudah pernah Anda simpan ke koleksi sebelumnya.',
          code: 'ALREADY_SAVED',
        );
      } else if (e.code == '22023') {
        throw const CaptureException(
          'Hanya hasil scan satwa nyata yang dapat disimpan ke koleksi (Plan 5.3).',
          code: 'NOT_ANIMAL',
        );
      } else if (e.code == '42501') {
        throw const CaptureException(
          'Akses ditolak: Anda bukan pemilik hasil scan ini.',
          code: 'FORBIDDEN',
        );
      }
      throw CaptureException(e.message, code: e.code ?? 'DATABASE_ERROR');
    } catch (e) {
      if (e is CaptureException) rethrow;
      debugPrint('CaptureService error tak terduga: $e');
      throw CaptureException('Gagal menyimpan ke koleksi: ${e.toString()}');
    }
  }

  /// Memverifikasi seluruh rantai integritas koleksi milik user (RPC `verify_chain`)
  Future<ChainVerificationResult> verifyUserChain([String? targetUserId]) async {
    final client = _getSupabaseClient();
    final currentUserId = targetUserId ?? _getCurrentUserId();

    if (AppConfig.isDemoMode || client == null || currentUserId == null) {
      return _verifyDemoChain();
    }

    try {
      final response = await client.rpc(
        'verify_chain',
        params: {'p_user_id': currentUserId},
      );

      if (response == null || (response is List && response.isEmpty)) {
        return const ChainVerificationResult(
          isValid: true,
          totalBlocks: 0,
          message: 'Koleksi masih kosong. Belum ada blok rantai yang tercatat.',
        );
      }

      final row = response is List
          ? Map<String, dynamic>.from(response.first as Map)
          : Map<String, dynamic>.from(response as Map);

      return ChainVerificationResult.fromJson(row);
    } catch (e) {
      debugPrint('verifyUserChain error: $e');
      return ChainVerificationResult(
        isValid: false,
        totalBlocks: 0,
        message: 'Gagal menghubungi server verifikasi rantai: $e',
      );
    }
  }

  /// Memverifikasi satu blok spesifik terhadap blok sebelumnya (RPC `verify_block`)
  Future<ChainVerificationResult> verifyBlock(String captureId) async {
    final client = _getSupabaseClient();
    if (AppConfig.isDemoMode || client == null) {
      return const ChainVerificationResult(
        isValid: true,
        totalBlocks: 1,
        message: 'Blok demo sah dan terverifikasi.',
      );
    }

    try {
      final response = await client.rpc(
        'verify_block',
        params: {'p_capture_id': captureId},
      );

      if (response == null || (response is List && response.isEmpty)) {
        return const ChainVerificationResult(
          isValid: false,
          totalBlocks: 0,
          message: 'Tangkapan tidak ditemukan.',
        );
      }

      final row = response is List
          ? Map<String, dynamic>.from(response.first as Map)
          : Map<String, dynamic>.from(response as Map);

      return ChainVerificationResult.fromJson(row);
    } catch (e) {
      debugPrint('verifyBlock error: $e');
      return ChainVerificationResult(
        isValid: false,
        totalBlocks: 0,
        message: 'Gagal memverifikasi blok: $e',
      );
    }
  }

  /// Generator demo capture untuk pengujian luring/offline
  CaptureModel _saveDemoCapture({
    required String scanId,
    String? photoPath,
    String? customDescription,
    String? speciesName,
    String? category,
    String? photoSha256,
    double? latitude,
    double? longitude,
    double? heading,
  }) {
    const demoUserId = '00000000-0000-0000-0000-000000000001';
    final now = DateTime.now();

    final int nextSeq = _demoCaptures.length + 1;
    final String prevHash = _demoCaptures.isEmpty
        ? calculateGenesisHash(demoUserId)
        : _demoCaptures.last.blockHash;

    final actualSha256 = photoSha256 ?? 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

    final blockHash = calculateBlockHash(
      seq: nextSeq,
      previousHash: prevHash,
      photoSha256: actualSha256,
      latitude: latitude ?? -6.2088,
      longitude: longitude ?? 106.8456,
      cameraHeading: heading ?? 148.0,
      receivedAt: now,
      userId: demoUserId,
    );

    final capture = CaptureModel(
      id: 'demo-capture-$nextSeq',
      scanId: scanId,
      userId: demoUserId,
      photoObjectPath: photoPath ?? 'captures/demo/$scanId.jpg',
      speciesName: speciesName ?? 'Kupu-kupu Jeruk (Demo)',
      category: category ?? 'Papilio demoleus',
      description: customDescription ?? 'Koleksi lapangan tersimpan di rantai hash kanonis.',
      latitude: latitude ?? -6.2088,
      longitude: longitude ?? 106.8456,
      cameraHeading: heading ?? 148.0,
      receivedAt: now,
      seq: nextSeq,
      previousHash: prevHash,
      blockHash: blockHash,
      photoSha256: actualSha256,
      createdAt: now,
    );

    _demoCaptures.add(capture);
    return capture;
  }

  ChainVerificationResult _verifyDemoChain() {
    if (_demoCaptures.isEmpty) {
      return const ChainVerificationResult(
        isValid: true,
        totalBlocks: 0,
        message: 'Koleksi masih kosong. Belum ada blok rantai yang tersimpan.',
      );
    }

    const demoUserId = '00000000-0000-0000-0000-000000000001';
    String expectedPrev = calculateGenesisHash(demoUserId);

    for (int i = 0; i < _demoCaptures.length; i++) {
      final item = _demoCaptures[i];
      final expectedSeq = i + 1;

      if (item.seq != expectedSeq) {
        return ChainVerificationResult(
          isValid: false,
          totalBlocks: _demoCaptures.length,
          brokenSeq: item.seq,
          message: 'Nomor blok terputus pada urutan #$expectedSeq',
        );
      }

      if (item.previousHash != expectedPrev) {
        return ChainVerificationResult(
          isValid: false,
          totalBlocks: _demoCaptures.length,
          brokenSeq: item.seq,
          message: 'Previous hash tidak cocok pada blok #${item.seq}',
        );
      }

      final computedHash = calculateBlockHash(
        seq: item.seq,
        previousHash: item.previousHash,
        photoSha256: item.photoSha256,
        latitude: item.latitude,
        longitude: item.longitude,
        cameraHeading: item.cameraHeading,
        receivedAt: item.receivedAt,
        userId: item.userId,
      );

      if (computedHash != item.blockHash) {
        return ChainVerificationResult(
          isValid: false,
          totalBlocks: _demoCaptures.length,
          brokenSeq: item.seq,
          message: 'Manipulasi data terdeteksi pada blok #${item.seq}',
        );
      }

      expectedPrev = item.blockHash;
    }

    return ChainVerificationResult(
      isValid: true,
      totalBlocks: _demoCaptures.length,
      message: 'Rantai hash SHA-256 kanonis utuh dan terverifikasi (${_demoCaptures.length} blok).',
    );
  }
}
