import 'package:flutter/material.dart';
import 'app_theme_extension.dart';

/// Quick access to brand theme colors from any widget [BuildContext].
///
/// Home screen convention:
/// - On **scaffold** (beige / navy background): [sectionTitle], [sectionSubtitle]
/// - On **cards** (white / navy card): [cardTitle], [cardAccentText], [cardMetaText]
extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme => AppThemeExtension.of(this);

  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  /// Section headings on scaffold — navy (light) / gold (dark). Same as [foreground].
  Color get sectionTitle => appTheme.foreground;

  /// Body / hints on scaffold.
  Color get sectionSubtitle => appTheme.mutedForeground;

  /// @deprecated Prefer [cardTitle] on cards or [sectionTitle] on scaffold.
  Color get textPrimary => appTheme.foreground;

  /// @deprecated Prefer [cardMetaText] on cards or [sectionSubtitle] on scaffold.
  Color get textSecondary => appTheme.mutedForeground;

  Color get cardTitle => appTheme.cardTitle;
  Color get cardAccentText => appTheme.cardAccentText;
  Color get cardMetaText => appTheme.cardMetaText;
}
