import 'dart:convert';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_theme_extension.dart';
import '../../core/design/brand_ui.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/localization/localization_helper.dart';
import '../../core/courses/course_pricing_utils.dart';
import '../../core/courses/lesson_duration_utils.dart';
import '../../core/live/live_lesson_utils.dart';
import '../../core/config/course_payment_methods_ui.dart';
import '../../core/enrollment/library_payment_admin_message.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import 'live_session_webview_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../services/activation_codes_service.dart';
import '../../services/app_config_service.dart';
import '../../services/courses_service.dart';
import '../../services/exams_service.dart';
import '../../core/api/api_client.dart';
import '../../services/enrollment_requests_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/profile_service.dart';
import '../../services/youtube_video_service.dart';
import '../../services/live_session_reminder_service.dart';
import '../../widgets/live_countdown_badge.dart';
import '../../widgets/skill_track_bundle_banner.dart';

/// User-visible text from exam API errors (prefers server [ApiException.message]).
/// Uses [l10n] for auth fallback so copy matches app language (en/ar).
String examFlowUserMessage(
  Object error, {
  required AppLocalizations l10n,
  required String fallback,
}) {
  if (error is ApiException) {
    final m = error.message.trim();
    if (m.isNotEmpty) return m;
    if (error.statusCode == 401) {
      return l10n.mustLoginFirst;
    }
  }
  var s = error.toString();
  if (s.startsWith('Exception: ')) {
    s = s.substring('Exception: '.length);
  }
  s = s.trim();
  if (s.isNotEmpty && s != 'Exception') return s;
  return fallback;
}

