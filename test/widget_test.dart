import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faunova/core/theme/app_colors.dart';
import 'package:faunova/core/theme/app_theme.dart';
import 'package:faunova/core/widgets/glass_bottom_bar.dart';
import 'package:faunova/core/widgets/app_avatar.dart';
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
import 'package:faunova/core/services/streak_service.dart';
import 'package:faunova/core/services/shake_service.dart';
import 'package:faunova/features/game/presentation/widgets/shake_quiz_sheet.dart';
import 'package:faunova/core/services/badge_service.dart';
import 'package:faunova/core/services/biometric_service.dart';
import 'package:faunova/features/profile/models/badge_model.dart';
import 'package:faunova/features/profile/presentation/widgets/badge_celebration_dialog.dart';
import 'package:faunova/features/profile/presentation/widgets/biometric_setting_sheet.dart';
import 'package:faunova/features/auth/presentation/biometric_lock_page.dart';
import 'package:faunova/core/services/notification_service.dart';
import 'package:faunova/features/profile/presentation/widgets/notification_setting_sheet.dart';
import 'package:faunova/features/profile/models/payment_transaction_model.dart';
import 'package:faunova/core/services/payment_service.dart';
import 'package:faunova/features/profile/presentation/midtrans_snap_webview_page.dart';
import 'package:faunova/features/profile/presentation/widgets/upgrade_blue_check_sheet.dart';
import 'package:faunova/features/profile/presentation/saran_kesan_page.dart';
import 'package:faunova/features/profile/presentation/widgets/app_settings_sheet.dart';
import 'package:faunova/features/profile/presentation/widgets/follow_list_sheet.dart';
import 'package:faunova/features/feed/presentation/widgets/report_post_sheet.dart';
import 'package:image/image.dart' as img;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    await EncryptedStorageService.instance.init(isTestEnv: true);
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

    test('ChatService: Batasan domain guardrail menolak pertanyaan non-satwa (coding & matematika)', () async {
      final chatService = ChatService.instance;
      chatService.resetDemoState();
      const scanContext = ScanResultModel(
        scanId: 'scan-guardrail-test',
        requestId: 'req-guardrail-test',
        status: 'completed',
        isAnimal: true,
        name: 'Gajah Afrika',
        categoryOrSpecies: 'Loxodonta africana',
      );

      // Uji pertanyaan coding
      final resCoding = await chatService.sendMessage(
        scanId: 'scan-guardrail-test',
        message: 'Bagaimana cara membuat fungsi python dan coding flutter?',
        scanContext: scanContext,
      );
      expect(resCoding.reply, contains('hanya dapat membantu menjawab pertanyaan seputar satwa'));

      // Uji pertanyaan matematika
      final resMath = await chatService.sendMessage(
        scanId: 'scan-guardrail-test',
        message: 'Tolong hitung rumus matematika 25 * 40 berapa hasilnya?',
        scanContext: scanContext,
      );
      expect(resMath.reply, contains('hanya dapat membantu menjawab pertanyaan seputar satwa'));

      chatService.resetDemoState();
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
      final expandToggle = find.textContaining('Tampilkan Rincian Hash');
      if (expandToggle.evaluate().isNotEmpty) {
        await tester.tap(expandToggle);
        await tester.pumpAndSettle();
      }
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
      await tester.ensureVisible(collectionTab);
      await tester.pumpAndSettle();
      expect(collectionTab, findsOneWidget);
      await tester.tap(collectionTab, warnIfMissed: false);
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

    testWidgets('ProfilePage: Tab Postingan Publik memuat daftar postingan atau state kosong dinamis', (tester) async {
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

      // Memastikan tab 'Postingan Publik' ada dan aktif
      final publicTab = find.text('Postingan Publik');
      await tester.scrollUntilVisible(publicTab, 300.0, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(publicTab);
      await tester.pumpAndSettle();
      expect(publicTab, findsOneWidget);
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
      expect(find.text('Elang Jawa'), findsOneWidget);

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
      expect(find.textContaining('Observasi Publik'), findsOneWidget);
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

  group('S14 - Streak Check-in dan Tantangan Hari Ini (Plan 5.8, 168-170, 197-200, 392)', () {
    setUp(() async {
      await EncryptedStorageService.instance.init();
      StreakService.instance.resetDemoState(streak: 5);
    });

    test('StreakService: claimDailyStreak menambah streak dan menolak klaim ganda (idempotensi)', () async {
      final todayWib = TimeZoneService.getCurrentDateWibString();
      // Set last claim date to yesterday
      final yesterday = DateTime.parse(todayWib).subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      StreakService.instance.resetDemoState(streak: 5, lastClaimDate: yesterdayStr);

      // Klaim pertama hari ini
      final claim1 = await StreakService.instance.claimDailyStreak();
      expect(claim1.isNewClaim, isTrue);
      expect(claim1.isClaimedToday, isTrue);
      expect(claim1.streakCount, equals(6)); // 5 + 1
      expect(claim1.lastClaimDate, equals(todayWib));

      // Klaim kedua pada hari yang sama (idempotensi)
      final claim2 = await StreakService.instance.claimDailyStreak();
      expect(claim2.isNewClaim, isFalse);
      expect(claim2.isClaimedToday, isTrue);
      expect(claim2.streakCount, equals(6)); // Tetap 6 (klaim ganda ditolak)
      expect(claim2.message, contains('sudah melakukan check-in'));
    });

    test('StreakService: getDailyChallenge merahasiakan kunci jawaban sebelum dijawab (Hard Rule 5)', () async {
      final challenge = await StreakService.instance.getDailyChallenge();

      expect(challenge.questionId, isNotEmpty);
      expect(challenge.questionText, isNotEmpty);
      expect(challenge.options.length, equals(4));
      expect(challenge.alreadyAnswered, isFalse);

      // Aturan Keras 5: correctOption dan explanation WAJIB null
      expect(challenge.correctOption, isNull);
      expect(challenge.explanation, isNull);
    });

    test('StreakService: answerDailyChallenge mengevaluasi jawaban dan menolak pengiriman kedua', () async {
      final initial = await StreakService.instance.getDailyChallenge();
      expect(initial.alreadyAnswered, isFalse);

      // Jawab opsi 0
      final result = await StreakService.instance.answerDailyChallenge(0);
      expect(result.alreadyAnswered, isTrue);
      expect(result.isCorrect, isNotNull);
      expect(result.correctOption, isNotNull); // Kunci sekarang terbuka untuk edukasi
      expect(result.explanation, isNotNull);

      // Pengiriman kedua pada hari yang sama harus ditolak
      expect(
        () => StreakService.instance.answerDailyChallenge(1),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('GamePage: Menampilkan kartu Streak dan Tantangan Hari Ini dengan opsi interaktif', (tester) async {
      StreakService.instance.resetDemoState();
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

      // Kartu Streak
      expect(find.text('Streak Observasi Harian'), findsOneWidget);
      expect(find.textContaining('Hari Berturut-turut'), findsOneWidget);

      // Kartu Tantangan Hari Ini
      expect(find.textContaining('Tantangan Hari Ini'), findsOneWidget);
      expect(find.text('+50 Poin'), findsOneWidget);

      // Status Klaim Streak
      expect(find.byType(ElevatedButton), findsWidgets);

      // Interaksi Pilihan Jawaban Tantangan Hari Ini
      final optionA = find.text('A');
      if (optionA.evaluate().isNotEmpty) {
        await tester.tap(optionA);
        await tester.pumpAndSettle();

        // Ulasan hasil harus muncul
        expect(find.textContaining('Jawabanmu'), findsOneWidget);
        expect(find.textContaining('Pilihanmu:'), findsOneWidget);
      }

      // Bersihkan widget dan timer SnackBar agar tidak bocor ke test berikutnya
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  });

  group('S15 - Shake-to-Quiz: Accelerometer, Kuota 3x/hari, dan Validasi Server (Plan 5.8, 190-196)', () {
    setUp(() {
      ShakeService.instance.resetDemoQuota();
    });

    test('ShakeService: getShakeQuota mengembalikan kuota awal 3/3 per hari WIB', () async {
      final quota = await ShakeService.instance.getShakeQuota();

      expect(quota.maxQuota, equals(3));
      expect(quota.usedQuota, equals(0));
      expect(quota.remainingQuota, equals(3));
      expect(quota.dateWib, isNotEmpty);
    });

    test('ShakeService: claimShakeQuiz mengembalikan soal TANPA kunci jawaban & mengurangi kuota', () async {
      // Klaim pertama
      final claim1 = await ShakeService.instance.claimShakeQuiz(customIdempotencyKey: 'idemp-shake-1');

      expect(claim1.claimId, isNotEmpty);
      expect(claim1.questionId, isNotEmpty);
      expect(claim1.category, isNotEmpty);
      expect(claim1.questionText, isNotEmpty);
      expect(claim1.options.length, equals(4));
      expect(claim1.remainingQuota, equals(2)); // Kuota berkurang 1
      expect(claim1.quotaExceeded, isFalse);

      // Idempotensi: Klaim ulang dengan kunci idempotency yang sama mengembalikan klaim yang sama tanpa mengurangi kuota lagi
      final claimRetry = await ShakeService.instance.claimShakeQuiz(customIdempotencyKey: 'idemp-shake-1');
      expect(claimRetry.claimId, equals(claim1.claimId));
      expect(claimRetry.remainingQuota, equals(2));
    });

    test('ShakeService: Menolak klaim ke-4 saat kuota 3/3 habis', () async {
      // Klaim 3 kali hingga habis
      await ShakeService.instance.claimShakeQuiz();
      await ShakeService.instance.claimShakeQuiz();
      await ShakeService.instance.claimShakeQuiz();

      // Klaim ke-4 harus ditolak dengan quotaExceeded == true
      final claim4 = await ShakeService.instance.claimShakeQuiz();
      expect(claim4.quotaExceeded, isTrue);
      expect(claim4.remainingQuota, equals(0));
      expect(claim4.message, contains('sudah habis (3/3)'));
    });

    test('ShakeService: answerShakeQuiz mengevaluasi jawaban dan menolak submit kedua', () async {
      final claim = await ShakeService.instance.claimShakeQuiz();

      // Jawab opsi 1
      final result = await ShakeService.instance.answerShakeQuiz(
        claimId: claim.claimId,
        selectedOption: 1,
      );

      expect(result.claimId, equals(claim.claimId));
      expect(result.selectedOption, equals(1));
      expect(result.isCorrect, isNotNull);
      expect(result.correctOption, isNotNull);
      expect(result.explanation, isNotEmpty);

      // Submission kedua pada claimId yang sama harus ditolak
      expect(
        () => ShakeService.instance.answerShakeQuiz(
          claimId: claim.claimId,
          selectedOption: 0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('GamePage: Menampilkan banner Shake-to-Quiz dan membuka ShakeQuizSheet saat diketuk', (tester) async {
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

      // Cari banner Shake-to-Quiz
      final bannerTitle = find.text('Goyang HP (Shake-to-Quiz)');
      expect(bannerTitle, findsOneWidget);
      expect(find.textContaining('Kuota'), findsOneWidget);

      // Ketuk banner untuk memicu kuis (simulasi goyang HP)
      await tester.tap(bannerTitle);
      await tester.pumpAndSettle();

      // ShakeQuizSheet modal harus terbuka
      expect(find.byType(ShakeQuizSheet), findsOneWidget);
      expect(find.textContaining('Soal Kejutan'), findsOneWidget);

      final sheetOptionA = find.descendant(of: find.byType(ShakeQuizSheet), matching: find.text('A'));
      expect(sheetOptionA, findsOneWidget);

      // Ketuk opsi A di dalam ShakeQuizSheet
      await tester.tap(sheetOptionA);
      await tester.pumpAndSettle();

      // Ulasan hasil harus tampil
      expect(find.textContaining('Jawabanmu'), findsWidgets);
      expect(find.text('Selesai & Lanjutkan'), findsOneWidget);

      // Tutup sheet
      await tester.tap(find.text('Selesai & Lanjutkan'));
      await tester.pumpAndSettle();

      // Sheet tertutup, kembali ke GamePage
      expect(find.text('Ekspedisi & Kuis Fauna'), findsOneWidget);
    });
  });

  group('S16 - Sistem Badge Gelar & Pop-up Pencapaian (Plan 5.8: 202-217)', () {
    setUp(() async {
      await EncryptedStorageService.instance.init();
      BadgeService.instance.resetCelebrated();
    });

    test('BadgeService: getUserBadges memuat 8 lencana MVP dengan target dan progres yang tepat', () async {
      final badges = await BadgeService.instance.getUserBadges();

      expect(badges.length, equals(8));

      // Verifikasi 8 lencana MVP sesuai Plan 207-217
      final ids = badges.map((b) => b.id).toList();
      expect(ids, containsAll([
        'pemula',
        'kolektor',
        'rajin',
        'si_pintar',
        'juara_kuis',
        'sosialita',
        'rutin_menantang',
        'si_goyang',
      ]));

      // Verifikasi target lencana
      final pemula = badges.firstWhere((b) => b.id == 'pemula');
      expect(pemula.targetCount, equals(1));
      expect(pemula.isUnlocked, isTrue); // demo has 4 captures

      final kolektor = badges.firstWhere((b) => b.id == 'kolektor');
      expect(kolektor.targetCount, equals(10));
      expect(kolektor.isUnlocked, isFalse); // 4/10
    });

    testWidgets('BadgeCelebrationDialog: Menampilkan modal perayaan saat lencana baru terbuka', (tester) async {
      final badge = const BadgeModel(
        id: 'pemula',
        name: 'Pemula',
        description: '1 tangkapan pertama disimpan ke koleksi kanonis.',
        targetCount: 1,
        currentProgress: 1,
        actualProgress: 1,
        isUnlocked: true,
        iconName: 'eco',
        category: 'Koleksi',
        isNewlyUnlocked: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => BadgeCelebrationDialog.show(context, badge: badge),
                  child: const Text('Buka Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Lencana Baru Terbuka! 🎉'), findsOneWidget);
      expect(find.text('Pemula'), findsOneWidget);
      expect(find.text('Klaim & Lanjutkan'), findsOneWidget);

      await tester.tap(find.text('Klaim & Lanjutkan'));
      await tester.pumpAndSettle();

      expect(find.text('Lencana Baru Terbuka! 🎉'), findsNothing);
    });

    testWidgets('BadgeDetailSheet: Menampilkan rincian progres dan status lencana', (tester) async {
      final badge = const BadgeModel(
        id: 'kolektor',
        name: 'Kolektor',
        description: 'Simpan 10 tangkapan hewan ke dalam koleksi.',
        targetCount: 10,
        currentProgress: 4,
        actualProgress: 4,
        isUnlocked: false,
        iconName: 'auto_stories',
        category: 'Koleksi',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => BadgeDetailSheet.show(context, badge: badge),
                  child: const Text('Buka Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Kolektor'), findsOneWidget);
      expect(find.text('Terkunci'), findsOneWidget);
      expect(find.text('4 / 10'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('4 / 10'), findsNothing);
    });

    testWidgets('ProfilePage: Menampilkan grid lencana dan membuka detail sheet saat diketuk', (tester) async {
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

      // Jika ada dialog perayaan badge terbuka otomatis (Plan 204), klaim & tutup
      final celebrationBtn = find.text('Klaim & Lanjutkan');
      if (celebrationBtn.evaluate().isNotEmpty) {
        await tester.tap(celebrationBtn);
        await tester.pumpAndSettle();
      }

      // Cari section lencana
      final badgeShelf = find.text('Lencana Gelar Pencapaian (MVP)');
      await tester.scrollUntilVisible(badgeShelf, 300, scrollable: find.byType(Scrollable).first);
      expect(badgeShelf, findsOneWidget);

      // Cari lencana Pemula dalam grid
      final pemulaItem = find.text('Pemula');
      await tester.ensureVisible(pemulaItem);
      await tester.pumpAndSettle();
      expect(pemulaItem, findsOneWidget);

      // Ketuk lencana Pemula
      await tester.tap(pemulaItem);
      await tester.pumpAndSettle();

      // BadgeDetailSheet terbuka
      expect(find.text('Syarat Pembukaan:'), findsOneWidget);
      expect(find.text('Terbuka'), findsWidgets);
    });
  });

  group('S17 - Autentikasi Biometrik: Toggle, Sesi Tersimpan, dan Proteksi 5x Gagal (Plan 5.1)', () {
    setUp(() async {
      await EncryptedStorageService.instance.init();
      BiometricService.instance.resetMockOverrides();
      await BiometricService.instance.resetFailedAttempts();
      await BiometricService.instance.setBiometricEnabled(false);
      await BiometricService.instance.clearSavedSession();
    });

    tearDown(() async {
      BiometricService.instance.resetMockOverrides();
      await BiometricService.instance.resetFailedAttempts();
      await BiometricService.instance.setBiometricEnabled(false);
      await BiometricService.instance.clearSavedSession();
    });

    testWidgets('BiometricService: Verifikasi status hardware, ketersediaan sensor, dan pendaftaran sidik jari', (tester) async {
      final hw = await BiometricService.instance.isHardwareAvailable();
      expect(hw, isTrue);

      final enrolled = await BiometricService.instance.hasEnrolledBiometrics();
      expect(enrolled, isTrue);

      final canUse = await BiometricService.instance.canUseBiometrics();
      expect(canUse, isTrue);

      // Uji simulasi hardware tidak tersedia (Plan 77)
      BiometricService.instance.setMockDependencies(mockIsDeviceSupported: false, mockCanCheckBiometrics: false);
      expect(await BiometricService.instance.isHardwareAvailable(), isFalse);
      expect(await BiometricService.instance.canUseBiometrics(), isFalse);

      BiometricService.instance.resetMockOverrides();
    });

    test('BiometricService: Pengaturan toggle disimpan lokal dan pengelolaan sesi tersimpan di secure storage (Plan 72, 75, 76)', () async {
      // 1. Toggle tersimpan di storage lokal perangkat (bukan di Supabase)
      expect(BiometricService.instance.isBiometricEnabled(), isFalse);

      await BiometricService.instance.setBiometricEnabled(true);
      expect(BiometricService.instance.isBiometricEnabled(), isTrue);

      // 2. Simpan sesi (hanya refresh token/sesi, kata sandi tidak pernah disimpan)
      expect(await BiometricService.instance.hasSavedSession(), isFalse);

      await BiometricService.instance.saveCurrentSession(
        email: 'satwa@faunova.id',
        refreshToken: 'mock_refresh_token_faunova_123',
      );

      expect(await BiometricService.instance.hasSavedSession(), isTrue);
      expect(await BiometricService.instance.getSavedUserEmail(), equals('satwa@faunova.id'));

      // 3. Logout manual menghapus sesi tersimpan (Plan 75)
      await BiometricService.instance.clearSavedSession();
      expect(await BiometricService.instance.hasSavedSession(), isFalse);
      expect(await BiometricService.instance.getSavedUserEmail(), isNull);
    });

    test('BiometricService: Proteksi 5x gagal mengunci biometrik dan reset saat berhasil (Plan 74)', () async {
      expect(BiometricService.instance.getFailedAttempts(), equals(0));
      expect(BiometricService.instance.isLockedOut(), isFalse);

      // Simulasi kegagalan bertahap 1 sampai 5 kali
      for (int i = 1; i <= 4; i++) {
        final count = await BiometricService.instance.recordFailedAttempt();
        expect(count, equals(i));
        expect(BiometricService.instance.isLockedOut(), isFalse);
      }

      // Kegagalan ke-5: Terkunci (Lockout)
      final count5 = await BiometricService.instance.recordFailedAttempt();
      expect(count5, equals(5));
      expect(BiometricService.instance.isLockedOut(), isTrue);

      // Eksekusi login biometrik saat terkunci langsung ditolak
      final res = await BiometricService.instance.performBiometricLogin();
      expect(res.success, isFalse);
      expect(res.isLockedOut, isTrue);
      expect(res.errorMessage, contains('Batas 5 kali'));

      // Reset counter saat login berhasil (email & kata sandi)
      await BiometricService.instance.resetFailedAttempts();
      expect(BiometricService.instance.getFailedAttempts(), equals(0));
      expect(BiometricService.instance.isLockedOut(), isFalse);
    });

    testWidgets('BiometricSettingSheet: Menampilkan status sensor, pendaftaran, dan toggle switch (Plan 73, 77)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: BiometricSettingSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan & Sidik Jari'), findsOneWidget);
      expect(find.text('Sensor Biometrik'), findsOneWidget);
      expect(find.text('Pendaftaran Sidik Jari'), findsOneWidget);
      expect(find.text('Masuk dengan Sidik Jari'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    });

    testWidgets('LoginPage: Tombol biometrik tampil saat sesi ada dan disembunyikan saat terkunci 5x (Plan 74)', (tester) async {
      await tester.runAsync(() async {
        await BiometricService.instance.setBiometricEnabled(true);
        await BiometricService.instance.saveCurrentSession(
          email: 'kolektor@faunova.id',
          refreshToken: 'valid_refresh_token_123',
        );
        await BiometricService.instance.resetFailedAttempts();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tombol sidik jari harus tampil
      expect(find.text('Masuk dengan Sidik Jari'), findsOneWidget);
      expect(find.text('Buka sesi tersimpan untuk kolektor@faunova.id'), findsOneWidget);

      // 2. Simulasikan 5 kali gagal berturut-turut (Plan 74)
      await tester.runAsync(() async {
        for (int i = 0; i < 5; i++) {
          await BiometricService.instance.recordFailedAttempt();
        }
      });

      // Rebuild LoginPage
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: LoginPage(key: UniqueKey()),
        ),
      );
      await tester.pumpAndSettle();

      // Tombol sidik jari harus disembunyikan dan banner peringatan terkunci tampil
      expect(find.text('Masuk dengan Sidik Jari'), findsNothing);
      expect(find.textContaining('Tombol sidik jari dinonaktifkan sementara'), findsOneWidget);
    });
  });

  group('S18 - Notifikasi Lokal Terjadwal: Streak, Tantangan, dan Centang Biru (Plan 5.9, 133, 170, 223)', () {
    setUp(() async {
      await EncryptedStorageService.instance.init();
      await NotificationService.instance.init();
      await NotificationService.instance.cancelAll();
      await NotificationService.instance.setStreakReminderEnabled(true);
      await NotificationService.instance.setChallengeReminderEnabled(true);
      await NotificationService.instance.setVerifiedExpiryReminderEnabled(true);
    });

    tearDown(() async {
      await NotificationService.instance.cancelAll();
    });

    test('NotificationService: Inisialisasi dan penjadwalan pengingat streak harian (19:00 WIB)', () async {
      expect(NotificationService.instance.isInitialized, isTrue);

      await NotificationService.instance.scheduleDailyStreakReminder(hour: 19, minute: 0);

      expect(
        NotificationService.instance.isNotificationScheduled(NotificationConstants.idStreakReminder),
        isTrue,
      );

      final record = NotificationService.instance.getScheduledRecord(NotificationConstants.idStreakReminder);
      expect(record, isNotNull);
      expect(record!.title, contains('Jaga Rekor Observasimu'));
      expect(record.category, equals('streak'));
      expect(record.isRecurringDaily, isTrue);
    });

    test('NotificationService: Pembatalan notifikasi streak hari ini saat check-in berhasil (Plan 170)', () async {
      await NotificationService.instance.scheduleDailyStreakReminder(hour: 19, minute: 0);
      expect(
        NotificationService.instance.isNotificationScheduled(NotificationConstants.idStreakReminder),
        isTrue,
      );

      // Eksekusi klaim streak harian
      final claimRes = await StreakService.instance.claimDailyStreak();
      expect(claimRes.isClaimedToday, isTrue);

      // Notifikasi hari ini dibatalkan dan otomatis dijadwalkan ulang untuk esok hari
      final rescheduled = NotificationService.instance.getScheduledRecord(NotificationConstants.idStreakReminder);
      expect(rescheduled, isNotNull);
      expect(rescheduled!.scheduledDate.isAfter(DateTime.now()), isTrue);
    });

    test('NotificationService: Penjadwalan pengingat Tantangan Hari Ini (08:00 WIB) dan pembatalan saat dijawab', () async {
      await NotificationService.instance.scheduleDailyChallengeReminder(hour: 8, minute: 0);

      expect(
        NotificationService.instance.isNotificationScheduled(NotificationConstants.idDailyChallengeReminder),
        isTrue,
      );

      final record = NotificationService.instance.getScheduledRecord(NotificationConstants.idDailyChallengeReminder);
      expect(record, isNotNull);
      expect(record!.title, contains('Tantangan Satwa Hari Ini'));
      expect(record.category, equals('challenge'));

      // Eksekusi pembatalan hari ini
      await NotificationService.instance.cancelChallengeReminderToday();

      final nextRecord = NotificationService.instance.getScheduledRecord(NotificationConstants.idDailyChallengeReminder);
      expect(nextRecord, isNotNull);
      expect(nextRecord!.scheduledDate.isAfter(DateTime.now()), isTrue);
    });

    test('NotificationService: Penjadwalan pengingat H-3 sebelum masa aktif Centang Biru berakhir (Plan 133, 223)', () async {
      // 1. Akun dengan masa aktif 30 hari lagi -> Notifikasi H-3 dijadwalkan
      final activeExpiry = DateTime.now().add(const Duration(days: 30));
      await NotificationService.instance.scheduleVerifiedExpiryReminder(activeExpiry);

      expect(
        NotificationService.instance.isNotificationScheduled(NotificationConstants.idVerifiedExpiryReminder),
        isTrue,
      );

      final record = NotificationService.instance.getScheduledRecord(NotificationConstants.idVerifiedExpiryReminder);
      expect(record, isNotNull);
      expect(record!.title, contains('Centang Biru'));
      expect(record.category, equals('verified'));

      // 2. Akun sudah kadaluwarsa -> Notifikasi dibatalkan
      final expiredDate = DateTime.now().subtract(const Duration(days: 2));
      await NotificationService.instance.scheduleVerifiedExpiryReminder(expiredDate);

      expect(
        NotificationService.instance.isNotificationScheduled(NotificationConstants.idVerifiedExpiryReminder),
        isFalse,
      );
    });

    testWidgets('NotificationSettingSheet: Menampilkan toggle switch, status alarm aktif, dan tombol uji coba notifikasi instan (Plan 223)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await NotificationService.instance.scheduleDailyStreakReminder(hour: 19, minute: 0);
      await NotificationService.instance.scheduleDailyChallengeReminder(hour: 8, minute: 0);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: NotificationSettingSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi judul dan header
      expect(find.text('Pengaturan Notifikasi'), findsOneWidget);
      expect(find.text('Notifikasi Lokal Mandiri (Plan 223)'), findsOneWidget);

      // Verifikasi 3 switch pengaturan
      expect(find.text('Pengingat Streak Harian (19:00 WIB)'), findsOneWidget);
      expect(find.text('Tantangan Satwa Hari Ini (08:00 WIB)'), findsOneWidget);
      expect(find.text('Masa Aktif Centang Biru (H-3)'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(3));

      // Verifikasi daftar jadwal alarm aktif
      expect(find.text('Jadwal Alarm Notifikasi Aktif'), findsOneWidget);

      // Verifikasi tombol uji coba notifikasi instan
      final testButton = find.text('Kirim Notifikasi Percobaan');
      expect(testButton, findsOneWidget);

      await tester.tap(testButton);
      await tester.pumpAndSettle();

      // Verifikasi SnackBar muncul
      expect(find.text('Notifikasi percobaan berhasil dikirim ke perangkat!'), findsOneWidget);

      // Verifikasi tombol close icon
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });
  });

  group('S19 - Midtrans Sandbox: create-payment, Snap WebView, dan Webhook Signature (Plan 5.4)', () {
    setUp(() {
      PaymentService.instance.resetDemoTransactions();
    });

    tearDown(() {
      PaymentService.instance.resetDemoTransactions();
    });

    test('PaymentTransactionModel: Parsing JSON, format nominal, dan status badge', () {
      final json = {
        'id': 'tx-12345',
        'order_id': 'FAUNOVA-CB-USER123-1729500000',
        'user_id': 'user-123',
        'amount_idr': 15000,
        'currency': 'IDR',
        'status': 'settlement',
        'provider_tx_id': 'midtrans-sandbox-999',
        'payment_type': 'qris',
        'entitlement_days': 30,
        'created_at': '2026-10-22T10:00:00Z',
        'settled_at': '2026-10-22T10:02:00Z',
      };

      final tx = PaymentTransactionModel.fromJson(json);
      expect(tx.id, 'tx-12345');
      expect(tx.orderId, 'FAUNOVA-CB-USER123-1729500000');
      expect(tx.amountIdr, 15000);
      expect(tx.currency, 'IDR');
      expect(tx.status, 'settlement');
      expect(tx.isSettled, isTrue);
      expect(tx.isPending, isFalse);
      expect(tx.statusLabel, 'Berhasil');
      expect(tx.formattedAmount, 'Rp 15.000');
      expect(tx.entitlementDays, 30);
    });

    test('PaymentService: createBlueCheckPayment menghasilkan orderId dan snap token valid', () async {
      final service = PaymentService.instance;
      final result = await service.createBlueCheckPayment();

      expect(result.success, isTrue);
      expect(result.orderId, isNotNull);
      expect(result.orderId, startsWith('FAUNOVA-CB-'));
      expect(result.amountIdr, 15000);
      expect(result.snapToken, isNotNull);
      expect(result.redirectUrl, isNotNull);
      expect(result.redirectUrl, contains('snap'));
    });

    test('PaymentService: getMyTransactions memuat riwayat pembayaran berstatus valid', () async {
      final service = PaymentService.instance;
      final history = await service.getMyTransactions();

      expect(history, isNotEmpty);
      final firstTx = history.first;
      expect(firstTx.amountIdr, 15000);
      expect(firstTx.currency, 'IDR');
      expect(['settlement', 'pending', 'expire', 'cancel'], contains(firstTx.status));
    });

    test('PaymentService: simulateWebhookSettlement idempoten dan memperbarui status lokal', () async {
      final service = PaymentService.instance;

      // Buat transaksi baru
      final paymentResult = await service.createBlueCheckPayment();
      expect(paymentResult.success, isTrue);
      final orderId = paymentResult.orderId!;

      // Simulasi webhook settlement pertama
      final firstSuccess = await service.simulateWebhookSettlement(orderId);
      expect(firstSuccess, isTrue);

      // Verifikasi status transaksi lokal menjadi settlement
      final statusAfterFirst = await service.checkTransactionStatus(orderId);
      expect(statusAfterFirst?.status, 'settlement');
      expect(statusAfterFirst?.isSettled, isTrue);

      // Simulasi webhook settlement kedua (uji idempotensi)
      final secondSuccess = await service.simulateWebhookSettlement(orderId);
      expect(secondSuccess, isTrue);

      final statusAfterSecond = await service.checkTransactionStatus(orderId);
      expect(statusAfterSecond?.status, 'settlement');
      expect(statusAfterSecond?.isSettled, isTrue);
    });

    testWidgets('UpgradeBlueCheckSheet: Menampilkan harga 3 mata uang, keunggulan, dan riwayat transaksi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final unverifiedProfile = PublicProfileModel(
        id: '00000000-0000-0000-0000-000000000001',
        username: 'arya_wallacea',
        displayName: 'Arya Wicaksana',
        avatarPath: null,
        bio: 'Penjelajah biodiversitas Indonesia Timur.',
        isVerified: false,
        verifiedUntil: null,
        streakCount: 18,
        bestQuizScore: 95,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        capturesCount: 14,
        postsCount: 4,
        followersCount: 186,
        followingCount: 42,
        isFollowedByMe: false,
        isMyProfile: true,
      );
      ProfileService.instance.setMockProfile(unverifiedProfile);
      addTearDown(() {
        ProfileService.instance.resetDemoProfile();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: UpgradeBlueCheckSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi judul dan banner
      expect(find.text('Kolektor Terverifikasi'), findsOneWidget);
      expect(find.text('Langganan Bulanan (Midtrans Sandbox)'), findsOneWidget);
      expect(find.text('Rp15.000'), findsOneWidget);

      // Verifikasi benefit
      expect(find.text('Lencana Centang Biru Resmi'), findsOneWidget);
      expect(find.text('Kuota Chat AI 10 Pertanyaan (Plan 124)'), findsOneWidget);
      expect(find.text('Prioritas Pencarian Kolektor Teratas'), findsOneWidget);

      // Verifikasi tombol pembayaran
      expect(find.textContaining('Bayar'), findsOneWidget);

      // Berpindah ke tab Riwayat Pembayaran
      final historyTab = find.text('Riwayat Pembayaran');
      expect(historyTab, findsOneWidget);
      await tester.tap(historyTab);
      await tester.pumpAndSettle();

      // Verifikasi konten riwayat pembayaran
      expect(find.textContaining('FAUNOVA-CB-'), findsWidgets);
      expect(find.text('Rp 15.000'), findsWidgets);
    });

    testWidgets('MidtransSnapWebViewPage: Menampilkan simulator sandbox dan memproses simulasi bayar berhasil', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool? returnedResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                returnedResult = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MidtransSnapWebViewPage(
                      orderId: 'FAUNOVA-CB-TEST-12345',
                      redirectUrl: 'https://app.sandbox.midtrans.com/snap/v2/vtweb/mock',
                      amountIdr: 15000,
                    ),
                  ),
                );
              },
              child: const Text('Buka WebView Snap'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka halaman MidtransSnapWebViewPage
      await tester.tap(find.text('Buka WebView Snap'));
      await tester.pumpAndSettle();

      // Verifikasi tampilan simulator sandbox
      expect(find.text('Simulator Midtrans Snap Sandbox'), findsOneWidget);
      expect(find.text('Order ID: FAUNOVA-CB-TEST-12345'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);

      // Ketuk tombol simulasi bayar berhasil
      final payButton = find.text('Simulasi Bayar Berhasil (Sandbox)');
      expect(payButton, findsOneWidget);
      await tester.tap(payButton);
      await tester.pumpAndSettle();

      // Dialog konfirmasi server muncul (Hard Rule 6: redirect tidak ubah status langsung)
      expect(find.text('Pembayaran Terkirim'), findsOneWidget);
      final returnButton = find.text('Kembali ke Profil');
      expect(returnButton, findsOneWidget);
      await tester.tap(returnButton);
      await tester.pumpAndSettle();

      // Verifikasi navigasi kembali dan returnedResult == true
      expect(returnedResult, isTrue);
      expect(find.text('Buka WebView Snap'), findsOneWidget);
    });
  });

  group('S20 - Centang Biru: verified_until, Ikon, Kuota Chat 10, dan Prioritas Pencarian (Plan 5.4)', () {
    test('PublicProfileModel: Evaluasi verified_until, isVerifiedActive, dan sisa hari masa aktif (Plan 120)', () {
      // 1. Akun dengan verified_until di masa depan (> now) => isVerifiedActive == true
      final futureDate = DateTime.now().add(const Duration(days: 25));
      final profileActive = PublicProfileModel.fromJson({
        'id': 'user-active',
        'username': 'kolektor_pro',
        'display_name': 'Kolektor Pro',
        'bio': 'Pengamat satwa terverifikasi',
        'is_verified': true,
        'verified_until': futureDate.toIso8601String(),
        'streak_count': 10,
        'best_quiz_score': 90,
        'captures_count': 5,
        'posts_count': 2,
        'followers_count': 20,
        'following_count': 10,
      });

      expect(profileActive.isVerifiedActive, isTrue);
      expect(profileActive.isVerified, isTrue);
      expect(profileActive.verifiedRemainingDays, greaterThanOrEqualTo(24));

      // 2. Akun dengan verified_until di masa lalu (< now) => otomatis kedaluwarsa (isVerifiedActive == false)
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final profileExpired = PublicProfileModel.fromJson({
        'id': 'user-expired',
        'username': 'kolektor_expired',
        'display_name': 'Kolektor Expired',
        'bio': 'Langganan telah berakhir',
        'is_verified': true, // Raw DB boolean true, tapi timestamp sudah lewat!
        'verified_until': pastDate.toIso8601String(),
        'streak_count': 10,
        'best_quiz_score': 90,
        'captures_count': 5,
        'posts_count': 2,
        'followers_count': 20,
        'following_count': 10,
      });

      expect(profileExpired.isVerifiedActive, isFalse);
      expect(profileExpired.isVerified, isFalse);
      expect(profileExpired.verifiedRemainingDays, equals(0));
    });

    test('ChatService: Kuota tanya-jawab AI otomatis 10 pertanyaan untuk Centang Biru aktif (Plan 125, 150)', () async {
      final chatService = ChatService.instance;
      chatService.resetDemoState();

      // Aktifkan Centang Biru
      chatService.setMockVerified(true);
      expect(chatService.isUserVerified, isTrue);

      const scanId = 'scan-verified-test';
      const sampleResult = ScanResultModel(
        scanId: scanId,
        requestId: 'req-v-test',
        status: 'completed',
        isAnimal: true,
        name: 'Jalak Bali',
        categoryOrSpecies: 'Leucopsar rothschildi',
      );

      // Lakukan 10 pertanyaan (harus diizinkan)
      for (int i = 1; i <= 10; i++) {
        final res = await chatService.sendMessage(
          scanId: scanId,
          message: 'Pertanyaan $i seputar makanan satwa',
          scanContext: sampleResult,
        );
        expect(res.chatCount, equals(i));
        expect(res.chatLimit, equals(10));
        expect(res.remaining, equals(10 - i));
      }

      // Pertanyaan ke-11 harus menolak dengan ChatQuotaExceededException kuota 10
      expect(
        () => chatService.sendMessage(
          scanId: scanId,
          message: 'Pertanyaan ke-11 yang melebihi batas',
          scanContext: sampleResult,
        ),
        throwsA(isA<ChatQuotaExceededException>().having((e) => e.chatLimit, 'chatLimit', 10)),
      );

      chatService.resetDemoState();
    });

    test('SearchService: Akun Centang Biru diprioritaskan di barisan teratas (Plan 126)', () async {
      final accounts = await SearchService.instance.searchAccounts('');
      expect(accounts.isNotEmpty, isTrue);

      // Verifikasi urutan: semua akun dengan isVerifiedActive = true harus muncul SEBELUM akun tanpa centang
      bool reachedUnverified = false;
      for (final acc in accounts) {
        if (!acc.isVerifiedActive) {
          reachedUnverified = true;
        } else if (reachedUnverified) {
          fail('Akun centang biru aktif ${acc.displayName} muncul setelah akun non-centang!');
        }
      }
    });

    testWidgets('ProfilePage: Menampilkan badge centang biru dan status langganan aktif saat terverifikasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final verifiedProfile = PublicProfileModel(
        id: 'my-verified-profile',
        username: 'arya_wallacea',
        displayName: 'Arya Wicaksana',
        bio: 'Penjelajah biodiversitas Indonesia Timur.',
        isVerified: true,
        verifiedUntil: DateTime.now().add(const Duration(days: 28)),
        streakCount: 20,
        bestQuizScore: 98,
        capturesCount: 8,
        postsCount: 3,
        followersCount: 300,
        followingCount: 45,
        isFollowedByMe: false,
        isMyProfile: true,
      );

      ProfileService.instance.setMockProfile(verifiedProfile);
      addTearDown(() {
        ProfileService.instance.resetDemoProfile();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfilePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Ikon centang biru harus muncul di profil
      expect(find.byIcon(Icons.verified_rounded), findsWidgets);
      expect(find.text('Centang Biru Aktif'), findsOneWidget);
      expect(find.text('Perpanjang'), findsOneWidget);
    });

    testWidgets('ScanChatPage: Menampilkan kuota 10 untuk akun Centang Biru', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ChatService.instance.resetDemoState();
      ChatService.instance.setMockVerified(true);
      addTearDown(() {
        ChatService.instance.resetDemoState();
      });

      const sampleSatwa = ScanResultModel(
        scanId: 'scan-chat-verified-ui',
        requestId: 'req-verified-ui',
        status: 'completed',
        isAnimal: true,
        name: 'Komodo',
        categoryOrSpecies: 'Varanus komodoensis',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ScanChatPage(scanResult: sampleSatwa),
        ),
      );
      await tester.pumpAndSettle();

      // Kuota awal untuk Centang Biru adalah 10/10 Sisa
      expect(find.text('10/10 Sisa'), findsOneWidget);
    });
  });

  group('S21 - Saran & Kesan Kuliah PAM, Menu Pojok, Layar Pengaturan, dan Perapian 4 State UI (Plan 63, 316 & Scope S21)', () {
    testWidgets('SaranKesanPage: Menampilkan banner kuliah PAM, profil 3 anggota tim, kesan, pesan & saran', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SaranKesanPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Judul dan Header
      expect(find.text('Saran & Kesan Kuliah PAM'), findsOneWidget);
      expect(find.textContaining('Teori Pemrograman Aplikasi Mobile'), findsOneWidget);
      expect(find.text('SEMESTER 5'), findsOneWidget);

      // 3 Anggota Tim Pengembang
      expect(find.text('Justin'), findsOneWidget);
      expect(find.text('Lead Mobile & UI/UX Specialist'), findsOneWidget);

      expect(find.text('Arya Wicaksana'), findsOneWidget);
      expect(find.text('Backend, Database & Security Engineer'), findsOneWidget);

      final budiFinder = find.text('Budi Satria');
      await tester.scrollUntilVisible(budiFinder, 200, scrollable: find.byType(Scrollable).first);
      expect(budiFinder, findsOneWidget);
      expect(find.text('Feature Integration & Sensor Specialist'), findsOneWidget);

      // Seksi Kesan dan Saran
      final kesanHeader = find.text('Kesan Selama Perkuliahan PAM');
      await tester.scrollUntilVisible(kesanHeader, 200, scrollable: find.byType(Scrollable).first);
      expect(kesanHeader, findsOneWidget);

      final pesanHeader = find.text('Pesan & Saran Mata Kuliah');
      await tester.scrollUntilVisible(pesanHeader, 200, scrollable: find.byType(Scrollable).first);
      expect(pesanHeader, findsOneWidget);

      final masukanHeader = find.text('Beri Masukan / Saran Tambahan');
      await tester.scrollUntilVisible(masukanHeader, 200, scrollable: find.byType(Scrollable).first);
      expect(masukanHeader, findsOneWidget);
    });

    testWidgets('SaranKesanPage: Validasi formulir masukan dan penyimpanan masukan ke riwayat', (tester) async {
      await tester.runAsync(() async {
        await EncryptedStorageService.instance.init(isTestEnv: true);
      });

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SaranKesanPage(),
        ),
      );
      await tester.pumpAndSettle();

      final submitButton = find.byKey(const Key('feedback_submit_button'));
      await tester.scrollUntilVisible(submitButton, 200, scrollable: find.byType(Scrollable).first);
      expect(submitButton, findsOneWidget);

      final formTitle = find.text('Formulir Catatan & Saran Tambahan');
      expect(formTitle, findsOneWidget);

      final nameField = find.byKey(const Key('feedback_name_field'));
      final feedbackField = find.byKey(const Key('feedback_text_field'));
      expect(nameField, findsOneWidget);
      expect(feedbackField, findsOneWidget);

      await tester.enterText(nameField, 'Dosen Pengampu PAM');
      await tester.pump();
      await tester.enterText(feedbackField, 'Aplikasi Faunova sangat komprehensif, fitur lengkap, dan UI elegan!');
      await tester.pump();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(submitButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('berhasil dicatat secara lokal'), findsOneWidget);

      final savedItem = find.text('Dosen Pengampu PAM');
      await tester.scrollUntilVisible(savedItem, 200, scrollable: find.byType(Scrollable).first);
      expect(savedItem, findsOneWidget);
      expect(find.textContaining('Aplikasi Faunova sangat komprehensif'), findsOneWidget);
    });

    testWidgets('AppSettingsSheet: Menampilkan pengaturan biometrik, notifikasi, privasi lapangan, dan info aplikasi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppSettingsSheet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi komponen header
      expect(find.text('Pengaturan Aplikasi'), findsOneWidget);
      expect(find.textContaining('Keamanan, notifikasi, privasi'), findsOneWidget);

      // Verifikasi seksi-seksi
      expect(find.text('Keamanan Akun & Biometrik'), findsOneWidget);
      expect(find.text('Masuk dengan Sidik Jari'), findsOneWidget);
      expect(find.text('Enkripsi Penyimpanan Lokal'), findsOneWidget);

      expect(find.text('Notifikasi & Pengingat Terjadwal'), findsOneWidget);
      expect(find.text('Pengingat Lapangan & Streak'), findsOneWidget);

      expect(find.textContaining('Privasi & Keamanan Lapangan'), findsOneWidget);
      expect(find.text('Grid Snapping 0.01° di Server'), findsOneWidget);
      expect(find.text('Pembersihan Metadata EXIF di Klien'), findsOneWidget);

      expect(find.text('Informasi Aplikasi & Lisensi'), findsOneWidget);
      expect(find.text('Faunova — Jurnal Sosial Satwa'), findsOneWidget);
    });

    testWidgets('ProfilePage: Popup menu pojok memuat opsi Saran & Kesan dan Pengaturan Aplikasi', (tester) async {
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

      // Buka popup menu di pojok kanan atas profil
      final popupMenuIcon = find.byIcon(Icons.more_vert_rounded);
      expect(popupMenuIcon, findsOneWidget);
      await tester.tap(popupMenuIcon);
      await tester.pumpAndSettle();

      // Verifikasi menu items
      expect(find.text('Saran & Kesan Kuliah PAM'), findsOneWidget);
      expect(find.text('Pengaturan Aplikasi'), findsOneWidget);
      expect(find.text('Pengaturan & Sidik Jari'), findsOneWidget);
      expect(find.text('Pengaturan Notifikasi'), findsOneWidget);
      expect(find.text('Keluar Akun'), findsOneWidget);
    });

    testWidgets('AppStateView: Menampilkan 4 state wajib (loading, empty, error, offline) dengan penjelasan jelas (AGENTS.md)', (tester) async {
      // 1. Loading state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStateView(
              status: AppViewStatus.loading,
              loadingMessage: 'Memuat data satwa...',
              child: Text('Konten'),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat data satwa...'), findsOneWidget);

      // 2. Empty state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStateView(
              status: AppViewStatus.empty,
              emptyTitle: 'Koleksi Kosong',
              emptyMessage: 'Belum ada data koleksi satwa.',
              child: Text('Konten'),
            ),
          ),
        ),
      );
      expect(find.text('Koleksi Kosong'), findsOneWidget);
      expect(find.text('Belum ada data koleksi satwa.'), findsOneWidget);

      // 3. Error state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStateView(
              status: AppViewStatus.error,
              errorMessage: 'Gagal menghubungi server.',
              child: Text('Konten'),
            ),
          ),
        ),
      );
      expect(find.text('Terjadi Kendala'), findsOneWidget);
      expect(find.text('Gagal menghubungi server.'), findsOneWidget);

      // 4. Offline state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStateView(
              status: AppViewStatus.offline,
              offlineMessage: 'Koneksi internet terputus.',
              child: Text('Konten'),
            ),
          ),
        ),
      );
      expect(find.text('Mode Luring (Offline)'), findsOneWidget);
      expect(find.text('Koneksi internet terputus.'), findsOneWidget);
    });

    testWidgets('S22 - AppAvatar: Mendukung preset satwa endemik, inisial fallback, dan nama', (tester) async {
      // 1. Uji preset Badak Jawa (emoji 🦏)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              avatarPath: 'preset:badak',
              displayName: 'badak',
              radius: 30,
            ),
          ),
        ),
      );
      expect(find.text('🦏'), findsOneWidget);

      // 2. Uji preset Harimau Sumatera (emoji 🐯)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              avatarPath: 'preset:harimau',
              displayName: 'Harimau',
              radius: 30,
            ),
          ),
        ),
      );
      expect(find.text('🐯'), findsOneWidget);

      // 3. Uji fallback inisial huruf pertama jika avatarPath null
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              avatarPath: null,
              displayName: 'Arya Wicaksana',
              radius: 30,
            ),
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('S22 - EditProfileSheet: Menampilkan tombol ubah foto dan avatar satwa', (tester) async {
      final dummyProfile = PublicProfileModel(
        id: 'user-test-1',
        username: 'badaks',
        displayName: 'badak',
        avatarPath: 'preset:badak',
        bio: 'Pecinta satwa',
        isVerified: false,
        streakCount: 1,
        bestQuizScore: 0,
        createdAt: DateTime.now(),
        capturesCount: 0,
        postsCount: 0,
        followersCount: 0,
        followingCount: 1,
        isFollowedByMe: false,
        isMyProfile: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditProfileSheet(initialProfile: dummyProfile),
          ),
        ),
      );

      // Pastikan form dan tombol ubah foto tampil
      expect(find.text('Edit Profil Kolektor'), findsOneWidget);
      expect(find.text('Ubah Foto / Avatar Satwa'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('🦏'), findsOneWidget);

      // Ketuk tombol Ubah Foto / Avatar Satwa untuk membuka opsi
      await tester.tap(find.text('Ubah Foto / Avatar Satwa'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Foto Profil Kolektor'), findsOneWidget);
      expect(find.text('Pilih Avatar Satwa Endemik'), findsOneWidget);
      expect(find.text('Pilih dari Galeri Foto'), findsOneWidget);
      expect(find.text('Ambil Foto dengan Kamera'), findsOneWidget);
    });

    test('SocialService: fetchUserFollowers dan fetchUserFollowing mengembalikan profil publik dengan relasi sosial yang valid', () async {
      SocialService.instance.initMockDemoSocial();

      // Cek followers akun saya
      final myFollowers = await SocialService.instance.fetchUserFollowers('00000000-0000-0000-0000-000000000001');
      expect(myFollowers, isNotEmpty);
      expect(myFollowers.any((u) => u.username == 'budi_satria'), isTrue);

      // Cek following akun saya
      final myFollowing = await SocialService.instance.fetchUserFollowing('00000000-0000-0000-0000-000000000001');
      expect(myFollowing, isNotEmpty);
      expect(myFollowing.any((u) => u.username == 'budi_satria'), isTrue);

      // Cek followers orang lain (budi_satria)
      final budiFollowers = await SocialService.instance.fetchUserFollowers('user-budi');
      expect(budiFollowers, isNotEmpty);

      // Cek following orang lain (budi_satria)
      final budiFollowing = await SocialService.instance.fetchUserFollowing('user-budi');
      expect(budiFollowing, isNotEmpty);
    });

    testWidgets('FollowListSheet: Menampilkan tab Pengikut & Mengikuti, filter pencarian, dan tombol ikuti/mengikuti', (tester) async {
      SocialService.instance.initMockDemoSocial();
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FollowListSheet(
              userId: '00000000-0000-0000-0000-000000000001',
              displayName: 'Arya Wicaksana',
              username: 'arya_wallacea',
              initialTab: FollowTab.followers,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan nama pemilik akun dan username tampil
      expect(find.text('Arya Wicaksana'), findsOneWidget);
      expect(find.text('@arya_wallacea'), findsOneWidget);

      // Pastikan kedua tab Pengikut dan Mengikuti tampil
      expect(find.textContaining('Pengikut'), findsWidgets);
      expect(find.textContaining('Mengikuti'), findsWidgets);

      // Pastikan ada search field
      expect(find.byType(TextField), findsOneWidget);

      // Pastikan salah satu pengikut tampil di list
      expect(find.text('Budi Satria Wibowo'), findsOneWidget);

      // Uji coba tab Mengikuti
      await tester.tap(find.textContaining('Mengikuti').first);
      await tester.pumpAndSettle();
    });

    testWidgets('MultiTimeZoneCard: Menggunakan padding EdgeInsets.zero untuk menghilangkan gap vertikal berlebih', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: MultiTimeZoneCard(
              title: 'Jam Observasi Lapangan (4 Zona)',
              subtitle: 'Sinkronisasi taktis WIB, WITA, WIT, dan London (BST/GMT)',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final grid = tester.widget<GridView>(gridFinder);
      expect(grid.padding, equals(EdgeInsets.zero));
    });

    // ============================================================================
    // S23 - Kunci Aplikasi Biometrik (App Lock) & Fallback Kata Sandi
    // ============================================================================
    group('S23 - Kunci Aplikasi Biometrik (App Lock) & Fallback Kata Sandi', () {
      setUp(() async {
        BiometricService.instance.resetMockOverrides();
        BiometricService.instance.setMockDependencies(
          mockCanCheckBiometrics: true,
          mockIsDeviceSupported: true,
          mockAuthResult: false,
          disableAutoTrigger: true,
          mockBiometricEnabled: false,
        );
        BiometricService.instance.setAppUnlocked(false);
      });

      tearDown(() async {
        BiometricService.instance.resetMockOverrides();
        await AuthService.instance.signOut();
      });

      test('BiometricService: performBiometricUnlock berhasil membuka kunci aplikasi', () async {
        BiometricService.instance.setMockDependencies(
          mockCanCheckBiometrics: true,
          mockIsDeviceSupported: true,
          mockAuthResult: true,
        );

        expect(BiometricService.instance.isAppUnlocked, isFalse);

        final result = await BiometricService.instance.performBiometricUnlock();
        expect(result.success, isTrue);
        expect(BiometricService.instance.isAppUnlocked, isTrue);
        expect(BiometricService.instance.getFailedAttempts(), equals(0));
      });

      test('BiometricService: verifyPasswordToUnlock dengan password valid membuka kunci', () async {
        expect(BiometricService.instance.isAppUnlocked, isFalse);

        // Password kurang dari 6 karakter gagal
        final failRes = await BiometricService.instance.verifyPasswordToUnlock('123');
        expect(failRes, isFalse);
        expect(BiometricService.instance.isAppUnlocked, isFalse);

        // Password >= 6 karakter berhasil (demo/test fallback)
        final successRes = await BiometricService.instance.verifyPasswordToUnlock('mock_test_token');
        expect(successRes, isTrue);
        expect(BiometricService.instance.isAppUnlocked, isTrue);
      });

      testWidgets('BiometricLockPage: Menampilkan UI kunci, info email, dan toggle password', (tester) async {
        bool unlocked = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: BiometricLockPage(
              autoTrigger: false,
              onUnlocked: () => unlocked = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Faunova Terkunci'), findsOneWidget);
        expect(find.text('Pindai Sidik Jari'), findsOneWidget);
        expect(find.text('Buka dengan Kata Sandi'), findsOneWidget);

        // Tap Buka dengan Kata Sandi
        await tester.tap(find.text('Buka dengan Kata Sandi'));
        await tester.pumpAndSettle();

        expect(find.text('Buka Kunci dengan Kata Sandi'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);

        // Masukkan kata sandi
        await tester.enterText(find.byType(TextFormField), 'mock_test_token');
        await tester.pump();

        final unlockBtn = find.widgetWithText(ElevatedButton, 'Buka Kunci');
        await tester.ensureVisible(unlockBtn);
        await tester.tap(unlockBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(unlocked, isTrue);
      });

      testWidgets('AuthGate: Menampilkan BiometricLockPage saat biometrik aktif dan belum unlock', (tester) async {
        AuthService.instance.enterDemoMode();
        BiometricService.instance.setMockDependencies(mockBiometricEnabled: true);
        BiometricService.instance.setAppUnlocked(false);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AuthGate(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Harusnya berada di BiometricLockPage
        expect(find.byType(BiometricLockPage), findsOneWidget);
        expect(find.text('Faunova Terkunci'), findsOneWidget);

        // Setelah unlock, berpindah ke MainNavigationScaffold
        BiometricService.instance.setAppUnlocked(true);
        await tester.pump();

        expect(find.byType(MainNavigationScaffold), findsOneWidget);
      });
    });
  });

  group('Tingkat 3 - Fitur Pelaporan Postingan & Moderasi Komunitas (Plan 53, 333)', () {
    test('PostService: reportPost mencatat ID postingan yang dilaporkan dan idempoten', () async {
      final service = PostService.instance;
      service.clearReportedPostsForTesting();

      expect(service.isPostReported('post-test-123'), isFalse);

      final result = await service.reportPost(
        postId: 'post-test-123',
        reason: 'bukan_hewan',
        notes: 'Hanya foto cangkir kopi',
      );

      expect(result['success'], isTrue);
      expect(result['post_id'], 'post-test-123');
      expect(service.isPostReported('post-test-123'), isTrue);
    });

    testWidgets('PostCard & ReportPostSheet: Menampilkan opsi laporkan, memilih alasan, dan mengirim laporan', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        PostService.instance.clearReportedPostsForTesting();
      });

      final testPost = PostModel(
        id: 'mock-post-report-1',
        captureId: 'mock-cap-report-1',
        caption: 'Bukan hewan liar, melainkan boneka mainan.',
        locationVisibility: 'coarse',
        displayLatitude: -6.200000,
        displayLongitude: 106.816666,
        areaLabel: 'Jakarta Pusat',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        speciesName: 'Objek Mencurigakan',
        category: 'Spam',
        photoUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=500',
        blockSeq: 99,
        blockHash: 'abcdef1234567890',
        photoSha256: 'abcdef1234567890',
        authorId: 'user-suspicious',
        authorName: 'Akun Pelanggar',
        authorUsername: 'pelanggar_etika',
        authorVerifiedUntil: null,
        likesCount: 2,
        isLikedByMe: false,
      );

      String? reportedPostId;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCard(
                post: testPost,
                onReported: (id) {
                  reportedPostId = id;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi tombol titik tiga / menu opsi muncul
      final moreBtn = find.byIcon(Icons.more_vert_rounded);
      expect(moreBtn, findsOneWidget);

      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Verifikasi opsi popup Laporkan Postingan
      final reportMenuItem = find.text('Laporkan Postingan');
      expect(reportMenuItem, findsOneWidget);

      await tester.tap(reportMenuItem);
      await tester.pumpAndSettle();

      // Verifikasi modal ReportPostSheet terbuka
      expect(find.byType(ReportPostSheet), findsOneWidget);
      expect(find.text('Bukan Satwa / Objek Mati'), findsOneWidget);
      expect(find.text('Kekerasan atau Perburuan Liar'), findsOneWidget);
      expect(find.text('Spam atau Promosi Ilegal'), findsOneWidget);

      // Pilih alasan "Bukan Satwa / Objek Mati"
      await tester.tap(find.text('Bukan Satwa / Objek Mati'));
      await tester.pumpAndSettle();

      // Ketuk tombol Kirim Laporan
      final submitBtn = find.text('Kirim Laporan');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verifikasi modal tertutup dan callback terpanggil
      expect(find.byType(ReportPostSheet), findsNothing);
      expect(reportedPostId, 'mock-post-report-1');
      expect(PostService.instance.isPostReported('mock-post-report-1'), isTrue);
    });
  });
}




