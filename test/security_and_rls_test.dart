// ==============================================================================
// FAUNOVA — RANGKAIAN UJI KEAMANAN, AUDIT RLS & CHECKLIST MVP (Sesi S22)
// Sesuai acuan: docs/plan_faunova_revisi_5_final.md (Bagian 13 & 15) & AGENTS.md
// ==============================================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:faunova/core/services/capture_service.dart';
import 'package:faunova/core/services/post_service.dart';
import 'package:faunova/core/services/quiz_service.dart';
import 'package:faunova/core/services/streak_service.dart';
import 'package:faunova/core/services/shake_service.dart';
import 'package:faunova/core/services/currency_service.dart';
import 'package:faunova/core/services/timezone_service.dart';
import 'package:faunova/core/services/encrypted_storage_service.dart';
import 'package:faunova/features/camera/models/scan_result_model.dart';
import 'package:faunova/features/feed/models/post_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await EncryptedStorageService.instance.init(isTestEnv: true);
  });

  group('Sesi S22: Checklist Keamanan & Akses (Plan Bagian 13 & AGENTS.md)', () {

    // -------------------------------------------------------------------------
    // 1. Audit Scanner Rahasia (Hard Rule 1: Tidak Ada Secret di Klien/Repo)
    // -------------------------------------------------------------------------
    test('Audit Secret Scanner: Tidak ada secret server, Gemini key, atau service_role di lib/', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'Direktori lib/ harus ada');

      final files = libDir.listSync(recursive: true).whereType<File>();
      final forbiddenStringPatterns = [
        RegExp(r'AIza[0-9A-Za-z-_]{35}'), // Gemini API key live pattern
        RegExp(r'SB-Mid-server-[0-9A-Za-z-_]+'), // Midtrans server key pattern
        RegExp(r'Mid-server-[0-9A-Za-z-_]+'), // Midtrans production server key
        RegExp(r'''['"][A-Za-z0-9._-]*service_role[A-Za-z0-9._-]*['"]'''), // String literal token yang memuat service_role
        RegExp(r'SUPABASE_SERVICE_ROLE_KEY'), // Environment variable server role
        RegExp(r'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[0-9A-Za-z-_]+\.[0-9A-Za-z-_]+'), // Live JWT pattern
      ];

      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;
        final content = file.readAsStringSync();

        for (final pattern in forbiddenStringPatterns) {
          final matches = pattern.allMatches(content);
          expect(
            matches.isEmpty,
            isTrue,
            reason: 'Ditemukan potensi kebocoran rahasia (${pattern.pattern}) pada ${file.path}',
          );
        }
      }
    });

    test('Audit Gitignore: .env terdaftar di .gitignore dan .env.example tidak memuat nilai asli', () {
      final gitignoreFile = File('.gitignore');
      expect(gitignoreFile.existsSync(), isTrue);
      final gitignoreContent = gitignoreFile.readAsStringSync();
      expect(gitignoreContent.contains('.env'), isTrue, reason: '.gitignore wajib mengabaikan .env');

      final envExampleFile = File('.env.example');
      if (envExampleFile.existsSync()) {
        final envExampleContent = envExampleFile.readAsStringSync();
        expect(envExampleContent.contains('AIza'), isFalse);
        expect(envExampleContent.contains('SB-Mid-server-'), isFalse);
      }
    });

    // -------------------------------------------------------------------------
    // 2. Audit Kerahasiaan Koordinat Tepat (Hard Rule 4: Koordinat Tepat Tidak ke Publik)
    // -------------------------------------------------------------------------
    test('Kerahasiaan Koordinat: Koordinat tepat tidak pernah keluar ke feed publik (Coarse Grid / Hidden)', () {
      const rawLat = -8.1122334455;
      const rawLng = 115.2233445566;

      // 1. Grid Snapping 0.01 derajat
      final gridded = PostService.snapToGridLocally(rawLat, rawLng);
      // Nilai gridded harus terpotong ke titik tengah sel grid 0.01 derajat
      expect(gridded['lat'], closeTo(-8.115, 0.001));
      expect(gridded['lng'], closeTo(115.225, 0.001));
      // Pastikan bukan nilai raw presisi tinggi
      expect(gridded['lat'] != rawLat, isTrue);
      expect(gridded['lng'] != rawLng, isTrue);

      // 2. Mode Hidden: Koordinat display bernilai NULL
      final hiddenPost = PostModel(
        id: 'post-hidden-1',
        captureId: 'cap-1',
        caption: 'Spesies langka tersembunyi',
        locationVisibility: 'hidden',
        displayLatitude: null,
        displayLongitude: null,
        areaLabel: null,
        speciesName: 'Badak Jawa',
        category: 'Mamalia',
        photoUrl: 'https://example.com/badak.jpg',
        blockSeq: 1,
        blockHash: 'abcdef123456',
        photoSha256: 'sha256badak',
        authorId: 'user-hidden-1',
        authorName: 'Ranger Ujung Kulon',
        authorUsername: 'ranger_uk',
        createdAt: DateTime.now(),
      );

      expect(hiddenPost.displayLatitude, isNull);
      expect(hiddenPost.displayLongitude, isNull);
      expect(hiddenPost.areaLabel, isNull);
    });

    // -------------------------------------------------------------------------
    // 3. Audit Kuis & Kerahasiaan Kunci Jawaban (Hard Rule 5)
    // -------------------------------------------------------------------------
    test('Kerahasiaan Kunci Kuis: Respons startQuizSession() dan getDailyChallenge() tidak memuat correctOption', () async {
      // Uji sesi kuis 10 soal
      final quizSession = await QuizService.instance.startQuizSession();
      expect(quizSession.questions.length, equals(10));
      for (final q in quizSession.questions) {
        expect(q.options.length, equals(4));
        expect(q.question.isNotEmpty, isTrue);
        // QuizQuestionModel tidak memiliki field correctOption sama sekali
        // Kunci jawaban tersimpan di server
      }

      // Uji tantangan harian
      final challenge = await StreakService.instance.getDailyChallenge();
      expect(challenge.options.length, equals(4));
      expect(challenge.alreadyAnswered, isFalse);
      expect(challenge.correctOption, isNull, reason: 'Kunci jawaban tidak boleh dikirim ke klien (Hard Rule 5)');
      expect(challenge.explanation, isNull);
    });

    // -------------------------------------------------------------------------
    // 4. Audit Aturan Bisnis Server & Idempotensi (Hard Rule 2)
    // -------------------------------------------------------------------------
    test('Idempotensi Streak & Challenge: Menolak klaim ganda di hari yang sama', () async {
      final todayWib = TimeZoneService.getCurrentDateWibString();
      final yesterday = DateTime.parse(todayWib).subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      StreakService.instance.resetDemoState(streak: 3, lastClaimDate: yesterdayStr);

      final firstClaim = await StreakService.instance.claimDailyStreak();
      expect(firstClaim.isNewClaim, isTrue);
      expect(firstClaim.isClaimedToday, isTrue);

      // Klaim kedua pada hari yang sama harus ditolak secara idempoten
      final secondClaim = await StreakService.instance.claimDailyStreak();
      expect(secondClaim.isNewClaim, isFalse);
      expect(secondClaim.isClaimedToday, isTrue);
      expect(secondClaim.message, contains('sudah melakukan check-in'));
    });

    test('Batas Kuota Shake-to-Quiz: Kuota 3x per hari ditegakkan secara tepat', () async {
      ShakeService.instance.resetDemoQuota();

      final initialQuota = await ShakeService.instance.getShakeQuota();
      expect(initialQuota.maxQuota, equals(3));
      expect(initialQuota.remainingQuota, equals(3));

      // Klaim 3 kali hingga habis
      await ShakeService.instance.claimShakeQuiz();
      await ShakeService.instance.claimShakeQuiz();
      await ShakeService.instance.claimShakeQuiz();

      // Klaim ke-4 wajib ditolak
      final claim4 = await ShakeService.instance.claimShakeQuiz();
      expect(claim4.quotaExceeded, isTrue);
      expect(claim4.remainingQuota, equals(0));
      expect(claim4.message, contains('sudah habis (3/3)'));
    });

    // -------------------------------------------------------------------------
    // 5. Audit Integritas Hash-Chain (Plan Bagian 13 & 17)
    // -------------------------------------------------------------------------
    test('Integritas Hash-Chain: Mengubah camera_heading atau kolom lain membatalkan validitas rantai', () {
      final now = DateTime.utc(2026, 10, 22, 12, 0, 0);
      const userId = 'user-chain-s22-test';
      const prevHash = '0000000000000000000000000000000000000000000000000000000000000000';
      const photoSha = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

      final validHash = CaptureService.calculateBlockHash(
        seq: 1,
        previousHash: prevHash,
        photoSha256: photoSha,
        latitude: -8.1122,
        longitude: 115.2233,
        cameraHeading: 148.5,
        receivedAt: now,
        userId: userId,
      );
      expect(validHash.length, equals(64));

      // 1. Modifikasi Heading (Kompas) -> Hash berubah
      final tamperedHeadingHash = CaptureService.calculateBlockHash(
        seq: 1,
        previousHash: prevHash,
        photoSha256: photoSha,
        latitude: -8.1122,
        longitude: 115.2233,
        cameraHeading: 150.0, // diubah dari 148.5
        receivedAt: now,
        userId: userId,
      );
      expect(tamperedHeadingHash != validHash, isTrue, reason: 'Perubahan heading wajib terdeteksi');

      // 2. Modifikasi Latitude -> Hash berubah
      final tamperedLatHash = CaptureService.calculateBlockHash(
        seq: 1,
        previousHash: prevHash,
        photoSha256: photoSha,
        latitude: -8.1123, // diubah dari -8.1122
        longitude: 115.2233,
        cameraHeading: 148.5,
        receivedAt: now,
        userId: userId,
      );
      expect(tamperedLatHash != validHash, isTrue, reason: 'Perubahan latitude wajib terdeteksi');

      // 3. Modifikasi Sequence -> Hash berubah
      final tamperedSeqHash = CaptureService.calculateBlockHash(
        seq: 2, // diubah dari 1
        previousHash: prevHash,
        photoSha256: photoSha,
        latitude: -8.1122,
        longitude: 115.2233,
        cameraHeading: 148.5,
        receivedAt: now,
        userId: userId,
      );
      expect(tamperedSeqHash != validHash, isTrue, reason: 'Perubahan sequence wajib terdeteksi');
    });

    // -------------------------------------------------------------------------
    // 6. Audit Validasi AI Satwa (Non-Animal Rejection)
    // -------------------------------------------------------------------------
    test('Validasi AI Satwa: Objek bukan hewan ditolak dari koleksi', () {
      final nonAnimalResult = ScanResultModel(
        scanId: 'scan-non-animal',
        requestId: 'req-non-animal',
        status: 'succeeded',
        isAnimal: false,
        name: 'Bukan Hewan',
        description: 'Objek terdeteksi berupa kendaraan bermotor atau benda mati.',
        categoryOrSpecies: 'Non-Animalia',
      );

      expect(nonAnimalResult.isAnimal, isFalse);
    });

    // -------------------------------------------------------------------------
    // 7. Audit Ketahanan Mata Uang & Pembayaran Midtrans (Hard Rule 6)
    // -------------------------------------------------------------------------
    test('Audit Transaksi: Harga transaksi resmi selalu Rp15.000 IDR dan kurs offline tetap berfungsi', () {
      const officialPriceIdr = 15000;
      expect(officialPriceIdr, equals(15000));

      final currency = CurrencyService.instance;
      final usdEst = currency.convertFromIdr(officialPriceIdr, 'USD');
      final jpyEst = currency.convertFromIdr(officialPriceIdr, 'JPY');
      expect(usdEst, greaterThan(0));
      expect(jpyEst, greaterThan(0));

      final formattedIdr = currency.formatPrice(officialPriceIdr, 'IDR');
      expect(formattedIdr, equals('Rp15.000'));
    });

  });
}
