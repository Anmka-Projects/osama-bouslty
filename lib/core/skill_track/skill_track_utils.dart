import '../courses/course_pricing_utils.dart';
import 'skill_track_catalog.dart';

/// Parses skill-track fields from course / API maps.
class SkillTrackUtils {
  SkillTrackUtils._();

  static int? tierFromCourse(Map<String, dynamic> course) {
    final track = course['skill_track'];
    if (track is Map) {
      final t = track['tier'];
      if (t is int) return t;
      if (t is num) return t.toInt();
      if (t is String) return int.tryParse(t);
    }
    final flat = course['skill_tier'];
    if (flat is int) return flat;
    if (flat is num) return flat.toInt();
    if (flat is String) return int.tryParse(flat);
    return null;
  }

  static bool isSkillTrackCourse(Map<String, dynamic> course) {
    if (course['is_skill_track_course'] == true) return true;
    return tierFromCourse(course) != null;
  }

  static List<Map<String, dynamic>> bundleIncludesFromCourse(
    Map<String, dynamic> course,
  ) {
    final raw = course['bundle_includes'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static num priceFromCourse(Map<String, dynamic> course) {
    return CoursePricingUtils.resolve(course).displayPrice;
  }

  static bool isFreeCourse(Map<String, dynamic> course) {
    return CoursePricingUtils.resolve(course).isFree;
  }

  static bool isEnrolledCourse(Map<String, dynamic> course) {
    if (course['is_enrolled'] == true || course['isEnrolled'] == true) {
      return true;
    }
    final status = course['enrollment_status']?.toString().toLowerCase();
    return status == 'enrolled' || status == 'approved';
  }

  /// Builds tier rows by merging API courses with [SkillTrackCatalog.defaultTiers].
  static List<Map<String, dynamic>> buildTiersFromCourses(
    List<Map<String, dynamic>> courses, {
    bool arabicTitles = false,
  }) {
    final byTier = <int, Map<String, dynamic>>{};
    for (final c in courses) {
      final tier = tierFromCourse(c);
      if (tier == null || tier < 1) continue;
      byTier[tier] = _tierRowFromCourse(c, tier);
    }

    final result = <Map<String, dynamic>>[];
    for (final template in SkillTrackCatalog.defaultTiers) {
      final tier = template['tier'] as int;
      if (byTier.containsKey(tier)) {
        final row = Map<String, dynamic>.from(byTier[tier]!);
        if (row['bundle_includes'] == null ||
            (row['bundle_includes'] is List &&
                (row['bundle_includes'] as List).isEmpty)) {
          row['bundle_includes'] = template['bundle_includes'];
        }
        result.add(row);
      } else {
        result.add(_tierRowFromTemplate(template, arabicTitles: arabicTitles));
      }
    }
    result.sort((a, b) => (a['tier'] as int).compareTo(b['tier'] as int));
    return result;
  }

  static Map<String, dynamic> _tierRowFromCourse(
    Map<String, dynamic> course,
    int tier,
  ) {
    final includes = bundleIncludesFromCourse(course);
    return {
      'tier': tier,
      'course_id': course['id']?.toString(),
      'title': course['title']?.toString() ?? '',
      'title_ar': course['title_ar']?.toString(),
      'price': priceFromCourse(course),
      'is_free': isFreeCourse(course),
      'is_enrolled': isEnrolledCourse(course),
      'bundle_includes': includes.isNotEmpty
          ? includes
          : _bundleForTier(tier),
      'course': course,
    };
  }

  static Map<String, dynamic> _tierRowFromTemplate(
    Map<String, dynamic> template, {
    bool arabicTitles = false,
  }) {
    final tier = template['tier'] as int;
    final title = arabicTitles
        ? (template['title_ar'] ?? template['title']).toString()
        : template['title'].toString();
    return {
      'tier': tier,
      'course_id': null,
      'title': title,
      'title_ar': template['title_ar'],
      'price': template['price'],
      'is_free': template['is_free'] == true,
      'is_enrolled': false,
      'bundle_includes': template['bundle_includes'] ?? [],
    };
  }

  static List<Map<String, dynamic>> _bundleForTier(int tier) {
    for (final t in SkillTrackCatalog.defaultTiers) {
      if (t['tier'] == tier) {
        final b = t['bundle_includes'];
        if (b is List) {
          return b.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    }
    return const [];
  }

  /// Number of courses unlocked when API returns bundle enrollment (2+).
  static int? enrolledBundleCount(Map<String, dynamic>? data) {
    if (data == null) return null;
    Map<String, dynamic>? payload = data;
    final nested = data['data'];
    if (nested is Map<String, dynamic>) {
      payload = nested;
    }
    final ids = payload['enrolled_course_ids'];
    if (ids is List && ids.length > 1) return ids.length;
    return null;
  }
}
