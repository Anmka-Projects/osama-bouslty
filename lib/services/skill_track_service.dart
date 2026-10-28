import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/skill_track/skill_track_catalog.dart';
import '../core/skill_track/skill_track_utils.dart';
import 'courses_service.dart';

/// Loads skill-track ladder from API with fallbacks.
class SkillTrackService {
  SkillTrackService._();

  static final SkillTrackService instance = SkillTrackService._();

  /// `GET /api/skill-track` → tiers; falls back to courses list + catalog.
  Future<SkillTrackData> fetchSkillTrack() async {
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.skillTrack);
      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          final tiers = _parseTiersFromSkillTrackPayload(data);
          if (tiers.isNotEmpty) {
            return SkillTrackData(
              enabled: data['enabled'] != false,
              currency: data['currency']?.toString() ?? SkillTrackCatalog.currency,
              unlockNoteAr: data['unlock_note_ar']?.toString(),
              unlockNoteEn: data['unlock_note_en']?.toString(),
              tiers: tiers,
              source: SkillTrackSource.api,
            );
          }
        }
      }
    } on ApiException catch (e) {
      if (kDebugMode && e.statusCode != 404) {
        print('skill-track API: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) print('skill-track API: $e');
    }

    return _fetchFromCourses();
  }

  Future<SkillTrackData> _fetchFromCourses() async {
    try {
      final result = await CoursesService.instance.getCourses(
        perPage: 50,
        page: 1,
      );
      final data = result['data'];
      List<dynamic> rawList = const [];
      if (data is Map<String, dynamic> && data['courses'] is List) {
        rawList = data['courses'] as List;
      } else if (data is List) {
        rawList = data;
      }
      final courses = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final trackCourses = courses
          .where(SkillTrackUtils.isSkillTrackCourse)
          .toList();

      if (trackCourses.isNotEmpty) {
        return SkillTrackData(
          enabled: true,
          currency: SkillTrackCatalog.currency,
          tiers: SkillTrackUtils.buildTiersFromCourses(trackCourses),
          source: SkillTrackSource.coursesList,
        );
      }
    } catch (e) {
      if (kDebugMode) print('skill-track courses fallback: $e');
    }

    return SkillTrackData(
      enabled: true,
      currency: SkillTrackCatalog.currency,
      tiers: SkillTrackCatalog.catalogTierRows(),
      source: SkillTrackSource.catalogOnly,
    );
  }

  List<Map<String, dynamic>> _parseTiersFromSkillTrackPayload(
    Map<String, dynamic> data,
  ) {
    final raw = data['tiers'];
    if (raw is! List) return [];
    final tiers = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final tier = m['tier'];
      final tierInt = tier is int
          ? tier
          : tier is num
              ? tier.toInt()
              : int.tryParse('$tier');
      if (tierInt == null) continue;
      final includes = m['bundle_includes'];
      tiers.add({
        'tier': tierInt,
        'course_id': m['course_id']?.toString(),
        'title': m['title']?.toString() ?? '',
        'title_ar': m['title_ar']?.toString(),
        'price': m['price'] is num
            ? m['price']
            : num.tryParse('${m['price']}') ?? 0,
        'is_free': m['is_free'] == true,
        'is_enrolled': m['is_enrolled'] == true,
        'bundle_includes': includes is List && includes.isNotEmpty
            ? includes
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : SkillTrackCatalog.bundleIncludesForTier(tierInt),
      });
    }
    tiers.sort((a, b) => (a['tier'] as int).compareTo(b['tier'] as int));
    return tiers;
  }
}

enum SkillTrackSource { api, coursesList, catalogOnly }

class SkillTrackData {
  final bool enabled;
  final String currency;
  final String? unlockNoteAr;
  final String? unlockNoteEn;
  final List<Map<String, dynamic>> tiers;
  final SkillTrackSource source;

  const SkillTrackData({
    required this.enabled,
    required this.currency,
    this.unlockNoteAr,
    this.unlockNoteEn,
    required this.tiers,
    required this.source,
  });
}
