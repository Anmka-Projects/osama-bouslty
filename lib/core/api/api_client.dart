import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../auth/session_error_parser.dart';
import '../auth/session_invalidation_service.dart';
import '../../services/token_storage_service.dart';

bool _httpBodyLooksLikeHtml(String body) {
  final t = body.trim().toLowerCase();
  return t.startsWith('<!doctype') ||
      t.startsWith('<html') ||
      t.contains('<html>');
}

String? _httpHtmlPageTitle(String body) {
  final m = RegExp(
    r'<title>\s*([^<]+?)\s*</title>',
    caseSensitive: false,
  ).firstMatch(body);
  return m?.group(1)?.trim();
}

/// User-facing + [ApiException.message] when the server returns HTML (e.g. 500 error page) instead of JSON.
String _friendlyMessageForHtmlError(int statusCode, String body) {
  final title = _httpHtmlPageTitle(body);
  if (title != null && title.isNotEmpty) {
    return 'Server error ($statusCode): $title';
  }
  if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
    return 'The server is temporarily unavailable. Please try again in a moment.';
  }
  return 'Invalid response from server ($statusCode). Please try again later.';
}

String _debugErrorBodyPreview(String body, {int maxLen = 500}) {
  if (body.length <= maxLen) return body;
  return '${body.substring(0, maxLen)}… [+${body.length - maxLen} chars]';
}

