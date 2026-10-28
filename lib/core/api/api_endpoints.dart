/// API Endpoints Configuration
class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'https://bouslty.anmka.com/api';

  /// Base URL for images and media files
  static const String imageBaseUrl = 'https://bouslty.anmka.com';

  /// Helper method to convert relative image path to full URL
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Handle both /uploads/ and /api/uploads/ paths
    String cleanPath = imagePath;

    // If path starts with /uploads/ (old format), convert to /api/uploads/
    if (cleanPath.startsWith('/uploads/')) {
      cleanPath = '/api${cleanPath}';
    }
    // If path already starts with /api/uploads/, keep it as is
    else if (!cleanPath.startsWith('/api/')) {
      // If path doesn't start with /, add it
      if (!cleanPath.startsWith('/')) {
        cleanPath = '/$cleanPath';
      }
      // If path doesn't start with /api/, add it
      if (!cleanPath.startsWith('/api/')) {
        cleanPath = '/api$cleanPath';
      }
    }

    // Remove leading slash to avoid double slashes when combining with baseUrl
    final finalPath =
        cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath;
    return '$imageBaseUrl/$finalPath';
  }

  /// Same file may be reachable at `/uploads/...` (static) or `/api/uploads/...` (proxied).
  /// Use when downloads return 404 — try alternates in order.
  static List<String> mediaDownloadUrlCandidates(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return const [];
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return [trimmed];

    final ordered = <String>[];
    void add(String s) {
      if (s.isNotEmpty && !ordered.contains(s)) ordered.add(s);
    }

    add(trimmed);
    final path = uri.path;
    if (path.contains('/api/uploads/')) {
      final altPath = path.replaceFirst('/api', '');
      add(uri.replace(path: altPath).toString());
    } else if (path.startsWith('/uploads/') && !path.startsWith('/api/')) {
      add(uri.replace(path: '/api$path').toString());
    }
    return ordered;
  }

  // App Configuration
  static String get appConfig => '$baseUrl/config/app';

  // Authentication
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get logout => '$baseUrl/auth/logout';

  /// Permanently delete the authenticated user's account — `docs/FLUTTER_DELETE_ACCOUNT.md`.
  static String get deleteAccount => '$baseUrl/auth/account';
  static String get forgotPassword => '$baseUrl/auth/forgot-password';
  static String get refreshToken => '$baseUrl/auth/refresh';
  static String get me => '$baseUrl/auth/me';
  static String get profile => '$baseUrl/auth/profile';
  static String get changePassword => '$baseUrl/auth/change-password';
  static String get socialLogin => '$baseUrl/auth/social-login';

  /// Register device FCM token (authenticated). See docs/FLUTTER_FCM.md.
  static String get deviceFcmToken => '$baseUrl/device/fcm-token';

  // Home Page
  static String get home => '$baseUrl/home';

  /// Public sliders (active only). No auth.
  static String get sliders => '$baseUrl/sliders';

  // Categories
  static String get categories => '$baseUrl/categories';
  static String get adminCategories => '$baseUrl/admin/categories';
  static String categoryCourses(String id) => '$baseUrl/categories/$id/courses';

  /// Skill-track ladder (tiers, bundle_includes). See docs/SKILL_TRACK_BACKEND.md.
  static String get skillTrack => '$baseUrl/skill-track';

  // Courses — lesson tree is embedded in GET [course] as `curriculum` (sections with nested `lessons`).
  // Per-lesson APIs: [courseLesson], [courseLessonContent], [courseLessonProgress].
  static String get courses => '$baseUrl/courses';
  static String course(String id) => '$baseUrl/courses/$id';
  static String courseReviews(String id) => '$baseUrl/courses/$id/reviews';
  static String courseLesson(String courseId, String lessonId) =>
      '$baseUrl/courses/$courseId/lessons/$lessonId';
  static String courseLessonContent(String courseId, String lessonId) =>
      '$baseUrl/courses/$courseId/lessons/$lessonId/content';
  static String courseLessonProgress(String courseId, String lessonId) =>
      '$baseUrl/courses/$courseId/lessons/$lessonId/progress';

  // Enrollment
  static String enrollCourse(String id) => '$baseUrl/courses/$id/enroll';

  /// WhatsApp payment proof — `docs/flutter-whatsapp-payment-proof.md`
  static String courseWhatsappPaymentProof(String courseId) =>
      '$baseUrl/courses/$courseId/whatsapp-payment-proof';
  static String get enrollments => '$baseUrl/enrollments';
  static String get enrollmentRequests => '$baseUrl/enrollment-requests';

  /// Activation codes — `POST /api/activation-codes/redeem`
  /// (`docs/FLUTTER_ENROLLMENT_REQUESTS_AND_ACTIVATION_CODES.md` §2).
  static String get activationCodesRedeem => '$baseUrl/activation-codes/redeem';

  // Payments & Checkout
  static String get payments => '$baseUrl/admin/payments';
  static String confirmPayment(String id) =>
      '$baseUrl/admin/payments/$id/confirm';
  static String get validateCoupon =>
      '$baseUrl/admin/payments/coupons/validate';

  // Exams (admin)
  static String get exams => '$baseUrl/admin/exams';
  static String exam(String id) => '$baseUrl/admin/exams/$id';
  static String startExam(String id) => '$baseUrl/admin/exams/$id/start';
  static String submitExam(String id) => '$baseUrl/admin/exams/$id/submit';

  /// Student: all exams across enrolled courses — `GET /api/my-exams` (see docs/FLUTTER_MY_EXAMS.md).
  static String get myExams => '$baseUrl/my-exams';

  /// Student: completed attempts history — `GET /api/my-exam-results`.
  static String get myExamResults => '$baseUrl/my-exam-results';

  // Course Exams
  static String courseExams(String courseId) =>
      '$baseUrl/courses/$courseId/exams';
  static String courseExamDetails(String courseId, String examId) =>
      '$baseUrl/courses/$courseId/exams/$examId';
  static String courseExamStart(String courseId, String examId) =>
      '$baseUrl/courses/$courseId/exams/$examId/start';
  static String courseExamSubmit(String courseId, String examId) =>
      '$baseUrl/courses/$courseId/exams/$examId/submit';

  // Certificates
  static String get certificates => '$baseUrl/certificates';
  static String certificate(String id) => '$baseUrl/admin/certificates/$id';

  // Live Courses
  static String get liveCourses => '$baseUrl/live-courses';
  static String liveSession(String id) => '$baseUrl/admin/live-sessions/$id';

  // Notifications
  static String get notifications => '$baseUrl/notifications';
  static String markNotificationRead(String id) =>
      '$baseUrl/notifications/$id/read';
  static String get markAllNotificationsRead =>
      '$baseUrl/notifications/read-all';

  // Downloads
  static String get curriculum => '$baseUrl/admin/curriculum';
  static String curriculumItem(String id) => '$baseUrl/admin/curriculum/$id';

  // Search
  static String get search => '$baseUrl/search';

  // Upload (API_DOCUMENTATION - POST multipart, returns url)
  static String get upload => '$baseUrl/upload';

  // Wishlist
  static String get wishlist => '$baseUrl/wishlist';
  static String wishlistItem(String courseId) => '$baseUrl/wishlist/$courseId';

  // QR Code (student/teacher - TEACHER_DASHBOARD_API uses attendance path)
  static String get myQrCode => '$baseUrl/my-qr-code';
  static String get attendanceMyQrCode => '$baseUrl/attendance/my-qr-code';

  // Progress
  static String progress(String period) => '$baseUrl/progress?period=$period';

  // Teachers (public)
  static String get teachers => '$baseUrl/teachers';
  static String teacher(String id) => '$baseUrl/teachers/$id';
  static String teacherCourses(String id) => '$baseUrl/teachers/$id/courses';

  // Teacher dashboard (admin/instructor APIs - TEACHER_DASHBOARD_API.md)
  static String get adminDashboardOverview =>
      '$baseUrl/admin/dashboard/overview';
  static String get adminDashboardCharts => '$baseUrl/admin/dashboard/charts';
  static String get adminDashboardActivity =>
      '$baseUrl/admin/dashboard/activity';
  static String get adminCourses => '$baseUrl/admin/courses';
  static String adminCourse(String id) => '$baseUrl/admin/courses/$id';

  /// Curriculum per teacher reference: GET/PUT /api/admin/curriculum/:courseId
  static String adminCurriculum(String courseId) =>
      '$baseUrl/admin/curriculum/$courseId';
  static String adminCurriculumSections(String courseId) =>
      '$baseUrl/admin/curriculum/$courseId/sections';
  static String adminCurriculumSection(String courseId, String sectionId) =>
      '$baseUrl/admin/curriculum/$courseId/sections/$sectionId';
  static String adminCurriculumLessons(String courseId, String sectionId) =>
      '$baseUrl/admin/curriculum/$courseId/sections/$sectionId/lessons';
  static String adminCurriculumLesson(
          String courseId, String sectionId, String lessonId) =>
      '$baseUrl/admin/curriculum/$courseId/sections/$sectionId/lessons/$lessonId';
  static String adminCourseCurriculum(String courseId) =>
      '$baseUrl/admin/courses/$courseId/curriculum';
  static String adminCourseLectures(String courseId) =>
      '$baseUrl/admin/courses/$courseId/lectures';
  static String adminCourseLecture(String courseId, String lectureId) =>
      '$baseUrl/admin/courses/$courseId/lectures/$lectureId';
  static String get adminPayments => '$baseUrl/admin/payments';
  static String get adminUsersMeEarnings => '$baseUrl/admin/users/me/earnings';
  static String adminUsersEarnings(String userId) =>
      '$baseUrl/admin/users/$userId/earnings';
  static String get adminTeachersMeSalarySettings =>
      '$baseUrl/admin/teachers/me/salary-settings';
  static String get adminTeachersMeCalculateSalary =>
      '$baseUrl/admin/teachers/me/calculate-salary';
  static String get adminTeachersReports => '$baseUrl/admin/teachers/reports';

  // Attendance (teacher/instructor)
  static String get adminAttendance => '$baseUrl/admin/attendance';
  static String get attendanceMyAttendance =>
      '$baseUrl/attendance/my-attendance';
  static String get attendanceScan => '$baseUrl/attendance/scan';
  static String get attendanceSession => '$baseUrl/attendance/session';

  // Update student parent phone (teacher only - students in their courses)
  static String adminStudentParentPhone(String studentId) =>
      '$baseUrl/admin/students/$studentId/parent-phone';

  // Chat (teacher-student)
  static String get chatConversations => '$baseUrl/chat/conversations';

  /// Socket.IO base URL – https://stp.anmka.com, no port (default 443).
  /// Use with socket_io_client at path /api/socket.io.
  static String get chatSocketBaseUrl {
    final url =
        baseUrl.replaceFirst('https://', '').replaceFirst('http://', '');
    final host = url.split('/').first;
    // Strip port if present; never add :0 or empty port
    final cleanHost = host.contains(':') ? host.split(':').first : host;
    return 'https://$cleanHost';
  }

  static String chatConversation(String id) =>
      '$baseUrl/chat/conversations/$id';
  static String chatMessages(String conversationId) =>
      '$baseUrl/chat/conversations/$conversationId/messages';
  static String chatMessageRead(String messageId) =>
      '$baseUrl/chat/messages/$messageId/read';
}
