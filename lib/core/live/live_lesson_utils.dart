/// Helpers for "live lesson" data embedded in course curriculum lessons.
///
/// A live lesson is a curriculum lesson whose content is a scheduled live
/// session (Zoom / Google Meet / Teams …) opened inside an in-app WebView.
/// Backend contract: `docs/LIVE_LESSONS_BACKEND.md`.
///
/// Relevant lesson fields (all optional, tolerant parsing):
/// - `type` / `lesson_type` / `delivery` / `format`: `live`
/// - `is_live`: `true`
/// - `live_link` / `meeting_url` / `join_url` / `platform_link` /
///   `stream_url` / `session_link` / `live_url`: join URL
/// - `platform`: `zoom` | `meet` | `teams` | …
/// - `scheduled_at` / `start_at` / `starts_at` / `start_date` / `live_at` /
///   `scheduledAt` / `startsAt` / `date`: ISO 8601 start time
/// - `ends_at` / `end_at` / `endsAt`: ISO 8601 end time (else start +
///   `duration_minutes`)
/// - `duration_minutes` / `duration` / `length_minutes`
/// - `price` / `lesson_price` / `amount`: per-lesson price
/// - `is_free` / `is_purchased` / `is_unlocked` / `has_access` /
///   `is_owned` / `purchased`
/// - `is_locked` / `locked`
/// - `status`: `scheduled` | `upcoming` | `live` | `completed` | `ended` |
///   `cancelled`
library;

enum LiveLessonStatus { unknown, upcoming, live, ended, cancelled }

class LiveLessonUtils {
  LiveLessonUtils._();

  /// Join window before [scheduledAt] during which the Join button unlocks.
  static const Duration earlyJoinWindow = Duration(minutes: 5);

  /// Assumed session length when neither `ends_at` nor a duration is given.
  static const Duration defaultSessionLength = Duration(hours: 3);

