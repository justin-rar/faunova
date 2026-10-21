import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// App bar dengan efek frosted glassmorphism tembus pandang (BackdropFilter)
/// konsisten di seluruh 5 tab navigasi Faunova (Beranda, Cari, Kamera, Game, Profil).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.automaticallyImplyLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: centerTitle,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: leading,
        title: title,
        actions: actions,
        bottom: bottom,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.sageTua.withValues(alpha: 0.78),
                    AppColors.sageTua.withValues(alpha: 0.50),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
