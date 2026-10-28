import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design/app_colors.dart';
import '../core/navigation/route_names.dart';
import '../core/localization/localization_helper.dart';
import 'global_whatsapp_support_fab.dart';

/// Bottom Navigation Bar - Liquid Glass Effect
class BottomNav extends StatelessWidget {
  final String activeTab;

  const BottomNav({
    super.key,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 380),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: isLight
                      ? _buildLightNavBar(context)
                      : _buildDarkNavBar(context),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: const WhatsappSupportCircleButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLightNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceLight,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.cardBorderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _navRow(context, isLight: true),
    );
  }

  Widget _buildDarkNavBar(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.navyLight.withValues(alpha: 0.92),
              AppColors.navyMid.withValues(alpha: 0.92),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.goldPrimary.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: _navRow(context, isLight: false),
      ),
    );
  }

  Widget _navRow(BuildContext context, {required bool isLight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          icon: Icons.home_rounded,
          label: context.l10n.home,
          id: 'home',
          activeTab: activeTab,
          isLight: isLight,
          onTap: () => context.go(RouteNames.home),
        ),
        _NavItem(
          icon: Icons.grid_view_rounded,
          label: context.l10n.courses,
          id: 'courses',
          activeTab: activeTab,
          isLight: isLight,
          onTap: () => context.go(RouteNames.allCourses),
        ),
        _NavItem(
          icon: Icons.menu_book_rounded,
          label: context.l10n.myCourses,
          id: 'enrolled',
          activeTab: activeTab,
          isLight: isLight,
          onTap: () => context.go(RouteNames.enrolled),
        ),
        _NavItem(
          icon: Icons.person_rounded,
          label: context.l10n.profile,
          id: 'dashboard',
          activeTab: activeTab,
          isLight: isLight,
          onTap: () => context.go(RouteNames.dashboard),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String id;
  final String activeTab;
  final bool isLight;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.id,
    required this.activeTab,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeTab == id;

    final Color activeColor =
        isLight ? AppColors.navyDeep : AppColors.goldPrimary;
    final Color inactiveColor = isLight
        ? AppColors.textSecondaryLight
        : AppColors.brandWhite.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isLight
                  ? AppColors.navyDeep.withValues(alpha: 0.08)
                  : AppColors.goldPrimary.withValues(alpha: 0.15))
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                icon,
                size: isActive ? 26 : 24,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.readexPro(
                fontSize: isActive ? 11 : 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
