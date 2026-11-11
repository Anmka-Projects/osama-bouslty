import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/categories/category_utils.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../services/courses_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/student_bottom_nav.dart';

/// Student search backed by the admin-managed classification tree.
///
/// The preferred shape is category -> subcategory -> subject. Older servers
/// that only have two levels remain usable: selecting their leaf sends a
/// `subcategory_id` until subjects are added by the admin.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _search = TextEditingController();
  bool _availableOnly = false;
  bool _loading = true;
  String _name = '';
  List<Map<String, dynamic>> _categories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ProfileService.instance
            .getProfile()
            .catchError((_) => <String, dynamic>{}),
        CoursesService.instance
            .getCategories(requireAuth: false)
            .catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _name = ((results[0] as Map)['name'] ?? '').toString();
        _categories = (results[1] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openResults({
    String? categoryId,
    String? subcategoryId,
    String? subjectId,
    String? label,
  }) {
    context.push(
      RouteNames.teachers,
      extra: {
        'query': _search.text.trim(),
        'availableOnly': _availableOnly,
        if (categoryId != null) 'categoryId': categoryId,
        if (subcategoryId != null) 'subcategoryId': subcategoryId,
        if (subjectId != null) 'subjectId': subjectId,
        if (label != null) 'filterLabel': label,
      },
    );
  }

  IconData _categoryIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('ابتد')) return Icons.child_care_rounded;
    if (value.contains('إعداد') || value.contains('اعداد')) {
      return Icons.menu_book_rounded;
    }
    if (value.contains('ثانو')) return Icons.school_rounded;
    if (value.contains('جامع')) return Icons.account_balance_rounded;
    return Icons.auto_stories_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final roots = CategoryUtils.topLevel(_categories);
    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _name.isNotEmpty ? 'مرحبًا $_name 👋' : 'مرحبًا 👋',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.readexPro(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'اختار المرحلة ثم الصف والمادة',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.readexPro(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _search,
                  textAlign: TextAlign.end,
                  onSubmitted: (_) => _openResults(),
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم المدرس أو المادة',
                    hintStyle: GoogleFonts.readexPro(
                      fontSize: 13,
                      color: AppColors.inkMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceRaised,
                    prefixIcon: IconButton(
                      icon: Icon(Icons.search_rounded,
                          color: AppColors.brandTeal),
                      onPressed: _openResults,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'التصنيفات والمواد',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.readexPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (roots.isEmpty)
                  _emptyState()
                else
                  ...roots.map(_categoryTile),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Switch(
                        value: _availableOnly,
                        activeThumbColor: AppColors.brandTeal,
                        onChanged: (value) =>
                            setState(() => _availableOnly = value),
                      ),
                      Expanded(
                        child: Text(
                          'متاح للحجز فقط',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.readexPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const StudentBottomNav(activeTab: 'search'),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'لا توجد تصنيفات متاحة حاليًا',
            style: GoogleFonts.readexPro(
              fontSize: 13,
              color: AppColors.inkMuted,
            ),
          ),
        ),
      );

  Widget _categoryTile(Map<String, dynamic> category) {
    final categoryId = category['id']?.toString() ?? '';
    final categoryName = CategoryUtils.displayName(category, arabic: true);
    final subcategories = CategoryUtils.resolveChildren(category, _categories);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading:
            Icon(_categoryIcon(categoryName), color: AppColors.brandSaffron),
        title: Text(
          categoryName,
          textAlign: TextAlign.end,
          style: GoogleFonts.readexPro(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: subcategories.isEmpty
            ? [
                ListTile(
                  dense: true,
                  title: const Text('عرض كل المدرسين'),
                  onTap: () => _openResults(
                    categoryId: categoryId,
                    label: categoryName,
                  ),
                ),
              ]
            : subcategories
                .map((subcategory) => _subcategoryTile(category, subcategory))
                .toList(),
      ),
    );
  }

  Widget _subcategoryTile(
    Map<String, dynamic> category,
    Map<String, dynamic> subcategory,
  ) {
    final categoryId = category['id']?.toString() ?? '';
    final subcategoryId = subcategory['id']?.toString() ?? '';
    final subcategoryName =
        CategoryUtils.displayName(subcategory, arabic: true);
    final subjects = CategoryUtils.resolveChildren(subcategory, _categories);
    if (subjects.isEmpty) {
      return ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: const Icon(Icons.chevron_left_rounded, size: 20),
        title: Text(
          subcategoryName,
          textAlign: TextAlign.end,
          style: GoogleFonts.readexPro(fontWeight: FontWeight.w700),
        ),
        onTap: () => _openResults(
          categoryId: categoryId,
          subcategoryId: subcategoryId,
          label: subcategoryName,
        ),
      );
    }
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        subcategoryName,
        textAlign: TextAlign.end,
        style: GoogleFonts.readexPro(fontWeight: FontWeight.w700),
      ),
      children: subjects.map((subject) {
        final subjectId = subject['id']?.toString() ?? '';
        final subjectName = CategoryUtils.displayName(subject, arabic: true);
        return ListTile(
          dense: true,
          leading:
              Icon(Icons.book_outlined, size: 18, color: AppColors.brandTeal),
          title: Text(subjectName, textAlign: TextAlign.end),
          onTap: () => _openResults(
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            subjectId: subjectId,
            label: subjectName,
          ),
        );
      }).toList(),
    );
  }
}
