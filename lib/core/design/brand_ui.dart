import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme_extension.dart';

/// Shared UI patterns from [HomeScreen] — works in light and dark via [AppThemeExtension].
abstract final class BrandUi {
  BrandUi._();

  /// Navy header with light status icons (home screen behavior).
  static void applyStatusBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  /// Section title on scaffold (Alexandria display font).
  static TextStyle sectionTitleStyle(
    AppThemeExtension theme, {
    double fontSize = 18,
  }) {
    return GoogleFonts.alexandria(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: theme.foreground,
    );
  }

  /// Primary line on a course/content card.
  static TextStyle cardTitleStyle(
    AppThemeExtension theme, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return GoogleFonts.readexPro(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: theme.cardTitle,
    );
  }

  /// Secondary line on a course/content card.
  static TextStyle cardMetaStyle(
    AppThemeExtension theme, {
    double fontSize = 12,
  }) {
    return GoogleFonts.readexPro(
      fontSize: fontSize,
      color: theme.cardMetaText,
    );
  }

  /// Standard elevated card surface (white in light, navy in dark).
  static BoxDecoration cardDecoration(
    AppThemeExtension theme, {
    double radius = 16,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? theme.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: theme.cardBorder),
      boxShadow: [
        BoxShadow(
          color: theme.shadow,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Muted inset panel inside a card.
  static BoxDecoration cardMutedDecoration(
    AppThemeExtension theme, {
    double radius = 12,
  }) {
    return BoxDecoration(
      color: theme.cardMuted,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: theme.cardBorder),
    );
  }
}