  static bool isLiveLesson(Map<dynamic, dynamic>? lesson) {
    if (lesson == null) return false;
    final type = (lesson['type'] ??
            lesson['lesson_type'] ??
            lesson['delivery'] ??
            lesson['format'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();
    if (type == 'live' ||
        type == 'live_session' ||
        type == 'livestream' ||
        type == 'stream') {
      return true;
    }
    if (lesson['is_live'] == true || lesson['isLive'] == true) return true;
    return liveLink(lesson) != null;
  }

  /// URL to open inside the in-app WebView for the live session.
  static String? liveLink(Map<dynamic, dynamic> lesson) {
    for (final key in const [
      'live_link',
      'meeting_url',
      'join_url',
      'platform_link',
      'stream_url',
      'session_link',
      'live_url',
    ]) {
      final v = lesson[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static String? platform(Map<dynamic, dynamic> lesson) {
    final p = lesson['platform']?.toString().trim();
    return p != null && p.isNotEmpty ? p : null;
  }

  static DateTime? scheduledAt(Map<dynamic, dynamic> lesson) {
    for (final key in const [
      'scheduled_at',
      'scheduledAt',
      'start_at',
      'starts_at',
      'startsAt',
      'start_date',
      'live_at',
      'date',
    ]) {
      final v = lesson[key]?.toString().trim();
      if (v == null || v.isEmpty) continue;
      final dt = DateTime.tryParse(v);
      if (dt != null) return dt;
    }
    return null;
  }

  static int durationMinutes(Map<dynamic, dynamic> lesson) {
    for (final key in const [
      'duration_minutes',
      'durationMinutes',
      'length_minutes',
      'duration',
    ]) {
      final raw = lesson[key];
      if (raw == null) continue;
      if (raw is int) return raw;
      if (raw is num) return raw.round();
      final parsed = int.tryParse(raw.toString().trim());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static DateTime? endsAt(Map<dynamic, dynamic> lesson) {
    for (final key in const ['ends_at', 'endsAt', 'end_at', 'end_date']) {
      final v = lesson[key]?.toString().trim();
      if (v == null || v.isEmpty) continue;
      final dt = DateTime.tryParse(v);
      if (dt != null) return dt;
    }
    final start = scheduledAt(lesson);
    if (start == null) return null;
    final minutes = durationMinutes(lesson);
    return start.add(
      minutes > 0 ? Duration(minutes: minutes) : defaultSessionLength,
    );
  }

  /// Per-lesson price (`0` means free / included).
  static double price(Map<dynamic, dynamic> lesson) {
    for (final key in const ['price', 'lesson_price', 'amount']) {
      final raw = lesson[key];
      if (raw == null) continue;
      if (raw is num) return raw.toDouble();
      final parsed = double.tryParse(raw.toString().trim());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static bool isFree(Map<dynamic, dynamic> lesson) {
    if (lesson['is_free'] == true || lesson['isFree'] == true) return true;
    return price(lesson) <= 0;
  }

  static bool isPurchased(Map<dynamic, dynamic> lesson) {
    for (final key in const [
      'is_purchased',
      'isPurchased',
      'is_unlocked',
      'isUnlocked',
      'has_access',
      'hasAccess',
      'is_owned',
      'isOwned',
      'purchased',
    ]) {
      if (lesson[key] == true) return true;
    }
    return false;
  }

  /// Whether the student can open this lesson: enrolled in the course,
  /// individually purchased it, or it is free and not explicitly locked.
  static bool hasAccess(
    Map<dynamic, dynamic> lesson, {
    required bool courseEnrolled,
    bool isOwnCourse = false,
  }) {
    if (courseEnrolled || isOwnCourse) return true;
    if (isPurchased(lesson)) return true;
    if (lesson['is_locked'] == true || lesson['locked'] == true) return false;
    return isFree(lesson);
  }

  /// Whether the lesson still requires a purchase to unlock.
  static bool requiresPurchase(
    Map<dynamic, dynamic> lesson, {
    required bool courseEnrolled,
    bool isOwnCourse = false,
  }) {
    if (hasAccess(lesson,
        courseEnrolled: courseEnrolled, isOwnCourse: isOwnCourse)) {
      return false;
    }
    return price(lesson) > 0;
  }

  /// Session lifecycle status. Prefers the server-provided `status`; falls
  /// back to computing it from `scheduled_at` + duration/end time.
  static LiveLessonStatus status(
    Map<dynamic, dynamic> lesson, {
    DateTime? now,
  }) {
    final raw = lesson['status']?.toString().toLowerCase().trim() ?? '';
    switch (raw) {
      case 'live':
      case 'live_now':
      case 'ongoing':
      case 'started':
        return LiveLessonStatus.live;
      case 'completed':
      case 'ended':
      case 'finished':
      case 'past':
        return LiveLessonStatus.ended;
      case 'cancelled':
      case 'canceled':
        return LiveLessonStatus.cancelled;
      case 'scheduled':
      case 'upcoming':
        return LiveLessonStatus.upcoming;
    }

    final n = now ?? DateTime.now();
    final start = scheduledAt(lesson);
    if (start == null) {
      return liveLink(lesson) != null
          ? LiveLessonStatus.live
          : LiveLessonStatus.unknown;
    }
    final end = endsAt(lesson);
    if (n.isBefore(start.toLocal())) return LiveLessonStatus.upcoming;
    if (end != null && n.isAfter(end.toLocal())) {
      return LiveLessonStatus.ended;
    }
    return LiveLessonStatus.live;
  }

  /// Whether the student may open the live link right now.
  static bool canJoinNow(Map<dynamic, dynamic> lesson, {DateTime? now}) {
    if (liveLink(lesson) == null) return false;
    final s = status(lesson, now: now);
    if (s == LiveLessonStatus.live) return true;
    if (s != LiveLessonStatus.upcoming) return false;
    final start = scheduledAt(lesson)?.toLocal();
    if (start == null) return true;
    final n = (now ?? DateTime.now());
    return !n.isBefore(start.subtract(earlyJoinWindow));
  }
}
