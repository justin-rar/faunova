import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faunova/core/theme/app_colors.dart';
import 'package:faunova/core/theme/app_theme.dart';
import 'package:faunova/core/widgets/glass_bottom_bar.dart';
import 'package:faunova/core/widgets/app_state_view.dart';
import 'package:faunova/features/navigation/main_navigation_scaffold.dart';

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
      expect(find.text('Eksplorasi & Pencarian'), findsOneWidget);
      expect(find.text('Akun Pengguna'), findsOneWidget);
      expect(find.text('Spesies Hewan'), findsOneWidget);

      // Pindah ke Tab 2 (Kamera)
      await tester.tap(find.text('Kamera'));
      await tester.pumpAndSettle();
      expect(find.text('Kamera Identifikasi AI'), findsOneWidget);
      expect(find.text('Kamera Layar Penuh (Sesi S5)'), findsOneWidget);

      // Pindah ke Tab 3 (Game)
      await tester.tap(find.text('Game'));
      await tester.pumpAndSettle();
      expect(find.text('Kuis & Game Fauna'), findsOneWidget);
      expect(find.text('Streak Check-in Harian'), findsOneWidget);
      expect(find.text('Tantangan Hari Ini'), findsOneWidget);

      // Pindah ke Tab 4 (Profil)
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Profil Saya'), findsOneWidget);
      expect(find.text('Langganan Centang Biru'), findsOneWidget);
      expect(find.text('Verifikasi Rantai'), findsOneWidget);
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
}
