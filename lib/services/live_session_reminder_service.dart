import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../core/notification_service/notification_service.dart';

/// Schedules local reminders before a live lesson / live session starts.
///
/// Notifications fire at 30 minutes, 10 minutes, and 0 minutes before the
/// session start. They are purely local — the backend should also send FCM
/// reminders as the source of truth (see
/// `docs/FLUTTER_LIVE_LESSONS_BACKEND_SPEC.md`).
///
/// Payload format matches [FirebaseNotification._scheduleNavigation]: the
/// `course_id` key deep-links into the course details screen.
class LiveSessionReminderService {
  LiveSessionReminderService._();

  static final LiveSessionReminderService instance =
      LiveSessionReminderService._();

  static bool _tzInitialized = false;

  /// Reminder offsets before session start (30 min, 10 min, at start).
  static const List<Duration> reminderOffsets = [
    Duration(minutes: 30),
    Duration(minutes: 10),
    Duration.zero,
  ];

  static Future<void> ensureInitialized() async {
    if (_tzInitialized) return;
    tzdata.initializeTimeZones();
    _tzInitialized = true;
  }

  FlutterLocalNotificationsPlugin get _plugin =>
      FirebaseNotification.flutterLocalNotificationsPlugin;

  /// Stable notification id per (session, reminder-slot). Keeps ids inside
  /// the 32-bit range expected by the platform plugins.
  static int _notificationId(String sessionId, int slot) {
    final base = sessionId.hashCode & 0x0FFFFF;
    return base * 8 + slot;
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await android?.canScheduleExactNotifications() ?? false;
      return canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  /// Schedule reminders for one live session/lesson.
  ///
  /// [bodyBuilder] receives the minutes-before-start (30, 10, 0) and returns
  /// the notification body text for that reminder.
  Future<void> scheduleSessionReminders({
    required String sessionId,
    required String courseId,
    String? lessonId,
    required String sessionTitle,
    required DateTime start,
    required String notificationTitle,
    required String Function(int minutesBefore) bodyBuilder,
  }) async {
    if (sessionId.isEmpty) return;
    await ensureInitialized();
    await cancelSessionReminders(sessionId);

    final mode = await _scheduleMode();
    final now = DateTime.now();
    final payload = jsonEncode(<String, dynamic>{
      'type': 'live_session',
      'course_id': courseId,
      if (lessonId != null && lessonId.isNotEmpty) 'lesson_id': lessonId,
    });

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'live_session_reminders',
        'Live session reminders',
        channelDescription:
            'Reminders before your purchased live sessions start.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    for (var i = 0; i < reminderOffsets.length; i++) {
      final offset = reminderOffsets[i];
      final fireAt = start.subtract(offset);
      if (!fireAt.isAfter(now.add(const Duration(seconds: 10)))) {
        continue; // too close or already passed — skip
      }
      try {
        await _plugin.zonedSchedule(
          _notificationId(sessionId, i),
          notificationTitle,
          bodyBuilder(offset.inMinutes),
          // Absolute instant — scheduling in UTC avoids device-tz lookup.
          tz.TZDateTime.from(fireAt.toUtc(), tz.UTC),
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ LiveSessionReminderService schedule failed: $e');
        }
      }
    }

    if (kDebugMode) {
      print('🔔 Reminders scheduled for session $sessionId at $start');
    }
  }

  /// Cancel all reminder slots for a session (e.g. after it ends or the
  /// student turns the reminder off).
  Future<void> cancelSessionReminders(String sessionId) async {
    for (var i = 0; i < reminderOffsets.length; i++) {
      try {
        await _plugin.cancel(_notificationId(sessionId, i));
      } catch (_) {}
    }
  }

  /// Whether any reminder slot is still pending for this session.
  Future<bool> hasPendingReminders(String sessionId) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (var i = 0; i < reminderOffsets.length; i++) {
        final id = _notificationId(sessionId, i);
        if (pending.any((r) => r.id == id)) return true;
      }
    } catch (_) {}
    return false;
  }
}
