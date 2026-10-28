/// Duration helpers for course/lesson Mobile API maps.
///
/// Use [resolveTotalSeconds] for timers, progress bars, and completion logic.
/// Use [formatLessonDuration] / [formatCourseDurationLabel] for display only.
class LessonDurationUtils {
  LessonDurationUtils._();

  static const String _separator = ' · ';

  static int _toNonNegativeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value < 0 ? 0 : value;
    if (value is num) {
      final n = value.toInt();
      return n < 0 ? 0 : n;
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      return parsed != null && parsed >= 0 ? parsed : 0;
    }
    return 0;
  }

  /// Minutes part from `duration_minutes` (legacy `duration` fallback).
  static int parseMinutes(Map<dynamic, dynamic> item) {
    final fromField =
        _toNonNegativeInt(item['duration_minutes'] ?? item['durationMinutes']);
    if (fromField > 0) return fromField;

    final durationField = item['duration'];
    if (durationField is num && durationField > 0) {
      return durationField.toInt();
    }
    if (durationField is String) {
      final trimmed = durationField.trim();
      if (trimmed.isEmpty) return 0;
      final asInt = int.tryParse(trimmed);
      if (asInt != null && asInt > 0) return asInt;
      final digits = RegExp(r'(\d+)').firstMatch(trimmed);
      if (digits != null) {
        final n = int.tryParse(digits.group(1)!);
        if (n != null && n > 0) return n;
      }
    }
    return 0;
  }

  /// Extra seconds (0–59) from `duration_seconds`.
  static int parseExtraSeconds(Map<dynamic, dynamic> item) {
    final s = _toNonNegativeInt(
      item['duration_seconds'] ?? item['durationSeconds'],
    );
    return s > 59 ? s % 60 : s;
  }

  /// Whether the API sent any duration (including `total_seconds` only).
  static bool hasDurationSet(Map<dynamic, dynamic> item) {
    if (_toNonNegativeInt(item['total_seconds'] ?? item['totalSeconds']) > 0) {
      return true;
    }
    if (parseMinutes(item) > 0) return true;
    if (parseExtraSeconds(item) > 0) return true;
    return false;
  }

  /// Full lesson/course/section length in seconds — preferred for logic.
  static int resolveTotalSeconds(Map<dynamic, dynamic> item) {
    final direct =
        _toNonNegativeInt(item['total_seconds'] ?? item['totalSeconds']);
    if (direct > 0) return direct;

    final progress = item['progress'];
    if (progress is Map) {
      final fromProgress = _toNonNegativeInt(
        progress['total_seconds'] ?? progress['totalSeconds'],
      );
      if (fromProgress > 0) return fromProgress;
    }

    final minutes = parseMinutes(item);
    final seconds = parseExtraSeconds(item);
    if (minutes > 0 || seconds > 0) return (minutes * 60) + seconds;

    return 0;
  }

  static ({int hours, int minutes, int seconds}) splitHms(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    return (
      hours: safe ~/ 3600,
      minutes: (safe % 3600) ~/ 60,
      seconds: safe % 60,
    );
  }

  static bool _isArabicDurationText(String value) {
    return RegExp(r'[سدث]').hasMatch(value);
  }

  static String _formatUnit(int value, String unit, {required bool isArabic}) {
    return isArabic ? '$value $unit' : '$value$unit';
  }

  /// Human-readable label: hours · minutes · seconds (omits zero parts).
  static String formatTotalSeconds(
    int totalSeconds, {
    bool isArabic = false,
    String? hourUnit,
    String? minuteUnit,
    String? secondUnit,
  }) {
    if (totalSeconds <= 0) return '—';

    final hour = hourUnit ?? (isArabic ? 'س' : 'h');
    final minute = minuteUnit ?? (isArabic ? 'د' : 'm');
    final second = secondUnit ?? (isArabic ? 'ث' : 's');

    final parts = splitHms(totalSeconds);
    final segments = <String>[];

    if (parts.hours > 0) {
      segments.add(_formatUnit(parts.hours, hour, isArabic: isArabic));
    }
    if (parts.minutes > 0) {
      segments.add(_formatUnit(parts.minutes, minute, isArabic: isArabic));
    }
    if (parts.seconds > 0 || segments.isEmpty) {
      segments.add(_formatUnit(parts.seconds, second, isArabic: isArabic));
    }
    return segments.join(_separator);
  }

  static String formatLessonDuration(
    Map<dynamic, dynamic>? item, {
    bool isArabic = false,
    String? hourUnit,
    String? minuteUnit,
    String? secondUnit,
  }) {
    if (item == null) return '—';
    final prepared = readPreparedDurationLabel(item, isArabic: isArabic);
    if (prepared != null) return prepared;
    final total = resolveTotalSeconds(item);
    if (total > 0) {
      return formatTotalSeconds(
        total,
        isArabic: isArabic,
        hourUnit: hourUnit,
        minuteUnit: minuteUnit,
        secondUnit: secondUnit,
      );
    }
    return '—';
  }

  /// Sum lesson/section durations for a course curriculum.
  static int sumCurriculumTotalSeconds(Map<String, dynamic> course) {
    var total = 0;

    void addFromLesson(Map lesson) {
      total += resolveTotalSeconds(lesson);
    }

    final curriculum = course['curriculum'];
    if (curriculum is List) {
      for (final item in curriculum) {
        if (item is! Map) continue;
        final nested = item['lessons'];
        if (nested is List) {
          final sectionTotal = resolveTotalSeconds(item);
          if (sectionTotal > 0) {
            total += sectionTotal;
          } else {
            for (final lesson in nested) {
              if (lesson is Map) addFromLesson(lesson);
            }
          }
        } else {
          addFromLesson(item);
        }
      }
    }
    if (total > 0) return total;

    final lessons = course['lessons'];
    if (lessons is List) {
      for (final lesson in lessons) {
        if (lesson is Map) addFromLesson(lesson);
      }
    }
    return total;
  }

  static bool _isPreformattedDuration(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || int.tryParse(trimmed) != null) return false;
    return RegExp(r'[سدثhmsec:]', caseSensitive: false).hasMatch(trimmed);
  }

  static String? readPreparedDurationLabel(
    Map<dynamic, dynamic> item, {
    required bool isArabic,
  }) {
    for (final key in ['duration_label', 'durationLabel']) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) {
        final trimmed = value.trim();
        if (isArabic || !_isArabicDurationText(trimmed)) {
          return trimmed;
        }
      }
    }
    final durationText = item['duration'];
    if (durationText is String && durationText.trim().isNotEmpty) {
      final trimmed = durationText.trim();
      if (!_isPreformattedDuration(trimmed)) return null;
      if (isArabic) return trimmed;
      if (!_isArabicDurationText(trimmed)) return trimmed;
    }
    return null;
  }

  static bool _hasStoredMinutesField(Map<dynamic, dynamic> item) {
    final minutesField =
        item['duration_minutes'] ?? item['durationMinutes'];
    if (minutesField is num && minutesField > 0) return true;
    final durationField = item['duration'];
    return durationField is num && durationField > 0;
  }

  /// Fields to persist when caching course/lesson maps locally.
  static Map<String, dynamic> durationSnapshotForCache(
    Map<String, dynamic> source,
  ) {
    final snapshot = <String, dynamic>{};
    for (final key in [
      'duration_minutes',
      'durationMinutes',
      'duration_seconds',
      'durationSeconds',
      'total_seconds',
      'totalSeconds',
      'duration_hours',
      'hours',
      'duration_label',
      'durationLabel',
    ]) {
      if (source[key] != null) snapshot[key] = source[key];
    }
    final label = readPreparedDurationLabel(source, isArabic: true);
    if (label != null && !snapshot.containsKey('duration_label')) {
      snapshot['duration_label'] = label;
    }
    final total = resolveTotalSeconds(source);
    if (total > 0) snapshot['total_seconds'] = total;
    return snapshot;
  }

  static String formatCourseDurationLabel(
    Map<String, dynamic> course, {
    bool isArabic = false,
    String? hourUnit,
    String? minuteUnit,
    String? secondUnit,
  }) {
    final prepared = readPreparedDurationLabel(course, isArabic: isArabic);
    if (prepared != null) return prepared;

    final courseTotal = resolveTotalSeconds(course);
    if (courseTotal > 0) {
      return formatTotalSeconds(
        courseTotal,
        isArabic: isArabic,
        hourUnit: hourUnit,
        minuteUnit: minuteUnit,
        secondUnit: secondUnit,
      );
    }

    final fromLessons = sumCurriculumTotalSeconds(course);
    if (fromLessons > 0) {
      return formatTotalSeconds(
        fromLessons,
        isArabic: isArabic,
        hourUnit: hourUnit,
        minuteUnit: minuteUnit,
        secondUnit: secondUnit,
      );
    }

    final minutes = parseMinutes(course);
    final seconds = parseExtraSeconds(course);
    if (minutes > 0 || seconds > 0) {
      return formatTotalSeconds(
        (minutes * 60) + seconds,
        isArabic: isArabic,
        hourUnit: hourUnit,
        minuteUnit: minuteUnit,
        secondUnit: secondUnit,
      );
    }

    // `duration_hours` alone is legacy in some list APIs — skip if minutes exist.
    final hours =
        _toNonNegativeInt(course['duration_hours'] ?? course['hours']);
    if (hours > 0 && !_hasStoredMinutesField(course)) {
      return formatTotalSeconds(
        (hours * 3600) + seconds,
        isArabic: isArabic,
        hourUnit: hourUnit,
        minuteUnit: minuteUnit,
        secondUnit: secondUnit,
      );
    }

    final zeroSecond = secondUnit ?? (isArabic ? 'ث' : 's');
    return _formatUnit(0, zeroSecond, isArabic: isArabic);
  }

  static int watchedSeconds(Map<dynamic, dynamic>? item) {
    if (item == null) return 0;
    final progress = item['progress'];
    if (progress is Map) {
      return _toNonNegativeInt(
        progress['watched_seconds'] ?? progress['watchedSeconds'],
      );
    }
    return 0;
  }

  /// Completion percentage using `progress.total_seconds`, not minutes only.
  static int progressPercentage(Map<dynamic, dynamic>? item) {
    if (item == null) return 0;
    final progress = item['progress'];
    if (progress is Map) {
      final pct = progress['percentage'];
      if (pct is num) return pct.round().clamp(0, 100);
      final watched = _toNonNegativeInt(
        progress['watched_seconds'] ?? progress['watchedSeconds'],
      );
      final total = _toNonNegativeInt(
        progress['total_seconds'] ?? progress['totalSeconds'],
      );
      if (total > 0) {
        return ((watched / total) * 100).round().clamp(0, 100);
      }
    }
    final total = resolveTotalSeconds(item);
    if (total <= 0) return 0;
    return ((watchedSeconds(item) / total) * 100).round().clamp(0, 100);
  }

  /// YouTube metadata usually returns whole minutes only.
  static void applyYoutubeMinutes(Map<dynamic, dynamic> lesson, int minutes) {
    if (minutes <= 0) return;
    lesson['duration_minutes'] = minutes;
    lesson['duration_seconds'] = 0;
    lesson['total_seconds'] = minutes * 60;
  }

  /// Copy duration/progress fields from lesson detail API into a lesson map.
  static void mergeDurationFields(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
  ) {
    for (final key in [
      'duration_minutes',
      'durationMinutes',
      'duration_seconds',
      'durationSeconds',
      'total_seconds',
      'totalSeconds',
      'duration_label',
      'durationLabel',
      'duration_hours',
      'hours',
    ]) {
      if (source[key] != null) target[key] = source[key];
    }
    if (source['progress'] is Map) {
      target['progress'] = source['progress'];
    }
  }
}
