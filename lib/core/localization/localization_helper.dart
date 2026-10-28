import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../courses/lesson_duration_utils.dart';

/// Helper class to easily access localization strings
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  bool get isArabicLocale =>
      Localizations.localeOf(this).languageCode == 'ar';

  String courseDurationLabel(Map<String, dynamic> course) {
    final l10n = this.l10n;
    final isAr = isArabicLocale;
    return LessonDurationUtils.formatCourseDurationLabel(
      course,
      isArabic: isAr,
      hourUnit: l10n.hourShort,
      minuteUnit: l10n.minuteShort,
      secondUnit: l10n.secondShort,
    );
  }

  String lessonDurationLabel(Map<dynamic, dynamic>? lesson) {
    final l10n = this.l10n;
    final isAr = isArabicLocale;
    return LessonDurationUtils.formatLessonDuration(
      lesson,
      isArabic: isAr,
      hourUnit: l10n.hourShort,
      minuteUnit: l10n.minuteShort,
      secondUnit: l10n.secondShort,
    );
  }
}
