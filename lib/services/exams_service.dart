import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Flattens nested submit payloads so [percentage], [correctAnswers], etc. are visible at top level.
Map<String, dynamic> _mergeExamSubmitMaps(Map<String, dynamic> root) {
  final out = Map<String, dynamic>.from(root);
  for (final key in <String>[
    'result',
    'submission',
    'attempt',
    'exam_result',
    'stats',
    'grading',
    'data',
  ]) {
    final inner = root[key];
    if (inner is Map) {
      out.addAll(
        Map<String, dynamic>.from(
          inner.map((k, v) => MapEntry(k.toString(), v)),
        ),
      );
    }
  }
  return out;
}

/// Service for exams
class ExamsService {
  ExamsService._();
  
  static final ExamsService instance = ExamsService._();

  /// Get exam details
  Future<Map<String, dynamic>> getExamDetails(String examId) async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.exam(examId),
        requireAuth: true,
      );
      
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch exam details');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Start exam
  Future<Map<String, dynamic>> startExam(String examId) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.startExam(examId),
        requireAuth: true,
      );
      
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to start exam');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Submit exam
  Future<Map<String, dynamic>> submitExam(
    String examId, {
    required String attemptId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.submitExam(examId),
        body: {
          'attempt_id': attemptId,
          'answers': answers,
        },
        requireAuth: true,
      );
      
      if (response['success'] == true && response['data'] != null) {
        final raw = response['data'];
        if (raw is! Map) {
          throw Exception(response['message'] ?? 'Failed to submit exam');
        }
        return _mergeExamSubmitMaps(
          Map<String, dynamic>.from(
            raw.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to submit exam');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get user exams — `GET /api/my-exams` returns `data` as an array of exam objects.
  /// Normalizes to `{ 'completed': [...] }` for [MyExamsScreen].
  Future<Map<String, dynamic>> getMyExams() async {
    final endpoint = ApiEndpoints.myExams;
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('📤 MY EXAMS — REQUEST (getMyExams)');
      print('═══════════════════════════════════════════════════════════');
      print('  Method: GET');
      print('  URL: $endpoint');
      print('  requireAuth: true');
      print('═══════════════════════════════════════════════════════════');
    }
    try {
      final response = await ApiClient.instance.get(
        endpoint,
        requireAuth: true,
      );

      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('📥 MY EXAMS — RAW RESPONSE (getMyExams)');
        print('═══════════════════════════════════════════════════════════');
        print('  success: ${response['success']}');
        print('  message: ${response['message']}');
        print('  keys: ${response.keys.toList()}');
        try {
          print(const JsonEncoder.withIndent('  ').convert(response));
        } catch (_) {
          print('  Raw: $response');
        }
        print('═══════════════════════════════════════════════════════════');
      }

      if (response['success'] == true) {
        final raw = response['data'];
        final exams = _parseMyExamsDataPayload(raw);
        final payload = <String, dynamic>{'completed': exams};
        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════════');
          print('📦 MY EXAMS — NORMALIZED FOR UI');
          print('═══════════════════════════════════════════════════════════');
          print('  count: ${exams.length}');
          try {
            print(const JsonEncoder.withIndent('  ').convert(payload));
          } catch (_) {
            print('  Raw: $payload');
          }
          print('═══════════════════════════════════════════════════════════');
        }
        return payload;
      }
      throw Exception(response['message'] ?? 'Failed to fetch exams');
    } catch (e) {
      if (kDebugMode) {
        print('❌ MY EXAMS — ERROR (getMyExams): $e');
      }
      rethrow;
    }
  }

  /// Handles `data` as a JSON array (documented API) or legacy map shapes.
  List<Map<String, dynamic>> _parseMyExamsDataPayload(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      final nested = m['completed'] ?? m['exams'] ?? m['data'] ?? m['items'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return [];
  }

  /// Get course exams
  Future<List<Map<String, dynamic>>> getCourseExams(String courseId) async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.courseExams(courseId),
        requireAuth: false, // Allow unauthenticated access
      );
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is List) {
          return data.map((exam) => exam as Map<String, dynamic>).toList();
        } else {
          return [];
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch course exams');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get course exam details
  Future<Map<String, dynamic>> getCourseExamDetails(
    String courseId,
    String examId,
  ) async {
    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.courseExamDetails(courseId, examId),
        requireAuth: false, // Allow unauthenticated access
      );
      
      if (response['success'] == true && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch exam details');
      }
    } catch (e) {
      rethrow;
    }
  }
}

