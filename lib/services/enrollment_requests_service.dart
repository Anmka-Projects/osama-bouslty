import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

const JsonEncoder _prettyJson = JsonEncoder.withIndent('  ');

/// Normalizes receipt path for `POST /api/enrollment-requests` (`receipt_image_url`):
/// full `https://...` unchanged; otherwise strip leading `/` so paths match server (`uploads/...`).
String normalizeEnrollmentReceiptImageUrl(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return '';
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  while (s.startsWith('/')) {
    s = s.substring(1);
  }
  return s;
}

/// Service for course enrollment requests (library / WhatsApp proof / gateway)
///
/// **Library:** `POST /api/enrollment-requests` — `receipt_image_url` optional
/// (`docs/flutter-library-enrollment-request.md`).
///
/// **WhatsApp proof:** `POST /api/courses/{id}/whatsapp-payment-proof` with uploaded image `url`
/// (`docs/flutter-whatsapp-payment-proof.md`).
class EnrollmentRequestsService {
  EnrollmentRequestsService._();

  static final EnrollmentRequestsService instance =
      EnrollmentRequestsService._();

  Future<Map<String, dynamic>> createEnrollmentRequest({
    required String courseId,
    required String paymentMethod,
    String? message,

    /// Per-lesson purchase (`docs/LIVE_LESSONS_BACKEND.md`). When set, the
    /// request unlocks a single lesson instead of the whole course.
    String? lessonId,

    /// Path or URL from `POST /api/upload`. Omit for library-only requests.
    String? receiptImageUrl,
  }) async {
    final receipt = receiptImageUrl != null && receiptImageUrl.trim().isNotEmpty
        ? normalizeEnrollmentReceiptImageUrl(receiptImageUrl)
        : '';

    final body = <String, dynamic>{
      'course_id': courseId,
      'payment_method': paymentMethod,
      if (lessonId != null && lessonId.isNotEmpty) 'lesson_id': lessonId,
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
      if (receipt.isNotEmpty) 'receipt_image_url': receipt,
    };

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 POST ${ApiEndpoints.enrollmentRequests}');
      print(_prettyJson.convert(body));
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    final response = await ApiClient.instance.post(
      ApiEndpoints.enrollmentRequests,
      body: body,
      requireAuth: true,
    );

    if (kDebugMode) {
      try {
        print('📥 enrollment-requests RESPONSE (raw):');
        print(_prettyJson.convert(response));
      } catch (_) {
        print('📥 enrollment-requests RESPONSE (raw): $response');
      }
    }

    if (response['success'] == true && response['data'] != null) {
      final data = Map<String, dynamic>.from(response['data'] as Map);
      if (kDebugMode) {
        print('✅ enrollment-requests data (parsed):');
        try {
          print(_prettyJson.convert(data));
        } catch (_) {
          print('$data');
        }
      }
      return data;
    }
    throw Exception(
        response['message'] ?? 'Failed to create enrollment request');
  }

  /// WhatsApp: upload image first (`POST /api/upload`), then call this with returned `url`.
  Future<Map<String, dynamic>> submitWhatsappPaymentProof({
    required String courseId,
    required String receiptImageUrl,
    String? message,

    /// Per-lesson purchase (`docs/LIVE_LESSONS_BACKEND.md`).
    String? lessonId,
  }) async {
    final receipt = receiptImageUrl.trim().isNotEmpty
        ? normalizeEnrollmentReceiptImageUrl(receiptImageUrl)
        : '';
    if (receipt.isEmpty) {
      throw Exception('Payment receipt image is required for WhatsApp proof.');
    }

    final body = <String, dynamic>{
      'receipt_image_url': receipt,
      if (lessonId != null && lessonId.isNotEmpty) 'lesson_id': lessonId,
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
    };

    if (kDebugMode) {
      print('📤 POST ${ApiEndpoints.courseWhatsappPaymentProof(courseId)}');
      print(_prettyJson.convert(body));
    }

    final response = await ApiClient.instance.post(
      ApiEndpoints.courseWhatsappPaymentProof(courseId),
      body: body,
      requireAuth: true,
    );

    if (response['success'] == true && response['data'] != null) {
      return Map<String, dynamic>.from(response['data'] as Map);
    }
    throw Exception(
      response['message'] ?? 'Failed to submit WhatsApp payment proof',
    );
  }

  Future<List<Map<String, dynamic>>> getEnrollmentRequests({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await getEnrollmentRequestsPage(
      status: status,
      page: page,
      perPage: perPage,
    );
    return result.requests;
  }

  /// `GET /enrollment-requests` with pagination meta
  /// (`docs/FLUTTER_ENROLLMENT_REQUESTS_AND_ACTIVATION_CODES.md` §1.2).
  Future<EnrollmentRequestsPage> getEnrollmentRequestsPage({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };

    final uri = Uri.parse(ApiEndpoints.enrollmentRequests)
        .replace(queryParameters: query);
    final response = await ApiClient.instance.get(
      uri.toString(),
      requireAuth: true,
    );

    if (response['success'] != true) {
      throw Exception(
          response['message'] ?? 'Failed to fetch enrollment requests');
    }

    var requests = <Map<String, dynamic>>[];
    Map<String, dynamic> meta = const {};

    final data = response['data'];
    if (data is List) {
      requests = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      final rawRequests = dataMap['requests'];
      if (rawRequests is List) {
        requests = rawRequests
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (dataMap['meta'] is Map) {
        meta = Map<String, dynamic>.from(dataMap['meta'] as Map);
      }
    }
    // Some responses put meta at the top level.
    if (meta.isEmpty && response['meta'] is Map) {
      meta = Map<String, dynamic>.from(response['meta'] as Map);
    }

    return EnrollmentRequestsPage(requests: requests, meta: meta);
  }
}

/// Page of enrollment requests + `meta` ({total, page, per_page, total_pages}).
class EnrollmentRequestsPage {
  const EnrollmentRequestsPage({required this.requests, required this.meta});

  final List<Map<String, dynamic>> requests;
  final Map<String, dynamic> meta;

  int get total => (meta['total'] as num?)?.toInt() ?? requests.length;
  int get page => (meta['page'] as num?)?.toInt() ?? 1;
  int get perPage => (meta['per_page'] as num?)?.toInt() ?? requests.length;
  int get totalPages =>
      (meta['total_pages'] as num?)?.toInt() ??
      (requests.length < perPage ? page : page + 1);
}
