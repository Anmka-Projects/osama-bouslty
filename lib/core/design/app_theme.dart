import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_radius.dart';
import 'app_theme_extension.dart';
import '../../models/app_config.dart';

/// App Theme Configuration — Bouslty brand tokens (light & dark).
class AppTheme {
  AppTheme._();

  static String? get _fontFamily => GoogleFonts.readexPro().fontFamily;

  static ThemeData lightTheme([ThemeConfig? themeConfig]) {
    final primaryColor = themeConfig?.getPrimaryColor() ?? AppColors.primary;
    final secondaryColor =
        themeConfig?.getSecondaryColor() ?? AppColors.secondary;
    final cardColor = AppColors.card;
    final backgroundColor = AppColors.scaffoldLight;
    final errorColor = themeConfig?.getErrorColor() ?? AppColors.destructive;
    final textColor = themeConfig?.getTextColor() ?? AppColors.foreground;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: const [AppThemeExtension.light],
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        onPrimary: AppColors.primaryForeground,
        onSecondary: AppColors.secondaryForeground,
        onSurface: textColor,
        error: errorColor,
        onError: AppColors.destructiveForeground,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: _fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1(),
        displayMedium: AppTextStyles.h2(),
        displaySmall: AppTextStyles.h3(),
        headlineMedium: AppTextStyles.h4(),
        bodyLarge: AppTextStyles.bodyLarge(),
        bodyMedium: AppTextStyles.bodyMedium(),
        bodySmall: AppTextStyles.bodySmall(),
        labelLarge: AppTextStyles.labelLarge(),
        labelMedium: AppTextStyles.labelMedium(),
        labelSmall: AppTextStyles.labelSmall(),
      ).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomNavBackground,
        selectedItemColor: AppColors.brandSaffron,
        unselectedItemColor: AppColors.inkSubtle,
      ),
      dividerColor: AppColors.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceRaised,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.iconPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandTeal,
          foregroundColor: AppColors.brandWhite,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.input,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.brandTeal,
            width: 2,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        contentTextStyle: TextStyle(color: AppColors.brandWhite),
        actionTextColor: AppColors.brandWhite,
      ),
    );
  }

  static ThemeData darkTheme([ThemeConfig? themeConfig]) {
    final primaryColor =
        themeConfig?.getPrimaryColor() ?? AppColors.darkPrimary;
    final secondaryColor =
        themeConfig?.getSecondaryColor() ?? AppColors.brandSaffron;
    final cardColor = AppColors.darkSurfaceRaised;
    final backgroundColor = AppColors.darkSurface;
    final errorColor = themeConfig?.getErrorColor() ?? AppColors.darkDanger;
    const textColor = AppColors.darkInk;
    const mutedTextColor = AppColors.darkInkMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: const [AppThemeExtension.dark],
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        onPrimary: AppColors.darkOnPrimary,
        onSecondary: AppColors.brandDeepTeal,
        onSurface: textColor,
        onSurfaceVariant: mutedTextColor,
        error: errorColor,
        onError: AppColors.destructiveForeground,
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: _fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1(),
        displayMedium: AppTextStyles.h2(),
        displaySmall: AppTextStyles.h3(),
        headlineMedium: AppTextStyles.h4(),
        bodyLarge: AppTextStyles.bodyLarge(),
        bodyMedium: AppTextStyles.bodyMedium(),
        bodySmall: AppTextStyles.bodySmall(),
        labelLarge: AppTextStyles.labelLarge(),
        labelMedium: AppTextStyles.labelMedium(),
        labelSmall: AppTextStyles.labelSmall(),
      ).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorderRadius,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceRaised,
        selectedItemColor: AppColors.brandSaffron,
        unselectedItemColor: AppColors.darkInkSubtle,
      ),
      dividerColor: AppColors.darkLine,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkInk,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandSaffron,
          foregroundColor: AppColors.brandDeepTeal,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceRaised,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.brandSaffron,
            width: 2,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        contentTextStyle: TextStyle(color: AppColors.darkInk),
        actionTextColor: AppColors.brandSaffron,
      ),
    );
  }
}
