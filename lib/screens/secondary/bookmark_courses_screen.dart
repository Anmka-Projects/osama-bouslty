import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../l10n/app_localizations.dart';
import '../../services/wishlist_service.dart';
import '../../core/design/app_theme_context.dart';

class BookmarkCoursesScreen extends StatefulWidget {
  const BookmarkCoursesScreen({super.key});

  @override
  State<BookmarkCoursesScreen> createState() => _BookmarkCoursesScreenState();
}

class _BookmarkCoursesScreenState extends State<BookmarkCoursesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _wishlistCourses = const [];

  /// Supports both response shapes:
  /// - New flat (docs/flutter-wishlist-endpoints-update.md):
  ///   `{ id, title, thumbnail, is_wishlisted, wishlist_id, wishlisted_at, ... }`
  /// - Old nested: `{ course: { id, ... }, course_id: "..." }`
  Map<String, dynamic> _extractCourseFromWishlistItem(Map item) {
    // New flat shape: item has 'id' directly and no nested 'course' map.
    final directId = item['id']?.toString();
    if (directId != null && directId.isNotEmpty) {
      final flat = Map<String, dynamic>.from(item);
      // Map thumbnail → image/cover fields used by CourseDetailsScreen.
      final thumb = item['thumbnail']?.toString();
      if (thumb != null && thumb.isNotEmpty) {
        flat.putIfAbsent('cover', () => thumb);
        flat.putIfAbsent('image', () => thumb);
      }
      return flat;
    }

    // Old nested shape: { course: { ... } }
    final nestedCourse = item['course'];
    if (nestedCourse is Map) {
      return Map<String, dynamic>.from(nestedCourse);
    }

    // Fallback: item itself with course_id promoted to id.
    final normalized = Map<String, dynamic>.from(item);
    final fallbackId = item['course_id']?.toString();
    if ((normalized['id'] == null || normalized['id'].toString().isEmpty) &&
        fallbackId != null &&
        fallbackId.isNotEmpty) {
      normalized['id'] = fallbackId;
    }
    return normalized;
  }

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await WishlistService.instance.getWishlist();
      if (kDebugMode) {
        debugPrint('══════════════════════════════════════════');
        debugPrint('❤️ WISHLIST SCREEN RESPONSE');
        debugPrint('Response: $response');
        final data = response['data'];
        if (data is List) {
          debugPrint('Items count: ${data.length}');
          for (var i = 0; i < data.length && i < 3; i++) {
            debugPrint('Item[$i]: ${data[i]}');
          }
        }
        debugPrint('══════════════════════════════════════════');
      }
      final items = response['data'] as List?;
      final parsed = (items ?? const [])
          .whereType<Map>()
          .map(_extractCourseFromWishlistItem)
          .where((course) => (course['id']?.toString().isNotEmpty ?? false))
          .toList();
      if (kDebugMode) {
        debugPrint('Parsed wishlist courses: ${parsed.length}');
      }

      if (!mounted) return;
      setState(() {
        _wishlistCourses = parsed;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          l10n.wishlistTitle,
          style: GoogleFonts.readexPro(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.headerGradient2,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishlistCourses.isEmpty
              ? _buildEmptyState(l10n)
              : RefreshIndicator(
                  onRefresh: _loadWishlist,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _wishlistCourses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final course = _wishlistCourses[index];
                      return _buildCourseCard(context, course, l10n);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 56,
              color: context.cardMetaText.withOpacity(0.7),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.wishlistEmptyTitle,
              style: GoogleFonts.readexPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.wishlistEmptyDescription,
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                fontSize: 14,
                height: 1.45,
                color: context.cardMetaText.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    Map<String, dynamic> course,
    AppLocalizations l10n,
  ) {
    final courseId = (course['id'] ?? '').toString();
    final title = (course['title'] ?? l10n.noTitle).toString();
    final description = (course['description'] ?? '').toString();
    final price = course['price'];
    final currency = (course['currency'] ?? l10n.egyptianPoundShort).toString();
    final thumbUrl = (course['thumbnail'] ?? course['cover'] ?? course['image'])
        ?.toString()
        .trim();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: courseId.isEmpty
          ? null
          : () async {
              await context.push(RouteNames.courseDetails, extra: course);
              if (mounted) _loadWishlist();
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (thumbUrl != null && thumbUrl.isNotEmpty)
                  ? Image.network(
                      thumbUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _bookmarkPlaceholder(),
                    )
                  : _bookmarkPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.cardMetaText.withOpacity(0.95),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${price ?? 0} $currency',
                    style: TextStyle(
                      color: context.appTheme.icon,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookmarkPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: context.appTheme.icon.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.bookmark_rounded, color: context.appTheme.icon, size: 26),
    );
  }
}
