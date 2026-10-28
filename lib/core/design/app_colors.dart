import 'package:flutter/material.dart';

/// Bouslty brand palette and app-wide color tokens.
/// Source: Bouslty Brand Kit v1 (06-For-Developers/tokens.json).
class AppColors {
  AppColors._();

  // —— Core brand palette ——
  static const Color brandDeepTeal = Color(0xFF083B41);
  static const Color brandTeal = Color(0xFF0E6E75);
  static const Color brandSaffron = Color(0xFFF2A922);
  static const Color brandSand = Color(0xFFFBF8F2);
  static const Color brandSandDeep = Color(0xFFE5DCCB);
  static const Color brandInk = Color(0xFF0D2A2E);
  static const Color brandWhite = Color(0xFFFFFFFF);

  // —— Light theme tokens ——
  static const Color surface = brandSand;
  static const Color surfaceRaised = brandWhite;
  static const Color surfaceSunken = Color(0xFFF3EDE2);
  static const Color surfaceBrand = brandDeepTeal;
  static const Color scrim = Color(0x8F052A2E);
  static const Color line = brandSandDeep;
  static const Color lineStrong = Color(0xFF7B8B89);
  static const Color ink = brandInk;
  static const Color inkMuted = Color(0xFF4A6063);
  static const Color inkSubtle = Color(0xFF5F7376);
  static const Color inkOnBrand = brandSand;
  static const Color primarySoft = Color(0xFFE1F0EF);
  static const Color primaryHover = Color(0xFF0B5960);
  static const Color accentHover = Color(0xFFDB9013);
  static const Color accentSoft = Color(0xFFFDF1D6);
  static const Color accentInk = Color(0xFF865407);

  // —— Dark theme tokens ——
  static const Color darkSurface = Color(0xFF06262A);
  static const Color darkSurfaceRaised = Color(0xFF0B3237);
  static const Color darkSurfaceSunken = Color(0xFF041D20);
  static const Color darkSurfaceBrand = Color(0xFF11545C);
  static const Color darkScrim = Color(0x99000000);
  static const Color darkLine = Color(0xFF1C4B51);
  static const Color darkLineStrong = Color(0xFF5E8F93);
  static const Color darkInk = Color(0xFFF2EEE6);
  static const Color darkInkMuted = Color(0xFFA9C0C0);
  static const Color darkInkSubtle = Color(0xFF8AA6A7);
  static const Color darkPrimary = Color(0xFF5CC7C1);
  static const Color darkPrimaryHover = Color(0xFF86D7D2);
  static const Color darkOnPrimary = Color(0xFF052A2E);
  static const Color darkPrimarySoft = Color(0xFF0F3E43);
  static const Color darkAccentHover = Color(0xFFF7C056);
  static const Color darkAccentSoft = Color(0xFF352A0F);
  static const Color darkAccentInk = Color(0xFFF7C056);

  // —— Status (light / dark) ——
  static const Color successSoft = Color(0xFFE1F2E9);
  static const Color warningSoft = Color(0xFFFDF0D6);
  static const Color dangerSoft = Color(0xFFFBE5E1);
  static const Color infoSoft = Color(0xFFE5EEF8);
  static const Color darkSuccess = Color(0xFF62CC9C);
  static const Color darkSuccessSoft = Color(0xFF0E3527);
  static const Color darkWarning = Color(0xFFF2B54A);
  static const Color darkWarningSoft = Color(0xFF382910);
  static const Color darkDanger = Color(0xFFF2907F);
  static const Color darkDangerSoft = Color(0xFF43201B);
  static const Color darkInfo = Color(0xFF8AB9EE);
  static const Color darkInfoSoft = Color(0xFF132C45);

  // —— School stages (light / dark + soft grounds) ——
  static const Color stagePrimary = Color(0xFF2B67A8);
  static const Color stagePrimarySoft = Color(0xFFE5EFF9);
  static const Color stageIntermediate = Color(0xFF1B7258);
  static const Color stageIntermediateSoft = Color(0xFFE1F2EA);
  static const Color stageSecondary = Color(0xFFAE4128);
  static const Color stageSecondarySoft = Color(0xFFFBE8E1);
  static const Color stageUniversity = Color(0xFF664AAA);
  static const Color stageUniversitySoft = Color(0xFFEEEAF8);

  static const Color darkStagePrimary = Color(0xFF8FBEF0);
  static const Color darkStagePrimarySoft = Color(0xFF14304B);
  static const Color darkStageIntermediate = Color(0xFF6CCFA8);
  static const Color darkStageIntermediateSoft = Color(0xFF10372B);
  static const Color darkStageSecondary = Color(0xFFF39C85);
  static const Color darkStageSecondarySoft = Color(0xFF432319);
  static const Color darkStageUniversity = Color(0xFFBBA8EF);
  static const Color darkStageUniversitySoft = Color(0xFF28224A);

  // —— Semantic (light theme defaults) ——
  static const Color background = surface;
  static const Color foreground = ink;
  static const Color card = surfaceRaised;
  static const Color cardForeground = ink;

