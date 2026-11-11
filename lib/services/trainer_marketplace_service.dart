import 'dart:math';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/trainer_marketplace.dart';

class TrainerMarketplaceService {
  TrainerMarketplaceService._();
  static final TrainerMarketplaceService instance =
      TrainerMarketplaceService._();

  String _idempotency() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return response;
  }

  Future<Map<String, dynamic>> listTrainers({
    int page = 1,
    String? query,
    String? language,
    double? minRating,
    String? categoryId,
    String? subcategoryId,
    String? subjectId,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '20',
    };
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    if (language != null && language.isNotEmpty) params['language'] = language;
    if (minRating != null) params['min_rating'] = minRating.toString();
    if (categoryId != null && categoryId.isNotEmpty)
      params['category_id'] = categoryId;
    if (subcategoryId != null && subcategoryId.isNotEmpty) {
      params['subcategory_id'] = subcategoryId;
    }
    if (subjectId != null && subjectId.isNotEmpty)
      params['subject_id'] = subjectId;
    final uri =
        Uri.parse(ApiEndpoints.trainers).replace(queryParameters: params);
    final response =
        await ApiClient.instance.get(uri.toString(), requireAuth: false);
    final data = _data(response);
    final rows = (data['trainers'] as List?) ??
        (response['data'] is List ? response['data'] as List : const []);
    return {
      'trainers': rows
          .whereType<Map>()
          .map((item) => TrainerCard.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      'pagination': data['pagination'] ?? const {},
      'platform': data['platform'] ?? const {},
    };
  }

  /// Admin-controlled "المسارات" list — GET /api/paths (public).
  Future<List<String>> paths() async {
    final response =
        await ApiClient.instance.get(ApiEndpoints.paths, requireAuth: false);
    final data = _data(response);
    final list = data['paths'] as List? ?? const [];
    return list.map((e) => e.toString()).toList();
  }

  Future<TrainerProfileDetail> trainer(String id) async {
    final response = await ApiClient.instance
        .get(ApiEndpoints.trainer(id), requireAuth: false);
    return TrainerProfileDetail.fromJson(_data(response));
  }

  Future<List<AvailabilitySlot>> availability(String trainerId) async {
    final response = await ApiClient.instance.get(
      ApiEndpoints.trainerAvailability(trainerId),
      requireAuth: false,
    );
    final data = _data(response);
    final slots = (data['slots'] as List?) ?? const [];
    return slots
        .whereType<Map>()
        .map((item) =>
            AvailabilitySlot.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<BookingQuote> quote({
    required String offeringId,
    required String slotId,
    String? coupon,
  }) async {
    final response = await ApiClient.instance.post(
      ApiEndpoints.bookingQuotes,
      headers: {'Idempotency-Key': _idempotency()},
      body: {
        'offering_id': offeringId,
        'slot_id': slotId,
        'coupon_code': coupon,
      },
    );
    return BookingQuote.fromJson(_data(response));
  }

  Future<SessionBooking> createBooking({
    String? quoteId,
    String? packagePurchaseId,
    String? slotId,
    required String paymentMethod,
    String? notes,
    String? receiptUrl,
  }) async {
    final response = await ApiClient.instance.post(
      ApiEndpoints.bookings,
      headers: {'Idempotency-Key': _idempotency()},
      body: {
        if (quoteId != null) 'quote_id': quoteId,
        if (packagePurchaseId != null) 'package_purchase_id': packagePurchaseId,
        if (slotId != null) 'slot_id': slotId,
        'payment_method': paymentMethod,
        'student_notes': notes,
        'receipt_url': receiptUrl,
      },
    );
    return SessionBooking.fromJson(_data(response));
  }

  Future<List<SessionBooking>> myBookings(
      {String role = 'student', String? status}) async {
    final params = <String, String>{
      'role': role,
      'page': '1',
      'per_page': '50'
    };
    if (status != null) params['status'] = status;
    final uri =
        Uri.parse(ApiEndpoints.bookings).replace(queryParameters: params);
    final response = await ApiClient.instance.get(uri.toString());
    final data = _data(response);
    final rows = (data['bookings'] as List?) ?? const [];
    return rows
        .whereType<Map>()
        .map((item) => SessionBooking.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<SessionBooking> booking(String id) async {
    final response = await ApiClient.instance.get(ApiEndpoints.booking(id));
    return SessionBooking.fromJson(_data(response));
  }

  Future<Map<String, dynamic>> join(String id) async {
    final response =
        await ApiClient.instance.post(ApiEndpoints.bookingJoin(id), body: {});
    return _data(response);
  }

  Future<SessionBooking> cancel(String id, String reason) async {
    final response = await ApiClient.instance.post(
      ApiEndpoints.bookingCancel(id),
      body: {'reason': reason},
    );
    return SessionBooking.fromJson(_data(response));
  }

  Future<SessionBooking> respondToRequest(String id,
      {required bool accept, String? reason}) async {
    final response = await ApiClient.instance.post(
      ApiEndpoints.instructorBookingRespond(id),
      body: {'accept': accept, 'reason': reason},
    );
    return SessionBooking.fromJson(_data(response));
  }

  Future<SessionBooking> reschedule(String id,
      {required String slotId, required int version, String? reason}) async {
    final response = await ApiClient.instance.post(
      ApiEndpoints.bookingReschedule(id),
      body: {
        'slot_id': slotId,
        'expected_schedule_version': version,
        'reason': reason,
      },
    );
    return SessionBooking.fromJson(_data(response));
  }

  Future<void> review(String id, {required int rating, String? comment}) async {
    await ApiClient.instance.post(
      ApiEndpoints.bookingReview(id),
      body: {'rating': rating, 'comment': comment},
    );
  }

  Future<Map<String, dynamic>> myTrainerProfile() async {
    final response =
        await ApiClient.instance.get(ApiEndpoints.instructorTrainerProfile);
    return _data(response);
  }

  Future<Map<String, dynamic>> updateTrainerProfile(
      Map<String, dynamic> body) async {
    final response = await ApiClient.instance
        .put(ApiEndpoints.instructorTrainerProfile, body: body);
    return _data(response);
  }

  Future<Map<String, dynamic>> myAvailability() async {
    final response =
        await ApiClient.instance.get(ApiEndpoints.instructorAvailability);
    return _data(response);
  }

  Future<Map<String, dynamic>> saveAvailability(
      Map<String, dynamic> body) async {
    final response = await ApiClient.instance
        .put(ApiEndpoints.instructorAvailability, body: body);
    return _data(response);
  }

  Future<void> publishMeeting(String bookingId,
      {required String joinUrl, String provider = 'custom_web'}) async {
    await ApiClient.instance.post(
      ApiEndpoints.instructorBookingMeeting(bookingId),
      body: {'join_url': joinUrl, 'provider': provider},
    );
  }

  Future<Map<String, dynamic>> earnings() async {
    final response = await ApiClient.instance
        .get(ApiEndpoints.instructorMarketplaceEarnings);
    return _data(response);
  }

  Future<void> requestPayout(String amount, {String? note}) async {
    await ApiClient.instance.post(
      ApiEndpoints.instructorPayouts,
      body: {'amount': amount, 'note': note},
    );
  }
}
