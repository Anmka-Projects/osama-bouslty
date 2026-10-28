// Import necessary libraries
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' show Random;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:educational_app/firebase_options.dart';
import '../../core/navigation/app_router.dart';
import '../../core/navigation/route_names.dart';
import '../../services/fcm_registration_service.dart';

/// Runs in a separate isolate when the app is in the background or terminated.
/// Must not rely on UI; initializes Firebase + local notifications, then shows a tray notification.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final bgTitle =
      message.notification?.title ?? message.data['title']?.toString();
  log('[FCM background] messageId=${message.messageId} title=$bgTitle');
  await FirebaseNotification.prepareBackgroundIsolate();
  await FirebaseNotification.showBasicNotification(message);
}

/// Optional: required on Android if using background notification actions (placeholder).
@pragma('vm:entry-point')
void _onBackgroundLocalNotificationTapped(NotificationResponse details) {
  log('[FCM] local notification tap (background entry): ${details.payload}');
}

class FirebaseNotification {
  static final FirebaseMessaging messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static String? fcmToken;

  static StreamSubscription<String>? _tokenRefreshSubscription;

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  static bool _interactionHandlersReady = false;

  /// Call once after [Firebase.initializeApp], before [runApp].
  static Future<void> initializeNotifications() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await requestNotificationPermission();
    await getFcmToken();
    await initializeLocalNotifications();
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    /// Foreground: show in-app banner (iOS) + duplicate as local notification for consistency.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('[FCM foreground] messageId=${message.messageId}');
      showBasicNotification(message);
    });

    _setupInteractionHandlers();
  }

  /// Minimal plugin setup for the FCM background isolate (no router / navigation).
  static Future<void> prepareBackgroundIsolate() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundLocalNotificationTapped,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _setupInteractionHandlers() {
    if (_interactionHandlersReady) return;
    _interactionHandlersReady = true;

    /// User tapped a notification while app was in memory but not foreground.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('[FCM background→foreground] opened from tray messageId=${message.messageId}');
      _handlePayloadNavigation(_mapMessageData(message.data));
    });

    /// Do not call [getInitialMessage] here — router is not ready. Use [consumeTerminatedStateLaunch].
  }

  /// Run after first frame when [MaterialApp] / GoRouter is mounted (cold start / killed).
  static Future<void> consumeTerminatedStateLaunch() async {
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        log('[FCM terminated/killed] opened from system notification');
        _scheduleNavigation(_mapMessageData(initial.data));
        return;
      }

      final launchDetails =
          await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final payload =
            launchDetails!.notificationResponse?.payload?.trim() ?? '';
        if (payload.isNotEmpty) {
          log('[FCM terminated/killed] opened from local notification tap');
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map) {
              _scheduleNavigation(Map<String, dynamic>.from(decoded));
            }
          } catch (e) {
            log('[FCM] launch payload decode error: $e');
          }
        }
      }
    } catch (e) {
      log('[FCM] consumeTerminatedStateLaunch error: $e');
    }
  }

  static Map<String, dynamic> _mapMessageData(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(data);
  }

  /// Routes using `data` from docs/FLUTTER_FCM.md (`course_id`, `deep_link`).
  static void _handlePayloadNavigation(Map<String, dynamic> data) {
    _scheduleNavigation(data);
  }

  static void _scheduleNavigation(Map<String, dynamic> data) {
    final courseId = data['course_id']?.toString() ??
        data['courseId']?.toString();
    final deepLink = data['deep_link']?.toString();
    String? resolvedId = courseId;
    if ((resolvedId == null || resolvedId.isEmpty) &&
        deepLink != null &&
        deepLink.startsWith('course:')) {
      resolvedId = deepLink.substring('course:'.length).trim();
    }
    if (resolvedId == null || resolvedId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppRouter.rootNavigatorKey.currentContext;
      if (ctx == null) return;
      try {
        GoRouter.of(ctx).push(
          RouteNames.courseDetails,
          extra: <String, dynamic>{'id': resolvedId},
        );
      } catch (e) {
        log('FCM navigation error: $e');
      }
    });
  }

  static Future<void> initializeLocalNotifications() async {
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onForegroundLocalNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundLocalNotificationTapped,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _onForegroundLocalNotificationTapped(NotificationResponse details) {
    final payload = details.payload?.trim() ?? '';
    if (payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _handlePayloadNavigation(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      log('[FCM] local tap payload error: $e');
    }
  }

  static Future<void> requestNotificationPermission() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      log('Android notification permission: $status');
    }

    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    log('FCM requestPermission: ${settings.authorizationStatus}');
  }

  static Future<void> getFcmToken() async {
    try {
      fcmToken = await messaging.getToken();
      log('FCM Token: $fcmToken');

      await FcmRegistrationService.registerTokenWithBackend(fcmToken);

      _tokenRefreshSubscription ??=
          messaging.onTokenRefresh.listen((String newToken) {
        fcmToken = newToken;
        log('FCM Token refreshed');
        FcmRegistrationService.registerTokenWithBackend(newToken);
      });
    } catch (e) {
      log('Error getting FCM token: $e');
    }
  }

  static final Random random = Random();

  static int generateRandomId() {
    return random.nextInt(10000);
  }

  /// Used for foreground (onMessage), background isolate, and optionally system display.
  static Future<void> showBasicNotification(RemoteMessage message) async {
    try {
      final title = message.notification?.title ??
          message.data['title']?.toString() ??
          'Notification';
      final body = message.notification?.body ??
          message.data['body']?.toString() ??
          '';

      final dataMap = Map<String, dynamic>.from(message.data);
      final payload = dataMap.isEmpty ? null : jsonEncode(dataMap);

      final NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await flutterLocalNotificationsPlugin.show(
        generateRandomId(),
        title,
        body,
        details,
        payload: payload,
      );

      log('[FCM] local tray notification shown hasPayload=${payload != null}');
    } catch (e) {
      log('Error showing local notification: $e');
    }
  }
}

/// Attach under [MaterialApp] so cold-start notification routing runs when GoRouter exists.
class FcmLaunchCoordinator extends StatefulWidget {
  const FcmLaunchCoordinator({super.key, required this.child});

  final Widget child;

  @override
  State<FcmLaunchCoordinator> createState() => _FcmLaunchCoordinatorState();
}

class _FcmLaunchCoordinatorState extends State<FcmLaunchCoordinator> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseNotification.consumeTerminatedStateLaunch();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