  static const Color primary = brandTeal;
  static const Color primaryForeground = brandWhite;
  static const Color primaryDark = brandDeepTeal;
  static const Color primaryLight = darkSurfaceBrand;
  static const Color primaryDeep = darkSurface;

  static const Color secondary = brandSaffron;
  static const Color secondaryForeground = brandDeepTeal;
  static const Color secondaryLight = darkAccentHover;
  static const Color secondaryDark = accentHover;
  static const Color secondaryMuted = Color(0x1AF2A922);

  static const Color muted = surfaceSunken;

  /// Secondary body text — readable on light/dark surfaces (not for icons).
  static const Color mutedForeground = inkMuted;

  /// Saffron-family text for labels/links on neutral backgrounds.
  static const Color accentText = accentInk;

  static const Color accent = brandSaffron;

  /// Labels on an accent fill — deep teal, never white (brand rule).
  static const Color accentForeground = brandDeepTeal;
  static const Color darkCard = darkSurfaceRaised;

  static const Color border = line;
  static const Color input = surfaceRaised;
  static const Color ring = brandTeal;

  static const Color destructive = Color(0xFFB4372B);
  static const Color destructiveForeground = brandWhite;
  static const Color success = Color(0xFF1D7650);
  static const Color warning = Color(0xFF8F5600);
  static const Color info = Color(0xFF2A62A3);

  static const Color bottomNavBackground = surfaceRaised;
  static const Color bottomNavActive = brandSaffron;
  static const Color bottomNavInactive = inkSubtle;
  static const Color iconPrimary = brandTeal;

  static const Color whiteOverlay20 = Color(0x33FFFFFF);
  static const Color whiteOverlay40 = Color(0x66FFFFFF);
  static const Color whiteOverlay10 = Color(0x1AFFFFFF);
  static const Color blackOverlay20 = Color(0x33000000);
  static const Color blackOverlay40 = Color(0x66000000);

  // Light theme surfaces
  static const Color scaffoldLight = surface;
  static const Color cardSurfaceLight = surfaceRaised;
  static const Color cardBorderLight = line;
  static const Color surfaceMutedLight = surfaceSunken;
  static const Color chipBackgroundLight = line;
  static const Color textSecondaryLight = inkMuted;
  static const Color shadowLight = Color(0x1F083B41);

  // Dark theme surfaces
  static const Color navyMutedSurfaceDark = darkSurfaceRaised;
  static const Color cardBorderDark = darkLine;
  static const Color textSecondaryDark = darkInkMuted;
  static const Color shadowDark = Color(0x66000000);

  // —— Legacy aliases ——
  /// @deprecated Use [darkSurfaceRaised].
  static const Color navyMutedSurfaceLight = surfaceMutedLight;
  static const Color navySkeletonBaseLight = brandSandDeep;
  static const Color navySkeletonBaseDark = darkSurfaceRaised;
  static const Color navySkeletonContainerLight = surfaceSunken;

  /// @deprecated Use [brandSaffron] / [accent].
  static const Color goldLight = darkAccentHover;
  static const Color goldPrimary = brandSaffron;
  static const Color goldText = accentInk;
  static const Color goldDark = accentInk;
  static const Color goldPrimary12 = Color(0x1FF2A922);
  static const Color goldPrimary24 = Color(0x3DF2A922);
  static const Color goldLight24 = Color(0x3DF7C056);

  /// @deprecated Use the dark-surface tokens.
  static const Color navyLight = darkSurfaceBrand;
  static const Color navyMid = brandDeepTeal;
  static const Color navyDeep = darkSurface;

  /// @deprecated Map old names to the brand palette.
  static const Color beige = background;
  static const Color beigeDark = muted;
  static const Color orange = brandSaffron;
  static const Color orangeLight = darkAccentHover;
  static const Color purple = brandDeepTeal;
  static const Color purpleLight = darkSurfaceBrand;
  static const Color purpleDark = darkSurface;
  static const Color dark = darkSurface;
  static const Color lavender = darkSurfaceBrand;
  static const Color lavenderLight = muted;

  /// Header / branded surfaces — deep-teal brand gradient.
  static const List<Color> headerGradient2 = <Color>[
    darkSurfaceBrand,
    brandDeepTeal,
  ];
  static const List<Color> headerGradient3 = <Color>[
    darkSurfaceBrand,
    brandDeepTeal,
    darkSurface,
  ];
  static const List<Color> secondaryGradient2 = <Color>[
    brandSaffron,
    accentHover,
  ];

  /// Login / register header — deep-teal brand band.
  static const List<Color> authHeaderGradient = <Color>[
    brandTeal,
    brandDeepTeal,
    darkSurface,
  ];

  /// Badge / chip on a brand band (on-accent ink is deep teal).
  static const Color badgeBackground = brandSaffron;
  static const Color badgeForeground = brandDeepTeal;

  /// Rating stars and highlights.
  static const Color rating = brandSaffron;

  /// Success chip — brand success green.
  static const Color chipSuccessBackground = successSoft;
  static const Color chipSuccessForeground = success;
}
