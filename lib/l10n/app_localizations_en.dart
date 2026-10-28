// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Bouslty';

  @override
  String get settings => 'Settings';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get privacyAndSecurity => 'Privacy & Security';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get changePassword => 'Change Password';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String languageChanged(String name) {
    return 'Language changed to $name';
  }

  @override
  String get preferencesUpdated => 'Preferences updated successfully';

  @override
  String get errorUpdatingPreferences => 'Error updating preferences';

  @override
  String get user => 'User';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get emailOptional => 'Email (Optional)';

  @override
  String get emailOrPhone => 'Email or Phone Number';

  @override
  String get enterEmailOrPhone => 'Enter your email or phone number';

  @override
  String get invalidEmailOrPhone => 'Invalid email or phone number';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Register Now';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get welcomeBack => 'Welcome back! 👋';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get or => 'OR';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get register => 'Create New Account';

  @override
  String get joinUsMessage => 'Join us and start your learning journey 🎓';

  @override
  String get fullName => 'Full Name';

  @override
  String get pleaseEnterName => 'Enter your full name';

  @override
  String get phone => 'Phone Number';

  @override
  String get phoneOptional => 'Phone Number (Optional)';

  @override
  String get phonePlaceholder => '01xxxxxxxxx';

  @override
  String get studentType => 'Student type';

  @override
  String get inPersonStudent => 'In-class student';

  @override
  String get onlineStudent => 'Online student';

  @override
  String get bothStudentTypes => 'Both';

  @override
  String get selectStudentType => 'Please choose your student type';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get enterPasswordAgain => 'Enter password again';

  @override
  String get iAgreeTo => 'I agree to';

  @override
  String get pleaseAcceptTerms => 'Please accept the terms and conditions';

  @override
  String get createAccount => 'Create Account';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get home => 'Home';

  @override
  String get courses => 'Courses';

  @override
  String get progress => 'Progress';

  @override
  String get profile => 'Profile';

  @override
  String get featuredCourses => 'Featured Courses';

  @override
  String get homePromoSliderEmpty => 'No banners at the moment';

  @override
  String get categories => 'Categories';

  @override
  String get subcategories => 'Subcategories';

  @override
  String get category => 'Category';

  @override
  String get educationalStage => 'Educational Stage';

  @override
  String get selectEducationalStage => 'Select your educational stage';

  @override
  String get grade => 'Grade';

  @override
  String get selectGrade => 'Select your grade';

  @override
  String get startLearningJourney =>
      'Start your learning journey and enroll in your first course';

  @override
  String get discount50 => '50% off on all courses';

  @override
  String get subscribeNow => 'Subscribe Now';

  @override
  String get all => 'All';

  @override
  String get newest => 'Newest';

  @override
  String get highestRated => 'Highest Rated';

  @override
  String get bestSelling => 'Best Selling';

  @override
  String get priceLowToHigh => 'Price: Low to High';

  @override
  String get priceHighToLow => 'Price: High to Low';

  @override
  String get errorLoadingCourses => 'Error loading courses';

  @override
  String get instructor => 'Instructor';

  @override
  String get lessons => 'Lessons';

  @override
  String get lesson => 'Lesson';

  @override
  String get course => 'Course';

  @override
  String get courseSuitable =>
      'This course is suitable for both beginners and professionals.';

  @override
  String get enrolledSuccessfully => 'Enrolled in course successfully';

  @override
  String get errorEnrolling => 'Error enrolling in course';

  @override
  String get addedToWishlist => 'Added to wishlist';

  @override
  String get removedFromWishlist => 'Removed from wishlist';

  @override
  String errorWishlist(String action) {
    return 'Error $action wishlist';
  }

  @override
  String get addingTo => 'adding to';

  @override
  String get removingFrom => 'removing from';

  @override
  String get wishlistTitle => 'Wishlist';

  @override
  String get wishlistMenuSubtitle => 'Saved courses — open to view or remove';

  @override
  String get wishlistEmptyTitle => 'No saved courses';

  @override
  String get wishlistEmptyDescription =>
      'Open any course and tap the bookmark to add it here.';

  @override
  String get startExam => 'Start Exam';

  @override
  String get errorStartingExam => 'Error starting exam';

  @override
  String get submitExam => 'Submit Exam';

  @override
  String get errorSubmittingExam => 'Error submitting exam';

  @override
  String get practiceExam => 'Practice Exam';

  @override
  String get question => 'Question';

  @override
  String questionNumber(int number) {
    return 'Question $number';
  }

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String timeTaken(int minutes) {
    return 'Time taken: $minutes minutes';
  }

  @override
  String get downloads => 'Downloads';

  @override
  String get downloadLinkReceived =>
      'Download link received. Download will start soon...';

  @override
  String errorDownloading(String error) {
    return 'Error downloading: $error';
  }

  @override
  String get fileDeleted => 'File deleted successfully';

  @override
  String errorDeleting(String error) {
    return 'Error deleting: $error';
  }

  @override
  String get certificates => 'Certificates';

  @override
  String downloadSuccessful(String path) {
    return 'Downloaded successfully: $path';
  }

  @override
  String errorDownloadingFile(String error) {
    return 'Error downloading file: $error';
  }

  @override
  String get errorSharing => 'Error sharing';

  @override
  String get student => 'Student';

  @override
  String get liveCourses => 'Live Courses';

  @override
  String get liveCoursesMenuSubtitle => 'Join live sessions & reminders';

  @override
  String get liveSessionsStatusScheduled => 'Scheduled';

  @override
  String get registeredSuccessfully => 'Registered for session successfully';

  @override
  String get errorRegistering => 'Error registering for session';

  @override
  String get sunday => 'Sunday';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get enrolledLessons => 'Enrolled Lessons';

  @override
  String get savedFiles => 'Saved Files';

  @override
  String get mainMenu => 'Main Menu';

  @override
  String get logout => 'Logout';

  @override
  String errorLoggingOut(String error) {
    return 'Error logging out: $error';
  }

  @override
  String get now => 'Now';

  @override
  String lessonNumber(int current, int total) {
    return 'Lesson $current of $total';
  }

  @override
  String get allLessonsCompleted => 'All lessons completed';

  @override
  String get previousLesson => 'Previous Lesson';

  @override
  String get nextLesson => 'Next Lesson';

  @override
  String duration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get notSpecified => 'Not specified';

  @override
  String get design => 'Design';

  @override
  String get programming => 'Programming';

  @override
  String get marketing => 'Marketing';

  @override
  String get data => 'Data';

  @override
  String get checkout => 'Checkout';

  @override
  String get discountApplied => 'Discount applied successfully';

  @override
  String get errorCheckingDiscount => 'Error checking discount code';

  @override
  String get purchaseSuccessful => 'Purchase completed successfully';

  @override
  String get errorCompletingPayment => 'Error completing payment';

  @override
  String get errorProcessingPayment => 'Error processing payment';

  @override
  String get discount20 => '20% discount applied';

  @override
  String get discount => 'Discount';

  @override
  String get total => 'Total';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String errorUpdatingProfile(String error) {
    return 'Error updating profile: $error';
  }

  @override
  String get country => 'Country (Optional)';

  @override
  String get timezone => 'Timezone (Optional)';

  @override
  String get name => 'Name';

  @override
  String get bio => 'About You';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get cameraPermissionDenied =>
      'Camera permission denied. Please allow camera access from settings';

  @override
  String get galleryPermissionDenied =>
      'Gallery permission denied. Please allow photo access from settings';

  @override
  String get errorPickingImage => 'Error picking image';

  @override
  String get avatarUploaded => 'Avatar uploaded successfully';

  @override
  String errorUploadingAvatar(String error) {
    return 'Error uploading avatar: $error';
  }

  @override
  String get passwordChanged => 'Password changed successfully';

  @override
  String errorChangingPassword(String error) {
    return 'Error changing password: $error';
  }

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get pleaseEnterCurrentPassword => 'Please enter current password';

  @override
  String get pleaseEnterNewPassword => 'Please enter new password';

  @override
  String get pleaseConfirmPassword => 'Please confirm password';

  @override
  String get forgotPasswordTitle => 'Forgot Password?';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get sentSuccessfully => 'Sent successfully!';

  @override
  String get resetPasswordSent =>
      'Password reset link has been sent to your email';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordDescription =>
      'Enter your email to send a reset link';

  @override
  String get sendResetLink => 'Send Link';

  @override
  String get sendToAnotherEmail => 'Send to another email';

  @override
  String get exams => 'Exam';

  @override
  String questionOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get finishExam => 'Finish Exam';

  @override
  String get finalResult => 'Final Result';

  @override
  String get correctAnswers => 'Correct Answers';

  @override
  String get wrongAnswers => 'Wrong Answers';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get science => 'Knowledge is the light that illuminates your path';

  @override
  String get success => 'Success starts with a step';

  @override
  String get nextStep => 'Next';

  @override
  String get startNow => 'Start Now';

  @override
  String get myCourses => 'My Courses';

  @override
  String get subjects => 'Subject';

  @override
  String lessonsCount(int count) {
    return '$count lessons';
  }

  @override
  String coursesCount(int count) {
    return '$count courses';
  }

  @override
  String get free => 'Free';

  @override
  String get paid => 'Paid';

  @override
  String get allCourses => 'All Courses';

  @override
  String coursesAvailable(int count) {
    return '$count courses available';
  }

  @override
  String get searchCourse => 'Search for a course...';

  @override
  String get noResults => 'No results';

  @override
  String get tryDifferentSearch =>
      'Try searching with different words or change filters';

  @override
  String egyptianPound(int amount) {
    return '$amount EGP';
  }

  @override
  String get noCourseData => 'No course data available';

  @override
  String get courseTitle => 'Course Title';

  @override
  String get trialExam => 'Trial Exam';

  @override
  String get noLessonsAvailable => 'No lessons available';

  @override
  String get certifiedCertificate => 'Certified certificate upon completion';

  @override
  String get loadingExam => 'Loading exam...';

  @override
  String get noTrialExamAvailable => 'No trial exam available';

  @override
  String get startExamButton => 'Start Exam';

  @override
  String get notAvailable => 'Not Available';

  @override
  String get enrolling => 'Enrolling...';

  @override
  String get startLearningNow => 'Start Learning Now';

  @override
  String get enrollFree => 'Enroll Free';

  @override
  String get enrollInCourse => 'Enroll in Course';

  @override
  String get loginRequired => 'Login required';

  @override
  String get noQuestionsAvailable => 'No questions available in exam';

  @override
  String get finishExamButton => 'Finish Exam';

  @override
  String get loadingQuestions => 'Loading questions...';

  @override
  String get finish => 'Finish';

  @override
  String examResultPercentageLabel(int percent) {
    return 'Percentage: $percent%';
  }

  @override
  String examResultCorrectSummary(int correct, int total) {
    return '$correct of $total correct answers';
  }

  @override
  String get examResultGreatJobTitle => 'Great job! 🎉';

  @override
  String get examResultTryAgainTitle => 'Try again';

  @override
  String get downloadLinkUnavailable => 'Download link unavailable';

  @override
  String get downloading => 'Downloading...';

  @override
  String get cannotAccessDownloads => 'Cannot access downloads folder';

  @override
  String certificateCompletion(String course) {
    return 'Certificate of Completion: $course';
  }

  @override
  String certificateNumber(String number) {
    return 'Certificate Number: $number';
  }

  @override
  String verificationLink(String url) {
    return 'Verification Link: $url';
  }

  @override
  String get download => 'Download';

  @override
  String get share => 'Share';

  @override
  String get noCertificatesYet => 'No certificates yet';

  @override
  String get completeCoursesForCertificates =>
      'Complete courses to get certified certificates';

  @override
  String get gettingDownloadLink => 'Getting download link...';

  @override
  String get deleteFile => 'Delete File';

  @override
  String get confirmDeleteFile => 'Are you sure you want to delete this file?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noDownloads => 'No downloads';

  @override
  String get willOpenOffline => 'Course will open in offline mode';

  @override
  String get noLiveSessions => 'No live sessions available';

  @override
  String get sessionsComingSoon => 'Upcoming sessions will be added soon';

  @override
  String get willOpenSessionLink => 'Session link will open';

  @override
  String get sessionLinkUnavailable => 'Session link unavailable';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get startsIn => 'Starts in';

  @override
  String get hour => 'hour';

  @override
  String get minute => 'minute';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get myExams => 'My Exams';

  @override
  String get viewAllExams => 'View all completed exams';

  @override
  String get exam => 'Exam';

  @override
  String get noCompletedExams => 'No completed exams';

  @override
  String get startCompletingExams =>
      'Start completing exams to see your results here';

  @override
  String get examListNotAttempted => 'Not taken';

  @override
  String get ago => 'A while ago';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String activeCourse(int count) {
    return '$count active courses';
  }

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmDeleteAccount =>
      'Are you sure you want to permanently delete your account? This cannot be undone. All your data, enrollments, and progress will be removed.';

  @override
  String get deleteAccountPasswordHint => 'Enter your password to confirm';

  @override
  String get deletingAccount => 'Deleting account...';

  @override
  String get accountDeletedSuccessfully => 'Your account has been deleted';

  @override
  String errorDeletingAccount(String error) {
    return 'Error deleting account: $error';
  }

  @override
  String get passwordRequiredToDelete =>
      'Password is required to delete your account';

  @override
  String get myAccount => 'My Account';

  @override
  String get customizeApp => 'Customize App';

  @override
  String get allSubjects => 'All Subjects';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get studentRating => 'Student Rating';

  @override
  String get top10Students => 'Top 10 Students';

  @override
  String get myExamsButton => 'My Exams';

  @override
  String get viewAllCompletedExams => 'View all completed exams';

  @override
  String welcome(String name) {
    return 'Welcome, $name 👋';
  }

  @override
  String get visitor => 'Visitor';

  @override
  String get excellentStudent => 'Excellent Student';

  @override
  String get specialOffer => 'Special Offer';

  @override
  String get subscribeNowButton => 'Subscribe Now';

  @override
  String get enrolledCourse => 'Enrolled Course';

  @override
  String get learningHours => 'Learning Hours';

  @override
  String get continueLearning => 'Continue Learning';

  @override
  String get recommendedCourses => 'Recommended Courses';

  @override
  String get viewMore => 'View More';

  @override
  String get searchPlaceholder =>
      'Search for a course, instructor, or topic...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get selectSubject => 'Select the subject you want to learn';

  @override
  String get noCategories => 'No categories';

  @override
  String get categoriesComingSoon => 'Categories will be added soon';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get passwordNeedsUppercase =>
      'Password must include an uppercase letter';

  @override
  String get passwordNeedsLowercase =>
      'Password must include a lowercase letter';

  @override
  String get passwordNeedsDigit => 'Password must include a number';

  @override
  String get passwordNeedsSpecial =>
      'Password must include a special character';

  @override
  String get passwordOnlyLettersAndDigits =>
      'Password may only contain letters and numbers';

  @override
  String get passwordNeedsLetter => 'Password must include a letter';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get invalidCouponCode => 'Invalid coupon code';

  @override
  String get completePurchase => 'Complete Purchase';

  @override
  String get enterCouponCode => 'Enter coupon code';

  @override
  String get apply => 'Apply';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get fawry => 'Fawry';

  @override
  String get payAtFawryBranch => 'Pay at any Fawry branch';

  @override
  String get eWallet => 'E-Wallet';

  @override
  String get walletDescription => 'Vodafone Cash - Etisalat Cash - Orange Cash';

  @override
  String get visaMastercard => 'Visa / Mastercard';

  @override
  String get creditDebitCard => 'Credit or Debit Card';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get coursePrice => 'Course Price';

  @override
  String egyptianPoundAmount(String amount) {
    return '$amount EGP';
  }

  @override
  String get confirmPayment => 'Confirm Payment';

  @override
  String get processing => 'Processing...';

  @override
  String get noCourse => 'No course';

  @override
  String get dateNotSpecified => 'Date not specified';

  @override
  String get certifiesThat => 'Certifies that';

  @override
  String get hasCompletedWithGrade => 'has completed this course with grade';

  @override
  String get excellent => 'Excellent';

  @override
  String get math => 'Mathematics';

  @override
  String get literature => 'Literature';

  @override
  String get biology => 'Biology';

  @override
  String get physics => 'Physics';

  @override
  String get chemistry => 'Chemistry';

  @override
  String get practicalEngineering => 'Practical Engineering';

  @override
  String get creativePlaneShapes => 'Creative Approaches to Plane Shapes';

  @override
  String get cellularBiologyDiscoveries => 'Discoveries in Cellular Biology';

  @override
  String get introduction => 'Introduction';

  @override
  String get whatIsDesign => 'What is Design?';

  @override
  String get howToCreateWireframe => 'How to Create Wireframe';

  @override
  String get yourFirstDesign => 'Your First Design';

  @override
  String progressPercent(int percent) {
    return 'Progress: $percent%';
  }

  @override
  String get helloJacob => 'Hello, Jacob 👋';

  @override
  String get startLearningJourneyMessage =>
      'Start your learning journey and enroll in your first course';

  @override
  String get learnEasily => 'Learn Easily';

  @override
  String get continuousProgress => 'Continuous Progress';

  @override
  String get discoverBestCourses =>
      'Discover the best educational courses with professional teachers from around the world';

  @override
  String get trackProgressAndGetCertificates =>
      'Track your progress and get certified certificates upon course completion';

  @override
  String get smartLearningPlatform => 'Smart Learning Platform';

  @override
  String get certifiedAndSecure => 'Certified and Secure Platform';

  @override
  String get everyDayNewOpportunity =>
      'Every day is a new opportunity to learn';

  @override
  String get version => 'v1.0.0';

  @override
  String enrolledCoursesCount(int count) {
    return '$count enrolled courses';
  }

  @override
  String get averageProgress => 'Average Progress';

  @override
  String get completed => 'Completed';

  @override
  String lessonFrom(int current, int total) {
    return 'Lesson $current of $total';
  }

  @override
  String get hourShort => 'h';

  @override
  String get minuteShort => 'm';

  @override
  String get secondShort => 's';

  @override
  String get timeAgo => 'A while ago';

  @override
  String get noEnrolledCourses => 'You haven\'t enrolled in any courses yet';

  @override
  String get exploreCourses => 'Explore Courses';

  @override
  String get noTitle => 'No Title';

  @override
  String get egyptianPoundShort => 'EGP';

  @override
  String errorLoadingNotifications(String error) {
    return 'Failed to load notifications: $error';
  }

  @override
  String errorUpdatingNotification(String error) {
    return 'Failed to update notification: $error';
  }

  @override
  String errorUpdatingNotifications(String error) {
    return 'Failed to update notifications: $error';
  }

  @override
  String get newNotifications => 'New Notifications';

  @override
  String newNotificationsCount(int count) {
    return '$count new notifications';
  }

  @override
  String get markAllAsRead => 'Mark All as Read';

  @override
  String get newSection => 'New';

  @override
  String get past => 'Past';

  @override
  String get noNotifications => 'No Notifications';

  @override
  String get newNotificationsWillAppear => 'New notifications will appear here';

  @override
  String get recently => 'Recently';

  @override
  String minutesAgoShort(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgoShort(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgoShort(int count) {
    return '$count days ago';
  }

  @override
  String get totalExams => 'Total Exams';

  @override
  String get passed => 'Passed';

  @override
  String get failed => 'Failed';

  @override
  String get undefinedDate => 'Undefined date';

  @override
  String get monthJanuary => 'January';

  @override
  String get monthFebruary => 'February';

  @override
  String get monthMarch => 'March';

  @override
  String get monthApril => 'April';

  @override
  String get monthMay => 'May';

  @override
  String get monthJune => 'June';

  @override
  String get monthJuly => 'July';

  @override
  String get monthAugust => 'August';

  @override
  String get monthSeptember => 'September';

  @override
  String get monthOctober => 'October';

  @override
  String get monthNovember => 'November';

  @override
  String get monthDecember => 'December';

  @override
  String downloadedFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'downloaded files',
      one: 'downloaded file',
    );
    return '$_temp0';
  }

  @override
  String get storage => 'Storage';

  @override
  String storageUsed(String used, String limit) {
    return '$used GB of $limit GB used';
  }

  @override
  String storageUsedMb(String used, String limit) {
    return '$used MB of $limit MB used';
  }

  @override
  String get file => 'File';

  @override
  String get undefinedSize => 'Undefined size';

  @override
  String get watchOffline => 'Watch Offline';

  @override
  String get fileIdNotAvailable => 'File ID not available';

  @override
  String get downloadLinkNotAvailable => 'Download link not available';

  @override
  String get downloadLinkObtained =>
      'Download link obtained. Download will start soon...';

  @override
  String get courseWillOpenOffline => 'Course will open in offline mode';

  @override
  String get courseIdNotAvailable => 'Course ID not available';

  @override
  String get downloadCoursesToWatchOffline =>
      'Download courses to watch offline';

  @override
  String liveSessionsCount(int count, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sessions',
      one: 'session',
    );
    return '$count $_temp0 $status';
  }

  @override
  String get live => 'live';

  @override
  String get upcoming => 'upcoming';

  @override
  String get liveSession => 'Live Session';

  @override
  String get liveNow => 'Live Now';

  @override
  String get remindMe => 'Remind Me';

  @override
  String get joinNow => 'Join Now';

  @override
  String get liveSessionButtonEnded => 'Session ended';

  @override
  String get liveSessionButtonUpcoming => 'Remind me';

  @override
  String get courseLiveSessionsTab => 'Live';

  @override
  String get liveSessionOpenLinkFailed => 'Could not open the session link';

  @override
  String get registeredForSession => 'Successfully registered for session';

  @override
  String get mustLoginFirst => 'Must login first';

  @override
  String get day => 'day';

  @override
  String get second => 'second';

  @override
  String get oneHour => '1 hour';

  @override
  String achievedCertificates(int count) {
    return '$count achieved certificates';
  }

  @override
  String get certificateOfCompletion => 'Certificate of Completion';

  @override
  String downloadFailed(int code) {
    return 'Download failed: $code';
  }

  @override
  String get certificateNumberLabel => 'Certificate Number';

  @override
  String get verificationLinkLabel => 'Verification Link';

  @override
  String get centerAttendance => 'Center Attendance';

  @override
  String get centerAttendanceDescription =>
      'Show this QR code at the center to mark your attendance';

  @override
  String get loadingQrCode => 'Loading QR code...';

  @override
  String get errorLoadingQrCode => 'Error loading QR code';

  @override
  String get scanQrCodeInstruction =>
      'Show this QR code to the center staff to mark your attendance';

  @override
  String get refreshQrCode => 'Refresh QR Code';

  @override
  String get retry => 'Retry';

  @override
  String get unknownError => 'Unknown error occurred';

  @override
  String get teachers => 'Teachers';

  @override
  String get allTeachers => 'All Teachers';

  @override
  String get teacherFallback => 'Teacher';

  @override
  String get teacherCoursesTitle => 'Courses offered';

  @override
  String studentsCount(int count) {
    return '$count students';
  }

  @override
  String get choosePaymentMethod => 'Payment method';

  @override
  String get bankTransferYourDetails => 'Your bank account';

  @override
  String get bankTransferHint =>
      'Enter the account you transfer from so we can verify your payment.';

  @override
  String get accountHolderName => 'Account holder name';

  @override
  String get bankAccountNumberLabel => 'Account / IBAN number';

  @override
  String get transferReferenceOptional => 'Transfer reference (optional)';

  @override
  String get bankDetailsRequired =>
      'Please enter account holder name and account number';

  @override
  String get checkoutPaymentBankTitle => 'Bank transfer';

  @override
  String get checkoutPaymentBankDescription =>
      'Transfer to the academy bank account. You will enter your account details on the next step to verify payment.';

  @override
  String get checkoutPaymentLibraryTitle => 'Purchase request';

  @override
  String get checkoutPaymentLibraryDescription =>
      'Send a purchase request to the administration; pay at the academy and get activated after approval.';

  @override
  String get checkoutPaymentWhatsappTitle => 'WhatsApp';

  @override
  String get checkoutPaymentWhatsappDescription =>
      'Contact us on WhatsApp to complete payment manually.';

  @override
  String get checkoutNoPaymentMethods =>
      'No payment methods are available right now. Please contact support.';

  @override
  String get checkoutSelectPaymentSubtitle =>
      'Select a payment method to continue';

  @override
  String get libraryPaymentProcessTitle => 'Purchase request';

  @override
  String get libraryPaymentProcessSubtitle =>
      'Follow these steps, then send your request. A summary is also sent in the request message.';

  @override
  String get libraryPaymentProcessSubtitleNoReceipt =>
      'Send your purchase request below; the administration will review it and activate your course access after payment is confirmed.';

  @override
  String get whatsappPaymentProcessSubtitle =>
      'Follow the two steps below, attach your receipt, then send your request to the administration.';

  @override
  String get whatsappPaymentStep1 =>
      'Contact the coordinator on WhatsApp to request the bank account number for the transfer, then attach a photo of the receipt.';

  @override
  String get whatsappPaymentStep2 => 'Tap “Send request to administrator”.';

  @override
  String get whatsappPaymentAfterConfirmationNote =>
      'After payment is confirmed, your course material will be unlocked.';

  @override
  String get libraryPaymentStep3NoReceipt =>
      'Complete the payment as directed by the administration (at the academy or via the agreed channel).';

  @override
  String get libraryPaymentStep1 =>
      'Send a purchase request for the course using the button below.';

  @override
  String get libraryPaymentStep2 =>
      'The administration receives and reviews your request.';

  @override
  String get libraryPaymentStep3 =>
      'Attach a clear photo of your receipt below if you already have one.';

  @override
  String get libraryPaymentStep4 =>
      'Once payment is confirmed, the course is activated on your account.';

  @override
  String get libraryPaymentNotesLabel =>
      'Notes for the administrator (optional)';

  @override
  String get libraryPaymentNotesHint =>
      'Receipt number, payment date, or other details';

  @override
  String get libraryPaymentAttachReceipt => 'Choose receipt photo (required)';

  @override
  String get libraryPaymentChangePhoto => 'Change photo';

  @override
  String get libraryPaymentRemovePhoto => 'Remove photo';

  @override
  String get libraryPaymentSendToAdmin => 'Send request to administrator';

  @override
  String get libraryPaymentUploadingReceipt => 'Uploading receipt…';

  @override
  String get libraryPaymentReceiptRequired =>
      'Please choose a photo of your payment receipt.';

  @override
  String get enrollmentRequestPendingReview =>
      'Your request has been received. It is under review and we will notify you when it is processed.';

  @override
  String get whatsappPaymentSendReceiptTitle => 'Send your receipt on WhatsApp';

  @override
  String get whatsappPaymentSendReceiptSubtitle =>
      'Choose a clear photo of your payment receipt, then share it with us on WhatsApp so the admin can verify your payment.';

  @override
  String get whatsappPaymentPickReceiptButton => 'Choose receipt photo';

  @override
  String get whatsappPaymentShareReceiptButton => 'Share receipt on WhatsApp';

  @override
  String get whatsappPaymentReceiptRequired =>
      'Please choose a photo of your payment receipt before sharing.';

  @override
  String whatsappReceiptShareCaption(String courseTitle) {
    return 'Payment receipt for course enrollment.\nCourse: $courseTitle';
  }

  @override
  String get whatsappPaymentShareFailed =>
      'Could not open the share sheet. Try again or send your receipt manually on WhatsApp.';

  @override
  String get globalWhatsappFabMessage =>
      'Hello, I would like to contact the academy.';

  @override
  String get globalWhatsappFabUnavailable =>
      'WhatsApp contact is not available right now.';

  @override
  String get globalWhatsappFabContactLabel => 'Contact us';

  @override
  String checkoutWhatsappPrefillMessage(String courseTitle) {
    return 'Hello, I want to complete payment for this course and will send my payment receipt in this chat.\nCourse: $courseTitle';
  }

  @override
  String get skillTrackTitle => 'Course levels';

  @override
  String get skillTrackSubtitle =>
      'Available courses — higher levels unlock previous courses automatically.';

  @override
  String get skillTrackUnlockNote =>
      'As you move up a level, all previous courses unlock automatically.';

  @override
  String get skillTrackHomeCta => 'Course levels';

  @override
  String get skillTrackHomeCtaSubtitle => '5 levels — bundle unlock';

  @override
  String get skillTrackIncludedFree => 'Also unlocks for free:';

  @override
  String get skillTrackFree => 'Free';

  @override
  String get skillTrackEnrolled => 'Enrolled';

  @override
  String get skillTrackViewCourse => 'View course';

  @override
  String get skillTrackLoadError =>
      'Could not load course levels. Pull to refresh or try again.';

  @override
  String get skillTrackBundleBannerTitle => 'Included in this level';

  @override
  String skillTrackBundleBannerBody(int count) {
    return 'Purchasing this level also unlocks $count previous course(s) at no extra charge.';
  }

  @override
  String skillTrackBundleUnlockedMessage(int count) {
    return '$count courses are now unlocked on your account.';
  }

  @override
  String get haveActivationCode => 'Have an activation code?';

  @override
  String get activationCodeSheetSubtitle =>
      'Enter your code to unlock this course instantly.';

  @override
  String get activationCodeDialogTitle => 'Activation code';

  @override
  String get activationCodeFieldHint => 'Enter the activation code';

  @override
  String get activationCodeSubmit => 'Activate';

  @override
  String get activationCodeRequired => 'Please enter the activation code.';

  @override
  String get activationCodeSuccessFallback => 'Course activated successfully.';

  @override
  String get activationCodeInvalidFallback =>
      'Could not activate this code. Check it and try again.';

  @override
  String get bankTransferProcessSubtitle =>
      'Follow the steps below, then send your request to the administration.';

  @override
  String get bankTransferStep1 =>
      'Transfer the course fee to the academy\'s bank account (account details are shared by the academy).';

  @override
  String get bankTransferStep2 =>
      'Write the sender name and transfer number or reference in the notes below.';

  @override
  String get bankTransferStep3 =>
      'Attach a photo of the transfer receipt (optional but speeds up review), then send the request.';

  @override
  String get bankTransferAttachReceiptOptional =>
      'Choose receipt photo (optional)';

  @override
  String get myEnrollmentRequests => 'My enrollment requests';

  @override
  String get enrollmentRequestsEmpty => 'No enrollment requests yet.';

  @override
  String get enrollmentRequestsLoadError =>
      'Could not load enrollment requests.';

  @override
  String get enrollmentRequestStatusPending => 'Pending review';

  @override
  String get enrollmentRequestStatusApproved => 'Approved';

  @override
  String get enrollmentRequestStatusRejected => 'Rejected';

  @override
  String get enrollmentRequestRejectionReason => 'Rejection reason';

  @override
  String get enrollmentRequestReviewedAt => 'Reviewed';

  @override
  String get liveLesson => 'Live Lesson';

  @override
  String get liveSessionReminderTitle => 'Live session reminder';

  @override
  String liveSessionReminderBody(String title, int minutes) {
    return '$title starts in $minutes min';
  }

  @override
  String liveSessionReminderNowBody(String title) {
    return '$title is starting now';
  }

  @override
  String get reminderSet => 'Reminder set';

  @override
  String get reminderOn => 'Reminder on';

  @override
  String get endsIn => 'Ends in';

  @override
  String get sessionNotStartedYet => 'The session has not started yet';
}
