/// Default skill-track ladder when API fields are not yet deployed.
class SkillTrackCatalog {
  SkillTrackCatalog._();

  static const String currency = 'EGP';

  static const List<Map<String, dynamic>> defaultTiers = [
    {
      'tier': 1,
      'title': 'Emotional Intelligence',
      'title_ar': 'الذكاء العاطفي',
      'price': 250,
      'is_free': false,
      'bundle_includes': <Map<String, dynamic>>[],
    },
    {
      'tier': 2,
      'title': 'Communication Skill',
      'title_ar': 'مهارات التواصل',
      'price': 500,
      'is_free': false,
      'bundle_includes': [
        {'tier': 1, 'title': 'Emotional Intelligence', 'title_ar': 'الذكاء العاطفي'},
      ],
    },
    {
      'tier': 3,
      'title': 'Presentation Skills',
      'title_ar': 'مهارات العرض',
      'price': 0,
      'is_free': true,
      'bundle_includes': <Map<String, dynamic>>[],
    },
    {
      'tier': 4,
      'title': 'Selling Skills',
      'title_ar': 'مهارات البيع',
      'price': 750,
      'is_free': false,
      'bundle_includes': [
        {'tier': 1, 'title': 'Emotional Intelligence', 'title_ar': 'الذكاء العاطفي'},
        {'tier': 2, 'title': 'Communication Skill', 'title_ar': 'مهارات التواصل'},
        {'tier': 3, 'title': 'Presentation Skills', 'title_ar': 'مهارات العرض'},
      ],
    },
    {
      'tier': 5,
      'title': 'Negotiation Skills',
      'title_ar': 'مهارات التفاوض',
      'price': 1000,
      'is_free': false,
      'bundle_includes': [
        {'tier': 1, 'title': 'Emotional Intelligence', 'title_ar': 'الذكاء العاطفي'},
        {'tier': 2, 'title': 'Communication Skill', 'title_ar': 'مهارات التواصل'},
        {'tier': 3, 'title': 'Presentation Skills', 'title_ar': 'مهارات العرض'},
        {'tier': 4, 'title': 'Selling Skills', 'title_ar': 'مهارات البيع'},
      ],
    },
  ];

  static List<Map<String, dynamic>> bundleIncludesForTier(int tier) {
    for (final t in defaultTiers) {
      if (t['tier'] == tier) {
        final b = t['bundle_includes'];
        if (b is List) {
          return b
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return const [];
  }

  static List<Map<String, dynamic>> catalogTierRows() {
    return defaultTiers
        .map(
          (t) => {
            'tier': t['tier'] as int,
            'course_id': null,
            'title': t['title'],
            'title_ar': t['title_ar'],
            'price': t['price'],
            'is_free': t['is_free'] == true,
            'is_enrolled': false,
            'bundle_includes': bundleIncludesForTier(t['tier'] as int),
          },
        )
        .toList();
  }
}
