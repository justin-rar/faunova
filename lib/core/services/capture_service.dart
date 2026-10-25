// ==============================================================================
// FAUNOVA SERVICE: CaptureService
// Layanan penyimpanan tangkapan satwa dan verifikasi rantai kanonis SHA-256
// Sesuai Plan 5.2, 5.3 & AGENTS.md (Sesi S7)
// ==============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../../features/camera/models/capture_model.dart';
import '../../features/camera/models/chain_verification_result.dart';
import 'encrypted_storage_service.dart';

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

  /// Mereset data demo cache untuk isolasi pengujian test runner
  void resetDemoCaptures() {
    _demoCaptures.clear();
  }

  /// Memuat ulang data demo awal 3 satwa terurut untuk demo dan pengujian
  void initMockDemoCaptures() {
    _demoCaptures.clear();
    _initMockDemoCaptures();
    const demoUserId = '00000000-0000-0000-0000-000000000001';
    try {
      EncryptedStorageService.instance.saveUserCaptures(
        demoUserId,
        List<CaptureModel>.from(_demoCaptures.reversed),
      );
    } catch (_) {}
  }

  /// Mengetahui jumlah item koleksi di cache demo
  int get demoCapturesCount => _demoCaptures.length;

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
      final client = Supabase.instance.client;
      return client.auth.currentUser?.id ?? client.auth.currentSession?.user.id;
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

    // Unggah file foto ke Supabase Storage (bucket 'captures') jika file lokal tersedia di perangkat
    String effectivePhotoPath = photoPath ?? '';
    if (photoPath != null && photoPath.isNotEmpty) {
      final localFile = File(photoPath);
      if (localFile.existsSync()) {
        try {
          final fileExt = photoPath.contains('.') ? photoPath.split('.').last : 'jpg';
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final storagePath = '$userId/${scanId}_$timestamp.$fileExt';
          await client.storage.from('captures').upload(
            storagePath,
            localFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
          effectivePhotoPath = 'captures/$storagePath';
        } catch (e) {
          debugPrint('CaptureService: Gagal upload ke Supabase Storage: $e');
          throw CaptureException(
            'Gagal mengunggah foto satwa ke cloud storage ($e). Pastikan koneksi internet stabil.',
            code: 'STORAGE_UPLOAD_ERROR',
          );
        }
      }
    }

    try {
      final response = await client.rpc(
        'save_capture_with_chain',
        params: {
          'p_scan_id': scanId,
          'p_photo_path': effectivePhotoPath,
          'p_custom_desc': customDescription,
        },
      );

      if (response == null || (response is List && response.isEmpty)) {
        throw const CaptureException('Gagal menyimpan tangkapan: respons server kosong.');
      }

      final Map<String, dynamic> row = response is List
          ? Map<String, dynamic>.from(response.first as Map)
          : Map<String, dynamic>.from(response as Map);

      final model = CaptureModel.fromJson({
        'id': row['capture_id'],
        'scan_id': scanId,
        'user_id': userId,
        'photo_object_path': effectivePhotoPath,
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

      // Simpan capture terbaru ke Hive terenkripsi (Plan 5.2 & 78)
      try {
        final existingCached = EncryptedStorageService.instance.getUserCaptures(userId);
        EncryptedStorageService.instance.saveUserCaptures(userId, [model, ...existingCached]);
      } catch (_) {}

      return model;
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

  /// Mengambil daftar koleksi tangkapan satwa milik user (dari database atau Hive terenkripsi / demo)
  Future<List<CaptureModel>> fetchUserCaptures([String? targetUserId]) async {
    final client = _getSupabaseClient();
    final currentUserId = targetUserId ?? _getCurrentUserId() ?? '00000000-0000-0000-0000-000000000001';

    if (AppConfig.isDemoMode || client == null) {
      // 1. Coba baca dari Hive terenkripsi dulu (Plan 5.2, 40, 78)
      final cachedList = EncryptedStorageService.instance.getUserCaptures(currentUserId);
      if (cachedList.isNotEmpty) {
        return cachedList;
      }
      if (_demoCaptures.isEmpty) {
        _initMockDemoCaptures();
      }
      return List<CaptureModel>.from(_demoCaptures.reversed);
    }

    try {
      final response = await client
          .from('captures')
          .select('*')
          .eq('user_id', currentUserId)
          .isFilter('deleted_at', null)
          .order('seq', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final captures = data.map((item) => CaptureModel.fromJson(Map<String, dynamic>.from(item as Map))).toList();

      // Simpan ke Hive terenkripsi untuk dibaca secara luring (offline) per Plan 40 & 78
      EncryptedStorageService.instance.saveUserCaptures(currentUserId, captures);

      return captures;
    } catch (e) {
      debugPrint('CaptureService fetchUserCaptures error: $e. Membaca dari Hive cache lokal terenkripsi.');
      // 2. Offline fallback ke Hive terenkripsi jika koneksi server gagal
      final cachedList = EncryptedStorageService.instance.getUserCaptures(currentUserId);
      if (cachedList.isNotEmpty) {
        return cachedList;
      }
      if (_demoCaptures.isNotEmpty) {
        return List<CaptureModel>.from(_demoCaptures.reversed);
      }
      throw CaptureException('Gagal memuat koleksi satwa: ${e.toString()}');
    }
  }

  void _initMockDemoCaptures() {
    if (_demoCaptures.isNotEmpty) return;
    const demoUserId = '00000000-0000-0000-0000-000000000001';
    final t1 = DateTime.utc(2026, 10, 19, 9, 30, 0);
    final t2 = DateTime.utc(2026, 10, 20, 14, 15, 0);
    final t3 = DateTime.utc(2026, 10, 21, 8, 45, 0);

    // Blok 1 (Jalak Bali)
    final h0 = calculateGenesisHash(demoUserId);
    final h1 = calculateBlockHash(
      seq: 1,
      previousHash: h0,
      photoSha256: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
      latitude: -8.115600,
      longitude: 114.527800,
      cameraHeading: 148.0,
      receivedAt: t1,
      userId: demoUserId,
    );
    _demoCaptures.add(
      CaptureModel(
        id: 'mock-cap-1',
        scanId: 'mock-scan-1',
        userId: demoUserId,
        photoObjectPath: 'assets/images/jalak_bali.jpg',
        speciesName: 'Jalak Bali',
        category: 'Leucopsar rothschildi',
        description: 'Burung endemik Bali Barat dengan bulu putih bersih dan topeng biru terang di kelopak mata.',
        latitude: -8.115600,
        longitude: 114.527800,
        cameraHeading: 148.0,
        receivedAt: t1,
        seq: 1,
        previousHash: h0,
        blockHash: h1,
        photoSha256: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
        createdAt: t1,
      ),
    );

    // Blok 2 (Kucing Kuwuk)
    final h2 = calculateBlockHash(
      seq: 2,
      previousHash: h1,
      photoSha256: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
      latitude: -7.250400,
      longitude: 110.428900,
      cameraHeading: 220.0,
      receivedAt: t2,
      userId: demoUserId,
    );
    _demoCaptures.add(
      CaptureModel(
        id: 'mock-cap-2',
        scanId: 'mock-scan-2',
        userId: demoUserId,
        photoObjectPath: 'assets/images/kucing_kuwuk.jpg',
        speciesName: 'Kucing Kuwuk',
        category: 'Prionailurus bengalensis',
        description: 'Kucing liar kecil nokturnal dengan tutul macan tutul di hutan sekunder Jawa Tengah.',
        latitude: -7.250400,
        longitude: 110.428900,
        cameraHeading: 220.0,
        receivedAt: t2,
        seq: 2,
        previousHash: h1,
        blockHash: h2,
        photoSha256: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
        createdAt: t2,
      ),
    );

    // Blok 3 (Kupu-kupu Jeruk)
    final h3 = calculateBlockHash(
      seq: 3,
      previousHash: h2,
      photoSha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      latitude: -6.208800,
      longitude: 106.845600,
      cameraHeading: 90.0,
      receivedAt: t3,
      userId: demoUserId,
    );
    _demoCaptures.add(
      CaptureModel(
        id: 'mock-cap-3',
        scanId: 'mock-scan-3',
        userId: demoUserId,
        photoObjectPath: 'assets/images/butterfly.jpg',
        speciesName: 'Kupu-kupu Jeruk',
        category: 'Papilio demoleus',
        description: 'Kupu-kupu anggun tropis bertotol kuning hitam yang diabadikan pada observasi lapangan.',
        latitude: -6.208800,
        longitude: 106.845600,
        cameraHeading: 90.0,
        receivedAt: t3,
        seq: 3,
        previousHash: h2,
        blockHash: h3,
        photoSha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        createdAt: t3,
      ),
    );
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
    try {
      EncryptedStorageService.instance.saveUserCaptures(
        demoUserId,
        List<CaptureModel>.from(_demoCaptures.reversed),
      );
    } catch (_) {}
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
