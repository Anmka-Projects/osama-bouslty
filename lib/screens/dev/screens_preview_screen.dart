import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/forgot_password_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../instructor/instructor_course_details_screen.dart';
import '../instructor/instructor_courses_screen.dart';
import '../instructor/instructor_create_course_screen.dart';
import '../instructor/instructor_earnings_screen.dart';
import '../instructor/instructor_home_screen.dart';
import '../instructor/instructor_marketplace_screen.dart';
import '../instructor/instructor_profile_screen.dart';
import '../instructor/instructor_scan_qr_screen.dart';
import '../instructor/instructor_session_details_screen.dart';
import '../roles/instructor_requests_screen.dart';
import '../roles/instructor_role_home.dart';
import '../roles/student_discover_screen.dart';
import '../secondary/all_courses_screen.dart';
import '../secondary/booking_details_screen.dart';
import '../secondary/bookmark_courses_screen.dart';
import '../secondary/categories_screen.dart';
import '../secondary/center_attendance_screen.dart';
import '../secondary/certificates_screen.dart';
import '../secondary/change_password_screen.dart';
import '../secondary/chat_conversations_screen.dart';
import '../secondary/chat_messages_screen.dart';
import '../secondary/checkout_screen.dart';
import '../secondary/course_details_screen.dart';
import '../secondary/downloaded_video_player.dart';
import '../secondary/downloads_screen.dart';
import '../secondary/edit_profile_screen.dart';
import '../secondary/enrolled_screen.dart';
import '../secondary/enrollment_requests_screen.dart';
import '../secondary/exams_screen.dart';
import '../secondary/help_support_screen.dart';
import '../secondary/lesson_viewer_screen.dart';
import '../secondary/library_payment_process_screen.dart';
import '../secondary/live_courses_screen.dart';
import '../secondary/live_lesson_screen.dart';
import '../secondary/live_session_webview_screen.dart';
import '../secondary/my_exams_screen.dart';
import '../secondary/notifications_screen.dart';
import '../secondary/pdf_viewer_screen.dart';
import '../secondary/settings_screen.dart';
import '../secondary/teacher_details_screen.dart';
import '../secondary/teachers_screen.dart';
import '../secondary/trainer_availability_screen.dart';
import '../startup/splash_screen.dart';
import '../student/courses_screen.dart';
import '../student/home_screen.dart';
import '../student/progress_screen.dart';
import '../student/student_dashboard_screen.dart';

/// Dev-only catalog: opens every screen directly with mock data.
class ScreensPreviewScreen extends StatelessWidget {
  const ScreensPreviewScreen({super.key});

  static Map<String, dynamic> get _mockCourse => {
        'id': 'preview-course',
        'title': 'Preview Course',
        'titleAr': 'كورس تجريبي',
        'description': 'A preview description for this course.',
        'descriptionAr': 'وصف تجريبي للكورس.',
        'price': 450,
        'is_free': false,
        'thumbnail': '',
        'instructor': {'name': 'Preview Teacher'},
        'category': {'name': 'Category'},
        'rating': 4.7,
        'students_count': 120,
        'duration_hours': 12.5,
      };

  static Map<String, dynamic> get _mockLesson => {
        'id': 'preview-lesson',
        'title': 'Preview Lesson',
        'titleAr': 'درس تجريبي',
        'type': 'VIDEO',
        'duration_minutes': 15,
        'is_free': true,
        'video_url': '',
      };

