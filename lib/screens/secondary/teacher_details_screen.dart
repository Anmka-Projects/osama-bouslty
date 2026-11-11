import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/navigation/route_names.dart';
import '../../l10n/app_localizations.dart';
import '../../services/teachers_service.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../services/chat_service.dart';
import '../../core/design/app_theme_context.dart';
import 'trainer_availability_screen.dart';

class TeacherDetailsScreen extends StatefulWidget {
  const TeacherDetailsScreen({super.key, this.teacher});

  final Map<String, dynamic>? teacher;

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  bool _isLoading = false;
  bool _isStartingChat = false;
  String? _errorMessage;
  Map<String, dynamic>? _teacherData;

  @override
  void initState() {
    super.initState();
    // If teacher has an ID, load from API; otherwise use passed data
    final teacherId = widget.teacher?['id']?.toString();
    if (teacherId != null && teacherId.isNotEmpty) {
      _loadTeacherDetails(teacherId);
    } else {
      // Use passed teacher data or fallback
      _teacherData = widget.teacher ?? const {};
    }
  }

  Future<void> _loadTeacherDetails(String teacherId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teacherDetails =
          await TeachersService.instance.getTeacherDetails(teacherId);
      try {
        final market =
            await TrainerMarketplaceService.instance.trainer(teacherId);
        if ((teacherDetails['intro_video_url']?.toString() ?? '').isEmpty) {
          teacherDetails['intro_video_url'] = market.introVideoUrl;
        }
        if ((teacherDetails['bio']?.toString() ?? '').isEmpty &&
            market.bio != null) {
          teacherDetails['bio'] = market.bio;
        }
      } catch (_) {}
      setState(() {
        _teacherData = teacherDetails;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        // Fallback to passed teacher data or sample
        _teacherData = widget.teacher ?? const {};
      });
    }
  }

  Future<void> _startChatWithTeacher() async {
    final teacherId = _teacher['id']?.toString() ??
        _teacher['userId']?.toString() ??
        _teacher['user_id']?.toString();
    if (teacherId == null || teacherId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'لا يمكن بدء المحادثة'
                  : 'Cannot start chat',
              style: GoogleFonts.readexPro(),
            ),
          ),
        );
      }
      return;
    }
    setState(() => _isStartingChat = true);
    try {
      final conv =
          await ChatService.instance.createOrGetConversation(teacherId);
      final convId =
          conv['id']?.toString() ?? conv['conversationId']?.toString();
      if (convId == null || convId.isEmpty || !mounted) return;
      context.push(
        '/chat/$convId',
        extra: {
          'conversationId': convId,
          'otherUser': _teacher,
          'conversation': conv,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  Map<String, dynamic> get _teacher =>
      _teacherData ?? widget.teacher ?? const {};


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _teacher['name']?.toString() ??
        _teacher['display_name']?.toString() ??
        l10n.teacherFallback;
    final title =
        _teacher['title']?.toString() ?? _teacher['headline']?.toString() ?? '';
    final avatar = _teacher['avatar']?.toString() ?? '';
    final rating = (_teacher['rating'] as num? ?? 0).toDouble();
    final ratingCount =
        (_teacher['rating_count'] as num? ?? _teacher['students'] as num? ?? 0)
            .toInt();
    final bio = _teacher['bio']?.toString() ?? '';
    final trainerId = _teacher['id']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.brandSand,
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandInk.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // رسالة (outlined)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isStartingChat ? null : _startChatWithTeacher,
                  icon: _isStartingChat
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: Text('تواصل مع المعلم',
                      style: GoogleFonts.readexPro(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandTeal,
                    side: BorderSide(color: AppColors.brandTeal, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // احجز الآن (filled)
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: trainerId.isEmpty
                      ? null
                      : () => context.push(
                            RouteNames.trainerAvailability,
                            extra: {
                              'trainerId': trainerId,
                              'trainerName': name,
                              'offering': _teacher['offering'] ?? const {},
                            },
                          ),
                  icon: const Icon(Icons.event_available_rounded, size: 18),
                  label: Text('احجز الآن',
                      style: GoogleFonts.readexPro(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text('ملف المعلم',
            style: GoogleFonts.readexPro(
                fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
        backgroundColor: AppColors.surfaceRaised,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: _isLoading && _teacherData == null
          ? _buildTeacherDetailsSkeleton()
          : _errorMessage != null && _teacherData == null
              ? _buildErrorState(l10n: l10n)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // header: name + verified + rating + avatar
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                                          style: GoogleFonts.readexPro(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.ink)),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(Icons.verified_rounded,
                                        size: 18, color: Color(0xFF2196F3)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('($ratingCount)',
                                        style: GoogleFonts.readexPro(
                                            fontSize: 12,
                                            color: AppColors.inkMuted)),
                                    const SizedBox(width: 4),
                                    Text(rating.toStringAsFixed(1),
                                        style: GoogleFonts.readexPro(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink)),
                                    const Icon(Icons.star_rounded,
                                        size: 16, color: Color(0xFFFBBF24)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(title,
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.readexPro(
                                        fontSize: 13,
                                        color: AppColors.inkMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: avatar.isNotEmpty
                                ? Image.network(avatar,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _avatarBox())
                                : _avatarBox(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // bio
                      if (bio.isNotEmpty) ...[
                        Text('نبذة عن المعلم',
                            textAlign: TextAlign.end,
                            style: GoogleFonts.readexPro(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink)),
                        const SizedBox(height: 8),
                        Text(bio,
                            textAlign: TextAlign.end,
                            style: GoogleFonts.readexPro(
                                fontSize: 13.5,
                                height: 1.7,
                                color: AppColors.ink)),
                        const SizedBox(height: 18),
                      ],

                      // marketplace panel (offerings/availability/reviews)
                      if (trainerId.isNotEmpty)
                        TrainerMarketplacePanel(trainerId: trainerId),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
    );
  }

  Widget _avatarBox() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.person_rounded, size: 34, color: AppColors.brandTeal),
      );

  /// User-friendly error UI with clear message and retry action
  Widget _buildErrorState({required AppLocalizations l10n}) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final (title, description) = _getUserFriendlyError(
      _errorMessage ?? '',
      isAr,
      false, // teacher details, not list
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
                    Icons.person_off_rounded,
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
                    onPressed: () {
                      final teacherId = widget.teacher?['id']?.toString();
                      if (teacherId != null && teacherId.isNotEmpty) {
                        _loadTeacherDetails(teacherId);
                      }
                    },
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

  Widget _buildTeacherDetailsSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.appTheme.card,
                borderRadius: BorderRadius.circular(AppRadius.largeCard),
                boxShadow: [
                  BoxShadow(
                    color: context.appTheme.icon.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.largeCard),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 18,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 18,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 13,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 13,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appTheme.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 14,
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                height: 14,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                height: 14,
                                width: 60,
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
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