/// Modern Course Details Screen with Beautiful UI
class CourseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? course;

  const CourseDetailsScreen({super.key, this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with TickerProviderStateMixin {
  AppThemeExtension get _theme => AppThemeExtension.of(context);

  late TabController _tabController;
  int _selectedLessonIndex = 0;
  bool _isLoading = false;
  bool _isEnrolling = false;
  bool _isEnrolled = false;
  Map<String, dynamic>? _courseData;
  List<Map<String, dynamic>> _courseExams = [];
  bool _isLoadingExams = false;
  bool _isInWishlist = false;
  bool _isTogglingWishlist = false;
  bool _isViewingOwnCourse = false;
  bool _isSubmittingLibraryRequest = false;
  String? _libraryRequestStatus; // pending | approved | rejected
  String? _libraryRequestAdminNotes;

  Future<void> _shareCourseLink() async {
    final course = _courseData ?? widget.course;
    if (course == null) return;

    final courseId = course['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    final title = course['title']?.toString().trim();
    final explicitLink =
        course['share_url']?.toString().trim().isNotEmpty == true
            ? course['share_url']?.toString().trim()
            : course['url']?.toString().trim().isNotEmpty == true
                ? course['url']?.toString().trim()
                : course['link']?.toString().trim().isNotEmpty == true
                    ? course['link']?.toString().trim()
                    : null;

    final courseLink =
        explicitLink ?? 'https://elsherifacademy.anmka.com/courses/$courseId';

    final shareText = (title != null && title.isNotEmpty)
        ? '$title\n$courseLink'
        : courseLink;

    await Share.share(shareText);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourseDetails();
    // _checkWishlistStatus is called inside _loadCourseDetails after course data
    // is ready (or as a fallback when is_in_wishlist is absent from the API).
    _loadLibraryEnrollmentRequestStatus();
  }

  Future<void> _loadCourseDetails() async {
    // If course data is already provided, use it
    if (widget.course != null && widget.course!['id'] != null) {
      final courseId = widget.course!['id']?.toString();
      if (courseId != null && courseId.isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          final courseDetails =
              await CoursesService.instance.getCourseDetails(courseId);

          // Print detailed response
          if (kDebugMode) {
            print(
                '═══════════════════════════════════════════════════════════');
            print('📋 COURSE DETAILS RESPONSE (getCourseDetails)');
            print(
                '═══════════════════════════════════════════════════════════');
            print('Course ID: $courseId');
            print('Response Type: ${courseDetails.runtimeType}');
            print('Response Keys: ${courseDetails.keys.toList()}');
            print(
                '───────────────────────────────────────────────────────────');
            print('Full Response JSON:');
            try {
              const encoder = JsonEncoder.withIndent('  ');
              print(encoder.convert(courseDetails));
            } catch (e) {
              print('Could not convert to JSON: $e');
              print('Raw Response: $courseDetails');
            }
            print(
                '───────────────────────────────────────────────────────────');
            print('Key Fields:');
            print('  - id: ${courseDetails['id']}');
            print('  - title: ${courseDetails['title']}');
            print('  - price: ${courseDetails['price']}');
            print('  - is_free: ${courseDetails['is_free']}');
            print('  - is_enrolled: ${courseDetails['is_enrolled']}');
            print('  - is_in_wishlist: ${courseDetails['is_in_wishlist']}');
            print('  - rating: ${courseDetails['rating']}');
            print('  - students_count: ${courseDetails['students_count']}');
            print('  - duration_hours: ${courseDetails['duration_hours']}');
            print(
                '  - curriculum length: ${(courseDetails['curriculum'] as List?)?.length ?? 0}');
            print(
                '  - lessons length: ${(courseDetails['lessons'] as List?)?.length ?? 0}');
            print(
                '───────────────────────────────────────────────────────────');
            print('📚 CURRICULUM DETAILS:');
            final curriculum = courseDetails['curriculum'] as List?;
            if (curriculum != null && curriculum.isNotEmpty) {
              print('  Total Items: ${curriculum.length}');

              // First, show summary of all topics
              print('');
              print('📁 ALL TOPICS FROM API:');
              print(
                  '═══════════════════════════════════════════════════════════');
              int topicCount = 0;
              for (int i = 0; i < curriculum.length; i++) {
                final item = curriculum[i];
                if (item is Map) {
                  // Check if this is a topic (has lessons field, even if empty)
                  // A topic is identified by having a 'lessons' field (can be empty list)
                  // OR by not having video/youtube_id fields (which indicate it's a lesson)
                  final nestedLessons = item['lessons'] as List?;
                  final hasVideo = item['video'] != null;
                  final hasYoutubeId = item['youtube_id'] != null ||
                      item['youtubeVideoId'] != null;

                  // It's a topic if:
                  // 1. It has a 'lessons' field (even if empty), OR
                  // 2. It doesn't have video/youtube_id (meaning it's a container, not a lesson)
                  final isTopic =
                      nestedLessons != null || (!hasVideo && !hasYoutubeId);

                  if (isTopic) {
                    topicCount++;
                    final lessonsCount = nestedLessons?.length ?? 0;
                    print('📁 TOPIC $topicCount:');
                    print('  - ID: ${item['id']}');
                    print('  - Title: ${item['title']}');
                    print('  - Order: ${item['order']}');
                    print('  - Type: ${item['type']}');
                    print('  - Lessons Count: $lessonsCount');
                    print('  - Duration Minutes: ${item['duration_minutes']}');
                    print('  - Has Lessons Field: ${nestedLessons != null}');
                    print('  - All Topic Keys: ${item.keys.toList()}');

                    // If it has lessons, show them
                    if (nestedLessons != null && nestedLessons.isNotEmpty) {
                      print('  - Lessons:');
                      for (int j = 0; j < nestedLessons.length; j++) {
                        final lesson = nestedLessons[j];
                        if (lesson is Map) {
                          print(
                              '      Lesson ${j + 1}: ${lesson['title'] ?? lesson['id']}');
                        }
                      }
                    } else if (nestedLessons != null && nestedLessons.isEmpty) {
                      print('  - ⚠️ This topic has an empty lessons array');
                    } else {
                      print('  - ⚠️ This topic does not have a lessons field');
                    }
                    print('');
                  }
                }
              }
              print(
                  '═══════════════════════════════════════════════════════════');
              print('Total Topics Found: $topicCount');
              print('Total Curriculum Items: ${curriculum.length}');
              print(
                  '═══════════════════════════════════════════════════════════');
              print('');

              // Then show all items in detail
              print('📋 ALL CURRICULUM ITEMS (DETAILED):');
              for (int i = 0; i < curriculum.length; i++) {
                final item = curriculum[i];
                if (item is Map) {
                  print(
                      '───────────────────────────────────────────────────────────');
                  print('  Item ${i + 1}:');
                  print('    - id: ${item['id']}');
                  print('    - title: ${item['title']}');
                  print('    - order: ${item['order']}');
                  print('    - type: ${item['type']}');
                  print('    - video: ${item['video']}');
                  print('    - youtube_id: ${item['youtube_id']}');
                  print('    - youtubeVideoId: ${item['youtubeVideoId']}');
                  print('    - duration_minutes: ${item['duration_minutes']}');
                  print('    - is_locked: ${item['is_locked']}');
                  print('    - is_completed: ${item['is_completed']}');
                  if (item['lessons'] != null) {
                    final lessonsList = item['lessons'] as List?;
                    print('    - has lessons: ${lessonsList?.length ?? 0}');
                    if (lessonsList != null && lessonsList.isNotEmpty) {
                      print('    - Lessons in this topic:');
                      for (int j = 0; j < lessonsList.length; j++) {
                        final lesson = lessonsList[j];
                        if (lesson is Map) {
                          print('      Lesson ${j + 1}:');
                          print('        - id: ${lesson['id']}');
                          print('        - title: ${lesson['title']}');
                          print('        - type: ${lesson['type']}');
                        }
                      }
                    }
                  }
                  print('    - All Keys: ${item.keys.toList()}');

                  // Print full JSON for topics
                  final nestedLessons = item['lessons'] as List?;
                  if (nestedLessons != null && nestedLessons.isNotEmpty) {
                    try {
                      const encoder = JsonEncoder.withIndent('    ');
                      print('    - Full Topic JSON:');
                      print(encoder.convert(item));
                    } catch (e) {
                      print('    - Could not convert topic to JSON: $e');
                    }
                  }
                }
              }
            } else {
              print('  Curriculum is empty or null');
            }
            print(
                '───────────────────────────────────────────────────────────');
            print('📖 LESSONS DETAILS:');
            final lessons = courseDetails['lessons'] as List?;
            if (lessons != null && lessons.isNotEmpty) {
              print('  Total Lessons: ${lessons.length}');
              for (int i = 0; i < lessons.length && i < 3; i++) {
                final lesson = lessons[i];
                if (lesson is Map) {
                  print('  Lesson $i:');
                  print('    - id: ${lesson['id']}');
                  print('    - title: ${lesson['title']}');
                  print('    - video: ${lesson['video']}');
                  print('    - All Keys: ${lesson.keys.toList()}');
                }
              }
            } else {
              print('  Lessons is empty or null');
            }
            print(
                '═══════════════════════════════════════════════════════════');
          }

          if (!mounted) return;
          setState(() {
            _courseData = courseDetails;
            _isEnrolled = courseDetails['is_enrolled'] == true;
            _isInWishlist = courseDetails['is_in_wishlist'] == true;
            _isLoading = false;
          });
          // Fill missing lesson durations from YouTube when API sends 0.
          _enrichLessonDurationsFromYoutube();
          // _loadCourseExams();
          // Re-check from wishlist endpoint to keep UI in sync even if
          // course-details `is_in_wishlist` is stale.
          _checkWishlistStatus();
          _checkIfViewingOwnCourse(courseDetails);
        } catch (e) {
          if (kDebugMode) {
            print(
                '═══════════════════════════════════════════════════════════');
            print('❌ ERROR LOADING COURSE DETAILS');
            print(
                '═══════════════════════════════════════════════════════════');
            print('Course ID: $courseId');
            print('Error: $e');
            print('Error Type: ${e.runtimeType}');
            print(
                '═══════════════════════════════════════════════════════════');
          }
          if (!mounted) return;
          setState(() {
            _courseData = widget.course; // Fallback to provided course
            _isLoading = false;
          });
          _checkIfViewingOwnCourse(widget.course);
        }
      } else {
        if (!mounted) return;
        setState(() {
          _courseData = widget.course;
        });
        _checkIfViewingOwnCourse(widget.course);
      }
    } else {
      if (!mounted) return;
      setState(() {
        _courseData = widget.course;
      });
      _checkIfViewingOwnCourse(widget.course);
    }
  }

  String? _extractRequestCourseId(Map<String, dynamic> request) {
    final direct = request['course_id']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    if (request['course'] is Map) {
      final nested = (request['course'] as Map)['id']?.toString();
      if (nested != null && nested.isNotEmpty) return nested;
    }
    return null;
  }

  Future<void> _loadLibraryEnrollmentRequestStatus() async {
    final course = _courseData ?? widget.course;
    final courseId = course?['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    try {
      final requests =
          await EnrollmentRequestsService.instance.getEnrollmentRequests(
        page: 1,
        perPage: 50,
      );
      bool isOffsiteEnrollment(String? pm) {
        final p = pm?.toLowerCase() ?? '';
        return p == 'library' || p == 'whatsapp' || p == 'bank_transfer';
      }

      final courseMatches = requests
          .where(
            (request) =>
                _extractRequestCourseId(request) == courseId &&
                isOffsiteEnrollment(request['payment_method']?.toString()),
          )
          .toList();

      courseMatches.sort((a, b) {
        final ta = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final tb = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      final libraryRequest =
          courseMatches.isNotEmpty ? courseMatches.first : <String, dynamic>{};

      if (!mounted) return;
      if (libraryRequest.isEmpty) {
        setState(() {
          _libraryRequestStatus = null;
          _libraryRequestAdminNotes = null;
        });
        return;
      }

      final status = libraryRequest['status']?.toString().toLowerCase();
      setState(() {
        _libraryRequestStatus = status;
        _libraryRequestAdminNotes = libraryRequest['admin_notes']?.toString();
        if (status == 'approved') {
          _isEnrolled = true;
        }
      });
    } catch (_) {
      // Non-blocking for screen rendering.
    }
  }

  Future<void> _submitLibraryEnrollmentRequest({
    required String message,
    String? receiptImageUrl,
    String paymentMethod = 'library',
  }) async {
    final course = _courseData ?? widget.course;
    final courseId = course?['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    final rawPm = paymentMethod.toLowerCase().trim();
    final pm =
        rawPm == 'whatsapp' || rawPm == 'bank_transfer' ? rawPm : 'library';

    if (mounted) {
      setState(() => _isSubmittingLibraryRequest = true);
    }

    try {
      final Map<String, dynamic> request;
      if (pm == 'whatsapp') {
        final r = receiptImageUrl?.trim();
        if (r == null || r.isEmpty) {
          throw Exception(
            'Payment receipt image is required for WhatsApp proof.',
          );
        }
        request =
            await EnrollmentRequestsService.instance.submitWhatsappPaymentProof(
          courseId: courseId,
          receiptImageUrl: r,
          message: message,
        );
      } else {
        request =
            await EnrollmentRequestsService.instance.createEnrollmentRequest(
          courseId: courseId,
          paymentMethod: pm,
          message: message,
          receiptImageUrl:
              receiptImageUrl != null && receiptImageUrl.trim().isNotEmpty
                  ? receiptImageUrl.trim()
                  : null,
        );
      }

      final status = request['status']?.toString().toLowerCase() ?? 'pending';
      if (!mounted) return;
      setState(() {
        _libraryRequestStatus = status;
        _libraryRequestAdminNotes = request['admin_notes']?.toString();
      });

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.enrollmentRequestPendingReview,
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // The server may reject with "لديك طلب انضمام قيد المراجعة" — resync the
      // request status so the UI shows the pending state instead of a dead end.
      _loadLibraryEnrollmentRequestStatus();
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage.isNotEmpty ? errorMessage : 'تعذر إرسال طلب الاشتراك',
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingLibraryRequest = false);
      }
    }
  }

  Future<void> _checkIfViewingOwnCourse(Map<String, dynamic>? course) async {
    if (course == null) return;
    final instructorId = course['instructor_id']?.toString() ??
        course['instructorId']?.toString() ??
        (course['instructor'] is Map
            ? (course['instructor'] as Map)['id']?.toString()
            : null);
    if (instructorId == null || instructorId.isEmpty) return;
    try {
      final profile = await ProfileService.instance.getProfile();
      final myId = profile['id']?.toString();
      if (myId != null && myId == instructorId && mounted) {
        setState(() => _isViewingOwnCourse = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _getFirstLesson() {
    final course = _courseData ?? widget.course;
    final curriculum = course?['curriculum'] as List?;
    final lessons = course?['lessons'] as List?;
    Map<String, dynamic>? firstLesson;

    if (curriculum != null && curriculum.isNotEmpty) {
      for (var item in curriculum) {
        if (item is Map<String, dynamic>) {
          // Check if this item has nested lessons (it's a topic/section)
          final nestedLessons = item['lessons'] as List?;
          if (nestedLessons != null && nestedLessons.isNotEmpty) {
            // Use first nested lesson
            final nestedLesson = nestedLessons[0];
            if (nestedLesson is Map<String, dynamic>) {
              firstLesson = nestedLesson;
              break;
            }
          } else {
            // This item is a lesson itself (has video or id)
            if (item['video'] != null ||
                item['id'] != null ||
                item['youtube_id'] != null ||
                item['youtubeVideoId'] != null) {
              firstLesson = item;
              break;
            }
          }
        }
      }
    }

    // If no lesson from curriculum, use lessons directly
    if (firstLesson == null && lessons != null && lessons.isNotEmpty) {
      final lesson = lessons[0];
      if (lesson is Map<String, dynamic>) {
        firstLesson = lesson;
      }
    }

    return firstLesson;
  }

  /// Opens a lesson — lessons are live-session-only, so this always goes to
  /// the live lesson screen (countdown/reminders/in-app WebView).
  void _openLesson(Map<String, dynamic> lesson) {
    if (!mounted) return;
    final course = _courseData ?? widget.course;
    // Lessons are live-session-only — every lesson opens the live screen
    // (countdown/reminders/join webview), never the recorded video viewer.
    context.push(RouteNames.liveLesson, extra: {
      'lesson': lesson,
      'courseId': course?['id']?.toString(),
      'courseTitle': course?['title']?.toString(),
    });
  }

  void _playLesson(int index, Map<String, dynamic> lesson) async {
    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('▶️ NAVIGATING TO LESSON');
      print('═══════════════════════════════════════════════════════════');
      print('Lesson Index: $index');
      print('Lesson ID: ${lesson['id']}');
      print('Lesson Title: ${lesson['title']}');
      print('All Lesson Keys: ${lesson.keys.toList()}');
      print('═══════════════════════════════════════════════════════════');
    }

    setState(() {
      _selectedLessonIndex = index;
    });

    // Navigate to lesson viewer screen
    if (mounted) {
      _openLesson(lesson);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = _courseData ?? widget.course;

    if (_isLoading && _courseData == null) {
      return Scaffold(
        backgroundColor: context.appTheme.scaffoldBackground,
        body: _buildSkeleton(),
      );
    }

    if (course == null) {
      return Scaffold(
        backgroundColor: context.appTheme.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Course Details'),
        ),
        body: Center(
          child: Text(
            'No course data available',
            style: GoogleFonts.readexPro(),
          ),
        ),
      );
    }

    final pricing = CoursePricingUtils.resolve(course);
    final finalIsFree = pricing.isFree;
    final priceValue = pricing.displayPrice;

    BrandUi.applyStatusBar(context);

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Video Player Section
              _buildVideoSection(),

              // Content Section - Scrollable
              Container(
                decoration: BoxDecoration(
                  color: _theme.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  border: Border(
                    top: BorderSide(color: _theme.cardBorder),
                  ),
                ),
                child: Column(
                  children: [
                    // Course Info Header
                    _buildCourseHeader(course, finalIsFree, priceValue),

                    SkillTrackBundleBanner(course: course),

                    // Tabs
                    _buildTabs(),

                    // Tab Content
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLiveSessionsTab(),
                          _buildAboutTab(course),
                          // _buildExamsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Action Button
      bottomNavigationBar: _buildBottomBar(course, finalIsFree),
    );
  }

  Widget _buildVideoSection() {
    final course = _courseData ?? widget.course;
    // Get thumbnail image
    final thumbnail = course?['thumbnail']?.toString() ??
        course?['image']?.toString() ??
        course?['banner']?.toString();

    return Container(
      height: 220,
      color: Colors.black,
      child: Stack(
        children: [
          // Thumbnail Image
          if (thumbnail != null && thumbnail.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: context.appTheme.icon.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      Icons.image,
                      color: context.appTheme.icon,
                      size: 50,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.appTheme.icon,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              color: context.appTheme.icon.withOpacity(0.1),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: context.appTheme.icon,
                  size: 50,
                ),
              ),
            ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),

          // Play Button Overlay (if enrolled)
          if (_isEnrolled)
            Positioned.fill(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    // Navigate to first lesson
                    final firstLesson = _getFirstLesson();
                    if (firstLesson != null && mounted) {
                      _openLesson(firstLesson);
                    }
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: context.appTheme.icon,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

          // Top Bar
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _isTogglingWishlist ? null : _toggleWishlist,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isInWishlist
                              ? AppColors.orange.withOpacity(0.85)
                              : Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isTogglingWishlist
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Icon(
                                _isInWishlist
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: _isInWishlist
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.9),
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _shareCourseLink,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
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
  }

  Widget _buildCourseHeader(
      Map<String, dynamic>? course, bool isFree, num price) {
    if (course == null) {
      return const SizedBox.shrink();
    }

    final rawCurrency = course['currency']?.toString().trim().toUpperCase();
    final currencyLabel = rawCurrency == 'EGP'
        ? 'EGP'
        : (rawCurrency?.isNotEmpty == true ? rawCurrency! : 'EGP');

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.appTheme.icon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  course['category'] is Map
                      ? (course['category'] as Map)['name']?.toString() ??
                          'Design'
                      : course['category']?.toString() ?? 'Design',
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.appTheme.icon,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFree
                        ? const [
                            AppColors.goldLight,
                            AppColors.goldPrimary,
                          ]
                        : AppColors.secondaryGradient2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFree ? 'Free' : '${price.toInt()} $currencyLabel',
                  style: GoogleFonts.readexPro(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isFree ? AppColors.navyDeep : AppColors.brandWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            course['title']?.toString() ?? 'Course Title',
            style: GoogleFonts.readexPro(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _theme.cardTitle,
            ),
          ),
          const SizedBox(height: 8),

          // Instructor
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.appTheme.icon.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.person, size: 16, color: context.appTheme.icon),
              ),
              const SizedBox(width: 8),
              Text(
                course['instructor'] is Map
                    ? (course['instructor'] as Map)['name']?.toString() ??
                        'Instructor'
                    : course['instructor']?.toString() ?? 'Instructor',
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  color: _theme.cardAccentText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats Row
          Row(
            children: [
              _buildStatChip(
                Icons.star_rounded,
                _safeParseRating(course['rating']),
                AppColors.goldPrimary,
              ),
              if (_isEnrolled) ...[
                const SizedBox(width: 12),
                _buildStatChip(
                  Icons.people_rounded,
                  _safeParseCount(
                      course['students_count'] ?? course['students']),
                  _theme.icon,
                ),
              ],
              const SizedBox(width: 12),
              _buildStatChip(
                Icons.access_time_rounded,
                _formatCourseDurationLabel(course),
                const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.readexPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.appTheme.cardMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.headerGradient2,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.goldPrimary,
        unselectedLabelColor: _theme.mutedForeground,
        labelStyle:
            GoogleFonts.readexPro(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.readexPro(fontSize: 13),
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(text: context.l10n.courseLiveSessionsTab),
          const Tab(text: 'About'),
          // const Tab(text: 'Exams'),
        ],
      ),
    );
  }

  String _safeParseRating(dynamic rating) {
    if (rating == null) return '0.0';
    if (rating is num) return rating.toStringAsFixed(1);
    if (rating is String) {
      final parsed = num.tryParse(rating);
      return parsed?.toStringAsFixed(1) ?? '0.0';
    }
    return '0.0';
  }

  String _safeParseCount(dynamic count) {
    if (count == null) return '0';
    if (count is int) return count.toString();
    if (count is num) return count.toInt().toString();
    if (count is String) {
      final parsed = int.tryParse(count);
      return parsed?.toString() ?? '0';
    }
    return '0';
  }

  String _formatCourseDurationLabel(Map<String, dynamic> course) {
    return context.courseDurationLabel(course);
  }

  String? _lessonYoutubeUrl(Map lesson) {
    final candidates = [
      lesson['video_url'],
      lesson['videoUrl'],
      lesson['youtube_url'],
      lesson['youtubeUrl'],
      lesson['video'],
    ];
    for (final c in candidates) {
      final s = c?.toString().trim() ?? '';
      if (s.isEmpty) continue;
      if (s.contains('youtube.com') || s.contains('youtu.be')) return s;
    }
    final id =
        (lesson['youtube_id'] ?? lesson['youtubeVideoId'])?.toString().trim();
    if (id != null && id.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$id';
    }
    return null;
  }

  /// When API sends duration_minutes: 0, resolve real length from YouTube.
  Future<void> _enrichLessonDurationsFromYoutube() async {
    final course = _courseData;
    if (course == null) return;

    final targets = <Map>[];

    void collect(Map lesson) {
      if (LessonDurationUtils.hasDurationSet(lesson)) return;
      if (_lessonYoutubeUrl(lesson) == null) return;
      targets.add(lesson);
    }

    final curriculum = course['curriculum'];
    if (curriculum is List) {
      for (final item in curriculum) {
        if (item is! Map) continue;
        final nested = item['lessons'];
        if (nested is List) {
          for (final lesson in nested) {
            if (lesson is Map) collect(lesson);
          }
        } else {
          collect(item);
        }
      }
    }
    final lessons = course['lessons'];
    if (lessons is List) {
      for (final lesson in lessons) {
        if (lesson is Map) collect(lesson);
      }
    }

    if (targets.isEmpty) return;

    var updated = false;
    for (final lesson in targets) {
      final url = _lessonYoutubeUrl(lesson);
      if (url == null) continue;
      final minutes =
          await YoutubeVideoService.instance.getVideoDurationMinutes(url);
      if (minutes == null || minutes <= 0) continue;
      LessonDurationUtils.applyYoutubeMinutes(lesson, minutes);
      updated = true;
      if (kDebugMode) {
        print(
            '⏱ Enriched lesson "${lesson['title']}" duration → $minutes min from YouTube');
      }
    }

    if (updated && mounted) {
      setState(() {
        // Mutated nested maps in place; bump state so duration chips refresh.
        _courseData = Map<String, dynamic>.from(course);
      });
    }
  }

  Widget _buildLessonsTab() {
    final course = _courseData ?? widget.course;
    // Try curriculum first, then lessons
    final curriculum = course?['curriculum'] as List?;
    final lessons = course?['lessons'] as List?;

    // Build hierarchical structure: topics with nested lessons
    final List<Map<String, dynamic>> topicsWithLessons = [];
    final List<Map<String, dynamic>> flatLessonsList = [];

    // First, try to get lessons from curriculum
    if (curriculum != null && curriculum.isNotEmpty) {
      for (var item in curriculum) {
        if (item is Map<String, dynamic>) {
          // Check if this item has nested lessons (it's a topic/section)
          final nestedLessons = item['lessons'] as List?;
          final hasVideo = item['video'] != null;
          final hasYoutubeId =
              item['youtube_id'] != null || item['youtubeVideoId'] != null;

          // It's a topic if it has lessons field (even if empty) OR doesn't have video/youtube_id
          final isTopic = nestedLessons != null || (!hasVideo && !hasYoutubeId);

          if (isTopic) {
            // This is a topic - add it even if it has no lessons
            final topicLessons = <Map<String, dynamic>>[];
            if (nestedLessons != null && nestedLessons.isNotEmpty) {
              for (var nestedLesson in nestedLessons) {
                if (nestedLesson is Map<String, dynamic>) {
                  topicLessons.add(nestedLesson);
                  // Add to flat list for indexing
                  flatLessonsList.add(nestedLesson);
                }
              }
            }
            // Add topic even if it has no lessons (empty array or null)
            topicsWithLessons.add({
              'is_topic': true,
              'topic': item,
              'lessons': topicLessons,
            });
          } else {
            // This item is a lesson itself (has video or id)
            if (hasVideo || item['id'] != null || hasYoutubeId) {
              flatLessonsList.add(item);
              topicsWithLessons.add({
                'is_topic': false,
                'lesson': item,
              });
            }
          }
        }
      }
    }

    // If no lessons from curriculum, use lessons directly
    if (topicsWithLessons.isEmpty && lessons != null && lessons.isNotEmpty) {
      for (var lesson in lessons) {
        if (lesson is Map<String, dynamic>) {
          flatLessonsList.add(lesson);
          topicsWithLessons.add({
            'is_topic': false,
            'lesson': lesson,
          });
        }
      }
    }

    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('📚 BUILDING LESSONS TAB');
      print('═══════════════════════════════════════════════════════════');
      print('Curriculum items: ${curriculum?.length ?? 0}');
      print('Lessons items: ${lessons?.length ?? 0}');
      print('Topics with lessons: ${topicsWithLessons.length}');
      print('Total flat lessons: ${flatLessonsList.length}');

      // Count topics
      int topicCount = 0;
      int standaloneLessonCount = 0;
      for (var item in topicsWithLessons) {
        if (item['is_topic'] == true) {
          topicCount++;
        } else {
          standaloneLessonCount++;
        }
      }

      print('');
      print('📊 SUMMARY:');
      print('  - Total Topics: $topicCount');
      print('  - Standalone Lessons: $standaloneLessonCount');
      print('  - Total Items: ${topicsWithLessons.length}');
      print('');

      // Show ALL topics from curriculum (even if they have no lessons)
      if (curriculum != null && curriculum.isNotEmpty) {
        print('📁 ALL TOPICS FROM CURRICULUM (COMPLETE LIST):');
        print('═══════════════════════════════════════════════════════════');
        int allTopicsCount = 0;
        for (int i = 0; i < curriculum.length; i++) {
          final item = curriculum[i];
          if (item is Map<String, dynamic>) {
            final nestedLessons = item['lessons'] as List?;
            final hasVideo = item['video'] != null;
            final hasYoutubeId =
                item['youtube_id'] != null || item['youtubeVideoId'] != null;

            // It's a topic if it has lessons field OR doesn't have video/youtube_id
            final isTopic =
                nestedLessons != null || (!hasVideo && !hasYoutubeId);

            if (isTopic) {
              allTopicsCount++;
              final lessonsCount = nestedLessons?.length ?? 0;
              print('📁 TOPIC $allTopicsCount:');
              print('  - ID: ${item['id']}');
              print('  - Title: ${item['title']}');
              print('  - Order: ${item['order']}');
              print('  - Type: ${item['type']}');
              print('  - Lessons Count: $lessonsCount');
              print('  - Has Lessons Field: ${nestedLessons != null}');
              if (nestedLessons == null) {
                print('  - ⚠️ No lessons field found');
              } else if (nestedLessons.isEmpty) {
                print('  - ⚠️ Empty lessons array');
              }
              print('  - All Keys: ${item.keys.toList()}');
              print('');
            }
          }
        }
        print('═══════════════════════════════════════════════════════════');
        print('Total Topics in Curriculum: $allTopicsCount');
        print('═══════════════════════════════════════════════════════════');
        print('');
      }

      // Show all topics summary (only topics that have lessons)
      if (topicCount > 0) {
        print('📁 TOPICS WITH LESSONS (FOR DISPLAY):');
        print('═══════════════════════════════════════════════════════════');
        int currentTopicNum = 0;
        for (int i = 0; i < topicsWithLessons.length; i++) {
          final item = topicsWithLessons[i];
          if (item['is_topic'] == true) {
            currentTopicNum++;
            final topic = item['topic'] as Map<String, dynamic>;
            final topicLessons = item['lessons'] as List<Map<String, dynamic>>;
            print('📁 TOPIC $currentTopicNum:');
            print('  - ID: ${topic['id']}');
            print('  - Title: ${topic['title']}');
            print('  - Order: ${topic['order']}');
            print('  - Lessons Count: ${topicLessons.length}');
            print('');
          }
        }
        print('═══════════════════════════════════════════════════════════');
        print('');
      }

      if (topicsWithLessons.isNotEmpty) {
        print('First item:');
        final first = topicsWithLessons[0];
        if (first['is_topic'] == true) {
          print('  - Type: Topic');
          print('  - Topic Title: ${first['topic']?['title']}');
          print(
              '  - Lessons Count: ${(first['lessons'] as List?)?.length ?? 0}');
        } else {
          print('  - Type: Lesson');
          print('  - Lesson Title: ${first['lesson']?['title']}');
        }
      }
      print('═══════════════════════════════════════════════════════════');
      print('📖 DETAILED LESSONS DATA:');
      print('═══════════════════════════════════════════════════════════');
      for (int i = 0; i < topicsWithLessons.length; i++) {
        final item = topicsWithLessons[i];
        final isTopic = item['is_topic'] == true;

        if (isTopic) {
          final topic = item['topic'] as Map<String, dynamic>;
          final topicLessons = item['lessons'] as List<Map<String, dynamic>>;

          print('───────────────────────────────────────────────────────────');
          print('📁 TOPIC ${i + 1}:');
          print('  - ID: ${topic['id']}');
          print('  - Title: ${topic['title']}');
          print('  - Order: ${topic['order']}');
          print('  - Type: ${topic['type']}');
          print('  - Lessons Count: ${topicLessons.length}');
          print('  - All Topic Keys: ${topic.keys.toList()}');
          print('');
          print('  📚 LESSONS IN THIS TOPIC:');

          for (int j = 0; j < topicLessons.length; j++) {
            final lesson = topicLessons[j];
            print(
                '    ───────────────────────────────────────────────────────');
            print('    📝 LESSON ${j + 1}:');
            print('      - ID: ${lesson['id']}');
            print('      - Title: ${lesson['title']}');
            print('      - Order: ${lesson['order']}');
            print('      - Type: ${lesson['type']}');
            print('      - Duration Minutes: ${lesson['duration_minutes']}');
            print('      - Is Locked: ${lesson['is_locked']}');
            print('      - Is Completed: ${lesson['is_completed']}');
            print('      - Video: ${lesson['video']}');
            print('      - YouTube ID: ${lesson['youtube_id']}');
            print('      - YouTube Video ID: ${lesson['youtubeVideoId']}');

            // Print video object details if exists
            if (lesson['video'] is Map) {
              final video = lesson['video'] as Map;
              print('      - Video Object Keys: ${video.keys.toList()}');
              video.forEach((key, value) {
                print('        - video.$key: $value');
              });
            }

            print('      - All Lesson Keys: ${lesson.keys.toList()}');

            // Print full lesson JSON
            try {
              const encoder = JsonEncoder.withIndent('        ');
              print('      - Full Lesson JSON:');
              print(encoder.convert(lesson));
            } catch (e) {
              print('      - Could not convert lesson to JSON: $e');
            }
          }
        } else {
          final lesson = item['lesson'] as Map<String, dynamic>;
          print('───────────────────────────────────────────────────────────');
          print('📝 STANDALONE LESSON ${i + 1}:');
          print('  - ID: ${lesson['id']}');
          print('  - Title: ${lesson['title']}');
          print('  - Order: ${lesson['order']}');
          print('  - Type: ${lesson['type']}');
          print('  - Duration Minutes: ${lesson['duration_minutes']}');
          print('  - Is Locked: ${lesson['is_locked']}');
          print('  - Is Completed: ${lesson['is_completed']}');
          print('  - Video: ${lesson['video']}');
          print('  - YouTube ID: ${lesson['youtube_id']}');
          print('  - YouTube Video ID: ${lesson['youtubeVideoId']}');

          // Print video object details if exists
          if (lesson['video'] is Map) {
            final video = lesson['video'] as Map;
            print('  - Video Object Keys: ${video.keys.toList()}');
            video.forEach((key, value) {
              print('    - video.$key: $value');
            });
          }

          print('  - All Lesson Keys: ${lesson.keys.toList()}');

          // Print full lesson JSON
          try {
            const encoder = JsonEncoder.withIndent('    ');
            print('  - Full Lesson JSON:');
            print(encoder.convert(lesson));
          } catch (e) {
            print('  - Could not convert lesson to JSON: $e');
          }
        }
      }
      print('═══════════════════════════════════════════════════════════');
    }

    if (topicsWithLessons.isEmpty) {
      return _buildEmptyState(
          'No lessons available', Icons.play_lesson_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      // physics: const NeverScrollableScrollPhysics(),
      itemCount: topicsWithLessons.length,
      itemBuilder: (context, index) {
        final item = topicsWithLessons[index];
        final isTopic = item['is_topic'] == true;

        if (isTopic) {
          // Render topic header with nested lessons
          final topic = item['topic'] as Map<String, dynamic>;
          final topicLessons = item['lessons'] as List<Map<String, dynamic>>;
          final topicTitle = topic['title']?.toString() ?? 'Topic';
          final topicOrder = topic['order'] ?? index + 1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic Header
              Container(
                margin: EdgeInsets.only(bottom: 12, top: index > 0 ? 16 : 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.appTheme.icon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.appTheme.icon.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.appTheme.icon,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$topicOrder',
                          style: GoogleFonts.readexPro(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyDeep,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        topicTitle,
                        style: GoogleFonts.readexPro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _theme.cardTitle,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.appTheme.icon.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${topicLessons.length} lessons',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.appTheme.icon,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Nested Lessons
              ...topicLessons.map((lesson) {
                // Find global index for this lesson
                final globalIndex = flatLessonsList.indexWhere(
                    (l) => l['id']?.toString() == lesson['id']?.toString());
                final actualIndex = globalIndex >= 0 ? globalIndex : 0;

                return _buildLessonItem(lesson, actualIndex, flatLessonsList);
              }),
            ],
          );
        } else {
          // Render standalone lesson
          final lesson = item['lesson'] as Map<String, dynamic>;
          final globalIndex = flatLessonsList.indexWhere(
              (l) => l['id']?.toString() == lesson['id']?.toString());
          final actualIndex = globalIndex >= 0 ? globalIndex : 0;

          return _buildLessonItem(lesson, actualIndex, flatLessonsList);
        }
      },
    );
  }

  Widget _buildLessonItem(Map<String, dynamic> lesson, int index,
      List<Map<String, dynamic>> allLessons) {
    final l10n = AppLocalizations.of(context)!;
    // Lessons are live-session-only — access/countdown rules come from
    // LiveLessonUtils regardless of whether the link is set yet.
    final isLocked = !LiveLessonUtils.hasAccess(
      lesson,
      courseEnrolled: _isEnrolled,
      isOwnCourse: _isViewingOwnCourse,
    );
    final isCompleted =
        lesson['is_completed'] == true || lesson['completed'] == true;
    final isSelected = index == _selectedLessonIndex;

    final liveStatus = LiveLessonUtils.status(lesson);
    final isLiveNow = liveStatus == LiveLessonStatus.live;
    final lessonPrice = LiveLessonUtils.price(lesson);
    final canBuy = LiveLessonUtils.requiresPurchase(
      lesson,
      courseEnrolled: _isEnrolled,
      isOwnCourse: _isViewingOwnCourse,
    );

    return GestureDetector(
      onTap: isLocked
          ? (canBuy ? () => _showLessonPurchaseSheet(lesson) : null)
          : () {
              _playLesson(index, lesson);
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? _theme.progressTrack
              : isLocked
                  ? _theme.cardMuted
                  : _theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLiveNow
                ? const Color(0xFFEF4444)
                : isSelected
                    ? _theme.icon
                    : isCompleted
                        ? AppColors.goldPrimary
                        : _theme.cardBorder,
            width: isSelected || isCompleted || isLiveNow ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Index/Status Circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isLiveNow
                    ? const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      )
                    : isSelected
                        ? const LinearGradient(
                            colors: AppColors.headerGradient2,
                          )
                        : isCompleted
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                            : null,
                color: isLocked ? _theme.progressTrack : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLocked
                  ? Icon(Icons.lock_rounded, color: _theme.iconMuted, size: 20)
                  : isLiveNow
                      ? const Icon(Icons.videocam_rounded,
                          color: Colors.white, size: 20)
                      : isCompleted
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : isSelected
                              ? const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 22)
                              : Icon(Icons.live_tv_rounded,
                                  color: context.appTheme.icon, size: 20),
            ),
            const SizedBox(width: 14),

            // Lesson Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson['title']?.toString() ?? 'Lesson',
                    style: GoogleFonts.readexPro(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? _theme.iconMuted : _theme.cardTitle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildLiveLessonMeta(lesson, liveStatus, l10n),
                ],
              ),
            ),

            // Trailing: price chip for purchasable lessons, else play icon
            if (isLocked && canBuy)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.goldPrimary.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  l10n.egyptianPoundAmount(
                    lessonPrice == lessonPrice.roundToDouble()
                        ? lessonPrice.toInt().toString()
                        : lessonPrice.toStringAsFixed(2),
                  ),
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldPrimary,
                  ),
                ),
              )
            else if (!isLocked)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? _theme.icon : _theme.progressTrack,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.login_rounded,
                  color: isSelected ? AppColors.navyDeep : _theme.icon,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Schedule + countdown + status meta row for a live lesson tile.
  Widget _buildLiveLessonMeta(
    Map<String, dynamic> lesson,
    LiveLessonStatus status,
    AppLocalizations l10n,
  ) {
    final start = LiveLessonUtils.scheduledAt(lesson);
    final end = LiveLessonUtils.endsAt(lesson);
    final durationMinutes = LiveLessonUtils.durationMinutes(lesson);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 13,
              color: _theme.iconMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _formatLiveSessionWhen(
                  context,
                  start?.toIso8601String(),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: _theme.cardMetaText,
                ),
              ),
            ),
            if (durationMinutes > 0)
              Text(
                '$durationMinutes min',
                style: GoogleFonts.readexPro(
                  fontSize: 11,
                  color: _theme.iconMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (status == LiveLessonStatus.live)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.liveNow,
              style: GoogleFonts.readexPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444),
              ),
            ),
          )
        else if (status == LiveLessonStatus.upcoming && start != null)
          LiveSessionCountdown(
            start: start,
            end: end,
            startsLabel: l10n.startsIn,
            endsLabel: l10n.endsIn,
            endedLabel: l10n.liveSessionButtonEnded,
            compact: true,
            backgroundColor: _theme.icon.withOpacity(0.12),
            foregroundColor: _theme.icon,
          )
        else if (status == LiveLessonStatus.ended ||
            status == LiveLessonStatus.cancelled)
          Text(
            l10n.liveSessionButtonEnded,
            style: GoogleFonts.readexPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _theme.iconMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildAboutTab(Map<String, dynamic>? course) {
    final courseData = _courseData ?? course;
    final description = courseData?['description']?.toString().trim();
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Description',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _theme.cardTitle,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _theme.cardMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _theme.cardBorder),
            ),
            child: Text(
              (description != null && description.isNotEmpty)
                  ? description
                  : l10n.notAvailable,
              style: GoogleFonts.readexPro(
                fontSize: 14,
                color: _theme.cardMetaText,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _liveSessionsForCourse() {
    final course = _courseData ?? widget.course;
    final raw = course?['live_sessions'];
    if (raw is! List) return [];
    final list =
        raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    list.sort((a, b) {
      final da = DateTime.tryParse(a['scheduled_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(b['scheduled_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return da.compareTo(db);
    });
    return list;
  }

  String _formatLiveSessionWhen(BuildContext context, String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMEd(locale).add_jm().format(dt.toLocal());
  }

  String _livePlatformLabel(String? p) {
    switch (p?.toLowerCase().trim()) {
      case 'zoom':
        return 'Zoom';
      case 'meet':
        return 'Google Meet';
      case 'teams':
        return 'Microsoft Teams';
      default:
        return p?.trim().isNotEmpty == true ? p!.trim() : '';
    }
  }

  void _openLiveSessionPlatformLink(String? rawUrl, {String? title}) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.sessionLinkUnavailable,
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.liveSessionOpenLinkFailed,
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveSessionWebViewScreen(url: trimmed, title: title),
      ),
    );
  }

  /// Schedules local notifications before an upcoming live session
  /// (30 min, 10 min, and at start).
  Future<void> _scheduleLiveSessionReminder(
    Map<String, dynamic> session,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final start = LiveLessonUtils.scheduledAt(session);
    if (start == null) return;
    final course = _courseData ?? widget.course;
    final title = session['title']?.toString() ?? l10n.liveSession;
    try {
      await LiveSessionReminderService.instance.scheduleSessionReminders(
        sessionId: session['id']?.toString() ?? title,
        courseId: course?['id']?.toString() ?? '',
        lessonId: session['lesson_id']?.toString(),
        sessionTitle: title,
        start: start,
        notificationTitle: l10n.liveSessionReminderTitle,
        bodyBuilder: (minutes) => minutes <= 0
            ? l10n.liveSessionReminderNowBody(title)
            : l10n.liveSessionReminderBody(title, minutes),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.reminderSet,
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.liveSessionOpenLinkFailed,
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildLiveSessionsTab() {
    final l10n = AppLocalizations.of(context)!;
    final sessions = _liveSessionsForCourse();
    if (sessions.isEmpty) {
      return _buildEmptyState(l10n.noLiveSessions, Icons.videocam_off_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _buildLiveSessionCard(
          session,
          index,
          sessions.length,
          l10n,
        );
      },
    );
  }

  Widget _buildLiveSessionCard(
    Map<String, dynamic> session,
    int index,
    int total,
    AppLocalizations l10n,
  ) {
    final title = session['title']?.toString().trim();
    final description = session['description']?.toString().trim() ?? '';
    final platform = session['platform']?.toString();
    final link = session['platform_link']?.toString();
    final scheduledAt = session['scheduled_at']?.toString();
    final durationRaw = session['duration_minutes'];
    final durationMinutes = durationRaw is int
        ? durationRaw
        : durationRaw is num
            ? durationRaw.toInt()
            : int.tryParse('$durationRaw') ?? 0;
    final capacity = session['capacity'];
    final cap = capacity is int
        ? capacity
        : capacity is num
            ? capacity.toInt()
            : int.tryParse('$capacity') ?? 0;
    final enrolled = session['enrolled_count'];
    final enr = enrolled is int
        ? enrolled
        : enrolled is num
            ? enrolled.toInt()
            : int.tryParse('$enrolled') ?? 0;
    final priceRaw = session['price'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse('$priceRaw') ?? 0.0;
    final status = session['status']?.toString() ?? '';
    final statusNorm = status.trim().toLowerCase();
    final isLive = statusNorm == 'live';
    final isCompleted = statusNorm == 'completed';
    final isCancelled = statusNorm == 'cancelled';
    final scheduledDt = scheduledAt != null && scheduledAt.isNotEmpty
        ? DateTime.tryParse(scheduledAt)
        : null;
    final startLocal = scheduledDt?.toLocal();
    final now = DateTime.now();
    final isFutureScheduled = !isLive &&
        !isCompleted &&
        !isCancelled &&
        (statusNorm == 'scheduled' || statusNorm.isEmpty) &&
        startLocal != null &&
        startLocal.isAfter(now);

    // Access rule: enrolled in the course (or it's your own), the session is
    // individually purchased, or it's free. Paid locked sessions show a buy
    // action that runs the per-lesson checkout (`item_type: lesson`).
    final hasAccess = _isEnrolled ||
        _isViewingOwnCourse ||
        LiveLessonUtils.isPurchased(session) ||
        price <= 0;
    final canBuy = !hasAccess && price > 0;

    late final bool primaryJoin;
    late final VoidCallback? joinAction;
    late final String buttonLabel;
    if (canBuy) {
      primaryJoin = true;
      joinAction = () => _showLessonPurchaseSheet(session);
      buttonLabel = l10n.subscribeNow;
    } else if (isLive) {
      primaryJoin = true;
      joinAction = () => _openLiveSessionPlatformLink(link, title: title);
      buttonLabel = l10n.joinNow;
    } else if (isCompleted || isCancelled) {
      primaryJoin = false;
      joinAction = null;
      buttonLabel = l10n.liveSessionButtonEnded;
    } else if (isFutureScheduled) {
      primaryJoin = false;
      joinAction = () => _scheduleLiveSessionReminder(session);
      buttonLabel = l10n.liveSessionButtonUpcoming;
    } else {
      primaryJoin = true;
      joinAction = () => _openLiveSessionPlatformLink(link, title: title);
      buttonLabel = l10n.joinNow;
    }

    final platformLabel = _livePlatformLabel(platform);
    final instructor = session['instructor'];
    String instructorName = '';
    String? instructorAvatar;
    if (instructor is Map) {
      instructorName = instructor['name']?.toString() ?? '';
      instructorAvatar = instructor['avatar']?.toString();
    }

    return Container(
      margin: EdgeInsets.only(bottom: index < total - 1 ? 16 : 0),
      decoration: BoxDecoration(
        color: context.appTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive ? const Color(0xFFEF4444) : context.appTheme.cardBorder,
          width: isLive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title?.isNotEmpty == true ? title! : l10n.liveSession,
                    style: GoogleFonts.readexPro(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.cardTitle,
                    ),
                  ),
                ),
                if (isLive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.liveNow,
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ] else if (isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.cardMetaText.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.completed,
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.cardMetaText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  height: 1.45,
                  color: context.cardMetaText,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 18, color: context.appTheme.icon.withOpacity(0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatLiveSessionWhen(context, scheduledAt),
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.cardTitle,
                    ),
                  ),
                ),
              ],
            ),
            if (startLocal != null && (isFutureScheduled || isLive)) ...[
              const SizedBox(height: 10),
              LiveSessionCountdown(
                start: scheduledDt,
                end: durationMinutes > 0
                    ? scheduledDt?.add(Duration(minutes: durationMinutes))
                    : null,
                startsLabel: l10n.startsIn,
                endsLabel: l10n.endsIn,
                endedLabel: l10n.liveSessionButtonEnded,
                compact: true,
                backgroundColor: isLive
                    ? const Color(0xFFEF4444).withOpacity(0.12)
                    : context.appTheme.icon.withOpacity(0.12),
                foregroundColor:
                    isLive ? const Color(0xFFEF4444) : context.appTheme.icon,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (durationMinutes > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timelapse_outlined,
                          size: 16, color: context.cardMetaText),
                      const SizedBox(width: 4),
                      Text(
                        '$durationMinutes min',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          color: context.cardMetaText,
                        ),
                      ),
                    ],
                  ),
                if (cap > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 16, color: context.cardMetaText),
                      const SizedBox(width: 4),
                      Text(
                        '$enr / $cap',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          color: context.cardMetaText,
                        ),
                      ),
                    ],
                  ),
                if (platformLabel.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.appTheme.icon.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      platformLabel,
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.appTheme.icon,
                      ),
                    ),
                  ),
                if (price > 0)
                  Text(
                    price == price.roundToDouble()
                        ? '${price.toInt()}'
                        : price.toStringAsFixed(2),
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.cardTitle,
                    ),
                  ),
              ],
            ),
            if (instructorName.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        context.appTheme.icon.withValues(alpha: 0.15),
                    backgroundImage:
                        instructorAvatar != null && instructorAvatar.isNotEmpty
                            ? NetworkImage(instructorAvatar)
                            : null,
                    child: instructorAvatar == null || instructorAvatar.isEmpty
                        ? Icon(Icons.person,
                            size: 20, color: context.appTheme.icon)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      instructorName,
                      style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.cardTitle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: joinAction,
                style: FilledButton.styleFrom(
                  backgroundColor: context.appTheme.icon,
                  disabledBackgroundColor: context.appTheme.progressTrack,
                  foregroundColor: AppColors.navyDeep,
                  disabledForegroundColor: context.appTheme.mutedForeground,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: GoogleFonts.readexPro(
                    fontWeight: FontWeight.bold,
                    color: primaryJoin ? AppColors.navyDeep : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsTab() {
    if (_isLoadingExams) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: context.appTheme.icon,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading exams...',
              style: GoogleFonts.readexPro(
                fontSize: 14,
                color: context.cardMetaText,
              ),
            ),
          ],
        ),
      );
    }

    if (_courseExams.isEmpty) {
      return _buildEmptyState('No exams available', Icons.quiz_rounded);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: _courseExams.length,
      itemBuilder: (context, index) {
        final exam = _courseExams[index];
        return _buildExamCard(exam, index);
      },
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam, int index) {
    final canStart = exam['can_start'] == true;
    final isPassed = exam['is_passed'] == true;
    final bestScore = exam['best_score'];
    final questionsCount = exam['questions_count'] ?? 0;
    final durationMinutes = exam['duration_minutes'] ?? 15;
    final passingScore = exam['passing_score'] ?? 70;
    final maxAttempts = exam['max_attempts'];
    final attemptsUsed = exam['attempts_used'] ?? 0;
    final examId = exam['id']?.toString() ?? '';
    final examTitle = exam['title']?.toString() ?? 'Exam';
    final examDescription = exam['description']?.toString() ?? '';

    // Determine if it's a trial exam
    final isTrial = exam['type'] == 'trial' ||
        exam['type'] == 'trial_exam' ||
        examTitle.contains('trial') ||
        examTitle.contains('trial');

    return Container(
      margin: EdgeInsets.only(bottom: index < _courseExams.length - 1 ? 16 : 0),
      decoration: BoxDecoration(
        gradient: isTrial
            ? const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: AppColors.headerGradient2,
              )
            : null,
        color: isTrial ? null : context.appTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: isTrial
            ? null
            : Border.all(
                color: context.appTheme.icon.withOpacity(0.2),
                width: 1,
              ),
        boxShadow: isTrial
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isTrial
                            ? Colors.white.withOpacity(0.2)
                            : context.appTheme.progressTrack,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTrial ? Icons.quiz_rounded : Icons.assignment_rounded,
                        size: 28,
                        color: isTrial ? Colors.white : context.appTheme.icon,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            examTitle,
                            style: GoogleFonts.readexPro(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isTrial ? Colors.white : context.cardTitle,
                            ),
                          ),
                          if (examDescription.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              examDescription,
                              style: GoogleFonts.readexPro(
                                fontSize: 13,
                                color: isTrial
                                    ? Colors.white.withOpacity(0.8)
                                    : context.appTheme.cardMetaText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Exam Info
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildExamInfoChip(
                      Icons.help_outline,
                      '$questionsCount questions',
                      isTrial
                          ? Colors.white.withOpacity(0.3)
                          : context.appTheme.progressTrack,
                      isTrial ? Colors.white : context.appTheme.icon,
                    ),
                    _buildExamInfoChip(
                      Icons.access_time,
                      '$durationMinutes min',
                      isTrial
                          ? Colors.white.withOpacity(0.3)
                          : context.appTheme.progressTrack,
                      isTrial ? Colors.white : context.appTheme.icon,
                    ),
                    _buildExamInfoChip(
                      Icons.star,
                      '$passingScore% to pass',
                      isTrial
                          ? Colors.white.withOpacity(0.3)
                          : context.appTheme.progressTrack,
                      isTrial ? Colors.white : context.appTheme.icon,
                    ),
                    if (maxAttempts != null)
                      _buildExamInfoChip(
                        Icons.repeat,
                        '$attemptsUsed/$maxAttempts attempts',
                        isTrial
                            ? Colors.white.withOpacity(0.3)
                            : context.appTheme.progressTrack,
                        isTrial ? Colors.white : context.appTheme.icon,
                      ),
                  ],
                ),
                if (bestScore != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? Colors.green.withOpacity(isTrial ? 0.3 : 0.1)
                          : Colors.orange.withOpacity(isTrial ? 0.3 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPassed ? Icons.check_circle : Icons.info_outline,
                          size: 16,
                          color: isTrial
                              ? Colors.white
                              : (isPassed ? Colors.green : Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPassed
                              ? 'Best score: $bestScore% ✓'
                              : 'Best score: $bestScore%',
                          style: GoogleFonts.readexPro(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isTrial
                                ? Colors.white
                                : (isPassed ? Colors.green : Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: canStart ? () => _startExam(examId, exam) : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: canStart
                          ? (isTrial ? Colors.white : context.appTheme.icon)
                          : (isTrial
                              ? Colors.white.withOpacity(0.5)
                              : context.appTheme.progressTrack),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          canStart
                              ? Icons.play_arrow_rounded
                              : Icons.lock_rounded,
                          color: canStart
                              ? (isTrial
                                  ? context.appTheme.icon
                                  : AppColors.navyDeep)
                              : context.appTheme.iconMuted,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          canStart
                              ? 'Start Exam'
                              : (maxAttempts != null &&
                                      attemptsUsed >= maxAttempts
                                  ? 'No attempts left'
                                  : 'Unavailable'),
                          style: GoogleFonts.readexPro(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: canStart
                                ? (isTrial
                                    ? context.appTheme.icon
                                    : AppColors.navyDeep)
                                : context.appTheme.iconMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamInfoChip(
    IconData icon,
    String text,
    Color bgColor, [
    Color? iconColor,
  ]) {
    final finalIconColor = iconColor ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: finalIconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.readexPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: finalIconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.appTheme.icon.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: context.appTheme.icon),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.readexPro(
              fontSize: 16,
              color: context.cardMetaText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic>? course, bool isFree) {
    if (_isViewingOwnCourse) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appTheme.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_rounded,
                  color: context.appTheme.icon, size: 22),
              const SizedBox(width: 8),
              Text(
                'You are the instructor of this course',
                style: GoogleFonts.readexPro(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.appTheme.icon,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appTheme.card,
        boxShadow: [
          BoxShadow(
            color: _theme.shadow,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: _theme.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: _isTogglingWishlist ? null : _toggleWishlist,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isInWishlist
                      ? AppColors.orange.withOpacity(0.18)
                      : AppColors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _isTogglingWishlist
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.orange),
                        ),
                      )
                    : Icon(
                        _isInWishlist
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: _isInWishlist
                            ? AppColors.orange
                            : AppColors.mutedForeground,
                        size: 24,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _isEnrolling || _isSubmittingLibraryRequest
                    ? null
                    : () async {
                        // If already enrolled, go to first lesson
                        if (_isEnrolled) {
                          final firstLesson = _getFirstLesson();
                          if (firstLesson != null && mounted) {
                            _openLesson(firstLesson);
                          }
                          return;
                        }

                        // If free course, enroll directly
                        if (isFree) {
                          await _enrollInCourse();
                        } else {
                          await _startPaidPurchase();
                        }
                      },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _isEnrolling || _isSubmittingLibraryRequest
                        ? null
                        : const LinearGradient(
                            colors: [
                              AppColors.goldLight,
                              AppColors.goldPrimary,
                            ],
                          ),
                    color: (_isEnrolling || _isSubmittingLibraryRequest)
                        ? _theme.progressTrack
                        : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isEnrolling)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _theme.icon,
                            ),
                          ),
                        )
                      else if (_isSubmittingLibraryRequest)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.navyDeep,
                            ),
                          ),
                        )
                      else
                        Icon(
                          _isEnrolled
                              ? Icons.play_circle_rounded
                              : _libraryRequestStatus == 'pending'
                                  ? Icons.hourglass_top_rounded
                                  : _libraryRequestStatus == 'rejected'
                                      ? Icons.error_outline_rounded
                                      : isFree
                                          ? Icons.play_circle_rounded
                                          : Icons.shopping_cart_rounded,
                          color: (_isEnrolling || _isSubmittingLibraryRequest)
                              ? _theme.iconMuted
                              : AppColors.navyDeep,
                          size: 22,
                        ),
                      const SizedBox(width: 10),
                      Text(
                        _isEnrolling
                            ? 'Enrolling...'
                            : _isSubmittingLibraryRequest
                                ? 'Sending request...'
                                : _isEnrolled
                                    ? 'Start Learning Now'
                                    : _libraryRequestStatus == 'pending'
                                        ? 'قيد المراجعة'
                                        : _libraryRequestStatus == 'approved'
                                            ? 'تمت الموافقة'
                                            : _libraryRequestStatus ==
                                                    'rejected'
                                                ? 'مرفوض'
                                                : isFree
                                                    ? 'Enroll for Free'
                                                    : 'Enroll in Course',
                        style: GoogleFonts.readexPro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: (_isEnrolling || _isSubmittingLibraryRequest)
                              ? _theme.mutedForeground
                              : AppColors.navyDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showPaymentMethodBottomSheet() async {
    final config = await AppConfigService.instance.getAppConfig();
    if (!mounted) return null;
    final l10n = AppLocalizations.of(context)!;
    final methods = CoursePaymentMethodsUi.availableMethods(config, l10n);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            color: context.appTheme.sheetBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: context.appTheme.cardBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appTheme.progressTrack,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context)!.choosePaymentMethod,
                style: GoogleFonts.readexPro(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appTheme.cardTitle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.checkoutSelectPaymentSubtitle,
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  color: context.appTheme.cardMetaText,
                ),
              ),
              const SizedBox(height: 14),
              if (methods.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.checkoutNoPaymentMethods,
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      color: context.appTheme.cardMetaText,
                    ),
                  ),
                ),
              ...methods.map((method) {
                return InkWell(
                  onTap: () =>
                      Navigator.of(context).pop(method['id'] as String),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.appTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: context.appTheme.cardMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            method['icon'] as IconData,
                            color: context.appTheme.icon,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['title'] as String,
                                style: GoogleFonts.readexPro(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.appTheme.cardTitle,
                                ),
                              ),
                              Text(
                                method['subtitle'] as String,
                                style: GoogleFonts.readexPro(
                                  fontSize: 12,
                                  color: context.appTheme.cardMetaText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.appTheme.cardMetaText,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // «لديك كود تفعيل؟» — instant unlock via activation code
              // (doc §2.2: shown beside the manual payment options).
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Divider(color: context.appTheme.cardBorder),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop('activation_code'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10, top: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.appTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.key_rounded,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.haveActivationCode,
                              style: GoogleFonts.readexPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.appTheme.cardTitle,
                              ),
                            ),
                            Text(
                              l10n.activationCodeSheetSubtitle,
                              style: GoogleFonts.readexPro(
                                fontSize: 12,
                                color: context.appTheme.cardMetaText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.appTheme.cardMetaText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Activation-code entry sheet — `POST /activation-codes/redeem` (doc §2.1).
  Future<void> _showActivationCodeSheet() async {
    final course = _courseData ?? widget.course;
    final courseId = course?['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    final codeController = TextEditingController();
    String? errorText;
    var submitting = false;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final l10n = AppLocalizations.of(context)!;
            Future<void> submit() async {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                setSheetState(() => errorText = l10n.activationCodeRequired);
                return;
              }
              setSheetState(() {
                submitting = true;
                errorText = null;
              });
              try {
                final data = await ActivationCodesService.instance.redeemCode(
                  code: code,
                  courseId: courseId,
                );
                if (context.mounted) {
                  Navigator.of(context).pop(data);
                }
              } catch (e) {
                var msg = e.toString();
                if (msg.startsWith('Exception: ')) {
                  msg = msg.substring('Exception: '.length);
                }
                // "أنت مشترك بالفعل في هذه الدورة" — doc says route the
                // student straight to the watch screen instead of an error.
                if (msg.contains('مشترك بالفعل') ||
                    msg.toLowerCase().contains('already enrolled')) {
                  if (context.mounted) {
                    Navigator.of(context).pop(
                      <String, dynamic>{'already_enrolled': true},
                    );
                  }
                  return;
                }
                setSheetState(() {
                  submitting = false;
                  errorText =
                      msg.isNotEmpty ? msg : l10n.activationCodeInvalidFallback;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                decoration: BoxDecoration(
                  color: context.appTheme.sheetBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: context.appTheme.cardBorder),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.appTheme.progressTrack,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.activationCodeDialogTitle,
                      style: GoogleFonts.readexPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.appTheme.cardTitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.activationCodeSheetSubtitle,
                      style: GoogleFonts.readexPro(
                        fontSize: 13,
                        color: context.appTheme.cardMetaText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      enabled: !submitting,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: l10n.activationCodeFieldHint,
                        hintStyle: GoogleFonts.readexPro(
                          color: context.appTheme.cardMetaText,
                          fontSize: 14,
                        ),
                        errorText: errorText,
                        errorStyle: GoogleFonts.readexPro(fontSize: 12),
                        filled: true,
                        fillColor: context.appTheme.cardMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.appTheme.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.appTheme.cardBorder,
                          ),
                        ),
                      ),
                      style: GoogleFonts.readexPro(fontSize: 14),
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting ? null : submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: context.appTheme.icon,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.activationCodeSubmit,
                                style: GoogleFonts.readexPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    codeController.dispose();
    if (!mounted || result == null) return;
    await _handleActivationSuccess(result);
  }

  /// After a successful redeem: mark enrolled, refresh details, move to
  /// the watch screen (doc §2.2). Handles bundle `enrolled_course_ids`.
  Future<void> _handleActivationSuccess(Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context)!;

    if (mounted) {
      setState(() => _isEnrolled = true);
    }

    if (data['already_enrolled'] == true) {
      await _loadCourseDetails();
      if (!mounted) return;
      final firstLesson = _getFirstLesson();
      if (firstLesson != null) {
        _openLesson(firstLesson);
      }
      return;
    }

    final enrolledIds = data['enrolled_course_ids'];
    final bundleCount =
        enrolledIds is List && enrolledIds.length > 1 ? enrolledIds.length : 0;
    final serverMessage = data['message']?.toString().trim();
    final snackText = bundleCount > 0
        ? l10n.skillTrackBundleUnlockedMessage(bundleCount)
        : (serverMessage != null && serverMessage.isNotEmpty
            ? serverMessage
            : l10n.activationCodeSuccessFallback);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(snackText, style: GoogleFonts.readexPro()),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Refresh so `is_enrolled` / unlocked curriculum come back from the API.
    await _loadCourseDetails();
    if (!mounted) return;

    final firstLesson = _getFirstLesson();
    if (firstLesson != null) {
      _openLesson(firstLesson);
    }
  }

  Future<void> _enrollInCourse() async {
    final course = _courseData ?? widget.course;
    if (course == null || course['id'] == null) return;

    final courseId = course['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    setState(() => _isEnrolling = true);

    try {
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('📤 ENROLL REQUEST (enrollInCourse)');
        print('═══════════════════════════════════════════════════════════');
        print('Course ID: $courseId');
        final title = course['title']?.toString();
        if (title != null) {
          print('Course Title: $title');
        }
        print('═══════════════════════════════════════════════════════════');
      }

      final enrollment = await CoursesService.instance.enrollInCourse(courseId);

      // Print detailed response
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('✅ ENROLLMENT RESPONSE (enrollInCourse)');
        print('═══════════════════════════════════════════════════════════');
        print('Course ID: $courseId');
        print('Response Type: ${enrollment.runtimeType}');
        print('Response Keys: ${enrollment.keys.toList()}');
        print('───────────────────────────────────────────────────────────');
        print('Full Response JSON:');
        try {
          const encoder = JsonEncoder.withIndent('  ');
          print(encoder.convert(enrollment));
        } catch (e) {
          print('Could not convert to JSON: $e');
          print('Raw Response: $enrollment');
        }
        print('───────────────────────────────────────────────────────────');
        print('Key Fields:');
        enrollment.forEach((key, value) {
          print('  - $key: $value (${value.runtimeType})');
        });
        print('═══════════════════════════════════════════════════════════');
      }

      if (!mounted) return;
      setState(() {
        _isEnrolled = true;
        _isEnrolling = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully enrolled in the course',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Navigate to first lesson if available
      final firstLesson = _getFirstLesson();
      if (firstLesson != null && mounted) {
        _openLesson(firstLesson);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error enrolling in course: $e');
      }

      if (!mounted) return;
      setState(() => _isEnrolling = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              examFlowUserMessage(
                e,
                l10n: l10n,
                fallback: l10n.errorEnrolling,
              ),
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// Paid-course CTA: pick a payment method, then route to checkout or the
  /// off-site enrollment-request flow depending on the method.
  Future<void> _startPaidPurchase() async {
    final courseData = _courseData ?? widget.course;
    if (courseData == null) return;

    if (_libraryRequestStatus == 'pending' ||
        _libraryRequestStatus == 'approved') {
      return;
    }
    if (_libraryRequestStatus == 'rejected' &&
        _libraryRequestAdminNotes != null &&
        _libraryRequestAdminNotes!.trim().isNotEmpty &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _libraryRequestAdminNotes!,
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final selectedMethod = await _showPaymentMethodBottomSheet();
    if (!mounted || selectedMethod == null) return;

    if (selectedMethod == 'activation_code') {
      await _showActivationCodeSheet();
      return;
    }

    if (selectedMethod == 'library_cash') {
      final l10n = AppLocalizations.of(context)!;
      final msg = buildLibraryPaymentAdminMessage(
        l10n,
        course: courseData,
        mode: 'library',
      );
      await _submitLibraryEnrollmentRequest(
        message: msg,
        receiptImageUrl: null,
        paymentMethod: 'library',
      );
      return;
    }

    if (selectedMethod == 'whatsapp') {
      final payResult = await context.push<Map<String, dynamic>?>(
        RouteNames.libraryPaymentProcess,
        extra: {
          'course': courseData,
          'enrollment_payment_method': 'whatsapp',
        },
      );
      if (!mounted || payResult == null) return;
      final msg = payResult['message']?.toString();
      final receipt = payResult['receipt_image_url']?.toString();
      final returnedPm = payResult['payment_method']?.toString();
      if (msg == null || msg.isEmpty) return;
      final pmOut = (returnedPm != null && returnedPm.trim().isNotEmpty)
          ? returnedPm.trim().toLowerCase()
          : 'whatsapp';
      if (pmOut == 'whatsapp' && (receipt == null || receipt.trim().isEmpty)) {
        return;
      }
      await _submitLibraryEnrollmentRequest(
        message: msg,
        receiptImageUrl: (receipt != null && receipt.trim().isNotEmpty)
            ? receipt.trim()
            : null,
        paymentMethod: pmOut,
      );
      return;
    }

    context.push(
      RouteNames.checkout,
      extra: {
        'course': courseData,
        'paymentMethod': selectedMethod,
      },
    );
  }

  /// Confirmation sheet for buying a single locked live lesson — then the
  /// standard method picker → checkout (`item_type: lesson` + `lesson_id`).
  Future<void> _showLessonPurchaseSheet(Map<String, dynamic> lesson) async {
    final courseData = _courseData ?? widget.course;
    if (courseData == null) return;

    final price = LiveLessonUtils.price(lesson);
    final priceText = price == price.roundToDouble()
        ? price.toInt().toString()
        : price.toStringAsFixed(2);
    final lessonTitle = lesson['title']?.toString().trim();
    final scheduled = LiveLessonUtils.scheduledAt(lesson);
    final when = scheduled != null
        ? _formatLiveSessionWhen(context, scheduled.toIso8601String())
        : null;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            color: context.appTheme.sheetBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: context.appTheme.cardBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appTheme.progressTrack,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.liveLesson,
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.appTheme.cardTitle,
                          ),
                        ),
                        if (lessonTitle != null && lessonTitle.isNotEmpty)
                          Text(
                            lessonTitle,
                            style: GoogleFonts.readexPro(
                              fontSize: 13,
                              color: context.appTheme.cardMetaText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (when != null) ...[
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: context.appTheme.cardMetaText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        when,
                        style: GoogleFonts.readexPro(
                          fontSize: 13,
                          color: context.appTheme.cardMetaText,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Text(
                    l10n.egyptianPoundAmount(priceText),
                    style: GoogleFonts.readexPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appTheme.icon,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.completePurchase,
                    style: GoogleFonts.readexPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final selectedMethod = await _showPaymentMethodBottomSheet();
    if (!mounted || selectedMethod == null) return;

    if (selectedMethod == 'activation_code') {
      await _showActivationCodeSheet();
      return;
    }

    await context.push(
      RouteNames.checkout,
      extra: {
        'course': courseData,
        'lesson': lesson,
        'paymentMethod': selectedMethod,
      },
    );

    // Refresh so `is_purchased` / lock state comes back from the API.
    if (mounted) await _loadCourseDetails();
  }

  Future<void> _loadCourseExams() async {
    final course = _courseData ?? widget.course;
    if (course == null || course['id'] == null) return;

    final courseId = course['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    setState(() => _isLoadingExams = true);

    try {
      final exams = await ExamsService.instance.getCourseExams(courseId);

      // Print detailed response
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('📝 COURSE EXAMS RESPONSE (getCourseExams)');
        print('═══════════════════════════════════════════════════════════');
        print('Course ID: $courseId');
        print('Response Type: ${exams.runtimeType}');
        print('Total Exams: ${exams.length}');
        print('───────────────────────────────────────────────────────────');
        print('Full Response JSON:');
        try {
          const encoder = JsonEncoder.withIndent('  ');
          print(encoder.convert(exams));
        } catch (e) {
          print('Could not convert to JSON: $e');
          print('Raw Response: $exams');
        }
        print('───────────────────────────────────────────────────────────');
        print('Exams Summary:');
        for (int i = 0; i < exams.length; i++) {
          final exam = exams[i];
          print('  Exam ${i + 1}:');
          print('    - ID: ${exam['id']}');
          print('    - Title: ${exam['title']}');
          print('    - Type: ${exam['type']}');
          print('    - Questions Count: ${exam['questions_count']}');
          print('    - Can Start: ${exam['can_start']}');
        }
        print('═══════════════════════════════════════════════════════════');
      }

      if (!mounted) return;
      setState(() {
        _courseExams = exams;
        _isLoadingExams = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('❌ ERROR LOADING COURSE EXAMS');
        print('═══════════════════════════════════════════════════════════');
        print('Course ID: $courseId');
        print('Error: $e');
        print('Error Type: ${e.runtimeType}');
        print('═══════════════════════════════════════════════════════════');
      }
      if (!mounted) return;
      setState(() => _isLoadingExams = false);
    }
  }

  Future<void> _checkWishlistStatus() async {
    if (!mounted) return;
    final course = _courseData ?? widget.course;
    if (course == null || course['id'] == null) return;

    final courseId = course['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    try {
      final wishlist = await WishlistService.instance.getWishlist();

      // Print detailed response
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('❤️ WISHLIST RESPONSE (getWishlist)');
        print('═══════════════════════════════════════════════════════════');
        print('Course ID: $courseId');
        print('Response Type: ${wishlist.runtimeType}');
        print('Response Keys: ${wishlist.keys.toList()}');
        print('───────────────────────────────────────────────────────────');
        print('Full Response JSON:');
        try {
          const encoder = JsonEncoder.withIndent('  ');
          print(encoder.convert(wishlist));
        } catch (e) {
          print('Could not convert to JSON: $e');
          print('Raw Response: $wishlist');
        }
        print('───────────────────────────────────────────────────────────');
        print('Key Fields:');
        wishlist.forEach((key, value) {
          if (key == 'data' && value is List) {
            print('  - $key: List with ${value.length} items');
            for (int i = 0; i < value.length && i < 3; i++) {
              print('    Item $i: ${value[i]}');
            }
          } else {
            print('  - $key: $value (${value.runtimeType})');
          }
        });
        print('═══════════════════════════════════════════════════════════');
      }

      final items = wishlist['data'] as List?;

      if (items != null) {
        final isInWishlist = items.any((item) {
          if (item is! Map) return false;
          // New flat shape (docs/flutter-wishlist-endpoints-update.md):
          // { id, title, thumbnail, is_wishlisted, wishlist_id, ... }
          final flatId = item['id']?.toString();
          if (flatId != null && flatId.isNotEmpty) return flatId == courseId;
          // Old nested shape: { course: { id }, course_id }
          final itemCourse = item['course'] as Map<String, dynamic>?;
          final itemCourseId =
              itemCourse?['id']?.toString() ?? item['course_id']?.toString();
          return itemCourseId == courseId;
        });

        if (kDebugMode) {
          print('Is Course in Wishlist: $isInWishlist');
        }

        if (mounted) {
          setState(() {
            _isInWishlist = isInWishlist;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('❌ ERROR CHECKING WISHLIST STATUS');
        print('═══════════════════════════════════════════════════════════');
        print('Course ID: $courseId');
        print('Error: $e');
        print('Error Type: ${e.runtimeType}');
        print('═══════════════════════════════════════════════════════════');
      }
      // Don't update state on error, keep current state
    }
  }

  Future<void> _toggleWishlist() async {
    final course = _courseData ?? widget.course;
    if (course == null || course['id'] == null) return;

    final courseId = course['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    setState(() => _isTogglingWishlist = true);

    try {
      if (_isInWishlist) {
        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════════');
          print('🗑️ REMOVING FROM WISHLIST');
          print('═══════════════════════════════════════════════════════════');
          print('Course ID: $courseId');
          print('═══════════════════════════════════════════════════════════');
        }
        await WishlistService.instance.removeFromWishlist(courseId);
        if (kDebugMode) {
          print('✅ Successfully removed from wishlist');
        }
      } else {
        if (kDebugMode) {
          print('═══════════════════════════════════════════════════════════');
          print('➕ ADDING TO WISHLIST');
          print('═══════════════════════════════════════════════════════════');
          print('Course ID: $courseId');
          print('═══════════════════════════════════════════════════════════');
        }
        await WishlistService.instance.addToWishlist(courseId);
        if (kDebugMode) {
          print('✅ Successfully added to wishlist');
        }
      }

      if (!mounted) return;
      setState(() {
        _isInWishlist = !_isInWishlist;
        _courseData?['is_in_wishlist'] = _isInWishlist;
        _isTogglingWishlist = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isInWishlist ? l10n.addedToWishlist : l10n.removedFromWishlist,
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error toggling wishlist: $e');
      }

      if (!mounted) return;
      setState(() => _isTogglingWishlist = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              examFlowUserMessage(
                e,
                l10n: l10n,
                fallback: l10n.errorWishlist(
                  _isInWishlist ? l10n.removingFrom : l10n.addingTo,
                ),
              ),
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _startExam(String examId, Map<String, dynamic> examData) async {
    if (examId.isEmpty) return;

    final course = _courseData ?? widget.course;
    if (course == null || course['id'] == null) return;

    final courseId = course['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    try {
      // Start exam via API
      final examSession = await ExamsService.instance.startExam(examId);

      // Print detailed response
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('🚀 START EXAM RESPONSE (startExam)');
        print('═══════════════════════════════════════════════════════════');
        print('Exam ID: $examId');
        print('Response Type: ${examSession.runtimeType}');
        print('Response Keys: ${examSession.keys.toList()}');
        print('───────────────────────────────────────────────────────────');
        print('Full Response JSON:');
        try {
          const encoder = JsonEncoder.withIndent('  ');
          print(encoder.convert(examSession));
        } catch (e) {
          print('Could not convert to JSON: $e');
          print('Raw Response: $examSession');
        }
        print('───────────────────────────────────────────────────────────');
        print('Key Fields:');
        examSession.forEach((key, value) {
          if (key == 'questions' && value is List) {
            print('  - $key: List with ${value.length} questions');
            for (int i = 0; i < value.length && i < 2; i++) {
              print('    Question $i: ${value[i]}');
            }
          } else {
            print('  - $key: $value (${value.runtimeType})');
          }
        });
        print('═══════════════════════════════════════════════════════════');
      }

      final questions = examSession['questions'] as List?;
      final attemptId = examSession['attempt_id']?.toString();

      if (questions == null || questions.isEmpty) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.noQuestionsAvailable,
                style: GoogleFonts.readexPro(),
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrialExamScreen(
              examId: examId,
              attemptId: attemptId,
              courseName:
                  (_courseData ?? widget.course)?['title']?.toString() ??
                      'Course',
              examData: examData,
              examSession: examSession,
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting exam: $e');
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final msg = examFlowUserMessage(
          e,
          l10n: l10n,
          fallback: l10n.errorStartingExam,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg,
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: Scaffold(
        backgroundColor: context.appTheme.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Video skeleton
              Container(
                height: 220,
                color: Colors.black,
              ),
              // Content skeleton
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.appTheme.card,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header skeleton
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 80,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: context.appTheme.progressTrack,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              Container(
                                width: 60,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: context.appTheme.progressTrack,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 24,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: context.appTheme.progressTrack,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 24,
                            width: 150,
                            decoration: BoxDecoration(
                              color: context.appTheme.progressTrack,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: context.appTheme.progressTrack,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 60,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: context.appTheme.progressTrack,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 60,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: context.appTheme.progressTrack,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Tabs skeleton
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.appTheme.progressTrack,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Lessons skeleton
                          ...List.generate(5, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                height: 70,
                                decoration: BoxDecoration(
                                  color: context.appTheme.progressTrack,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trial Exam Screen
class TrialExamScreen extends StatefulWidget {
  final String examId;
  final String? attemptId;
  final String courseName;
  final Map<String, dynamic>? examData;
  final Map<String, dynamic>? examSession;
  final List<Map<String, dynamic>>? questions; // Fallback for static questions

  const TrialExamScreen({
    super.key,
    required this.examId,
    this.attemptId,
    required this.courseName,
    this.examData,
    this.examSession,
    this.questions,
  });

  @override
  State<TrialExamScreen> createState() => _TrialExamScreenState();
}

class _TrialExamScreenState extends State<TrialExamScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, List<String>> _selectedAnswers =
      {}; // For multiple choice questions
  final Map<int, String?> _singleAnswers = {}; // For single choice questions
  bool _showResult = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _examResult;
  List<Map<String, dynamic>> _questions = [];
  String? _attemptId;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    // Get questions from exam session or use fallback
    if (widget.examSession != null &&
        widget.examSession!['questions'] != null) {
      final questions = widget.examSession!['questions'] as List;
      _questions = questions.map((q) => q as Map<String, dynamic>).toList();
      _attemptId =
          widget.examSession!['attempt_id']?.toString() ?? widget.attemptId;
    } else if (widget.questions != null) {
      _questions = List<Map<String, dynamic>>.from(widget.questions!);
    }

    // Initialize answers
    for (int i = 0; i < _questions.length; i++) {
      _singleAnswers[i] = null;
      _selectedAnswers[i] = [];
    }
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      final question = _questions[_currentQuestionIndex];

      // Check if multiple choice
      final isMultiple = question['is_multiple'] == true ||
          question['type'] == 'multiple_choice';

      if (isMultiple) {
        final selected = _selectedAnswers[_currentQuestionIndex] ?? [];
        final optionId = question['options']?[optionIndex]?['id']?.toString() ??
            question['options']?[optionIndex]?['option_id']?.toString();

        if (selected.contains(optionId)) {
          selected.remove(optionId);
        } else {
          selected.add(optionId ?? optionIndex.toString());
        }
        _selectedAnswers[_currentQuestionIndex] = selected;
      } else {
        // Single choice
        final optionId = question['options']?[optionIndex]?['id']?.toString() ??
            question['options']?[optionIndex]?['option_id']?.toString();
        _singleAnswers[_currentQuestionIndex] =
            optionId ?? optionIndex.toString();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitExam();
    }
  }

  bool get _hasSelectedAnswer {
    final question = _questions[_currentQuestionIndex];
    final isMultiple = question['is_multiple'] == true ||
        question['type'] == 'multiple_choice';

    if (isMultiple) {
      final selected = _selectedAnswers[_currentQuestionIndex] ?? [];
      return selected.isNotEmpty;
    } else {
      return _singleAnswers[_currentQuestionIndex] != null;
    }
  }

  Future<void> _submitExam() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Prepare answers in API format
      final answers = <Map<String, dynamic>>[];

      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final questionId = question['id']?.toString() ??
            question['question_id']?.toString() ??
            'q_$i';

        final isMultiple = question['is_multiple'] == true ||
            question['type'] == 'multiple_choice';

        if (isMultiple) {
          final selected = _selectedAnswers[i] ?? [];
          answers.add({
            'question_id': questionId,
            'selected_options': selected,
          });
        } else {
          final selected = _singleAnswers[i];
          if (selected != null) {
            answers.add({
              'question_id': questionId,
              'selected_options': [selected],
            });
          }
        }
      }

      if (_attemptId == null || _attemptId!.isEmpty) {
        throw Exception('Attempt ID is missing');
      }

      // Print answers before submission
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('📤 SUBMITTING EXAM');
        print('═══════════════════════════════════════════════════════════');
        print('Exam ID: ${widget.examId}');
        print('Attempt ID: $_attemptId');
        print('Total Questions: ${_questions.length}');
        print('Answers to Submit:');
        try {
          const encoder = JsonEncoder.withIndent('  ');
          print(encoder.convert(answers));
        } catch (e) {
          print('Could not convert answers to JSON: $e');
          print('Raw Answers: $answers');
        }
        print('═══════════════════════════════════════════════════════════');
      }

      final result = await ExamsService.instance.submitExam(
        widget.examId,
        attemptId: _attemptId!,
        answers: answers,
      );

      // Print detailed response
      if (kDebugMode) {
        print('═══════════════════════════════════════════════════════════');
        print('✅ EXAM SUBMISSION RESPONSE (submitExam)');
        print('═══════════════════════════════════════════════════════════');
        print('Exam ID: ${widget.examId}');
        print('Attempt ID: $_attemptId');
        print('Response Type: ${result.runtimeType}');
        print('Response Keys: ${result.keys.toList()}');
        print('───────────────────────────────────────────────────────────');
        print('Full Response JSON:');
        try {
          const encoder = JsonEncoder.withIndent('  ');
          print(encoder.convert(result));
        } catch (e) {
          print('Could not convert to JSON: $e');
          print('Raw Response: $result');
        }
        print('───────────────────────────────────────────────────────────');
        print('Key Fields:');
        result.forEach((key, value) {
          print('  - $key: $value (${value.runtimeType})');
        });
        print('───────────────────────────────────────────────────────────');
        print('Summary:');
        final pct = result['percentage'];
        final scr = result['score'];
        print(
            '  - percentage (display): ${pct ?? '(none)'}  |  score (raw points): ${scr ?? '(none)'}');
        print('  - Is Passed: ${result['is_passed'] ?? result['isPassed']}');
        print(
            '  - Correct: ${result['correct_answers'] ?? result['correctAnswers']} / ${result['total_questions'] ?? result['totalQuestions']}');
        final t = result['time_taken_minutes'] ??
            result['timeTaken'] ??
            result['time_taken'];
        if (t != null) {
          print('  - Time Taken: $t');
        }
        print('═══════════════════════════════════════════════════════════');
      }

      setState(() {
        _examResult = result;
        _showResult = true;
        _isSubmitting = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting exam: $e');
      }

      setState(() => _isSubmitting = false);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final errorMessage = examFlowUserMessage(
        e,
        l10n: l10n,
        fallback: l10n.errorSubmittingExam,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.readexPro()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: context.appTheme.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: context.appTheme.icon,
          title: Text(
            l10n.trialExam,
            style: GoogleFonts.readexPro(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: context.appTheme.icon,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.loadingQuestions,
                style: GoogleFonts.readexPro(
                  fontSize: 16,
                  color: context.cardMetaText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_showResult) {
      return _buildResultScreen();
    }

    final question = _questions[_currentQuestionIndex];
    final options = question['options'] as List? ?? [];
    final isMultiple = question['is_multiple'] == true ||
        question['type'] == 'multiple_choice';

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.appTheme.icon,
        title: Text(
          l10n.trialExam,
          style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Center(
              child: Text(
                '${_currentQuestionIndex + 1}/${_questions.length}',
                style: GoogleFonts.readexPro(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.appTheme.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.question} ${_currentQuestionIndex + 1}',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.appTheme.icon,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question['question']?.toString() ??
                        question['text']?.toString() ??
                        l10n.question,
                    style: GoogleFonts.readexPro(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.cardTitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Options
            ...List.generate(options.length, (index) {
              final option = options[index];
              final optionId = option['id']?.toString() ??
                  option['option_id']?.toString() ??
                  index.toString();

              bool isSelected = false;
              if (isMultiple) {
                final selected = _selectedAnswers[_currentQuestionIndex] ?? [];
                isSelected = selected.contains(optionId);
              } else {
                isSelected = _singleAnswers[_currentQuestionIndex] == optionId;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _selectAnswer(index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.appTheme.progressTrack
                          : context.appTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? context.appTheme.icon
                            : context.appTheme.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.appTheme.icon
                                : context.appTheme.cardMuted,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isSelected && isMultiple
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.navyDeep,
                                    size: 20,
                                  )
                                : Text(
                                    String.fromCharCode(1571 + index),
                                    style: GoogleFonts.readexPro(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.navyDeep
                                          : context.appTheme.cardMetaText,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option['text']?.toString() ??
                                option['option']?.toString() ??
                                option.toString(),
                            style: GoogleFonts.readexPro(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? context.appTheme.cardAccentText
                                  : context.appTheme.cardTitle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Next Button
            GestureDetector(
              onTap:
                  (_hasSelectedAnswer && !_isSubmitting) ? _nextQuestion : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: (_hasSelectedAnswer && !_isSubmitting)
                      ? const LinearGradient(colors: AppColors.headerGradient2)
                      : null,
                  color: (!_hasSelectedAnswer || _isSubmitting)
                      ? context.appTheme.progressTrack
                      : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        )
                      : Text(
                          _currentQuestionIndex == _questions.length - 1
                              ? l10n.finishExamButton
                              : l10n.next,
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _hasSelectedAnswer
                                ? Colors.white
                                : Colors.grey[500],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Parses ints from JSON (handles [String], [double], [int]).
  int? _readSubmitInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  Widget _buildResultScreen() {
    final l10n = AppLocalizations.of(context)!;
    // Prefer `percentage` for the 0–100 result; `score` is often raw points.
    int displayPercent = 0;
    bool passed = false;
    int correctAnswers = 0;
    int totalQuestions = _questions.length;
    String? message;
    int? timeTakenForUi;

    if (_examResult != null) {
      final r = _examResult!;
      final pctField = r['percentage'] ??
          r['percent'] ??
          r['score_percent'] ??
          r['scorePercentage'];
      final parsedPct = _readSubmitInt(pctField);
      if (parsedPct != null) {
        displayPercent = parsedPct.clamp(0, 100);
      } else {
        final s = r['score'];
        if (s is num) {
          displayPercent = s.round().clamp(0, 100);
        } else {
          final si = _readSubmitInt(s);
          if (si != null) {
            displayPercent = si.clamp(0, 100);
          }
        }
      }
      passed = r['is_passed'] == true || r['isPassed'] == true;
      final ca = r['correct_answers'] ??
          r['correctAnswers'] ??
          r['correct'] ??
          r['correct_count'];
      final tq = r['total_questions'] ??
          r['totalQuestions'] ??
          r['total'] ??
          r['questionCount'];
      correctAnswers = _readSubmitInt(ca) ?? 0;
      final totalParsed = _readSubmitInt(tq);
      totalQuestions = (totalParsed != null && totalParsed > 0)
          ? totalParsed
          : _questions.length;
      message = r['message']?.toString();
      final timeRaw = r['time_taken_minutes'] ??
          r['timeTaken'] ??
          r['time_taken'] ??
          r['duration_minutes'];
      final timeParsed = _readSubmitInt(timeRaw);
      if (timeParsed != null && timeParsed > 0) {
        timeTakenForUi = timeParsed;
      }
    }

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color:
                        passed ? const Color(0xFF10B981) : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message ??
                      (passed
                          ? l10n.examResultGreatJobTitle
                          : l10n.examResultTryAgainTitle),
                  style: GoogleFonts.readexPro(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: context.cardTitle,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.examResultPercentageLabel(displayPercent),
                  style: GoogleFonts.readexPro(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        passed ? const Color(0xFF10B981) : AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.examResultCorrectSummary(
                    correctAnswers,
                    totalQuestions,
                  ),
                  style: GoogleFonts.readexPro(
                    fontSize: 16,
                    color: context.cardMetaText,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (timeTakenForUi != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.timeTaken(timeTakenForUi),
                    style: GoogleFonts.readexPro(
                      fontSize: 14,
                      color: context.cardMetaText,
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.headerGradient2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        l10n.finish,
                        style: GoogleFonts.readexPro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
}