  static void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final items = <_PreviewItem>[
      _PreviewItem.section('Student'),
      _PreviewItem('Home', (c) => const HomeScreen()),
      _PreviewItem('Courses (tab)', (c) => const CoursesScreen()),
      _PreviewItem('Progress', (c) => const ProgressScreen()),
      _PreviewItem('Dashboard / Profile', (c) => const StudentDashboardScreen()),
      _PreviewItem('Discover (roles)', (c) => const StudentDiscoverScreen()),
      _PreviewItem.section('Tutor / Instructor'),
      _PreviewItem('Instructor Home', (c) => const InstructorRoleHome()),
      _PreviewItem('Instructor Dashboard', (c) => const InstructorHomeScreen()),
      _PreviewItem('Instructor Courses', (c) => const InstructorCoursesScreen()),
      _PreviewItem('Create Course', (c) => const InstructorCreateCourseScreen()),
      _PreviewItem('Course Details (inst.)',
          (c) => InstructorCourseDetailsScreen(course: _mockCourse)),
      _PreviewItem('Session Details (inst.)', (c) =>
          InstructorSessionDetailsScreen(
              courseId: 'preview-course',
              course: _mockCourse,
              section: const {'title': 'Section 1', 'titleAr': 'القسم ١'})),
      _PreviewItem('Earnings', (c) => const InstructorEarningsScreen()),
      _PreviewItem('Marketplace', (c) => const InstructorMarketplaceScreen()),
      _PreviewItem('Instructor Profile', (c) => const InstructorProfileScreen()),
      _PreviewItem('Scan QR', (c) => const InstructorScanQrScreen()),
      _PreviewItem('Instructor Requests', (c) => const InstructorRequestsScreen()),
      _PreviewItem.section('Secondary'),
      _PreviewItem('All Courses', (c) => const AllCoursesScreen()),
      _PreviewItem('Course Details',
          (c) => CourseDetailsScreen(course: _mockCourse)),
      _PreviewItem('Lesson Viewer', (c) => LessonViewerScreen(
          lesson: _mockLesson, courseId: 'preview-course', lessons: [_mockLesson])),
      _PreviewItem('PDF Viewer',
          (c) => const PdfViewerScreen(pdfUrl: 'https://example.com/test.pdf', title: 'Preview PDF')),
      _PreviewItem('Teachers', (c) => const TeachersScreen()),
      _PreviewItem('Teacher Details', (c) => const TeacherDetailsScreen()),
      _PreviewItem('Categories', (c) => const CategoriesScreen()),
      _PreviewItem('Enrolled', (c) => const EnrolledScreen()),
      _PreviewItem('Bookmarks', (c) => const BookmarkCoursesScreen()),
      _PreviewItem('Checkout', (c) => const CheckoutScreen()),
      _PreviewItem('Library Payment', (c) => const LibraryPaymentProcessScreen()),
      _PreviewItem('Enrollment Requests', (c) => const EnrollmentRequestsScreen()),
      _PreviewItem('My Exams', (c) => const MyExamsScreen()),
      _PreviewItem('Exams', (c) => const ExamsScreen()),
      _PreviewItem('Live Courses', (c) => const LiveCoursesScreen()),
      _PreviewItem('Live Lesson', (c) => const LiveLessonScreen()),
      _PreviewItem('Live WebView', (c) => const LiveSessionWebViewScreen(
          url: 'https://example.com', title: 'Preview Session')),
      _PreviewItem('Downloads', (c) => const DownloadsScreen()),
      _PreviewItem('Video Player', (c) => const DownloadedVideoPlayer(
          videoPath: '', videoTitle: 'Preview Video')),
      _PreviewItem('Certificates', (c) => const CertificatesScreen()),
      _PreviewItem('Center Attendance', (c) => const CenterAttendanceScreen()),
      _PreviewItem('Trainer Match', (c) => const TrainerMatchScreen()),
      _PreviewItem('My Bookings', (c) => const MyBookingsScreen()),
      _PreviewItem('Booking Details', (c) => const BookingDetailsScreen(bookingId: 'preview')),
      _PreviewItem('Chat List', (c) => const ChatConversationsScreen()),
      _PreviewItem('Chat Messages',
          (c) => const ChatMessagesScreen(conversationId: 'preview')),
      _PreviewItem('Notifications', (c) => const NotificationsScreen()),
      _PreviewItem('Settings', (c) => const SettingsScreen()),
      _PreviewItem('Edit Profile', (c) => const EditProfileScreen()),
      _PreviewItem('Change Password', (c) => const ChangePasswordScreen()),
      _PreviewItem('Help & Support', (c) => const HelpSupportScreen()),
      _PreviewItem.section('Auth / Startup'),
      _PreviewItem('Splash', (c) => const SplashScreen()),
      _PreviewItem('Login', (c) => const LoginScreen()),
      _PreviewItem('Register', (c) => const RegisterScreen()),
      _PreviewItem('Forgot Password', (c) => const ForgotPasswordScreen()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Screens Preview')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          if (item.isSection) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              color: Colors.grey.shade100,
              child: Text(
                item.title,
                style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            );
          }
          return ListTile(
            dense: true,
            title: Text(item.title, style: GoogleFonts.cairo(fontSize: 14)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => _open(context, item.builder!(context)),
          );
        },
      ),
    );
  }
}

class _PreviewItem {
  _PreviewItem(this.title, this.builder) : isSection = false;
  _PreviewItem.section(this.title)
      : builder = null,
        isSection = true;

  final String title;
  final bool isSection;
  final Widget Function(BuildContext)? builder;
}
