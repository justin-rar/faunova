import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Bottom bar dengan efek kaca (glassmorphism) berbentuk bar penuh (bukan melayang)
/// dan animasi kapsul indikator meluncur (sliding pill indicator) yang mulus saat berpindah tab.
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
    const horizontalMargin = 8.0;
    const topPadding = 8.0;
    final bottomInset = bottomPadding > 0 ? bottomPadding : 10.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
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
            top: topPadding,
            bottom: bottomInset,
            left: horizontalMargin,
            right: horizontalMargin,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / 5;
              const pillInset = 3.0;

              return SizedBox(
                height: 52,
                child: Stack(
                  children: [
                    // 1. Kapsul Kaca Meluncur (Sliding Pill Animation)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastOutSlowIn,
                      left: (currentIndex * tabWidth) + pillInset,
                      top: 1,
                      bottom: 1,
                      width: tabWidth - (pillInset * 2),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.95),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Ikon & Teks 5 Tab di Atas Kapsul Meluncur
                    Row(
                      children: [
                        _buildTabItem(
                          index: 0,
                          label: 'Beranda',
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                        ),
                        _buildTabItem(
                          index: 1,
                          label: 'Cari',
                          icon: Icons.search_outlined,
                          activeIcon: Icons.search_rounded,
                        ),
                        _buildTabItem(
                          index: 2,
                          label: 'Kamera',
                          icon: Icons.camera_alt_outlined,
                          activeIcon: Icons.camera_alt_rounded,
                          isCameraTab: true,
                        ),
                        _buildTabItem(
                          index: 3,
                          label: 'Game',
                          icon: Icons.sports_esports_outlined,
                          activeIcon: Icons.sports_esports_rounded,
                        ),
                        _buildTabItem(
                          index: 4,
                          label: 'Profil',
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
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
        child: AnimatedScale(
          scale: isSelected ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected ? AppColors.sageTua : AppColors.sage,
                  size: isCameraTab ? 24 : 22,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.sageTua : AppColors.sage,
                  letterSpacing: 0.1,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