/// API Client for making HTTP requests
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  /// Returns raw JWT; strips a duplicated `Bearer ` prefix if the token was stored wrong.
  static String? _normalizeBearerToken(String? token) {
    if (token == null || token.isEmpty) return null;
    var t = token.trim();
    if (t.length >= 7 && t.substring(0, 7).toLowerCase() == 'bearer ') {
      t = t.substring(7).trim();
    }
    return t.isEmpty ? null : t;
  }

  /// Helps backend MIME validation — `MultipartFile.fromPath` alone often sends generic types.
  static MediaType? _multipartMediaTypeForFilename(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.mp4')) return MediaType('video', 'mp4');
    if (lower.endsWith('.webm')) return MediaType('video', 'webm');
    if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (lower.endsWith('.doc')) return MediaType('application', 'msword');
    if (lower.endsWith('.docx')) {
      return MediaType(
        'application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    }
    return null;
  }

  /// Log API request (optionally via dart:developer for filterable logs)
  void _logRequest(String method, String url, Map<String, String>? headers,
      Map<String, dynamic>? body,
      {String? logTag}) {
    if (!kDebugMode && logTag == null) return;
    final sb = StringBuffer();
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📤 API REQUEST');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Method: $method');
    sb.writeln('URL: $url');
    if (headers != null && headers.isNotEmpty) {
      sb.writeln('Headers:');
      headers.forEach((key, value) {
        // Value is already e.g. "Bearer eyJ..." — do not prefix "Bearer " again.
        if (key.toLowerCase() == 'authorization') {
          final preview =
              value.length > 72 ? '${value.substring(0, 48)}...' : value;
          sb.writeln('  $key: $preview');
        } else {
          sb.writeln('  $key: $value');
        }
      });
      if (!headers.containsKey('Authorization')) {
        sb.writeln('  ⚠️ WARNING: Authorization header is MISSING!');
      }
    } else {
      sb.writeln('⚠️ WARNING: No headers provided!');
    }
    if (body != null && body.isNotEmpty) {
      sb.writeln('Body:');
      try {
        sb.writeln(const JsonEncoder.withIndent('  ').convert(body));
      } catch (e) {
        sb.writeln('  $body');
      }
    }
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final msg = sb.toString();
    if (logTag != null) {
      developer.log(msg, name: logTag);
    } else if (kDebugMode) {
      print(msg);
    }
  }

  /// Log API response (optionally via dart:developer for filterable logs)
  void _logResponse(String method, String url, int statusCode,
      Map<String, dynamic>? response, String? error,
      {String? logTag}) {
    if (!kDebugMode && logTag == null) return;
    final sb = StringBuffer();
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('📥 API RESPONSE');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('Method: $method');
    sb.writeln('URL: $url');
    sb.writeln('Status Code: $statusCode');
    if (error != null) {
      sb.writeln('❌ Error: $error');
    } else if (response != null) {
      sb.writeln('Response:');
      try {
        sb.writeln(const JsonEncoder.withIndent('  ').convert(response));
      } catch (e) {
        sb.writeln('  $response');
      }
    }
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    final msg = sb.toString();
    if (logTag != null) {
      developer.log(msg, name: logTag);
    } else if (kDebugMode) {
      print(msg);
    }
  }

  /// Base headers for all requests
  Future<Map<String, String>> _getHeaders({
    Map<String, String>? additionalHeaders,
    bool requireAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add authentication token from cache if required (like Dio interceptor)
    if (requireAuth) {
      final token = await TokenStorageService.instance.getAccessToken();
      final jwt = _normalizeBearerToken(token);
      if (jwt != null && jwt.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwt';
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      if (logTag != null) {
        _logRequest('GET', url, finalHeaders, null, logTag: logTag);
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: finalHeaders,
          )
          .timeout(const Duration(seconds: 45));

      final responseData = _handleResponse(response);
      if (logTag != null) {
        _logResponse('GET', url, response.statusCode, responseData, null,
            logTag: logTag);
      }
      return responseData;
    } catch (e) {
      if (logTag != null) {
        _logResponse('GET', url, 0, null, e.toString(), logTag: logTag);
      }
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      _logRequest('POST', url, finalHeaders, body, logTag: logTag);

      final response = await http
          .post(
            Uri.parse(url),
            headers: finalHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 45));

      final responseData = _handleResponse(response);
      _logResponse('POST', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      _logResponse('POST', url, 0, null, e.toString(), logTag: logTag);
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      _logRequest('PUT', url, finalHeaders, body, logTag: logTag);

      final response = await http
          .put(
            Uri.parse(url),
            headers: finalHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 45));

      final responseData = _handleResponse(response);
      _logResponse('PUT', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      _logResponse('PUT', url, 0, null, e.toString(), logTag: logTag);
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// PATCH request
  Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      _logRequest('PATCH', url, finalHeaders, body, logTag: logTag);

      final response = await http
          .patch(
            Uri.parse(url),
            headers: finalHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 45));

      final responseData = _handleResponse(response);
      _logResponse('PATCH', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      _logResponse('PATCH', url, 0, null, e.toString(), logTag: logTag);
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// DELETE request (optional JSON [body], e.g. password confirmation).
  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final finalHeaders = await _getHeaders(
        additionalHeaders: headers,
        requireAuth: requireAuth,
      );

      _logRequest('DELETE', url, finalHeaders, body, logTag: logTag);

      final http.Response response;
      if (body != null) {
        final request = http.Request('DELETE', Uri.parse(url));
        request.headers.addAll(finalHeaders);
        request.body = jsonEncode(body);
        final streamed =
            await request.send().timeout(const Duration(seconds: 45));
        response = await http.Response.fromStream(streamed);
      } else {
        response = await http
            .delete(
              Uri.parse(url),
              headers: finalHeaders,
            )
            .timeout(const Duration(seconds: 45));
      }

      final responseData = _handleResponse(response);
      _logResponse('DELETE', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      if (e is ApiException) rethrow;
      _logResponse('DELETE', url, 0, null, e.toString(), logTag: logTag);
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Multipart POST request for file uploads
  Future<Map<String, dynamic>> postMultipart(
    String url, {
    required Map<String, String> fields,
    required Map<String, File> files,
    bool requireAuth = true,
    String? logTag,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers (but NOT Content-Type - it will be set automatically by multipart)
      request.headers['Accept'] = 'application/json';

      // Add authentication token
      if (requireAuth) {
        final token = await TokenStorageService.instance.getAccessToken();
        final jwt = _normalizeBearerToken(token);
        if (jwt != null && jwt.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $jwt';
          if (kDebugMode) {
            print(
                '🔑 Multipart upload - Token added: ${jwt.length > 20 ? "${jwt.substring(0, 20)}..." : jwt}');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Avatar Upload - No token found!');
          }
        }
      }

      // Add fields
      request.fields.addAll(fields);

      // Add files
      for (var entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;
        final fileName = file.path.split(Platform.pathSeparator).last;

        if (kDebugMode) {
          print('📎 Adding file: $fieldName = $fileName (${file.path})');
        }

        final ct = _multipartMediaTypeForFilename(fileName);
        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            filename: fileName,
            contentType: ct,
          ),
        );
      }

      _logRequest(
          'POST (Multipart)',
          url,
          request.headers,
          {
            'fields': fields,
            'files': files.keys.toList(),
          },
          logTag: logTag);

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('📥 Avatar Upload Response Status: ${response.statusCode}');
        print('📥 Avatar Upload Response Body: ${response.body}');
      }

      final responseData = _handleResponse(response);
      _logResponse(
          'POST (Multipart)', url, response.statusCode, responseData, null,
          logTag: logTag);
      return responseData;
    } catch (e) {
      _logResponse('POST (Multipart)', url, 0, null, e.toString(),
          logTag: logTag);
      if (kDebugMode) {
        print('❌ Avatar Upload Error: $e');
      }
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  /// Handle HTTP response
  /// Automatically handles 401 errors by clearing cached tokens (like Dio interceptor)
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) {
        return {'success': true};
      }
      if (_httpBodyLooksLikeHtml(response.body)) {
        if (kDebugMode) {
          print(
            '⚠️ Success status but body is HTML (not JSON): ${_debugErrorBodyPreview(response.body)}',
          );
        }
        throw ApiException(
          _friendlyMessageForHtmlError(
            response.statusCode,
            response.body,
          ),
          statusCode: response.statusCode,
        );
      }
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print(
            '⚠️ Failed to parse JSON response: ${_debugErrorBodyPreview(response.body)}',
          );
        }
        throw ApiException('Invalid JSON response: ${e.toString()}',
            statusCode: response.statusCode);
      }
    } else {
      String errorMessage = 'Request failed with status ${response.statusCode}';
      Map<String, dynamic>? errorData;
      String? errorCode;

      try {
        errorData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = errorData['message'] as String? ?? errorMessage;
        errorCode = errorData['code']?.toString();
      } catch (e) {
        if (_httpBodyLooksLikeHtml(response.body)) {
          errorMessage = _friendlyMessageForHtmlError(
            response.statusCode,
            response.body,
          );
        } else {
          final raw = response.body.trim();
          if (raw.isNotEmpty) {
            errorMessage = raw.length > 280
                ? 'Request failed (${response.statusCode}): ${raw.substring(0, 280)}…'
                : 'Request failed (${response.statusCode}): $raw';
          }
        }
      }

      if (kDebugMode) {
        if (_httpBodyLooksLikeHtml(response.body)) {
          print(
            '❌ Error ${response.statusCode} — HTML page (${response.body.length} chars): ${_debugErrorBodyPreview(response.body)}',
          );
          final t = _httpHtmlPageTitle(response.body);
          if (t != null) print('   <title>: $t');
        } else {
          print('❌ Error Response Body: ${_debugErrorBodyPreview(response.body)}');
        }
      }

      // Handle 401 Unauthorized - token expired or invalid (like Dio onError interceptor)
      if (response.statusCode == 401) {
        if (kDebugMode) {
          print('🔒 401 Unauthorized - Token may be expired or invalid');
        }

        // Check if it's a real auth error (not validation error)
        bool isAuthError = true;
        if (errorData != null) {
          final message = errorData['message']?.toString().toLowerCase() ?? '';
          // Don't treat validation/parameter errors as auth errors
          if (message.contains('invalid') ||
              message.contains('validation') ||
              message.contains('parameter') ||
              message.contains('date') ||
              message.contains('format')) {
            isAuthError = false;
            if (kDebugMode) {
              print(
                  '  ℹ️ This appears to be a validation error, not auth error');
            }
          }
        }

        if (isAuthError) {
          final shouldNotifyLoggedOutFromAnotherDevice =
              errorCode == 'SESSION_REVOKED_BY_NEW_LOGIN' ||
                  isLoggedInFromAnotherDeviceMessage(errorMessage);

          // Clear cached tokens (like Dio _handleTokenExpiry)
          TokenStorageService.instance.clearTokens().then((_) {
            if (kDebugMode) {
              print(
                  '🗑️ Cleared cached tokens due to 401 authentication error');
            }

            if (shouldNotifyLoggedOutFromAnotherDevice) {
              SessionInvalidationService.instance
                  .notifyLoggedInFromAnotherDevice(
                message: errorMessage,
              );
            }
          });
        }
      }

      throw ApiException(
        errorMessage,
        statusCode: response.statusCode,
        code: errorCode,
      );
    }
  }
}

/// API Exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  @override
  String toString() => message;
}
