/// Helpers for category <-> subcategory data.
///
/// The backend may return categories in either of two shapes:
/// - **Nested**: each parent has a `children` / `subcategories` array.
/// - **Flat**: every item has a `parent_id` (null for roots).
///
/// These resolvers handle both so the UI doesn't care which one ships.
class CategoryOption {
  const CategoryOption({required this.category, required this.depth});

  final Map<String, dynamic> category;
  final int depth;
}

class CategoryUtils {
  CategoryUtils._();

  /// Keys the API may use for a nested children array.
  static const List<String> _childrenKeys = [
    'children',
    'subcategories',
    'subCategories',
    'sub_categories',
  ];

  /// Keys the API may use for the parent reference on a flat list.
  static const List<String> _parentKeys = [
    'parent_id',
    'parentId',
    'parent',
  ];

  /// Nested children attached directly on the category map.
  static List<Map<String, dynamic>> childrenOf(Map<dynamic, dynamic> category) {
    for (final key in _childrenKeys) {
      final raw = category[key];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  static bool hasChildren(Map<dynamic, dynamic> category) =>
      childrenOf(category).isNotEmpty;

  /// Parent id of a category when the API returns a flat list.
  /// Accepts `parent_id` (num/string) or a `parent` object.
  static String? parentIdOf(Map<dynamic, dynamic> category) {
    for (final key in _parentKeys) {
      final value = category[key];
      if (value == null) continue;
      if (value is num) {
        final s = value.toString();
        if (s.isNotEmpty && s != '0') return s;
        continue;
      }
      if (value is String && value.isNotEmpty && value != '0' && value != 'null') {
        return value;
      }
      if (value is Map) {
        final id = value['id'];
        if (id != null) {
          final s = id.toString();
          if (s.isNotEmpty && s != '0') return s;
        }
      }
    }
    return null;
  }

  /// Root categories only — filters out children when the API returns a
  /// flat list with `parent_id`. No-op for the nested shape.
  static List<Map<String, dynamic>> topLevel(
      List<Map<String, dynamic>> categories) {
    return categories.where((c) => parentIdOf(c) == null).toList();
  }

  /// Children of [parentId] picked out of a flat list.
  static List<Map<String, dynamic>> childrenOfId(
      List<Map<String, dynamic>> categories, String parentId) {
    return categories.where((c) => parentIdOf(c) == parentId).toList();
  }

  /// Resolve the children of [parent] — nested first, flat-list fallback.
  static List<Map<String, dynamic>> resolveChildren(
    Map<String, dynamic> parent,
    List<Map<String, dynamic>> allCategories,
  ) {
    final nested = childrenOf(parent);
    if (nested.isNotEmpty) return nested;
    final id = parent['id']?.toString();
    if (id == null || id.isEmpty) return const [];
    return childrenOfId(allCategories, id);
  }

  /// Flatten a category tree into ordered rows (root, then its children,
  /// recursively) — used by pickers/dropdowns so a subcategory id can be
  /// selected directly.
  static List<CategoryOption> flatten(List<Map<String, dynamic>> categories) {
    final options = <CategoryOption>[];

    // Index by parent for the flat parent_id shape.
    final byParent = <String, List<Map<String, dynamic>>>{};
    for (final c in categories) {
      final pid = parentIdOf(c);
      if (pid != null) byParent.putIfAbsent(pid, () => []).add(c);
    }

    void emit(Map<String, dynamic> category, int depth) {
      options.add(CategoryOption(category: category, depth: depth));
      var kids = childrenOf(category);
      if (kids.isEmpty) {
        final id = category['id']?.toString();
        if (id != null) kids = byParent[id] ?? const [];
      }
      for (final kid in kids) {
        emit(kid, depth + 1);
      }
    }

    for (final root in topLevel(categories)) {
      emit(root, 0);
    }
    return options;
  }

  /// Localized display name — prefers `name_ar` when [arabic] is true.
  static String displayName(Map<dynamic, dynamic> category,
      {bool arabic = true}) {
    final ar = (category['name_ar'] ?? category['nameAr'])?.toString();
    final en = (category['name'] ?? category['name_en'])?.toString();
    if (arabic) return (ar?.isNotEmpty == true ? ar : en) ?? '';
    return (en?.isNotEmpty == true ? en : ar) ?? '';
  }
}
