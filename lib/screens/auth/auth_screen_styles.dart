import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_theme_extension.dart';

/// Shared layout tokens for login / register / forgot-password — light & dark.
abstract final class AuthScreenStyles {
  static AppThemeExtension _theme(BuildContext context) =>
      AppThemeExtension.of(context);

  static bool _isDark(BuildContext context) =>
      _theme(context).isDarkStyle;

  static Color scaffoldBackground(BuildContext context) =>
      _theme(context).scaffoldBackground;

  /// Navy header gradient (both themes).
  static BoxDecoration headerDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.headerGradient2,
      ),
    );
  }

  /// Form sheet: white card (light) or navy sheet (dark).
  static BoxDecoration formSheetDecoration(BuildContext context) {
    final theme = _theme(context);
    if (_isDark(context)) {
      return BoxDecoration(
        color: AppColors.navyMid,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, -6),
          ),
        ],
      );
    }
    return BoxDecoration(
      color: theme.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      border: Border(
        top: BorderSide(color: theme.cardBorder),
        left: BorderSide(color: theme.cardBorder),
        right: BorderSide(color: theme.cardBorder),
      ),
      boxShadow: [
        BoxShadow(
          color: theme.shadow,
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
        BoxShadow(
          color: AppColors.goldPrimary.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, -6),
        ),
      ],
    );
  }

  static BoxDecoration textFieldDecoration(BuildContext context) {
    final theme = _theme(context);
    if (_isDark(context)) {
      return BoxDecoration(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.25),
        ),
      );
    }
    return BoxDecoration(
      color: theme.cardMuted,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.cardBorder),
    );
  }

  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.goldPrimary,
      foregroundColor: AppColors.navyDeep,
      disabledBackgroundColor: AppColors.goldPrimary.withValues(alpha: 0.4),
      disabledForegroundColor: AppColors.navyDeep.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    );
  }

  static TextStyle formLabelStyle(BuildContext context) {
    return GoogleFonts.readexPro(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: _isDark(context)
          ? AppColors.brandWhite
          : _theme(context).cardTitle,
    );
  }

  static TextStyle fieldTextStyle(BuildContext context) {
    return GoogleFonts.readexPro(
      fontSize: 15,
      color: _isDark(context)
          ? AppColors.brandWhite
          : _theme(context).cardTitle,
    );
  }

  static TextStyle fieldHintStyle(BuildContext context) {
    return GoogleFonts.readexPro(
      color: _isDark(context)
          ? AppColors.brandWhite.withValues(alpha: 0.55)
          : _theme(context).cardMetaText,
      fontSize: 14,
    );
  }

  static Color fieldIconColor(BuildContext context) => _theme(context).icon;

  static Color fieldSuffixIconColor(BuildContext context) =>
      _isDark(context)
          ? AppColors.brandWhite.withValues(alpha: 0.55)
          : _theme(context).cardMetaText;

  static TextStyle bodySecondaryStyle(BuildContext context) {
    return GoogleFonts.readexPro(
      fontSize: 14,
      color: _isDark(context)
          ? AppColors.brandWhite.withValues(alpha: 0.75)
          : _theme(context).cardMetaText,
    );
  }

  static TextStyle bodyLinkStyle(BuildContext context) {
    return GoogleFonts.readexPro(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: _theme(context).icon,
    );
  }

  static Widget loadingIndicator(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        color: AppColors.navyDeep,
        strokeWidth: 2.5,
      ),
    );
  }

  /// Titles and icons on navy header (gold in both themes).
  static Color get headerForeground => AppColors.goldPrimary;

  static Color get headerForegroundMuted => AppColors.goldText;

  static Color headerControlBg(BuildContext context) =>
      AppColors.goldPrimary.withValues(alpha: 0.15);

  static Color headerControlBorder(BuildContext context) =>
      AppColors.goldPrimary.withValues(alpha: 0.35);

  static TextStyle headerTitleStyle({double fontSize = 20}) {
    return GoogleFonts.readexPro(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: headerForeground,
    );
  }

  static TextStyle headerSubtitleStyle({double fontSize = 15}) {
    return GoogleFonts.readexPro(
      fontSize: fontSize,
      color: headerForegroundMuted,
    );
  }

  static BoxDecoration logoDecoration() {
    return BoxDecoration(
      color: AppColors.brandWhite,
      shape: BoxShape.circle,
      border: Border.all(
        color: AppColors.goldDark.withValues(alpha: 0.5),
        width: 3,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.navyDeep.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
