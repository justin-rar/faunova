import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/main_navigation_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase secara aman (tidak crash jika .env/define masih kosong di S1)
  await AppConfig.initializeSupabase();

  runApp(const FaunovaApp());
}

class FaunovaApp extends StatelessWidget {
  const FaunovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Faunova',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scrollBehavior: const FaunovaScrollBehavior(),
      home: const MainNavigationScaffold(),
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

