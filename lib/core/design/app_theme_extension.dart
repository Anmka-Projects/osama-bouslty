import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware semantic colors — Bouslty brand styling in light and dark.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.scaffoldBackground,
    required this.foreground,
    required this.card,
    required this.cardBorder,
    required this.cardMuted,
    required this.mutedForeground,
    required this.icon,
    required this.iconMuted,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.skeletonContainer,
    required this.searchBarFill,
    required this.sheetBackground,
    required this.shadow,
    required this.promoEmptyFill,
    required this.progressTrack,
    required this.cardTitle,
    required this.cardAccentText,
    required this.cardMetaText,
    required this.headerForeground,
    required this.headerMuted,
  });

  final Color scaffoldBackground;

  /// Primary text on scaffold (section titles, body).
  final Color foreground;
  final Color card;
  final Color cardBorder;
  final Color cardMuted;
  final Color mutedForeground;
  final Color icon;
  final Color iconMuted;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final Color skeletonContainer;
  final Color searchBarFill;
  final Color sheetBackground;
  final Color shadow;
  final Color promoEmptyFill;
  final Color progressTrack;

  /// Course / teacher card title.
  final Color cardTitle;

  /// Instructor name, highlights, chips on cards.
  final Color cardAccentText;

  /// Stats and secondary lines on navy cards.
  final Color cardMetaText;

  /// Text on navy gradient headers.
  final Color headerForeground;
  final Color headerMuted;

  static const AppThemeExtension light = AppThemeExtension(
    scaffoldBackground: AppColors.surface,
    foreground: AppColors.ink,
    card: AppColors.surfaceRaised,
    cardBorder: AppColors.line,
    cardMuted: AppColors.surfaceSunken,
    mutedForeground: AppColors.inkMuted,
    icon: AppColors.brandTeal,
    iconMuted: AppColors.inkSubtle,
    skeletonBase: AppColors.brandSandDeep,
    skeletonHighlight: AppColors.brandWhite,
    skeletonContainer: AppColors.surfaceSunken,
    searchBarFill: AppColors.surfaceRaised,
    sheetBackground: AppColors.surfaceRaised,
    shadow: AppColors.shadowLight,
    promoEmptyFill: AppColors.surfaceSunken,
    progressTrack: AppColors.line,
    cardTitle: AppColors.ink,
    cardAccentText: AppColors.accentInk,
    cardMetaText: AppColors.inkMuted,
    headerForeground: AppColors.inkOnBrand,
    headerMuted: Color(0xB3FBF8F2),
  );

  static const AppThemeExtension dark = AppThemeExtension(
    scaffoldBackground: AppColors.darkSurface,
    foreground: AppColors.darkInk,
    card: AppColors.darkSurfaceRaised,
    cardBorder: AppColors.darkLine,
    cardMuted: AppColors.darkSurfaceSunken,
    mutedForeground: AppColors.darkInkMuted,
    icon: AppColors.brandSaffron,
    iconMuted: AppColors.darkInkSubtle,
    skeletonBase: AppColors.darkSurfaceRaised,
    skeletonHighlight: AppColors.goldLight24,
    skeletonContainer: AppColors.darkSurfaceBrand,
    searchBarFill: AppColors.darkSurfaceRaised,
    sheetBackground: AppColors.darkSurfaceRaised,
    shadow: AppColors.shadowDark,
    promoEmptyFill: AppColors.darkSurfaceSunken,
    progressTrack: AppColors.darkAccentSoft,
    cardTitle: AppColors.darkInk,
    cardAccentText: AppColors.darkAccentInk,
    cardMetaText: AppColors.darkInkMuted,
    headerForeground: AppColors.inkOnBrand,
    headerMuted: Color(0xB3FBF8F2),
  );

  static AppThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>() ?? light;
  }

  static Color textPrimary(BuildContext context) => of(context).foreground;
  static Color textSecondary(BuildContext context) =>
      of(context).mutedForeground;

  bool get isDarkStyle => card == AppColors.darkSurfaceRaised;

  @override
  AppThemeExtension copyWith({
    Color? scaffoldBackground,
    Color? foreground,
    Color? card,
    Color? cardBorder,
    Color? cardMuted,
    Color? mutedForeground,
    Color? icon,
    Color? iconMuted,
    Color? skeletonBase,
    Color? skeletonHighlight,
    Color? skeletonContainer,
    Color? searchBarFill,
    Color? sheetBackground,
    Color? shadow,
    Color? promoEmptyFill,
    Color? progressTrack,
    Color? cardTitle,
    Color? cardAccentText,
    Color? cardMetaText,
    Color? headerForeground,
    Color? headerMuted,
  }) {
    return AppThemeExtension(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      cardMuted: cardMuted ?? this.cardMuted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      icon: icon ?? this.icon,
      iconMuted: iconMuted ?? this.iconMuted,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      skeletonContainer: skeletonContainer ?? this.skeletonContainer,
      searchBarFill: searchBarFill ?? this.searchBarFill,
      sheetBackground: sheetBackground ?? this.sheetBackground,
      shadow: shadow ?? this.shadow,
      promoEmptyFill: promoEmptyFill ?? this.promoEmptyFill,
      progressTrack: progressTrack ?? this.progressTrack,
      cardTitle: cardTitle ?? this.cardTitle,
      cardAccentText: cardAccentText ?? this.cardAccentText,
      cardMetaText: cardMetaText ?? this.cardMetaText,
      headerForeground: headerForeground ?? this.headerForeground,
      headerMuted: headerMuted ?? this.headerMuted,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppThemeExtension(
      scaffoldBackground:
          lerpColor(scaffoldBackground, other.scaffoldBackground),
      foreground: lerpColor(foreground, other.foreground),
      card: lerpColor(card, other.card),
      cardBorder: lerpColor(cardBorder, other.cardBorder),
      cardMuted: lerpColor(cardMuted, other.cardMuted),
      mutedForeground: lerpColor(mutedForeground, other.mutedForeground),
      icon: lerpColor(icon, other.icon),
      iconMuted: lerpColor(iconMuted, other.iconMuted),
      skeletonBase: lerpColor(skeletonBase, other.skeletonBase),
      skeletonHighlight: lerpColor(skeletonHighlight, other.skeletonHighlight),
      skeletonContainer: lerpColor(skeletonContainer, other.skeletonContainer),
      searchBarFill: lerpColor(searchBarFill, other.searchBarFill),
      sheetBackground: lerpColor(sheetBackground, other.sheetBackground),
      shadow: lerpColor(shadow, other.shadow),
      promoEmptyFill: lerpColor(promoEmptyFill, other.promoEmptyFill),
      progressTrack: lerpColor(progressTrack, other.progressTrack),
      cardTitle: lerpColor(cardTitle, other.cardTitle),
      cardAccentText: lerpColor(cardAccentText, other.cardAccentText),
      cardMetaText: lerpColor(cardMetaText, other.cardMetaText),
      headerForeground: lerpColor(headerForeground, other.headerForeground),
      headerMuted: lerpColor(headerMuted, other.headerMuted),
    );
  }
}
