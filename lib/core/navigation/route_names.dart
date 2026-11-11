/// Route names for navigation
class RouteNames {
  RouteNames._();

  // Startup flow
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Student flow (main app with bottom nav)
  static const String home = '/home';
  static const String courses = '/courses';
  static const String progress = '/progress';
  static const String dashboard = '/dashboard';

  // Instructor flow
  static const String instructorHome = '/instructor';
  static const String instructorCourses = '/instructor/courses';
  static const String instructorCreateCourse = '/instructor/create-course';
  static const String instructorEarnings = '/instructor/earnings';
  static const String instructorProfile = '/instructor/profile';
  static const String instructorCourseDetails = '/instructor/course-details';
  static const String instructorSessionDetails = '/instructor/session-details';
  static const String instructorScanQr = '/instructor/scan-qr';

  // Secondary screens
  static const String categories = '/categories';
  static const String courseDetails = '/course-details';
  static const String lessonViewer = '/lesson-viewer';

  /// Live lesson/session screen — in-app WebView + countdown + reminders.
  static const String liveLesson = '/live-lesson';
  static const String exams = '/exams';
  static const String myExams = '/my-exams';
  static const String notifications = '/notifications';
  static const String checkout = '/checkout';

  /// Library cash payment: steps + receipt before enrollment request
  static const String libraryPaymentProcess = '/library-payment';

  /// Student's enrollment requests (pending/approved/rejected + admin notes)
  static const String myEnrollmentRequests = '/my-enrollment-requests';
  static const String liveCourses = '/live-courses';
  static const String downloads = '/downloads';
  static const String certificates = '/certificates';
  static const String enrolled = '/enrolled';
  static const String settings = '/settings';
  static const String helpSupport = '/help-support';
  static const String allCourses = '/all-courses';
  static const String bookmarkCourses = '/bookmark-courses';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String pdfViewer = '/pdf-viewer';
  static const String centerAttendance = '/center-attendance';
  static const String teachers = '/teachers';
  static const String discover = '/discover';
  static const String teacherDetails = '/teacher-details';
  static const String trainerAvailability = '/trainer-availability';
  static const String instructorCalendar = '/instructor-calendar';
  static const String instructorMessages = '/instructor/messages';
  static const String trainerMatch = '/trainer-match';
  static const String bookingCheckout = '/booking-checkout';
  static const String myBookings = '/my-bookings';
  static const String bookingDetails = '/booking-details';
  static const String bookingReview = '/booking-review';
  static const String instructorRequests = '/instructor/requests';
  static const String instructorMarketplace = '/instructor/marketplace';
  static const String instructorBookings = '/instructor/bookings';
  static const String chatConversations = '/chat';
  static const String screensPreview = '/screens-preview';
  static const String chatMessages = '/chat/:conversationId';
}
