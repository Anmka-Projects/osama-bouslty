import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Service for payments and checkout
class PaymentsService {
  PaymentsService._();

  static final PaymentsService instance = PaymentsService._();

  static Map<String, dynamic> _bankTransferBody({
    String? accountHolderName,
    String? bankAccountNumber,
    String? transferReference,
  }) {
    return {
      if (accountHolderName != null && accountHolderName.trim().isNotEmpty)
        'account_holder_name': accountHolderName.trim(),
      if (bankAccountNumber != null && bankAccountNumber.trim().isNotEmpty)
        'bank_account_number': bankAccountNumber.trim(),
      if (transferReference != null && transferReference.trim().isNotEmpty)
        'transfer_reference': transferReference.trim(),
    };
  }

  /// Initiate checkout
  ///
  /// When [lessonId] is provided this is a per-lesson purchase:
  /// `item_type: lesson` + `lesson_id` (`docs/LIVE_LESSONS_BACKEND.md`).
  Future<Map<String, dynamic>> initiateCheckout({
    required String courseId,
    required String paymentMethod,
    String? lessonId,
    String? couponCode,
    String? accountHolderName,
    String? bankAccountNumber,
    String? transferReference,
  }) async {
    try {
      final body = <String, dynamic>{
        'course_id': courseId,
        'payment_method': paymentMethod,
        if (lessonId != null && lessonId.isNotEmpty) ...{
          'item_type': 'lesson',
          'lesson_id': lessonId,
        },
        if (couponCode != null && couponCode.isNotEmpty)
          'coupon_code': couponCode,
        if (paymentMethod == 'bank_account')
          ..._bankTransferBody(
            accountHolderName: accountHolderName,
            bankAccountNumber: bankAccountNumber,
            transferReference: transferReference,
          ),
      };

      final response = await ApiClient.instance.post(
        ApiEndpoints.payments,
        body: body,
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to initiate checkout');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Complete checkout
  Future<Map<String, dynamic>> completeCheckout({
    required String checkoutSessionId,
    required String paymentMethod,
    required String paymentToken,
    String? accountHolderName,
    String? bankAccountNumber,
    String? transferReference,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.confirmPayment(checkoutSessionId),
        body: {
          'checkout_session_id': checkoutSessionId,
          'payment_method': paymentMethod,
          'payment_token': paymentToken,
          if (paymentMethod == 'bank_account')
            ..._bankTransferBody(
              accountHolderName: accountHolderName,
              bankAccountNumber: bankAccountNumber,
              transferReference: transferReference,
            ),
        },
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to complete checkout');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Validate coupon
  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required String courseId,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.validateCoupon,
        body: {
          'code': code,
          'course_id': courseId,
        },
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Invalid coupon code');
      }
    } catch (e) {
      rethrow;
    }
  }
}
