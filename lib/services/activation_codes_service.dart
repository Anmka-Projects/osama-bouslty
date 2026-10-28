import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

/// Service for course activation codes (instant free unlock).
///
/// `POST /api/activation-codes/redeem` — code is bound to a single course
/// (`docs/FLUTTER_ENROLLMENT_REQUESTS_AND_ACTIVATION_CODES.md` §2).
class ActivationCodesService {
  ActivationCodesService._();

  static final ActivationCodesService instance = ActivationCodesService._();

  /// Redeem [code] for [courseId].
  ///
  /// Returns `data`: `{course_id, course_title, enrolled_course_ids, message}`.
  /// `enrolled_course_ids` may contain more than one id when the course is part
  /// of a bundle. Throws [Exception] with the server message on failure.
  Future<Map<String, dynamic>> redeemCode({
    required String code,
    required String courseId,
  }) async {
    final body = <String, dynamic>{
      'code': code.trim(),
      'course_id': courseId,
    };

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 POST ${ApiEndpoints.activationCodesRedeem}');
      print(_prettyJson.convert(body));
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    final response = await ApiClient.instance.post(
      ApiEndpoints.activationCodesRedeem,
      body: body,
      requireAuth: true,
    );

    if (kDebugMode) {
      try {
        print('📥 activation-codes/redeem RESPONSE:');
        print(_prettyJson.convert(response));
      } catch (_) {
        print('📥 activation-codes/redeem RESPONSE: $response');
      }
    }

    if (response['success'] == true) {
      final data = response['data'];
      final result =
          data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      // Surface top-level `message` ("تم تفعيل الدورة بنجاح") when `data` lacks it.
      result['message'] ??= response['message'];
      return result;
    }
    throw Exception(response['message'] ?? 'Failed to redeem activation code');
  }
}
