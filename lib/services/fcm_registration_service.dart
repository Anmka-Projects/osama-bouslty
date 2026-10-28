import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import 'token_storage_service.dart';

/// Sends FCM device token to LMS API (`POST /api/device/fcm-token`).
/// See `docs/FLUTTER_FCM.md`.
class FcmRegistrationService {
  FcmRegistrationService._();

  /// `android` | `ios` | `web` per backend contract.
  static String get platformKey {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'android';
  }

  /// Registers [token] with the backend when the user is logged in.
  static Future<void> registerTokenWithBackend(String? token) async {
    if (token == null || token.length < 10) return;
    final loggedIn = await TokenStorageService.instance.isLoggedIn();
    if (!loggedIn) return;
    try {
      await ApiClient.instance.post(
        ApiEndpoints.deviceFcmToken,
        body: {
          'fcm_token': token,
          'platform': platformKey,
        },
        requireAuth: true,
      );
      if (kDebugMode) {
        final preview =
            token.length <= 12 ? token : '${token.substring(0, 12)}...';
        print('✅ FCM token registered with server ($preview)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ FCM register with server failed: $e');
      }
    }
  }

  /// Fetches current FCM token from Firebase and registers it (cold start / post-login).
  static Future<void> syncCurrentDeviceToken() async {
    final loggedIn = await TokenStorageService.instance.isLoggedIn();
    if (!loggedIn) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await registerTokenWithBackend(token);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ FCM syncCurrentDeviceToken: $e');
      }
    }
  }
}
