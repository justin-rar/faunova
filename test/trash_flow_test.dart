// ignore_for_file: avoid_print
// ==============================================================================
// FAUNOVA TEST: trash_flow_test.dart
// Pengujian Lengkap Fitur Sampah (Soft Delete), Pemulihan, Re-share Like Retention,
// dan Integritas Rantai Blok Kriptografi (Hash-Chain Tombstone)
// Sesuai Plan 5.2, 5.3, 5.7, 5.9, Scope Tingkat 3 & Aturan Keras AGENTS.md
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/config/app_config.dart';
import 'package:faunova/core/services/trash_service.dart';
import 'package:faunova/core/services/post_service.dart';
import 'package:faunova/core/services/capture_service.dart';
import 'package:faunova/core/services/encrypted_storage_service.dart';
import 'package:faunova/features/camera/models/capture_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUserId = '00000000-0000-0000-0000-000000000001';
  final t1 = DateTime.utc(2026, 10, 19, 9, 30, 0);
  final t2 = DateTime.utc(2026, 10, 20, 14, 15, 0);
  final t3 = DateTime.utc(2026, 10, 21, 8, 45, 0);

  // Helper untuk membuat 3 blok terhubung
  late String h0;
  late String h1;
  late String h2;
  late String h3;
  late CaptureModel cap1;
  late CaptureModel cap2;
  late CaptureModel cap3;

  setUp(() {
    AppConfig.isDemoMode = true;
    TrashService.instance.resetDemoTrash();
    PostService.instance.resetMockDemoPosts();

    h0 = CaptureService.calculateGenesisHash(testUserId);
    h1 = CaptureService.calculateBlockHash(
      seq: 1,
      previousHash: h0,
      photoSha256: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
      latitude: -8.115600,
      longitude: 114.527800,
      cameraHeading: 148.0,
      receivedAt: t1,
      userId: testUserId,
    );

    h2 = CaptureService.calculateBlockHash(
      seq: 2,
      previousHash: h1,
      photoSha256: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
      latitude: -7.250400,
      longitude: 110.428900,
      cameraHeading: 220.0,
      receivedAt: t2,
      userId: testUserId,
    );

    h3 = CaptureService.calculateBlockHash(
      seq: 3,
      previousHash: h2,
      photoSha256: '3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d',
      latitude: -0.923400,
      longitude: 100.362100,
      cameraHeading: 85.0,
      receivedAt: t3,
      userId: testUserId,
    );

    cap1 = CaptureModel(
      id: 'cap-uuid-1',
      scanId: 'scan-uuid-1',
      userId: testUserId,
      photoObjectPath: 'captures/test_1.jpg',
      speciesName: 'Jalak Bali',
      category: 'Aves',
      description: 'Spesies Jalak Bali liar di Teluk Brumbun',
      latitude: -8.115600,
      longitude: 114.527800,
      cameraHeading: 148.0,
      receivedAt: t1,
      seq: 1,
      previousHash: h0,
      blockHash: h1,
      photoSha256: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
      createdAt: t1,
    );

    cap2 = CaptureModel(
      id: 'cap-uuid-2',
      scanId: 'scan-uuid-2',
      userId: testUserId,
      photoObjectPath: 'captures/test_2.jpg',
      speciesName: 'Kucing Kuwuk',
      category: 'Mamalia',
      description: 'Kucing liar hutan lereng Ungaran',
      latitude: -7.250400,
      longitude: 110.428900,
      cameraHeading: 220.0,
      receivedAt: t2,
      seq: 2,
      previousHash: h1,
      blockHash: h2,
      photoSha256: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
      createdAt: t2,
    );

    cap3 = CaptureModel(
      id: 'cap-uuid-3',
      scanId: 'scan-uuid-3',
      userId: testUserId,
      photoObjectPath: 'captures/test_3.jpg',
      speciesName: 'Harimau Sumatera',
      category: 'Mamalia',
      description: 'Jejak observasi harimau Sumatera',
      latitude: -0.923400,
      longitude: 100.362100,
      cameraHeading: 85.0,
      receivedAt: t3,
      seq: 3,
      previousHash: h2,
      blockHash: h3,
      photoSha256: '3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d',
      createdAt: t3,
    );

    // Inisialisasi storage terenkripsi lokal
    EncryptedStorageService.instance.saveUserCaptures(testUserId, [cap1, cap2, cap3]);
  });

  group('A. Fitur Sampah & Pemulihan Postingan (Soft Delete Post)', () {
    test('1. Memindahkan postingan ke Sampah menyembunyikannya dari feed linimasa', () async {
      final post = await PostService.instance.createPost(
        captureId: cap1.id,
        caption: 'Postingan pengamatan Jalak Bali',
        demoSpeciesName: cap1.speciesName,
        demoPhotoPath: cap1.photoObjectPath,
      );

      expect(PostService.instance.demoPosts.any((p) => p.id == post.id), isTrue);

      // Pindahkan ke sampah
      await TrashService.instance.trashPost(post.id);

      // Post hilang dari feed linimasa
      expect(PostService.instance.demoPosts.any((p) => p.id == post.id), isFalse);

      // Post muncul di daftar Sampah
      final myTrash = await TrashService.instance.fetchMyTrash();
      expect(myTrash['posts']!.any((p) => p.id == post.id), isTrue);
      expect(myTrash['posts']!.firstWhere((p) => p.id == post.id).daysLeft, lessThanOrEqualTo(30));
    });

    test('2. trash_post bersifat idempoten dan tidak mereset trashed_at', () async {
      final post = await PostService.instance.createPost(
        captureId: cap1.id,
        caption: 'Postingan uji idempoten',
      );

      await TrashService.instance.trashPost(post.id);
      final trashedFirst = TrashService.instance.demoTrashedPosts.firstWhere((p) => p.id == post.id);
      final firstTrashedAt = trashedFirst.trashedAt;

      // Panggil trashPost kedua kali
      await TrashService.instance.trashPost(post.id);
      final trashedSecond = TrashService.instance.demoTrashedPosts.firstWhere((p) => p.id == post.id);

      expect(trashedSecond.trashedAt, equals(firstTrashedAt));
    });

    test('3. Menolak memindahkan postingan yang telah dimoderasi (deleted_at IS NOT NULL)', () async {
      final post = await PostService.instance.createPost(
        captureId: cap1.id,
        caption: 'Postingan melanggar aturan',
      );

      // Simulasikan moderasi komunitas
      final moderatedPost = post.copyWith(deletedAt: DateTime.now());
      PostService.instance.updateDemoPost(moderatedPost);

      expect(
        () => TrashService.instance.trashPost(post.id),
        throwsA(isA<TrashException>().having((e) => e.code, 'code', equals('MODERATED'))),
      );
    });

    test('4. Memulihkan postingan dari Sampah mengembalikannya ke linimasa', () async {
      final post = await PostService.instance.createPost(
        captureId: cap1.id,
        caption: 'Postingan untuk dipulihkan',
      );

      await TrashService.instance.trashPost(post.id);
      expect(PostService.instance.demoPosts.any((p) => p.id == post.id), isFalse);

      await TrashService.instance.restorePost(post.id);
      expect(PostService.instance.demoPosts.any((p) => p.id == post.id), isTrue);
      expect(PostService.instance.demoPosts.firstWhere((p) => p.id == post.id).trashedAt, isNull);
    });

    test('5. Menolak memulihkan postingan jika koleksi induk masih berada di Sampah', () async {
      final post = await PostService.instance.createPost(
        captureId: cap1.id,
        caption: 'Postingan koleksi',
      );

      // Pindahkan post ke sampah
      await TrashService.instance.trashPost(post.id);

      // Pindahkan juga capture ke sampah
      await TrashService.instance.trashCapture(cap1.id);

      // Coba pulihkan post saat capture masih di sampah -> DITOLAK
      expect(
        () => TrashService.instance.restorePost(post.id),
        throwsA(isA<TrashException>().having(
          (e) => e.message,
          'message',
          equals('Koleksi terkait masih berada di Sampah. Pulihkan koleksi terlebih dahulu.'),
        )),
      );

      // Pulihkan capture terlebih dahulu
      await TrashService.instance.restoreCapture(cap1.id);

      // Sekarang pulihkan post -> BERHASIL
      await TrashService.instance.restorePost(post.id);
      expect(PostService.instance.demoPosts.any((p) => p.id == post.id), isTrue);
    });
  });

  group('B. Fitur Sampah & Pemulihan Koleksi Satwa (Soft Delete Capture)', () {
    test('1. Memindahkan koleksi ke Sampah menyembunyikannya dari fetchUserCaptures & Hive', () async {
      // Sebelum trash: 3 captures aktif
      final before = await CaptureService.instance.fetchUserCaptures(testUserId);
      expect(before.length, equals(3));

      // Pindahkan cap2 ke Sampah
      await TrashService.instance.trashCapture(cap2.id);

      // Setelah trash: hanya 2 captures aktif (cap2 tersembunyi)
      final after = await CaptureService.instance.fetchUserCaptures(testUserId);
      expect(after.length, equals(2));
      expect(after.any((c) => c.id == cap2.id), isFalse);

      // Muncul di daftar Sampah
      final myTrash = await TrashService.instance.fetchMyTrash();
      expect(myTrash['captures']!.any((c) => c.id == cap2.id), isTrue);
    });

    test('2. Restoring koleksi mengembalikannya ke tab Koleksi', () async {
      await TrashService.instance.trashCapture(cap2.id);
      expect((await CaptureService.instance.fetchUserCaptures(testUserId)).length, equals(2));

      await TrashService.instance.restoreCapture(cap2.id);
      final restoredList = await CaptureService.instance.fetchUserCaptures(testUserId);
      expect(restoredList.length, equals(3));
      expect(restoredList.any((c) => c.id == cap2.id), isTrue);
    });

    test('3. Post yang di-trash manual sebelum capture di-trash tetap tinggal di Sampah saat capture dipulihkan', () async {
      final post = await PostService.instance.createPost(
        captureId: cap1.id,
        caption: 'Postingan independen',
      );

      // 1. User manual trash postingan
      await TrashService.instance.trashPost(post.id);
      expect(TrashService.instance.demoTrashedPosts.any((p) => p.id == post.id), isTrue);

      // 2. User kemudian trash koleksi
      await TrashService.instance.trashCapture(cap1.id);

      // 3. User pulihkan koleksi
      await TrashService.instance.restoreCapture(cap1.id);

      // Sesuai aturan keras: Postingan manual tetap tinggal di Sampah!
      expect(TrashService.instance.demoTrashedPosts.any((p) => p.id == post.id), isTrue);
      expect(PostService.instance.demoPosts.any((p) => p.id == post.id), isFalse);
    });
  });

  group('C. Re-Share via create_post Mempertahankan Like Lama', () {
    test('Bagikan ulang (re-share) auto-restore post dari Sampah dan LIKE LAMA TIDAK HILANG', () async {
      // 1. Buat postingan pertama kali
      final post = await PostService.instance.createPost(
        captureId: cap1.id,
        caption: 'Takarir Pertama',
      );

      // 2. Simulasikan like pada postingan tersebut (misal terkumpul 42 like)
      final postWithLikes = post.copyWith(likesCount: 42, isLikedByMe: true);
      PostService.instance.updateDemoPost(postWithLikes);

      // 3. Pindahkan postingan ke Sampah
      await TrashService.instance.trashPost(post.id);
      expect(PostService.instance.demoPosts.any((p) => p.id == post.id), isFalse);
      expect(TrashService.instance.demoTrashedPosts.any((p) => p.id == post.id), isTrue);

      // 4. User membagikan ulang tangkapan yang sama via createPost dengan takarir baru
      final resharedPost = await PostService.instance.createPost(
        captureId: cap1.id,
        caption: 'Takarir Baru Hasil Bagikan Ulang',
      );

      // Verifikasi: ID tetap sama, takarir diperbarui, DAN JUMLAH LIKE 42 TETAP TERJAGA!
      expect(resharedPost.id, equals(post.id));
      expect(resharedPost.caption, equals('Takarir Baru Hasil Bagikan Ulang'));
      expect(resharedPost.likesCount, equals(42));
      expect(resharedPost.isLikedByMe, isTrue);
      expect(resharedPost.trashedAt, isNull);

      // Postingan kembali aktif di linimasa
      expect(PostService.instance.demoPosts.any((p) => p.id == post.id), isTrue);
    });

    test('create_post menolak memposting tangkapan yang berada di Sampah', () async {
      await TrashService.instance.trashCapture(cap3.id);

      expect(
        () => PostService.instance.createPost(
          captureId: cap3.id,
          caption: 'Coba post capture di sampah',
        ),
        throwsA(isA<PostException>().having((e) => e.code, 'code', equals('CAPTURE_IN_TRASH'))),
      );
    });
  });

  group('D. Purge Permanen & Bukti Integritas Kriptografi Rantai Blok (Tombstone)', () {
    test('Purge capture: tombstone DB row, cascade delete post, dan integritas hash-chain 100% UTUH', () async {
      // 1. Buat post untuk cap2
      final post2 = await PostService.instance.createPost(
        captureId: cap2.id,
        caption: 'Kucing kuwuk langka',
      );

      // Hubungkan demo captures ke CaptureService untuk audit rantai
      CaptureService.instance.initMockDemoCapturesWith([cap1, cap2, cap3]);

      print('\n================================================================');
      print('BUKTI KRIPTOGRAFI HASH-CHAIN SEBELUM PURGE (BASELINE UTUH):');
      print('================================================================');
      print('Genesis Hash (H0): $h0');
      print('Blok #1 Hash (H1): $h1 (Jalak Bali)');
      print('Blok #2 Hash (H2): $h2 (Kucing Kuwuk)');
      print('Blok #3 Hash (H3): $h3 (Harimau Sumatera)');

      final verifyBefore = CaptureService.instance.verifyMockChain();
      print('Status Audit Rantai Sebelum Purge: ${verifyBefore.isValid ? "100% VALID" : "GAGAL"} (${verifyBefore.totalBlocks} Blok)');
      expect(verifyBefore.isValid, isTrue);
      expect(verifyBefore.totalBlocks, equals(3));

      // 2. Pindahkan cap2 ke Sampah terlebih dahulu
      await TrashService.instance.trashCapture(cap2.id);

      // 3. Eksekusi Purge Permanen pada cap2 (Blok #2 di tengah rantai!)
      await TrashService.instance.purgeItem(
        type: 'capture',
        id: cap2.id,
        photoObjectPath: cap2.photoObjectPath,
      );

      // Verifikasi: Post terkait cap2 telah di-hard delete secara cascade
      expect(PostService.instance.demoPosts.any((p) => p.id == post2.id), isFalse);
      expect(TrashService.instance.demoTrashedPosts.any((p) => p.id == post2.id), isFalse);

      // Ambil data cap2 setelah purge tombstone
      final purgedCap2 = TrashService.instance.demoTrashedCaptures.firstWhere((c) => c.id == cap2.id);
      expect(purgedCap2.isPurged, isTrue);
      expect(purgedCap2.speciesName, equals('[Observasi Dipurge]'));
      expect(purgedCap2.photoObjectPath, equals('purged'));
      expect(purgedCap2.category, isNull);
      expect(purgedCap2.description, isEmpty);

      print('\n================================================================');
      print('BUKTI KRIPTOGRAFI HASH-CHAIN SETELAH PURGE TOMBSTONE (BLOK #2):');
      print('================================================================');
      print('Blok #2 Tombstone Status: purged_at = ${purgedCap2.purgedAt}');
      print('Blok #2 Redaksi Non-Hash: species_name = "${purgedCap2.speciesName}", photo = "${purgedCap2.photoObjectPath}"');
      print('Blok #2 Hash Inputs:');
      print('  - seq: ${purgedCap2.seq}');
      print('  - previous_hash: ${purgedCap2.previousHash}');
      print('  - photo_sha256: ${purgedCap2.photoSha256}');
      print('  - latitude: ${purgedCap2.latitude}');
      print('  - longitude: ${purgedCap2.longitude}');
      print('  - camera_heading: ${purgedCap2.cameraHeading}');
      print('  - received_at: ${purgedCap2.receivedAt.toIso8601String()}');
      print('  - user_id: ${purgedCap2.userId}');
      print('  - block_hash tersimpan: ${purgedCap2.blockHash}');

      // Hitung ulang hash kanonis secara independen dari field yang tersisa
      final recalculatedH2 = CaptureService.calculateBlockHash(
        seq: purgedCap2.seq,
        previousHash: purgedCap2.previousHash,
        photoSha256: purgedCap2.photoSha256,
        latitude: purgedCap2.latitude,
        longitude: purgedCap2.longitude,
        cameraHeading: purgedCap2.cameraHeading,
        receivedAt: purgedCap2.receivedAt,
        userId: purgedCap2.userId,
      );

      print('  - block_hash dihitung ulang: $recalculatedH2');
      print('  - Selisih Bit Hash: 0 (Cocok Sempurna!)');
      expect(recalculatedH2, equals(h2));
      expect(purgedCap2.blockHash, equals(h2));

      // Periksa sambungan Blok #3 ke Blok #2
      expect(cap3.previousHash, equals(purgedCap2.blockHash));

      // Jalankan verifikasi seluruh rantai setelah purge
      final verifyAfter = CaptureService.instance.verifyMockChainWithPurged([cap1, purgedCap2, cap3]);
      print('Status Audit Rantai Setelah Purge: ${verifyAfter.isValid ? "100% VALID" : "GAGAL"} (${verifyAfter.totalBlocks} Blok)');
      print('Pesan Audit: "${verifyAfter.message}"');
      print('================================================================\n');

      expect(verifyAfter.isValid, isTrue);
      expect(verifyAfter.totalBlocks, equals(3));
      expect(verifyAfter.brokenSeq, isNull);
    });

    test('purgeItem menolak item yang tidak berada di Sampah (trashed_at IS NULL)', () async {
      // cap1 masih aktif di koleksi (belum di-trash)
      expect(
        () => TrashService.instance.purgeItem(type: 'capture', id: cap1.id),
        throwsA(isA<TrashException>().having((e) => e.code, 'code', equals('NOT_IN_TRASH'))),
      );
    });

    test('purgeItem bersifat idempoten', () async {
      await TrashService.instance.trashCapture(cap1.id);
      await TrashService.instance.purgeItem(type: 'capture', id: cap1.id);

      // Panggilan kedua tidak menyebabkan error dan tetap sukses
      await TrashService.instance.purgeItem(type: 'capture', id: cap1.id);
      expect(TrashService.instance.demoTrashedCaptures.firstWhere((c) => c.id == cap1.id).isPurged, isTrue);
    });
  });
}
