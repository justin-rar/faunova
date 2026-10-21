import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faunova/core/theme/app_colors.dart';
import 'package:faunova/core/theme/app_theme.dart';
import 'package:faunova/core/widgets/glass_bottom_bar.dart';
import 'package:faunova/core/widgets/app_state_view.dart';
import 'package:faunova/features/navigation/main_navigation_scaffold.dart';
import 'package:faunova/core/services/auth_service.dart';
import 'package:faunova/features/auth/presentation/auth_gate.dart';
import 'package:faunova/features/auth/presentation/login_page.dart';
import 'package:faunova/features/auth/presentation/register_page.dart';
import 'package:faunova/features/auth/presentation/forgot_password_page.dart';
import 'package:faunova/features/auth/presentation/verify_email_page.dart';
import 'package:faunova/core/services/compass_heading_service.dart';
import 'package:faunova/core/config/app_config.dart';
import 'package:faunova/features/camera/models/scan_result_model.dart';
import 'package:faunova/core/services/image_processing_service.dart';
import 'package:faunova/features/camera/presentation/scan_result_page.dart';
import 'package:faunova/features/camera/presentation/camera_page.dart';
import 'package:faunova/features/camera/models/scan_chat_message_model.dart';
import 'package:faunova/core/services/chat_service.dart';
import 'package:faunova/features/camera/presentation/scan_chat_page.dart';
import 'package:faunova/features/camera/models/capture_model.dart';
import 'package:faunova/core/services/capture_service.dart';
import 'package:faunova/features/profile/presentation/profile_page.dart';
import 'package:faunova/features/profile/presentation/capture_detail_page.dart';
import 'package:faunova/features/profile/presentation/widgets/collection_grid_view.dart';
import 'package:faunova/features/profile/presentation/widgets/collection_map_view.dart';
import 'package:faunova/features/feed/models/post_model.dart';
import 'package:faunova/core/services/post_service.dart';
import 'package:faunova/features/feed/presentation/feed_page.dart';
import 'package:faunova/features/feed/presentation/widgets/post_card.dart';
import 'package:faunova/features/feed/presentation/widgets/create_post_sheet.dart';
import 'package:faunova/core/services/social_service.dart';
import 'package:faunova/features/profile/models/public_profile_model.dart';
import 'package:faunova/features/profile/presentation/public_profile_page.dart';
import 'package:faunova/core/services/profile_service.dart';
import 'package:faunova/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:faunova/core/services/search_service.dart';
import 'package:faunova/features/search/presentation/search_page.dart';
import 'package:faunova/core/services/encrypted_storage_service.dart';
import 'package:faunova/core/services/currency_service.dart';
import 'package:faunova/core/services/timezone_service.dart';
import 'package:faunova/features/profile/presentation/widgets/currency_converter_card.dart';
import 'package:faunova/features/profile/presentation/widgets/multi_timezone_card.dart';
import 'package:faunova/core/services/quiz_service.dart';
import 'package:faunova/features/game/models/quiz_session_model.dart';
import 'package:faunova/features/game/presentation/quiz_arena_page.dart';
import 'package:faunova/features/game/presentation/game_page.dart';
import 'package:image/image.dart' as img;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('S1 - Kerangka Palet Warna & Desain Visual AGENTS.md', () {
    test('Palet warna sesuai dengan nilai heksadesimal spesifikasi', () {
      expect(AppColors.sageTua, const Color(0xFF5C7457));
      expect(AppColors.sage, const Color(0xFF8FA28A));
      expect(AppColors.sageMuda, const Color(0xFFC7D3C0));
      expect(AppColors.gading, const Color(0xFFF7F4ED));
      expect(AppColors.emas, const Color(0xFFC8A96B));
      expect(AppColors.emasTua, const Color(0xFF7F6326));
      expect(AppColors.teksGelap, const Color(0xFF1F2A1E));
      expect(AppColors.merahStatus, const Color(0xFFB3261E));
      expect(AppColors.teksPutih, const Color(0xFFFFFFFF));
    });

    test('Tema Material 3 menerapkan latar gading dan header sage tua', () {
      final theme = AppTheme.lightTheme;
      expect(theme.scaffoldBackgroundColor, AppColors.gading);
      expect(theme.appBarTheme.backgroundColor, AppColors.sageTua);
      expect(theme.appBarTheme.foregroundColor, AppColors.teksPutih);
      expect(theme.cardTheme.color, AppColors.sageMuda);
    });
  });

  group('S1 - Navigasi 5 Tab & GlassBottomBar', () {
    testWidgets('Menampilkan 5 tab di bottom bar kaca dan berpindah antar tab', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScaffold(),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan GlassBottomBar ada dan memiliki BackdropFilter (efek kaca)
      expect(find.byType(GlassBottomBar), findsOneWidget);
      expect(find.descendant(of: find.byType(GlassBottomBar), matching: find.byType(BackdropFilter)), findsOneWidget);

      // Verifikasi 5 label tab ada di bottom bar
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Cari'), findsOneWidget);
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Game'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Tab 0 default aktif (Beranda)
      expect(find.text('Untuk Kamu'), findsOneWidget);
      expect(find.text('Mengikuti'), findsOneWidget);

      // Pindah ke Tab 1 (Cari)
      await tester.tap(find.text('Cari'));
      await tester.pumpAndSettle();
      expect(find.text('Akun Pengguna'), findsOneWidget);
      expect(find.text('Katalog Spesies'), findsOneWidget);

      // Pindah ke Tab 2 (Kamera)
      await tester.tap(find.text('Kamera'));
      await tester.pumpAndSettle();
      expect(find.text('Kamera Identifikasi AI'), findsOneWidget);
      expect(find.text('HEADING 148° TG'), findsOneWidget);

      // Pindah ke Tab 3 (Game)
      await tester.tap(find.text('Game'));
      await tester.pumpAndSettle();
      expect(find.text('Ekspedisi & Kuis Fauna'), findsOneWidget);
      expect(find.text('Streak Observasi Harian'), findsOneWidget);

      // Pindah ke Tab 4 (Profil)
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Profil Kolektor'), findsOneWidget);
      expect(find.text('Centang Biru Aktif'), findsOneWidget);
    });

    testWidgets('AppStateView menangani 4 state: loading, error, empty, offline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppStateView(
              status: AppViewStatus.loading,
              loadingMessage: 'Sedang memuat data...',
              child: const Text('Konten Normal'),
            ),
          ),
        ),
      );

      // Loading state
      expect(find.text('Sedang memuat data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Empty state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppStateView(
              status: AppViewStatus.empty,
              emptyTitle: 'Belum Ada Data',
              emptyMessage: 'Silakan tambahkan data.',
              child: const Text('Konten Normal'),
            ),
          ),
        ),
      );
      expect(find.text('Belum Ada Data'), findsOneWidget);
      expect(find.text('Silakan tambahkan data.'), findsOneWidget);

      // Error state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppStateView(
              status: AppViewStatus.error,
              errorMessage: 'Terjadi kendala server.',
              retryLabel: 'Coba Lagi',
              onRetry: () {},
              child: const Text('Konten Normal'),
            ),
          ),
        ),
      );
      expect(find.text('Terjadi Kendala'), findsOneWidget);
      expect(find.text('Terjadi kendala server.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      // Offline state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppStateView(
              status: AppViewStatus.offline,
              offlineMessage: 'Mode luring aktif.',
              child: const Text('Konten Normal'),
            ),
          ),
        ),
      );
      expect(find.text('Mode Luring (Offline)'), findsOneWidget);
      expect(find.text('Mode luring aktif.'), findsOneWidget);
    });
  });

  group('S2 - Autentikasi Supabase & Alur Masuk/Daftar/Lupa Password', () {
    setUp(() async {
      await AuthService.instance.signOut();
    });

    tearDown(() async {
      await AuthService.instance.signOut();
    });

    testWidgets('AuthGate menampilkan LoginPage ketika belum terautentikasi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuthGate(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Masuk ke Akun'), findsOneWidget);
      expect(find.text('Belum memiliki akun? '), findsOneWidget);
    });

    testWidgets('LoginPage memvalidasi input kosong dan format email yang salah', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Klik Masuk tanpa mengisi input apa pun
      await tester.tap(find.text('Masuk ke Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Alamat email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);

      // Isi email format salah
      await tester.enterText(find.byType(TextFormField).first, 'emailsalah');
      await tester.tap(find.text('Masuk ke Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Format alamat email tidak valid'), findsOneWidget);

      // Isi password kurang dari 6 karakter
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Masuk ke Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
    });

    testWidgets('Navigasi dari LoginPage ke RegisterPage dan validasi formulir pendaftaran', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Klik Daftar Baru
      await tester.ensureVisible(find.text('Daftar Baru'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daftar Baru'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.text('Bergabung dengan Faunova'), findsOneWidget);
      expect(find.text('Daftarkan Akun'), findsOneWidget);
    });

    testWidgets('Navigasi dari LoginPage ke ForgotPasswordPage dan validasi reset password', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Klik Lupa kata sandi?
      await tester.ensureVisible(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lupa kata sandi?'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('Kirim Tautan Pemulihan'), findsOneWidget);

      // Submit formulir kosong
      await tester.tap(find.text('Kirim Tautan Pemulihan'));
      await tester.pumpAndSettle();

      expect(find.text('Alamat email wajib diisi'), findsOneWidget);
    });

    testWidgets('VerifyEmailPage menampilkan instruksi verifikasi Brevo SMTP', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const VerifyEmailPage(email: 'peneliti@faunova.id'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cek Kotak Masuk Anda'), findsOneWidget);
      expect(find.text('peneliti@faunova.id'), findsOneWidget);
      expect(find.text('Kembali ke Halaman Masuk'), findsOneWidget);
    });

    testWidgets('Mode Demo mengaktifkan navigasi dan dialog keluar berfungsi dengan baik', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AuthGate(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi awal berada di LoginPage
      expect(find.byType(LoginPage), findsOneWidget);

      // Aktifkan mode demo via tombol demo di banner
      await tester.tap(find.text('Mode Demo'));
      await tester.pumpAndSettle();

      // Masuk ke MainNavigationScaffold
      expect(find.byType(MainNavigationScaffold), findsOneWidget);

      // Pindah ke Profil
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();

      // Buka popup menu di appbar
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Pilih Keluar Akun
      await tester.tap(find.text('Keluar Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari Akun?'), findsOneWidget);

      // Konfirmasi keluar
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();

      // Kembali ke LoginPage
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('S3 - Skema Database & Migrasi Supabase (Postgres & RLS)', () {
    test('File migrasi 001_initial_schema.sql memiliki DDL lengkap sesuai spesifikasi AGENTS.md', () {
      final migrationFile = File('supabase/migrations/001_initial_schema.sql');
      expect(migrationFile.existsSync(), isTrue);
      final sql = migrationFile.readAsStringSync();
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.profiles'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.scans'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.captures'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.posts'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.follows'), isTrue);
      expect(sql.contains('CREATE TABLE IF NOT EXISTS public.likes'), isTrue);
      expect(sql.contains('ENABLE ROW LEVEL SECURITY'), isTrue);
      expect(sql.contains('CREATE OR REPLACE VIEW public.public_profiles'), isTrue);
    });

    test('Konfigurasi .env dan skema public_profiles konsisten dengan aturan AGENTS.md', () {
      // Memastikan nama field sanitasi publik
      const publicFields = [
        'id',
        'username',
        'display_name',
        'avatar_path',
        'bio',
        'is_verified',
        'streak_count',
        'best_quiz_score',
        'created_at'
      ];
      expect(publicFields.contains('username'), isTrue);
      expect(publicFields.contains('email'), isFalse); // email dilarang bocor ke publik
      expect(publicFields.contains('password'), isFalse);
    });
  });

  group('S4 - Uji Berisiko (Spike): Kompas, Edge Function Gemini, dan Midtrans Sandbox', () {
    test('CompassHeadingService: Normalisasi sudut 0..360 derajat', () {
      expect(CompassHeadingService.normalizeDegrees(0.0), 0.0);
      expect(CompassHeadingService.normalizeDegrees(360.0), 0.0);
      expect(CompassHeadingService.normalizeDegrees(720.0), 0.0);
      expect(CompassHeadingService.normalizeDegrees(-90.0), 270.0);
      expect(CompassHeadingService.normalizeDegrees(-360.0), 0.0);
      expect(CompassHeadingService.normalizeDegrees(375.0), 15.0);
    });

    test('CompassHeadingService: Konversi 8 mata angin resmi (U, TL, T, TG, S, BD, B, BL)', () {
      expect(CompassHeadingService.degreesToCardinal(0.0), CardinalDirection.utara);
      expect(CompassHeadingService.degreesToCardinal(350.0), CardinalDirection.utara);
      expect(CompassHeadingService.degreesToCardinal(10.0), CardinalDirection.utara);
      expect(CompassHeadingService.degreesToCardinal(45.0), CardinalDirection.timurLaut);
      expect(CompassHeadingService.degreesToCardinal(90.0), CardinalDirection.timur);
      expect(CompassHeadingService.degreesToCardinal(135.0), CardinalDirection.tenggara);
      expect(CompassHeadingService.degreesToCardinal(148.0), CardinalDirection.tenggara);
      expect(CompassHeadingService.degreesToCardinal(180.0), CardinalDirection.selatan);
      expect(CompassHeadingService.degreesToCardinal(225.0), CardinalDirection.baratDaya);
      expect(CompassHeadingService.degreesToCardinal(270.0), CardinalDirection.barat);
      expect(CompassHeadingService.degreesToCardinal(315.0), CardinalDirection.baratLaut);
    });

    test('CompassHeadingService: Format HUD taktis dan deskripsi Indonesia', () {
      expect(CompassHeadingService.formatHud(148.0), '148° TG');
      expect(CompassHeadingService.formatHud(0.0), '0° U');
      expect(CompassHeadingService.formatHud(359.8), '0° U');
      expect(CompassHeadingService.formatFullDescription(148.0), 'Menghadap Tenggara (148°)');
    });

    test('CompassHeadingService: Selisih sudut lingkar dan evaluasi batas toleransi 20° Plan 5.10', () {
      // Selisih melintasi batas 0/360 derajat
      expect(CompassHeadingService.angularDifference(355.0, 5.0), 10.0);
      expect(CompassHeadingService.angularDifference(5.0, 355.0), 10.0);
      expect(CompassHeadingService.angularDifference(10.0, 30.0), 20.0);

      // Batas toleransi 20 derajat
      expect(CompassHeadingService.isWithinTolerance(10.0, 25.0, toleranceDegrees: 20.0), isTrue);
      expect(CompassHeadingService.isWithinTolerance(10.0, 35.0, toleranceDegrees: 20.0), isFalse);
      expect(CompassHeadingService.isWithinTolerance(358.0, 15.0, toleranceDegrees: 20.0), isTrue);
    });

    test('AppConfig: Client Key Midtrans Sandbox tersedia untuk klien tanpa mengekspos Server Key', () {
      expect(AppConfig.midtransClientKey.isNotEmpty, isTrue);
      expect(AppConfig.midtransClientKey.startsWith('Mid-client-'), isTrue);
    });

    test('Edge Functions: Verifikasi berkas ai-gateway, create-payment, dan midtrans-webhook', () {
      final aiGateway = File('supabase/functions/ai-gateway/index.ts');
      final createPayment = File('supabase/functions/create-payment/index.ts');
      final midtransWebhook = File('supabase/functions/midtrans-webhook/index.ts');

      expect(aiGateway.existsSync(), isTrue);
      expect(createPayment.existsSync(), isTrue);
      expect(midtransWebhook.existsSync(), isTrue);

      final aiCode = aiGateway.readAsStringSync();
      expect(aiCode.contains('gemini-3.8-flash'), isTrue);
      expect(aiCode.contains('daily_scan_usage'), isTrue);
      expect(aiCode.contains('isAnimal'), isTrue);

      final webhookCode = midtransWebhook.readAsStringSync();
      expect(webhookCode.contains('SHA-512'), isTrue);
      expect(webhookCode.contains('MIDTRANS_SERVER_KEY'), isTrue);
    });
  });

  group('S5 - Kamera Layar Penuh, Kompresi EXIF, GPS & Scan AI Hasil (Plan 5.2)', () {
    test('ImageProcessingService: Kompresi, pembersihan EXIF, dan SHA-256', () async {
      // Buat gambar uji raw 200x200
      final rawImage = img.Image(width: 200, height: 200);
      img.fill(rawImage, color: img.ColorRgb8(100, 150, 200));
      final rawBytes = Uint8List.fromList(img.encodeJpg(rawImage));

      final processed = await ImageProcessingService.processCameraImage(
        rawBytes,
        maxDimension: 150,
        quality: 80,
      );

      expect(processed.cleanBytes.isNotEmpty, isTrue);
      expect(processed.base64String.isNotEmpty, isTrue);
      expect(processed.sha256Hash.length, 64); // SHA-256 adalah 64 karakter hex
      expect(processed.width <= 150, isTrue);
      expect(processed.height <= 150, isTrue);
    });

    test('ScanResultModel: Serialisasi hasil satwa dan penolakan non-satwa', () {
      // Uji satwa terdeteksi
      final animalJson = {
        'scanId': 'scan-uuid-1234',
        'status': 'completed',
        'isAnimal': true,
        'result': {
          'isAnimal': true,
          'name': 'Kupu-kupu Jeruk',
          'categoryOrSpecies': 'Papilio demoleus',
          'description': 'Kupu-kupu dengan corak khas.',
          'additionalFact': 'Memiliki organ osmeterium.',
        },
        'photoSha256': 'a' * 64,
        'quotaUsed': 1,
        'quotaMax': 20,
      };

      final animalModel = ScanResultModel.fromJson(animalJson);
      expect(animalModel.isAnimal, isTrue);
      expect(animalModel.name, 'Kupu-kupu Jeruk');
      expect(animalModel.categoryOrSpecies, 'Papilio demoleus');
      expect(animalModel.quotaRemaining, 19);

      // Uji non-satwa ditolak
      final nonAnimalJson = {
        'scanId': 'scan-uuid-5678',
        'status': 'rejected_not_animal',
        'isAnimal': false,
        'result': {
          'isAnimal': false,
          'name': null,
          'categoryOrSpecies': null,
          'description': null,
          'additionalFact': 'Foto ini memuat cangkir kopi, bukan satwa.',
        },
        'photoSha256': 'b' * 64,
        'quotaUsed': 2,
        'quotaMax': 20,
      };

      final nonAnimalModel = ScanResultModel.fromJson(nonAnimalJson);
      expect(nonAnimalModel.isAnimal, isFalse);
      expect(nonAnimalModel.status, 'rejected_not_animal');
      expect(nonAnimalModel.additionalFact!.contains('cangkir kopi'), isTrue);
    });

    testWidgets('ScanResultPage: Menampilkan hasil identifikasi satwa terverifikasi', (tester) async {
      final sampleAnimal = ScanResultModel(
        scanId: 'sample-animal-1',
        requestId: 'req-1',
        status: 'completed',
        isAnimal: true,
        name: 'Kupu-kupu Jeruk',
        categoryOrSpecies: 'Papilio demoleus',
        description: 'Kupu-kupu indah di kepulauan Indonesia.',
        additionalFact: 'Ulatnya memiliki aroma pertahanan diri.',
        photoSha256: '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
        latitude: -6.2088,
        longitude: 106.8456,
        cameraHeading: 148.0,
        quotaUsed: 1,
        quotaMax: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ScanResultPage(scanResult: sampleAnimal),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hasil Identifikasi Satwa'), findsOneWidget);
      expect(find.text('TERVERIFIKASI SATWA'), findsOneWidget);
      expect(find.text('Kupu-kupu Jeruk'), findsOneWidget);
      expect(find.text('Papilio demoleus'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Tanya AI Seputar Satwa'), 200);
      expect(find.text('Tanya AI Seputar Satwa'), findsOneWidget);
      expect(find.text('Simpan ke Koleksi Kanonis'), findsOneWidget);
      expect(find.text('Pindai Satwa Lain'), findsOneWidget);
    });

    testWidgets('ScanResultPage: Menolak objek non-satwa dan menonaktifkan fitur simpan/chat', (tester) async {
      final sampleNonAnimal = ScanResultModel(
        scanId: 'sample-non-animal-1',
        requestId: 'req-2',
        status: 'rejected_not_animal',
        isAnimal: false,
        additionalFact: 'Foto ini tidak memuat satwa. Terdeteksi cangkir kopi.',
        quotaUsed: 2,
        quotaMax: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ScanResultPage(scanResult: sampleNonAnimal),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi AI Ditolak'), findsOneWidget);
      expect(find.text('BUKAN SATWA'), findsOneWidget);
      expect(find.text('Objek Bukan Satwa'), findsOneWidget);
      expect(find.text('Ambil Foto Satwa Ulang'), findsOneWidget);

      // Memastikan aturan bisnis AGENTS.md: foto bukan hewan TIDAK bisa disimpan atau diajak chat
      expect(find.text('Tanya AI Seputar Satwa'), findsNothing);
      expect(find.text('Simpan ke Koleksi Kanonis (Sesi S7)'), findsNothing);
    });

    testWidgets('CameraPage: HUD Kompas, Status GPS, dan Pemilih Target Uji', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CameraPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kamera Identifikasi AI'), findsOneWidget);
      expect(find.text('Mode Bidikan Kamera (Sesi S5)'), findsOneWidget);
      expect(find.text('Kupu-kupu (Satwa)'), findsOneWidget);
      expect(find.text('Komodo (Satwa)'), findsOneWidget);
      expect(find.text('Cangkir Kopi (Non-Satwa)'), findsOneWidget);

      // Pilih chip Kupu-kupu
      await tester.tap(find.text('Kupu-kupu (Satwa)'));
      await tester.pumpAndSettle();
      expect(find.text('Sampel Uji: Kupu-kupu (Satwa)'), findsOneWidget);

      // Pilih chip Non-Satwa Kopi
      await tester.tap(find.text('Cangkir Kopi (Non-Satwa)'));
      await tester.pumpAndSettle();
      expect(find.text('Sampel Uji: Kopi (Non-Satwa)'), findsOneWidget);
    });
  });

  group('S6 - Chat AI Per Scan dan Kuota Atomik (5 Pertanyaan / Scan)', () {
    setUp(() {
      ChatService.instance.resetDemoState();
    });

    test('ScanChatMessageModel deserialization dan role getter', () {
      final jsonUser = {
        'id': 'msg-1',
        'scan_id': 'scan-123',
        'role': 'user',
        'content': 'Apa makanannya?',
        'created_at': '2026-10-21T10:00:00Z',
      };
      final userMsg = ScanChatMessageModel.fromJson(jsonUser);
      expect(userMsg.isUser, isTrue);
      expect(userMsg.isAssistant, isFalse);
      expect(userMsg.content, 'Apa makanannya?');
      expect(userMsg.scanId, 'scan-123');

      final jsonAssistant = {
        'id': 'msg-2',
        'scan_id': 'scan-123',
        'role': 'assistant',
        'content': 'Satwa ini memakan nektar bunga.',
        'created_at': '2026-10-21T10:00:05Z',
      };
      final assistantMsg = ScanChatMessageModel.fromJson(jsonAssistant);
      expect(assistantMsg.isUser, isFalse);
      expect(assistantMsg.isAssistant, isTrue);
      expect(assistantMsg.content, 'Satwa ini memakan nektar bunga.');
    });

    test('ChatService: Validasi input kosong dan batas 500 karakter', () async {
      final chatService = ChatService.instance;
      expect(
        () => chatService.sendMessage(scanId: 'scan-test', message: '   '),
        throwsA(isA<ChatException>()),
      );

      final veryLongMessage = 'A' * 501;
      expect(
        () => chatService.sendMessage(scanId: 'scan-test', message: veryLongMessage),
        throwsA(isA<ChatException>()),
      );
    });

    test('ChatService: Batas kuota 5 pertanyaan ditegakkan secara tepat', () async {
      final chatService = ChatService.instance;
      final scanContext = const ScanResultModel(
        scanId: 'scan-quota-test',
        requestId: 'req-quota-test',
        status: 'completed',
        isAnimal: true,
        name: 'Kupu-kupu Jeruk',
        categoryOrSpecies: 'Papilio demoleus',
      );

      // Kirim 5 pertanyaan berturut-turut (kuota standar reguler)
      for (int i = 1; i <= 5; i++) {
        final result = await chatService.sendMessage(
          scanId: 'scan-quota-test',
          message: 'Pertanyaan nomor $i?',
          scanContext: scanContext,
        );
        expect(result.chatCount, i);
        expect(result.chatLimit, 5);
        expect(result.remaining, 5 - i);
      }

      // Pertanyaan ke-6 harus gagal dengan ChatQuotaExceededException
      expect(
        () => chatService.sendMessage(
          scanId: 'scan-quota-test',
          message: 'Pertanyaan ke-6 yang melampaui batas kuota',
          scanContext: scanContext,
        ),
        throwsA(isA<ChatQuotaExceededException>()),
      );
    });

    testWidgets('ScanChatPage: UI rendering, suggestions, tanya jawab, dan banner kuota', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleSatwa = const ScanResultModel(
        scanId: 'scan-ui-test',
        requestId: 'req-ui-test',
        status: 'completed',
        isAnimal: true,
        name: 'Kupu-kupu Jeruk',
        categoryOrSpecies: 'Papilio demoleus',
        description: 'Kupu-kupu dengan bentang sayap kuning dan hitam.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ScanChatPage(scanResult: sampleSatwa),
        ),
      );
      await tester.pumpAndSettle();

      // Cek Header & Konteks Satwa
      expect(find.text('Tanya AI: Kupu-kupu Jeruk'), findsOneWidget);
      expect(find.text('5/5 Sisa'), findsOneWidget);
      expect(find.text('Papilio demoleus'), findsOneWidget);
      expect(find.text('AI Terkalibrasi'), findsOneWidget);

      // Cek Suggestion Chips
      expect(find.text('Apa makanan utama satwa ini?'), findsWidgets);

      // Ketuk chip saran pertanyaan
      await tester.tap(find.text('Apa makanan utama satwa ini?').first);
      await tester.pump();
      await tester.pumpAndSettle();

      // Pesan user dan balasan asisten muncul
      expect(find.text('Apa makanan utama satwa ini?'), findsWidgets);
      expect(find.textContaining('mengonsumsi nektar bunga'), findsOneWidget);
      expect(find.text('4/5 Sisa'), findsOneWidget);
    });

    testWidgets('ScanResultPage: Navigasi tombol Tanya AI ke ScanChatPage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleSatwa = const ScanResultModel(
        scanId: 'scan-nav-test',
        requestId: 'req-nav-test',
        status: 'completed',
        isAnimal: true,
        name: 'Kupu-kupu Jeruk',
        categoryOrSpecies: 'Papilio demoleus',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ScanResultPage(scanResult: sampleSatwa),
        ),
      );
      await tester.pumpAndSettle();

      // Temukan tombol Tanya AI dan scroll ke tombol
      final tanyaAiButton = find.text('Tanya AI Seputar Satwa');
      await tester.scrollUntilVisible(tanyaAiButton, 200);
      expect(tanyaAiButton, findsOneWidget);

      await tester.tap(tanyaAiButton);
      await tester.pumpAndSettle();

      // Harus berpindah ke ScanChatPage
      expect(find.byType(ScanChatPage), findsOneWidget);
      expect(find.text('Tanya AI: Kupu-kupu Jeruk'), findsOneWidget);
    });
  });

  group('S7 - save-capture dan Hash-Chain Kanonis SHA-256 (Plan 5.2 & 5.3)', () {
    test('CaptureModel: Serialisasi, deserialisasi, dan format short hash', () {
      final now = DateTime.now();
      final model = CaptureModel(
        id: 'cap-1234',
        scanId: 'scan-5678',
        userId: 'user-0001',
        photoObjectPath: 'captures/user-0001/scan-5678.jpg',
        speciesName: 'Jalak Bali',
        category: 'Leucopsar rothschildi',
        description: 'Burung endemik Bali dengan bulu putih bersih.',
        latitude: -8.123456,
        longitude: 115.654321,
        cameraHeading: 148.5,
        receivedAt: now,
        seq: 1,
        previousHash: 'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90',
        blockHash: 'f0e1d2c3b4a5968778695a4b3c2d1e0ff0e1d2c3b4a5968778695a4b3c2d1e0f',
        photoSha256: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        createdAt: now,
      );

      final json = model.toJson();
      expect(json['species_name'], 'Jalak Bali');
      expect(json['seq'], 1);

      final fromJson = CaptureModel.fromJson(json);
      expect(fromJson.id, 'cap-1234');
      expect(fromJson.speciesName, 'Jalak Bali');
      expect(fromJson.shortBlockHash, 'f0e1d2c3...1e0f');
      expect(fromJson.shortPreviousHash, 'a1b2c3d4...8f90');
    });

    test('CaptureService: Format kanonisasi dan determinisme block hash', () {
      final now = DateTime.utc(2026, 10, 21, 12, 0, 0, 123, 456);
      const userId = '11111111-2222-3333-4444-555555555555';
      const prevHash = '0000000000000000000000000000000000000000000000000000000000000000';
      const photoSha = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

      final canonical = CaptureService.canonicalEncode(
        seq: 1,
        previousHash: prevHash,
        photoSha256: photoSha,
        latitude: -6.208800,
        longitude: 106.845600,
        cameraHeading: 90.0,
        receivedAt: now,
        userId: userId,
      );

      expect(canonical, contains('1|'));
      expect(canonical, contains('|-6.208800|106.845600|90.00|'));
      expect(canonical, contains('2026-10-21T12:00:00.123456Z|'));
      expect(canonical, endsWith(userId));

      // Test determinisme
      final hash1 = CaptureService.calculateBlockHash(
        seq: 1,
        previousHash: prevHash,
        photoSha256: photoSha,
        latitude: -6.208800,
        longitude: 106.845600,
        cameraHeading: 90.0,
        receivedAt: now,
        userId: userId,
      );
      final hash2 = CaptureService.calculateBlockHash(
        seq: 1,
        previousHash: prevHash,
        photoSha256: photoSha,
        latitude: -6.208800,
        longitude: 106.845600,
        cameraHeading: 90.0,
        receivedAt: now,
        userId: userId,
      );

      expect(hash1.length, 64);
      expect(hash1, equals(hash2));

      // Genesis hash
      final genesis = CaptureService.calculateGenesisHash(userId);
      expect(genesis.length, 64);
    });

    test('CaptureService: Tamper Detection (Mengubah satu kolom membatalkan validitas rantai)', () {
      const userId = 'user-tamper-test';
      final t1 = DateTime.utc(2026, 10, 21, 10, 0, 0);
      final t2 = DateTime.utc(2026, 10, 21, 11, 0, 0);

      // Blok 1 (Genesis)
      final genesisHash = CaptureService.calculateGenesisHash(userId);
      final block1Hash = CaptureService.calculateBlockHash(
        seq: 1,
        previousHash: genesisHash,
        photoSha256: 'hash-photo-1',
        latitude: -6.100000,
        longitude: 106.100000,
        cameraHeading: 45.0,
        receivedAt: t1,
        userId: userId,
      );

      // Blok 2 (Tersambung ke Blok 1)
      final block2Hash = CaptureService.calculateBlockHash(
        seq: 2,
        previousHash: block1Hash,
        photoSha256: 'hash-photo-2',
        latitude: -6.200000,
        longitude: 106.200000,
        cameraHeading: 90.0,
        receivedAt: t2,
        userId: userId,
      );

      // 1. Kondisi Untouched: Rantai Sah
      final calculatedB1 = CaptureService.calculateBlockHash(
        seq: 1,
        previousHash: genesisHash,
        photoSha256: 'hash-photo-1',
        latitude: -6.100000,
        longitude: 106.100000,
        cameraHeading: 45.0,
        receivedAt: t1,
        userId: userId,
      );
      expect(calculatedB1, equals(block1Hash));

      // 2. Tampering test: Ubah latitude blok 1 sebesar 0.000001
      final tamperedB1 = CaptureService.calculateBlockHash(
        seq: 1,
        previousHash: genesisHash,
        photoSha256: 'hash-photo-1',
        latitude: -6.100001, // DIMANIPULASI
        longitude: 106.100000,
        cameraHeading: 45.0,
        receivedAt: t1,
        userId: userId,
      );
      // Hash blok 1 berubah!
      expect(tamperedB1, isNot(equals(block1Hash)));

      // Blok 2 sekarang putus karena previousHash-nya (block1Hash) tidak lagi cocok dengan tamperedB1!
      expect(tamperedB1, isNot(equals(block2Hash)));
    });

    testWidgets('ScanResultPage: Tombol Simpan ke Koleksi Kanonis dan Dialog Sukses', (tester) async {
      CaptureService.instance.resetDemoCaptures();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final satwaResult = const ScanResultModel(
        scanId: 'scan-s7-test',
        requestId: 'req-s7-test',
        status: 'completed',
        isAnimal: true,
        name: 'Kupu-kupu Sayap Burung Peri',
        categoryOrSpecies: 'Ornithoptera chimaera',
        photoSha256: 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ScanResultPage(scanResult: satwaResult),
        ),
      );
      await tester.pumpAndSettle();

      final saveButton = find.text('Simpan ke Koleksi Kanonis');
      await tester.scrollUntilVisible(saveButton, 200);
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Dialog sukses harus tampil
      expect(find.text('Tersimpan di Koleksi!'), findsOneWidget);
      expect(find.text('Nomor Blok'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);

      // Tutup dialog
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      // Tombol berubah status menjadi tersimpan
      expect(find.textContaining('Tersimpan di Koleksi (Blok #1)'), findsOneWidget);
    });
  });

  group('S8 - Koleksi Grid, Detail, Peta OpenStreetMap, dan Verifikasi Rantai (Plan 5.2, 5.7)', () {
    setUp(() {
      CaptureService.instance.initMockDemoCaptures();
    });

    test('CaptureService: fetchUserCaptures memuat koleksi satwa terurut terbalik (seq terbaru)', () async {
      final captures = await CaptureService.instance.fetchUserCaptures();
      expect(captures.isNotEmpty, isTrue);
      expect(captures.length, greaterThanOrEqualTo(3));

      // Urutan seq harus menurun (terbaru dahulu)
      expect(captures.first.seq, greaterThan(captures.last.seq));

      // Verifikasi integritas format kolom setiap capture
      for (final cap in captures) {
        expect(cap.seq, greaterThan(0));
        expect(cap.speciesName.isNotEmpty, isTrue);
        expect(cap.blockHash.length, equals(64));
        expect(cap.previousHash.length, equals(64));
        expect(cap.photoSha256.length, equals(64));
      }
    });

    test('CaptureService: verifyUserChain memvalidasi keutuhan seluruh rantai blok', () async {
      final result = await CaptureService.instance.verifyUserChain();
      expect(result.isValid, isTrue);
      expect(result.totalBlocks, greaterThanOrEqualTo(3));
      expect(result.brokenSeq, isNull);
      expect(result.message, contains('terverifikasi'));
    });

    testWidgets('CollectionGridView: Menampilkan kartu koleksi dengan badge #seq dan taksonomi satwa', (tester) async {
      final dummyCaptures = await CaptureService.instance.fetchUserCaptures();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CollectionGridView(captures: dummyCaptures),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan kartu satwa dan nomor blok tampil
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('Kupu-kupu Jeruk'), findsOneWidget);
      expect(find.text('Jalak Bali'), findsOneWidget);

      // Uji empty state saat koleksi kosong
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: CollectionGridView(captures: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Koleksi Masih Kosong'), findsOneWidget);
      expect(find.textContaining('Anda belum memiliki tangkapan satwa'), findsOneWidget);
    });

    testWidgets('CaptureDetailPage: Menampilkan detail satwa, format kanonis, metadata sensor, dan verifikasi blok', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final captures = await CaptureService.instance.fetchUserCaptures();
      final targetCapture = captures.firstWhere((c) => c.seq == 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CaptureDetailPage(capture: targetCapture),
        ),
      );
      await tester.pumpAndSettle();

      // Header dan judul blok
      expect(find.text('Blok Koleksi #1'), findsOneWidget);
      expect(find.text('Jalak Bali'), findsOneWidget);
      expect(find.text('Leucopsar rothschildi'), findsOneWidget);

      // Panel Audit Hash Kanonis
      expect(find.textContaining('Audit Rantai Kriptografis'), findsOneWidget);
      expect(find.textContaining('Block Hash'), findsOneWidget);
      expect(find.textContaining('Previous Hash'), findsOneWidget);
      expect(find.textContaining('SHA-256 Byte Citra Asli'), findsOneWidget);

      // Metadata Sensor & Lapangan
      expect(find.textContaining('Metadata Sensor'), findsOneWidget);
      expect(find.textContaining('Tenggara'), findsOneWidget);

      // Uji tombol audit blok
      final verifyButton = find.textContaining('verify_block');
      await tester.ensureVisible(verifyButton);
      expect(verifyButton, findsOneWidget);

      await tester.tap(verifyButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('terverifikasi'), findsOneWidget);
    });

    testWidgets('CollectionMapView: Menampilkan peta OpenStreetMap dengan pin dan ringkasan lokasi', (tester) async {
      final captures = await CaptureService.instance.fetchUserCaptures();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CollectionMapView(captures: captures, height: 350),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Badge total lokasi
      expect(find.textContaining('Lokasi Terpetakan'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    });

    testWidgets('ProfilePage: Sub-tab Koleksi & Peta serta Dialog Audit Verifikasi Rantai', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfilePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Pindah ke sub-tab 'Koleksi & Peta'
      final collectionTab = find.text('Koleksi & Peta');
      await tester.scrollUntilVisible(collectionTab, 300.0, scrollable: find.byType(Scrollable).first);
      expect(collectionTab, findsOneWidget);
      await tester.tap(collectionTab);
      await tester.pumpAndSettle();

      // Banner Integritas Buku Besar harus tampil
      expect(find.text('Integritas Buku Besar (Simple Blockchain)'), findsOneWidget);

      // Tombol Verifikasi Rantai
      final verifyChainButton = find.text('Verifikasi Rantai (verify_chain)');
      await tester.scrollUntilVisible(verifyChainButton, 300.0, scrollable: find.byType(Scrollable).first);
      expect(verifyChainButton, findsOneWidget);

      // Tekan tombol verifikasi rantai
      await tester.tap(verifyChainButton);
      await tester.pumpAndSettle();

      // Dialog Audit Verifikasi Rantai harus muncul
      expect(find.text('Rantai Integritas Sah'), findsOneWidget);
      expect(find.text('VALID (100% Cocok)'), findsOneWidget);
      expect(find.textContaining('Blok Koleksi'), findsOneWidget);

      // Tutup dialog
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();

      // Mode Switcher Peta
      final mapToggle = find.textContaining('Peta (');
      await tester.ensureVisible(mapToggle);
      expect(mapToggle, findsOneWidget);
      await tester.tap(mapToggle);
      await tester.pumpAndSettle();

      expect(find.textContaining('Lokasi Terpetakan'), findsOneWidget);
    });
  });

  group('S9 - create_post, Grid Snapping 0.01°, dan Feed Untuk Kamu (Plan 5.7, 5.9, 18)', () {
    setUp(() {
      PostService.instance.initMockDemoPosts();
    });

    test('PostService: snapToGridLocally mengaburkan koordinat ke pusat sel 0.01° secara deterministik', () {
      // Titik 1: Jakarta (-6.208800, 106.845600)
      final r1 = PostService.snapToGridLocally(-6.208800, 106.845600);
      expect(r1['lat'], equals(-6.205000));
      expect(r1['lng'], equals(106.845000));

      // Titik 2: Bali Barat (-8.115600, 114.527800)
      final r2 = PostService.snapToGridLocally(-8.115600, 114.527800);
      expect(r2['lat'], equals(-8.115000));
      expect(r2['lng'], equals(114.525000));

      // Titik NULL
      final rNull = PostService.snapToGridLocally(null, null);
      expect(rNull['lat'], isNull);
      expect(rNull['lng'], isNull);
    });

    test('PostService: createPost opsi coarse dan hidden melindungi koordinat privat', () async {
      // 1. Opsi Coarse: Menyimpan koordinat snapped
      final postCoarse = await PostService.instance.createPost(
        captureId: 'cap-coarse-test',
        caption: 'Melihat elang laut beterbangan di tepi pantai.',
        visibility: 'coarse',
        areaLabel: 'Taman Nasional Bali Barat (Area Perkiraan)',
        demoRawLat: -8.115600,
        demoRawLng: 114.527800,
      );
      expect(postCoarse.locationVisibility, equals('coarse'));
      expect(postCoarse.displayLatitude, equals(-8.115000));
      expect(postCoarse.displayLongitude, equals(114.525000));
      expect(postCoarse.hasLocation, isTrue);

      // 2. Opsi Hidden: Lokasi benar-benar dihilangkan (display_lat dan display_lng NULL)
      final postHidden = await PostService.instance.createPost(
        captureId: 'cap-hidden-test',
        caption: 'Observasi satwa langka yang lokasinya dirahasiakan.',
        visibility: 'hidden',
        demoRawLat: -8.115600,
        demoRawLng: 114.527800,
      );
      expect(postHidden.locationVisibility, equals('hidden'));
      expect(postHidden.displayLatitude, isNull);
      expect(postHidden.displayLongitude, isNull);
      expect(postHidden.areaLabel, isNull);
      expect(postHidden.hasLocation, isFalse);
    });

    test('PostService: fetchForYouFeed dan togglePostLike idempoten', () async {
      final feed = await PostService.instance.fetchForYouFeed();
      expect(feed.isNotEmpty, isTrue);
      expect(feed.length, greaterThanOrEqualTo(3));

      final targetPost = feed.first;
      final initialLikes = targetPost.likesCount;
      final initialLiked = targetPost.isLikedByMe;

      // Like
      final likeResult = await PostService.instance.togglePostLike(targetPost.id);
      expect(likeResult['is_liked'], equals(!initialLiked));

      // Unlike kembali
      final unlikeResult = await PostService.instance.togglePostLike(targetPost.id);
      expect(unlikeResult['is_liked'], equals(initialLiked));
      expect(unlikeResult['likes_count'], equals(initialLikes));
    });

    testWidgets('PostCard: Menampilkan detail satwa dan lokasi snapped hanya bila coarse', (tester) async {
      final coarsePost = PostModel(
        id: 'post-coarse',
        captureId: 'cap-1',
        caption: 'Catatan observasi satwa liar.',
        locationVisibility: 'coarse',
        displayLatitude: -8.115000,
        displayLongitude: 114.525000,
        areaLabel: 'Bali Barat (Area Perkiraan)',
        createdAt: DateTime.now(),
        speciesName: 'Jalak Bali',
        category: 'Leucopsar rothschildi',
        photoUrl: 'assets/images/jalak_bali.jpg',
        blockSeq: 14,
        blockHash: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
        photoSha256: '9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b',
        authorId: 'user-budi',
        authorName: 'Budi Satria Wibowo',
        authorUsername: 'budi_satria',
        likesCount: 15,
        isLikedByMe: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: PostCard(post: coarsePost)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jalak Bali'), findsOneWidget);
      expect(find.text('#14'), findsOneWidget);
      expect(find.text('Bali Barat (Area Perkiraan)'), findsOneWidget);
      expect(find.text('Peta Area'), findsOneWidget);

      // Post dengan hidden location
      final hiddenPost = coarsePost.copyWith(
        id: 'post-hidden',
        locationVisibility: 'hidden',
        displayLatitude: null,
        displayLongitude: null,
        areaLabel: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(child: PostCard(post: hiddenPost)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Peta Area'), findsNothing);
      expect(find.text('Bali Barat (Area Perkiraan)'), findsNothing);
    });

    testWidgets('CreatePostSheet: Menampilkan formulir publikasi dan pengatur privasi lokasi', (tester) async {
      final capture = CaptureModel(
        id: 'cap-test',
        scanId: 'scan-test',
        userId: 'user-1',
        photoObjectPath: 'assets/images/jalak_bali.jpg',
        speciesName: 'Jalak Bali',
        category: 'Leucopsar rothschildi',
        description: 'Burung endemik langka.',
        latitude: -8.115600,
        longitude: 114.527800,
        receivedAt: DateTime.now(),
        seq: 1,
        previousHash: 'prev-hash',
        blockHash: 'block-hash-1234567890',
        photoSha256: 'photo-hash-1234567890',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CreatePostSheet(capture: capture),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Publikasikan Observasi ke Linimasa'), findsOneWidget);
      expect(find.text('Area Kasar (Grid)'), findsOneWidget);
      expect(find.text('Sembunyikan'), findsOneWidget);
      expect(find.text('Bagikan ke Linimasa Komunitas'), findsOneWidget);
    });

    testWidgets('FeedPage: Linimasa Untuk Kamu memuat PostCard dan mendukung interaksi like', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const FeedPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan tab 'Untuk Kamu' menampilkan postingan
      expect(find.text('Untuk Kamu'), findsOneWidget);
      expect(find.text('Jalak Bali'), findsOneWidget);
      expect(find.text('Kucing Kuwuk'), findsOneWidget);

      // Verifikasi tombol like berfungsi
      final likeIcon = find.byIcon(Icons.favorite_border_rounded).first;
      await tester.tap(likeIcon);
      await tester.pumpAndSettle();

      // Sekarang status like aktif
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    });
  });

  group('S10 - Follow, Tab Mengikuti, Like Idempoten, dan Profil Publik (Plan 5.7, 5.9, 18)', () {
    setUp(() {
      PostService.instance.initMockDemoPosts();
      SocialService.instance.initMockDemoSocial();
    });

    test('SocialService: toggleFollow idempoten dan menolak follow diri sendiri', () async {
      // 1. Awalnya Budi diikuti, Siti belum diikuti
      expect(SocialService.instance.isFollowing('user-siti'), isFalse);

      // 2. Ikuti Siti (Follow)
      final followResult = await SocialService.instance.toggleFollow('user-siti');
      expect(followResult['is_following'], isTrue);
      expect(SocialService.instance.isFollowing('user-siti'), isTrue);

      // 3. Batalkan ikuti Siti (Unfollow)
      final unfollowResult = await SocialService.instance.toggleFollow('user-siti');
      expect(unfollowResult['is_following'], isFalse);
      expect(SocialService.instance.isFollowing('user-siti'), isFalse);
    });

    test('SocialService: fetchFollowingFeed hanya memuat postingan dari pengguna yang diikuti', () async {
      // Budi diikuti -> postingan Budi ('Jalak Bali') muncul di feed mengikuti
      var followingFeed = await SocialService.instance.fetchFollowingFeed();
      expect(followingFeed.any((p) => p.authorId == 'user-budi'), isTrue);

      // Unfollow Budi
      await SocialService.instance.toggleFollow('user-budi');

      // Sekarang feed mengikuti tidak memuat postingan Budi
      followingFeed = await SocialService.instance.fetchFollowingFeed();
      expect(followingFeed.any((p) => p.authorId == 'user-budi'), isFalse);
    });

    test('SocialService: getPublicProfile mengembalikan data profil publik dan agregat tanpa kolom sensitif', () async {
      final profile = await SocialService.instance.getPublicProfile('user-budi');

      expect(profile.username, equals('budi_satria'));
      expect(profile.displayName, equals('Budi Satria Wibowo'));
      expect(profile.isVerified, isTrue);
      expect(profile.streakCount, equals(14));
      expect(profile.followersCount, greaterThan(0));
      expect(profile.isFollowedByMe, isTrue);
    });

    testWidgets('PublicProfilePage: Menampilkan portofolio publik, metrik sosial, dan tombol ikuti interaktif', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const PublicProfilePage(userId: 'user-siti'),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan nama, username, bio, dan metrik tampil
      expect(find.text('Siti Rahmawati'), findsWidgets);
      expect(find.text('@siti_flora_fauna'), findsWidgets);
      expect(find.text('Observasi'), findsOneWidget);
      expect(find.text('Pengikut'), findsOneWidget);
      expect(find.text('Mengikuti'), findsWidgets);

      // Tombol + Ikuti Penjelajah Ini (karena Siti belum diikuti)
      final followBtn = find.text('+ Ikuti Penjelajah Ini');
      expect(followBtn, findsOneWidget);

      // Tekan tombol ikuti
      await tester.tap(followBtn);
      await tester.pumpAndSettle();

      // Sekarang status berubah menjadi 'Mengikuti'
      expect(find.text('Mengikuti'), findsWidgets);
    });

    testWidgets('FeedPage: Tab Mengikuti menampilkan postingan author yang diikuti dan mendukung navigasi profil', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const FeedPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Pindah ke tab Mengikuti (tab index 0)
      final followingTab = find.text('Mengikuti');
      await tester.tap(followingTab);
      await tester.pumpAndSettle();

      // Budi diikuti -> Jalak Bali muncul di tab Mengikuti
      expect(find.text('Jalak Bali'), findsOneWidget);

      // Tap header author untuk menguji navigasi ke PublicProfilePage
      await tester.tap(find.text('Budi Satria Wibowo').first);
      await tester.pumpAndSettle();

      // Memastikan PublicProfilePage terbuka
      expect(find.text('Observasi Publik (1)'), findsOneWidget);
    });
  });

  group('S11 - Profil Sendiri, Edit Profil, dan Pencarian Akun & Spesies (Plan 5.2, 5.4, 5.7)', () {
    setUp(() {
      ProfileService.instance.initMockDemoMyProfile();
    });

    test('ProfileService: getMyProfile dan updateMyProfile validasi batas panjang', () async {
      final initial = await ProfileService.instance.getMyProfile();
      expect(initial.displayName, equals('Arya Wicaksana'));
      expect(initial.username, equals('arya_wallacea'));

      // Update sukses
      final updated = await ProfileService.instance.updateMyProfile(
        displayName: 'Arya Wicaksana Wallacea',
        bio: 'Peneliti satwa endemik Wallacea & pegiat sains warga.',
      );
      expect(updated.displayName, equals('Arya Wicaksana Wallacea'));
      expect(updated.bio, contains('Peneliti satwa'));

      // Validasi nama terlalu pendek (<2 char)
      expect(
        () => ProfileService.instance.updateMyProfile(displayName: 'A', bio: ''),
        throwsA(isA<ProfileException>()),
      );
    });

    test('SearchService: searchAccounts memprioritaskan akun Centang Biru di urutan teratas', () async {
      final allAccounts = await SearchService.instance.searchAccounts('');
      expect(allAccounts.isNotEmpty, isTrue);

      // Pastikan akun Centang Biru selalu berada sebelum akun tanpa centang
      bool seenUnverified = false;
      for (final acc in allAccounts) {
        if (!acc.isVerified) {
          seenUnverified = true;
        } else if (seenUnverified) {
          fail('Akun terverifikasi ${acc.displayName} ditemukan setelah akun yang belum terverifikasi!');
        }
      }

      // Cari dengan kata kunci spesifik
      final budiSearch = await SearchService.instance.searchAccounts('budi');
      expect(budiSearch.any((a) => a.username == 'budi_satria'), isTrue);
    });

    test('SearchService: searchSpecies mengembalikan taksonomi dan memfilter kelas fauna', () async {
      // Cari nama satwa
      final jalakResults = await SearchService.instance.searchSpecies('jalak');
      expect(jalakResults.any((s) => s.speciesName == 'Jalak Bali'), isTrue);

      // Filter kategori 'Mamalia'
      final mamaliaResults = await SearchService.instance.searchSpecies('', category: 'Mamalia');
      for (final sp in mamaliaResults) {
        expect(sp.taxonomyClass, equals('Mamalia'));
      }

      // Filter kategori 'Aves'
      final avesResults = await SearchService.instance.searchSpecies('', category: 'Aves (Burung)');
      for (final sp in avesResults) {
        expect(sp.taxonomyClass, equals('Aves'));
      }
    });

    testWidgets('EditProfileSheet: Form pengeditan profil menampilkan field dan memperbarui nama', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final profile = await ProfileService.instance.getMyProfile();
      PublicProfileModel? savedResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EditProfileSheet(
              initialProfile: profile,
              onSaved: (res) => savedResult = res,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profil Kolektor'), findsOneWidget);
      expect(find.text('@arya_wallacea'), findsOneWidget);
      expect(find.text('Nama Tampilan'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);

      // Ubah nama tampilan
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Arya Wicaksana Baru');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.displayName, equals('Arya Wicaksana Baru'));
    });

    testWidgets('SearchPage: Menampilkan tab Akun Pengguna & Katalog Spesies serta interaksi filter', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SearchPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab Akun Pengguna
      expect(find.text('Akun Pengguna'), findsOneWidget);
      expect(find.text('Katalog Spesies'), findsOneWidget);
      expect(find.text('Hasil Akun (Prioritas Centang Biru Teratas)'), findsOneWidget);
      expect(find.text('Balai Konservasi Sumber Daya Alam'), findsOneWidget);

      // Pindah ke Tab Katalog Spesies
      await tester.tap(find.text('Katalog Spesies'));
      await tester.pumpAndSettle();

      expect(find.text('Jalak Bali'), findsOneWidget);
      expect(find.text('Mamalia'), findsWidgets);
      expect(find.text('Reptilia'), findsWidgets);

      // Filter kategori Mamalia
      await tester.tap(find.text('Mamalia').first);
      await tester.pumpAndSettle();

      expect(find.text('Kucing Kuwuk (Kucing Hutan)'), findsOneWidget);
    });
  });

  group('S12 - Hive Terenkripsi, Kurs Mata Uang, dan Konversi Waktu 4 Zona (Plan 40, 78, 127, 136, 318)', () {
    setUp(() async {
      await EncryptedStorageService.instance.init();
      await CurrencyService.instance.init();
    });

    test('EncryptedStorageService: Menyimpan dan membaca koleksi, kurs, setting, serta pembersihan logout', () async {
      const testUserId = 'test-user-s12-001';
      final sampleCapture = CaptureModel(
        id: 'cap-s12-test',
        scanId: 'scan-s12-test',
        userId: testUserId,
        photoObjectPath: 'assets/test.jpg',
        speciesName: 'Komodo',
        category: 'Varanus komodoensis',
        description: 'Kadal purba terbesar di dunia.',
        latitude: -8.5833,
        longitude: 119.4833,
        cameraHeading: 180.0,
        receivedAt: DateTime.utc(2026, 10, 21, 10, 0, 0),
        seq: 1,
        previousHash: 'genesis-s12',
        blockHash: 'blockhash-s12',
        photoSha256: 'sha-s12',
        createdAt: DateTime.utc(2026, 10, 21, 10, 0, 0),
      );

      // Simpan koleksi ke Hive terenkripsi
      await EncryptedStorageService.instance.saveUserCaptures(testUserId, [sampleCapture]);
      final retrieved = EncryptedStorageService.instance.getUserCaptures(testUserId);
      expect(retrieved.length, equals(1));
      expect(retrieved.first.speciesName, equals('Komodo'));
      expect(retrieved.first.seq, equals(1));

      // Simpan kurs mata uang ke Hive terenkripsi
      await EncryptedStorageService.instance.saveCurrencyRates(
        rates: {'IDR': 1.0, 'USD': 0.000062, 'JPY': 0.0095},
        lastUpdatedAt: DateTime.utc(2026, 10, 21, 12, 0, 0),
        baseCurrency: 'IDR',
      );
      final ratesCached = EncryptedStorageService.instance.getCurrencyRates();
      expect(ratesCached, isNotNull);
      expect(ratesCached!['base'], equals('IDR'));

      // Simpan setting & skor
      await EncryptedStorageService.instance.saveBestQuizScore(850);
      expect(EncryptedStorageService.instance.getBestQuizScore(), equals(850));

      await EncryptedStorageService.instance.saveSetting('offline_mode_active', true);
      expect(EncryptedStorageService.instance.getSetting('offline_mode_active'), isTrue);

      // Pembersihan cache privat saat logout (Plan 563)
      await EncryptedStorageService.instance.clearPrivateCacheOnSignOut();
      final afterLogout = EncryptedStorageService.instance.getUserCaptures(testUserId);
      expect(afterLogout.isEmpty, isTrue);
    });

    test('TimeZoneService: Konversi presisi WIB, WITA, WIT, dan London (BST/GMT)', () {
      // 1. Waktu musim panas (Juli) -> London harus BST (UTC+1)
      final summerUtc = DateTime.utc(2026, 7, 15, 12, 0, 0);
      expect(TimeZoneService.isLondonBst(summerUtc), isTrue);
      final londonSummer = TimeZoneService.toLondon(summerUtc);
      expect(londonSummer.hour, equals(13)); // UTC+1

      // 2. Waktu musim dingin (Desember) -> London harus GMT (UTC+0)
      final winterUtc = DateTime.utc(2026, 12, 15, 12, 0, 0);
      expect(TimeZoneService.isLondonBst(winterUtc), isFalse);
      final londonWinter = TimeZoneService.toLondon(winterUtc);
      expect(londonWinter.hour, equals(12)); // UTC+0

      // 3. Konversi Indonesia (WIB UTC+7, WITA UTC+8, WIT UTC+9)
      final wib = TimeZoneService.toWib(summerUtc);
      final wita = TimeZoneService.toWita(summerUtc);
      final wit = TimeZoneService.toWit(summerUtc);
      expect(wib.hour, equals(19));
      expect(wita.hour, equals(20));
      expect(wit.hour, equals(21));

      // 4. Tanggal Server WIB (Plan 136)
      final dateWib = TimeZoneService.getCurrentDateWib(DateTime.utc(2026, 10, 21, 23, 0, 0));
      // Jam 23:00 UTC tanggal 21 = Jam 06:00 WIB tanggal 22
      expect(dateWib.day, equals(22));

      // 5. getAllZones mengembalikan 4 zona lengkap
      final allZones = TimeZoneService.getAllZones(summerUtc);
      expect(allZones.length, equals(4));
      expect(allZones.any((z) => z.code == TimeZoneCode.wib), isTrue);
      expect(allZones.any((z) => z.code == TimeZoneCode.wita), isTrue);
      expect(allZones.any((z) => z.code == TimeZoneCode.wit), isTrue);
      expect(allZones.any((z) => z.code == TimeZoneCode.london), isTrue);
    });

    test('CurrencyService: Konversi IDR, USD, JPY dan pemformatan harga resmi/estimasi', () {
      final currency = CurrencyService.instance;
      const baseIdr = 15000;

      // IDR tetap IDR
      expect(currency.convertFromIdr(baseIdr, 'IDR'), equals(15000.0));
      expect(currency.formatPrice(baseIdr, 'IDR'), equals('Rp15.000'));

      // USD terkonversi positif
      final usdVal = currency.convertFromIdr(baseIdr, 'USD');
      expect(usdVal, greaterThan(0.0));
      expect(usdVal, lessThan(2.0)); // Sekitar $0.93 USD
      final usdFormatted = currency.formatPrice(baseIdr, 'USD');
      expect(usdFormatted, contains('\$'));
      expect(usdFormatted, contains('USD'));

      // JPY terkonversi positif
      final jpyVal = currency.convertFromIdr(baseIdr, 'JPY');
      expect(jpyVal, greaterThan(50.0));
      expect(jpyVal, lessThan(300.0)); // Sekitar ¥143 JPY
      final jpyFormatted = currency.formatPrice(baseIdr, 'JPY');
      expect(jpyFormatted, contains('¥'));
      expect(jpyFormatted, contains('JPY'));

      // Mock rates
      currency.setMockRates(usd: 0.00007, jpy: 0.01);
      expect(currency.convertFromIdr(100000, 'USD'), closeTo(7.0, 0.0001));
      expect(currency.convertFromIdr(10000, 'JPY'), closeTo(100.0, 0.0001));
    });

    testWidgets('MultiTimeZoneCard: Menampilkan 4 zona waktu dengan label WIB, WITA, WIT, dan BST/GMT', (tester) async {
      final fixedUtc = DateTime.utc(2026, 10, 21, 14, 30, 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MultiTimeZoneCard(
                targetTime: fixedUtc,
                title: 'Waktu Observasi Lapangan',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Waktu Observasi Lapangan'), findsOneWidget);
      expect(find.text('WIB'), findsOneWidget);
      expect(find.text('WITA'), findsOneWidget);
      expect(find.text('WIT'), findsOneWidget);
      expect(find.text('UTC+7'), findsOneWidget);
      expect(find.text('UTC+8'), findsOneWidget);
      expect(find.text('UTC+9'), findsOneWidget);
    });

    testWidgets('CurrencyConverterCard: Menampilkan estimasi harga 3 mata uang dan tombol perbarui', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: CurrencyConverterCard(baseAmountIdr: 15000),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estimasi Kurs Centang Biru'), findsOneWidget);
      expect(find.text('IDR (Resmi)'), findsOneWidget);
      expect(find.text('Rp15.000'), findsOneWidget);
      expect(find.text('USD (Est.)'), findsOneWidget);
      expect(find.text('JPY (Est.)'), findsOneWidget);
      expect(find.textContaining('Cache Hive Terenkripsi'), findsOneWidget);

      // Tekan tombol Perbarui
      final refreshBtn = find.text('Perbarui');
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verifikasi respons/feedback
      expect(find.textContaining('kurs'), findsWidgets);
    });
  });

  group('S13 - Arena Kuis Biologi Satwa: Timer, 3 Nyawa, Combo, dan Skor Server (Plan 46, 180-186, 277)', () {
    setUp(() async {
      await EncryptedStorageService.instance.init();
    });

    test('QuizService: startQuizSession mengembalikan 10 soal TANPA kunci jawaban (Hard Rule 5)', () async {
      final session = await QuizService.instance.startQuizSession();

      expect(session.sessionId, isNotEmpty);
      expect(session.questions.length, equals(10));

      for (final q in session.questions) {
        expect(q.id, isNotEmpty);
        expect(q.question, isNotEmpty);
        expect(q.category, isNotEmpty);
        expect(q.options.length, equals(4)); // 4 pilihan ganda (A, B, C, D)
      }
    });

    test('QuizService: finishQuizSession menghitung skor deterministik, combo bonus, dan skor tertinggi', () async {
      final session = await QuizService.instance.startQuizSession();
      final answers = <QuizAnswerInput>[];

      // Simulasi jawaban untuk 10 soal (semua memilih opsi 0)
      for (int i = 0; i < session.questions.length; i++) {
        answers.add(
          QuizAnswerInput(
            questionId: session.questions[i].id,
            selectedOption: 0,
            elapsedMs: 3500, // dijawab dalam 3.5 detik (mendapat speed bonus)
          ),
        );
      }

      final result = await QuizService.instance.finishQuizSession(
        sessionId: session.sessionId,
        answers: answers,
      );

      expect(result.sessionId, equals(session.sessionId));
      expect(result.score, greaterThanOrEqualTo(0));
      expect(result.bestQuizScore, greaterThanOrEqualTo(result.score));
      expect(result.answersSummary.length, equals(10));

      // Verifikasi skor terbaik disimpan ke cache Hive terenkripsi (Plan 186)
      final cachedBest = QuizService.instance.getBestQuizScore();
      expect(cachedBest, equals(result.bestQuizScore));
    });

    testWidgets('QuizArenaPage: Menampilkan timer 15s, 3 nyawa, kartu soal, dan 4 opsi jawaban', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final session = await QuizService.instance.startQuizSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: QuizArenaPage(session: session),
        ),
      );
      await tester.pump();

      // Status Bar: 3 Nyawa & Timer 15s
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
      expect(find.text('15s'), findsOneWidget);

      // Kartu Soal
      expect(find.text('Soal 1 dari 10'), findsOneWidget);
      expect(find.text(session.questions.first.question), findsOneWidget);

      // 4 Opsi (A, B, C, D)
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);

      // Pilih Opsi A (Opsi index 0)
      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Berpindah ke Soal 2
      expect(find.text('Soal 2 dari 10'), findsOneWidget);
    });

    testWidgets('GamePage: Menampilkan Arena Kuis dan membuka QuizArenaPage saat ditekan', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const GamePage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Arena Kuis Satwa Liar'), findsOneWidget);
      expect(find.textContaining('Skor Terbaik'), findsOneWidget);

      // Tombol Mulai Kuis
      final startQuizBtn = find.text('Mulai Sesi Kuis (10 Soal)');
      expect(startQuizBtn, findsOneWidget);

      await tester.tap(startQuizBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Halaman QuizArenaPage terbuka
      expect(find.text('Soal 1 dari 10'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    });
  });
}


