import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Bottom bar dengan efek kaca (glassmorphism) berbentuk bar penuh (bukan melayang)
/// sesuai dengan aturan AGENTS.md dan referensi visual frosted glass iOS/macOS.
/// 
/// - Bar penuh menempel ke dasar dan tepi layar (full width)
/// - Efek blur BackdropFilter ImageFilter.blur (sigma 24)
/// - Latar transparan frosted gading/putih sehingga konten yang lewat di bawahnya terlihat blur
/// - Tab aktif berbalut kapsul glossy (pill container) seperti referensi visual
/// - Ikon aktif memakai sage tua #5C7457
/// - Ikon tidak aktif memakai sage / teks gelap teredam
class GlassBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const GlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            // Transparansi frosted glass yang tembus pandang
            color: const Color(0xFFF7F4ED).withValues(alpha: 0.60),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.75),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teksGelap.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            top: 8.0,
            bottom: bottomPadding > 0 ? bottomPadding : 10.0,
            left: 8.0,
            right: 8.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGlassTab(
                index: 0,
                label: 'Beranda',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
              ),
              _buildGlassTab(
                index: 1,
                label: 'Cari',
                icon: Icons.search_outlined,
                activeIcon: Icons.search_rounded,
              ),
              _buildGlassTab(
                index: 2,
                label: 'Kamera',
                icon: Icons.camera_alt_outlined,
                activeIcon: Icons.camera_alt_rounded,
                isCameraTab: true,
              ),
              _buildGlassTab(
                index: 3,
                label: 'Game',
                icon: Icons.sports_esports_outlined,
                activeIcon: Icons.sports_esports_rounded,
              ),
              _buildGlassTab(
                index: 4,
                label: 'Profil',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTab({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    bool isCameraTab = false,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              // Pill kapsul kaca aktif sesuai referensi gambar
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.75)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: isSelected
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1.0,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.sageTua : AppColors.sage,
                  size: isCameraTab ? 24 : 22,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.sageTua : AppColors.sage,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
