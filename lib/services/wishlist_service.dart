import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Saved courses: GET/POST [ApiEndpoints.wishlist], DELETE [ApiEndpoints.wishlistItem].
/// POST JSON body: `{ "course_id": "<uuid>" }` (snake_case only).
/// Contract reference: `docs/flutter-wishlist-endpoints-update.md`.
class WishlistService {
  WishlistService._();
  
  static final WishlistService instance = WishlistService._();

  bool _isOperationSuccessful(Map<String, dynamic> response) {
    final nested = response['data'];
    if (nested is Map<String, dynamic>) {
      // Placeholder backend may return API-level success=true but data.success=false.
      if (nested['success'] == false) return false;
    }
    return true;
  }

  String _extractOperationErrorMessage(
    Map<String, dynamic> response,
    String fallback,
  ) {
    final nested = response['data'];
    if (nested is Map<String, dynamic>) {
      final nestedMsg = nested['message']?.toString().trim();
      if (nestedMsg != null && nestedMsg.isNotEmpty) return nestedMsg;
    }
    final msg = response['message']?.toString().trim();
    if (msg != null && msg.isNotEmpty) return msg;
    return fallback;
  }

  /// Get wishlist
  Future<Map<String, dynamic>> getWishlist() async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.wishlist,
        requireAuth: true,
      );
      
      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch wishlist');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add to wishlist
  Future<void> addToWishlist(String courseId) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.wishlist,
        body: {'course_id': courseId},
        requireAuth: true,
      );
      
      if (response['success'] != true || !_isOperationSuccessful(response)) {
        throw Exception(
          _extractOperationErrorMessage(response, 'Failed to add to wishlist'),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Remove from wishlist
  Future<void> removeFromWishlist(String courseId) async {
    try {
      final response = await ApiClient.instance.delete(
        ApiEndpoints.wishlistItem(courseId),
        requireAuth: true,
      );
      
      if (response['success'] != true || !_isOperationSuccessful(response)) {
        throw Exception(
          _extractOperationErrorMessage(
            response,
            'Failed to remove from wishlist',
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

