import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/services/currency_service.dart';
import 'core/services/encrypted_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/feed/presentation/widgets/social_notification_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase secara aman (tidak crash jika .env/define masih kosong di S1)
  await AppConfig.initializeSupabase();

  // Inisialisasi Hive AES-256 terenkripsi, CurrencyService, dan Notifikasi Lokal (Sesi S12 & S18)
  try {
    await EncryptedStorageService.instance.init();
    await CurrencyService.instance.init();
    await NotificationService.instance.init();
    await NotificationService.instance.scheduleDailyStreakReminder();
    await NotificationService.instance.scheduleDailyChallengeReminder();

    // Rute ketukan notifikasi sistem Android ke Pusat Notifikasi (Level A)
    NotificationService.instance.onNotificationTapped = (payload) {
      final navContext = FaunovaApp.navigatorKey.currentContext;
      if (navContext != null && payload.startsWith('social:')) {
        SocialNotificationSheet.show(navContext);
      }
    };
  } catch (e) {
    debugPrint('Faunova main services init warning: $e');
  }

  runApp(const FaunovaApp());
}

class FaunovaApp extends StatelessWidget {
  const FaunovaApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Faunova',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const FaunovaScrollBehavior(),
      home: const AuthGate(),
    );
  }
}

/// Menghilangkan efek overscroll stretch (karet melar berlebih) bawaan Android 12+
/// dan menggantinya dengan ClampingScrollPhysics yang solid dan halus.
class FaunovaScrollBehavior extends MaterialScrollBehavior {
  const FaunovaScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

