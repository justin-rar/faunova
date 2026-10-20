import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Bottom bar dengan efek kaca (glassmorphism) berbentuk bar penuh (bukan melayang)
/// sesuai dengan aturan AGENTS.md dan plan_faunova_revisi_5_final.md.
/// 
/// - Bar penuh menempel ke bawah dan tepi layar
/// - Efek blur BackdropFilter ImageFilter.blur
/// - Ikon aktif memakai sage tua #5C7457
/// - Ikon tidak aktif memakai sage #8FA28A
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
        filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
        child: Container(
          // Bar penuh dari sisi ke sisi
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.gading.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: AppColors.sage.withValues(alpha: 0.28),
                width: 1.0,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            top: 8.0,
            bottom: bottomPadding > 0 ? bottomPadding : 10.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Beranda',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'Cari',
                icon: Icons.search_outlined,
                activeIcon: Icons.search_rounded,
              ),
              _buildCameraNavItem(
                index: 2,
                label: 'Kamera',
              ),
              _buildNavItem(
                index: 3,
                label: 'Game',
                icon: Icons.sports_esports_outlined,
                activeIcon: Icons.sports_esports_rounded,
              ),
              _buildNavItem(
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

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        splashColor: AppColors.sageMuda.withValues(alpha: 0.3),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.sageMuda.withValues(alpha: 0.45)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.sageTua : AppColors.sage,
                  size: 24,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.sageTua : AppColors.sage,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraNavItem({
    required int index,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(index),
        splashColor: AppColors.sageMuda.withValues(alpha: 0.3),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.sageTua : AppColors.sage,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? AppColors.sageTua : AppColors.sage)
                          .withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.teksPutih, // Teks/ikon putih di atas sage tua
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.sageTua : AppColors.sage,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
