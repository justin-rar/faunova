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
      expect(find.byType(BackdropFilter), findsOneWidget);

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
      expect(find.text('HEADING 148° SE'), findsOneWidget);

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
      await tester.tap(find.text('Daftar Baru'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.text('Bergabung dengan Faunova'), findsOneWidget);
      expect(find.text('Daftarkan Akun'), findsOneWidget);

      // Submit formulir kosong
      await tester.ensureVisible(find.text('Daftarkan Akun'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daftarkan Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('Nama pengguna wajib diisi'), findsOneWidget);
      expect(find.text('Alamat email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
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
      await tester.tap(find.text('Lupa kata sandi?'));
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
}
