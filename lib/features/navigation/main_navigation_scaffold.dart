import 'package:flutter/material.dart';
import '../../core/widgets/glass_bottom_bar.dart';
import '../camera/presentation/camera_page.dart';
import '../feed/presentation/feed_page.dart';
import '../game/presentation/game_page.dart';
import '../profile/presentation/profile_page.dart';
import '../search/presentation/search_page.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FeedPage(),
    SearchPage(),
    CameraPage(),
    GamePage(),
    ProfilePage(),
  ];

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: GlassBottomBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
