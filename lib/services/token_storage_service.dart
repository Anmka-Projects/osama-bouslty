import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and retrieving authentication tokens
class TokenStorageService {
  TokenStorageService._();

  static final TokenStorageService instance = TokenStorageService._();

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user_data';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserId = 'user_id';

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRefreshToken, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  /// Save tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('TokenStorageService: refused empty access token');
      }
      throw Exception('Access token cannot be empty');
    }

    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.setString(_keyAccessToken, accessToken),
      prefs.setString(_keyRefreshToken, refreshToken),
    ]);

    final savedToken = prefs.getString(_keyAccessToken);
    if (kDebugMode &&
        (savedToken == null || savedToken != accessToken)) {
      debugPrint(
        'TokenStorageService: save verification failed (saved: ${savedToken != null})',
      );
    }
  }

  /// Save user ID (used to isolate per-user downloads)
  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  /// Get the stored user ID, returns empty string if not set
  Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId) ?? '';
  }

  /// Save user role (for role-based routing: student vs instructor)
  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role);
  }

  /// Get stored user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  /// Clear all tokens, role, and user id
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyAccessToken),
      prefs.remove(_keyRefreshToken),
      prefs.remove(_keyUser),
      prefs.remove(_keyUserRole),
      prefs.remove(_keyUserId),
    ]);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
