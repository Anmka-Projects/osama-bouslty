import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Fetches home promo sliders (`GET /api/sliders`). Public, no auth.
class SlidersService {
  SlidersService._();

  static final SlidersService instance = SlidersService._();

  Future<List<Map<String, dynamic>>> getSliders() async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.sliders,
        requireAuth: false,
      );
      if (response['success'] != true) {
        return [];
      }
      final raw = response['data'];
      if (raw is! List) return [];

      return raw.map((e) {
        if (e is! Map) return <String, dynamic>{};
        final m = Map<String, dynamic>.from(e);
        m['image'] = ApiEndpoints.getImageUrl(m['image']?.toString());
        return m;
      }).where((m) => (m['image'] as String?)?.isNotEmpty == true).toList();
    } catch (e) {
      if (kDebugMode) {
        print('SlidersService.getSliders: $e');
      }
      return [];
    }
  }
}
