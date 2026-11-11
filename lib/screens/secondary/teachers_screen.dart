import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/navigation/route_names.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trainer_marketplace.dart';
import '../../services/teachers_service.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../core/bookings/booking_status.dart';
import '../../core/design/app_theme_context.dart';
import '../../widgets/student_bottom_nav.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen(
      {super.key,
      this.teachers,
      this.query,
      this.availableOnly = false,
      this.categoryId,
      this.subcategoryId,
      this.subjectId,
      this.filterLabel});

  final List<Map<String, dynamic>>? teachers;
  final String? query;
  final bool availableOnly;
  final String? categoryId;
  final String? subcategoryId;
  final String? subjectId;
  final String? filterLabel;

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _teachers = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.query != null && widget.query!.isNotEmpty) {
      _search.text = widget.query!;
    }
    // If teachers are passed, use them; otherwise load from API
    if (widget.teachers != null && widget.teachers!.isNotEmpty) {
      _teachers = List<Map<String, dynamic>>.from(widget.teachers!);
    } else {
      _loadTeachers();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers({bool loadMore = false}) async {
    if (loadMore) {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final marketplace = await TrainerMarketplaceService.instance.listTrainers(
        page: loadMore ? _currentPage : 1,
        query: _search.text,
        categoryId: widget.categoryId,
        subcategoryId: widget.subcategoryId,
        subjectId: widget.subjectId,
      );
      final cards = (marketplace['trainers'] as List).cast<TrainerCard>();
      final mapped = cards.map((trainer) {
        return <String, dynamic>{
          'id': trainer.id,
          'name': trainer.displayName,
          'title': trainer.headline ?? '',
          'avatar': ApiEndpoints.getImageUrl(trainer.avatarUrl),
          'rating': trainer.ratingAverage,
          'students': trainer.studentsCount,
          'starting_price': trainer.startingPrice,
          'currency': 'USD',
          'bio': trainer.bio,
          'badge_label': trainer.badgeLabel,
          'hours_count': trainer.hoursCount,
          'completed_sessions_count': trainer.completedSessions,
          'rating_count': trainer.ratingCount,
          'is_accepting_bookings': trainer.isAcceptingBookings,
          'specialties': trainer.specialties,
        };
      }).toList();
      final pagination = marketplace['pagination'];
      final page = pagination is Map
          ? int.tryParse('${pagination['page'] ?? 1}') ?? 1
          : 1;
      final total = pagination is Map
          ? int.tryParse('${pagination['total'] ?? mapped.length}') ??
              mapped.length
          : mapped.length;
      setState(() {
        if (loadMore) {
          _teachers.addAll(mapped);
        } else {
          _teachers = mapped;
        }
        _currentPage = page + 1;
        _hasMore = _teachers.length < total;
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });
      return;
    } catch (_) {
      // Fall through to the legacy teachers endpoint.
    }

    try {
      final response = await TeachersService.instance.getTeachers(
        page: _currentPage,
        perPage: 20,
        sort: 'rating',
      );

      final data = response['data'];
      List<Map<String, dynamic>> newTeachers = [];

      if (data is Map<String, dynamic> && data['teachers'] != null) {
        newTeachers = List<Map<String, dynamic>>.from(data['teachers']);
        final meta = data['meta'] as Map<String, dynamic>?;
        if (meta != null) {
          _hasMore = (meta['current_page'] as int? ?? 1) <
              (meta['last_page'] as int? ?? 1);
        }
      } else if (data is List) {
        newTeachers = List<Map<String, dynamic>>.from(data);
        _hasMore = false; // No pagination info, assume no more
      }

      setState(() {
        if (loadMore) {
          _teachers.addAll(newTeachers);
          _currentPage++;
        } else {
          _teachers = newTeachers;
          _currentPage = 2; // Next page for load more
        }
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> get _data => _teachers;

  String _sort = 'rating'; // rating | price_asc | price_desc
  double? _minRating;

  List<Map<String, dynamic>> get _visible {
    var list = _data;
    if (widget.availableOnly) {
      list = list.where((t) => t['is_accepting_bookings'] == true).toList();
    }
    if (_minRating != null) {
      list = list
          .where((t) => (t['rating'] as num? ?? 0).toDouble() >= _minRating!)
          .toList();
    }
    if (_sort == 'price_asc' || _sort == 'price_desc') {
      list = List.of(list)
        ..sort((a, b) {
          final pa =
              double.tryParse(a['starting_price']?.toString() ?? '') ?? 0;
          final pb =
              double.tryParse(b['starting_price']?.toString() ?? '') ?? 0;
          return _sort == 'price_asc' ? pa.compareTo(pb) : pb.compareTo(pa);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              color: AppColors.surfaceRaised,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (context.canPop())
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          color: AppColors.ink,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      else
                        const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            Text('نتائج المعلمين',
                                style: GoogleFonts.readexPro(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                            Text(
                                (widget.filterLabel ?? '').isNotEmpty
                                    ? widget.filterLabel!
                                    : _search.text.isEmpty
                                        ? 'المعلمون المتاحون'
                                        : _search.text,
                                style: GoogleFonts.readexPro(
                                    fontSize: 12, color: AppColors.inkMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onSubmitted: (_) => _loadTeachers(),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن معلم أو مادة…',
                      hintStyle: GoogleFonts.readexPro(
                          fontSize: 13, color: AppColors.inkMuted),
                      filled: true,
                      fillColor: AppColors.brandSand,
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: IconButton(
                          onPressed: _loadTeachers,
                          icon: const Icon(Icons.arrow_forward, size: 18)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _filterChips(),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading && _teachers.isEmpty
                ? _buildTeachersSkeleton()
                : _errorMessage != null && _teachers.isEmpty
                    ? _buildErrorState(
                        onRetry: _loadTeachers,
                        l10n: l10n,
                        isTeachersList: true,
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent) {
                            _loadTeachers(loadMore: true);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          itemCount: _visible.length + (_hasMore ? 1 : 0) + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  '${_visible.length} معلمًا متاحًا',
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.readexPro(
                                      fontSize: 13, color: AppColors.inkMuted),
                                ),
                              );
                            }
                            final i = index - 1;
                            if (i == _visible.length) {
                              return _isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    )
                                  : const SizedBox.shrink();
                            }
                            return _teacherCard(_visible[i]);
                          },
                        ),
                      ),
          ),
          const StudentBottomNav(activeTab: 'search'),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return Row(
      children: [
        _chip(
          label: _sort == 'price_asc'
              ? 'الترتيب: الأقل سعرًا'
              : _sort == 'price_desc'
                  ? 'الترتيب: الأعلى سعرًا'
                  : 'الترتيب',
          icon: Icons.swap_vert_rounded,
          onTap: () => _pickFromSheet(
              'الترتيب',
              {
                'rating': 'الأعلى تقييمًا',
                'price_asc': 'الأقل سعرًا',
                'price_desc': 'الأعلى سعرًا',
              },
              (v) => setState(() => _sort = v)),
        ),
        const SizedBox(width: 8),
        _chip(
          label: _minRating == null
              ? 'تصفية'
              : 'تقييم ${_minRating!.toStringAsFixed(0)}+',
          icon: Icons.tune_rounded,
          onTap: () => _pickFromSheet(
              'تصفية بالتقييم',
              {
                '0': 'الكل',
                '4.5': '4.5+',
                '4.0': '4.0+',
                '3.0': '3.0+',
              },
              (v) => setState(
                  () => _minRating = v == '0' ? null : double.parse(v))),
        ),
      ],
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.readexPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink)),
                ),
                Icon(icon, size: 16, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
      );

  Future<void> _pickFromSheet(
    String title,
    Map<String, String> options,
    ValueChanged<String> onPick,
  ) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(title,
                style: GoogleFonts.readexPro(
                    fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...options.entries.map((e) => ListTile(
                  title: Text(e.value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.readexPro(fontSize: 14)),
                  onTap: () => Navigator.pop(ctx, e.key),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (value != null) onPick(value);
  }

  /// Teacher card — reference design.
  Widget _teacherCard(Map<String, dynamic> teacher) {
    final name = teacher['name']?.toString() ?? '';
    final title = teacher['title']?.toString() ?? '';
    final avatar = teacher['avatar']?.toString() ?? '';
    final rating = (teacher['rating'] as num? ?? 0).toDouble();
    final ratingCount = (teacher['rating_count'] as num? ??
            teacher['ratingCount'] as num? ??
            teacher['students'] as num? ??
            0)
        .toInt();
    final price = teacher['starting_price'];
    final available =
        teacher['is_accepting_bookings'] ?? teacher['accepting'] ?? true;

    return GestureDetector(
      onTap: () => context.push(RouteNames.teacherDetails, extra: teacher),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandInk.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((teacher['badge_label']?.toString() ?? '').isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    teacher['badge_label'].toString(),
                    style: GoogleFonts.readexPro(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // availability pill (left side in RTL = end)
                if (available == true)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('متاح الآن',
                            style: GoogleFonts.readexPro(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF16A34A))),
                        const SizedBox(width: 4),
                        const Icon(Icons.circle,
                            size: 8, color: Color(0xFF22C55E)),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 10),
                // info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(name,
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.readexPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: Color(0xFF2196F3)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('($ratingCount)',
                              style: GoogleFonts.readexPro(
                                  fontSize: 11, color: AppColors.inkMuted)),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1),
                              style: GoogleFonts.readexPro(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                          const Icon(Icons.star_rounded,
                              size: 15, color: Color(0xFFFBBF24)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(title,
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.readexPro(
                              fontSize: 12, color: AppColors.inkMuted)),
                      const SizedBox(height: 8),
                      if ((teacher['bio']?.toString() ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            teacher['bio'].toString(),
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.readexPro(
                                fontSize: 12, color: AppColors.inkMuted),
                          ),
                        ),
                      Text(
                        '${teacher['hours_count'] ?? 0} ساعة · ${teacher['students'] ?? 0} طالب',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.readexPro(
                            fontSize: 11, color: AppColors.inkMuted),
                      ),
                      if (price != null)
                        Text(
                          '${MoneyText.format(price, 'USD')} / الساعة',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.readexPro(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandSaffron),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: avatar.isNotEmpty
                      ? Image.network(avatar,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback())
                      : _avatarFallback(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.person_rounded, size: 30, color: AppColors.brandTeal),
      );

  /// User-friendly error UI with clear message and retry action
  Widget _buildErrorState({
    required VoidCallback onRetry,
    required AppLocalizations l10n,
    bool isTeachersList = true,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final (title, description) = _getUserFriendlyError(
      _errorMessage ?? '',
      isAr,
      isTeachersList,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: context.appTheme.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: context.appTheme.icon.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 40,
                    color: AppColors.destructive,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: GoogleFonts.readexPro(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.cardTitle,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: GoogleFonts.readexPro(
                    fontSize: 15,
                    color: context.cardMetaText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    label: Text(
                      l10n.retry,
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appTheme.icon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Convert technical error to user-friendly (title, description)
  (String, String) _getUserFriendlyError(
    String rawError,
    bool isAr,
    bool isTeachersList,
  ) {
    final err = rawError.toLowerCase();
    if (err.contains('socket') ||
        err.contains('connection') ||
        err.contains('network') ||
        err.contains('internet')) {
      return (
        isAr ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection',
        isAr
            ? 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى.'
            : 'Please check your internet connection and try again.',
      );
    }
    if (err.contains('timeout') || err.contains('timed out')) {
      return (
        isAr ? 'انتهت مهلة الاتصال' : 'Connection timed out',
        isAr
            ? 'استغرق الطلب وقتاً طويلاً. حاول مرة أخرى.'
            : 'The request took too long. Please try again.',
      );
    }
    if (err.contains('401') || err.contains('unauthorized')) {
      return (
        isAr ? 'يجب تسجيل الدخول' : 'Login required',
        isAr
            ? 'يرجى تسجيل الدخول لمشاهدة المحتوى.'
            : 'Please sign in to view this content.',
      );
    }
    if (err.contains('404') || err.contains('not found')) {
      return (
        isAr ? 'المحتوى غير متوفر' : 'Content not found',
        isAr
            ? 'لم يتم العثور على المحتوى المطلوب.'
            : 'The requested content could not be found.',
      );
    }
    if (err.contains('500') || err.contains('server')) {
      return (
        isAr ? 'مشكلة في الخادم' : 'Server issue',
        isAr
            ? 'هناك مشكلة مؤقتة. حاول مرة أخرى لاحقاً.'
            : 'There\'s a temporary issue. Please try again later.',
      );
    }
    // Generic fallback
    final what = isTeachersList
        ? (isAr ? 'المعلمين' : 'teachers')
        : (isAr ? 'تفاصيل المعلم' : 'teacher details');
    return (
      isAr ? 'لم نتمكن من التحميل' : 'Couldn\'t load $what',
      isAr
          ? 'حدث خطأ أثناء تحميل $what. حاول مرة أخرى.'
          : 'Something went wrong while loading $what. Please try again.',
    );
  }

  Widget _buildTeachersSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appTheme.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: [
                BoxShadow(
                  color: context.appTheme.icon.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 13,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            height: 18,
                            width: 36,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 18,
                            width: 55,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.appTheme.icon.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
