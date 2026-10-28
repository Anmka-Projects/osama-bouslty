import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Bouslty'**
  String get appName;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// General settings section title
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Privacy and security setting
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacyAndSecurity;

  /// Help and support setting
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// Change password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Arabic language name
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Language change success message
  ///
  /// In en, this message translates to:
  /// **'Language changed to {name}'**
  String languageChanged(String name);

  /// Preferences update success message
  ///
  /// In en, this message translates to:
  /// **'Preferences updated successfully'**
  String get preferencesUpdated;

  /// Preferences update error message
  ///
  /// In en, this message translates to:
  /// **'Error updating preferences'**
  String get errorUpdatingPreferences;

  /// Default user name
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Optional email field on register
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// Email or phone number field
  ///
  /// In en, this message translates to:
  /// **'Email or Phone Number'**
  String get emailOrPhone;

  /// Enter email or phone placeholder text
  ///
  /// In en, this message translates to:
  /// **'Enter your email or phone number'**
  String get enterEmailOrPhone;

  /// Invalid email or phone error message
  ///
  /// In en, this message translates to:
  /// **'Invalid email or phone number'**
  String get invalidEmailOrPhone;

  /// Password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// Register link
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get registerNow;

  /// Invalid email error message
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// Enter email message
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Enter password message
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Welcome message in login
  ///
  /// In en, this message translates to:
  /// **'Welcome back! 👋'**
  String get welcomeBack;

  /// Email placeholder text
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Password placeholder text
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Field required message
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// OR
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// Google
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// Apple
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// Register screen title
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get register;

  /// Welcome message in register
  ///
  /// In en, this message translates to:
  /// **'Join us and start your learning journey 🎓'**
  String get joinUsMessage;

  /// Full name field
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Enter name message
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get pleaseEnterName;

  /// Phone number field
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone;

  /// Optional phone number field on register
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get phoneOptional;

  /// Phone number placeholder
  ///
  /// In en, this message translates to:
  /// **'01xxxxxxxxx'**
  String get phonePlaceholder;

  /// Student type label
  ///
  /// In en, this message translates to:
  /// **'Student type'**
  String get studentType;

  /// On-campus student option
  ///
  /// In en, this message translates to:
  /// **'In-class student'**
  String get inPersonStudent;

  /// Online student option
  ///
  /// In en, this message translates to:
  /// **'Online student'**
  String get onlineStudent;

  /// Both option
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get bothStudentTypes;

  /// Validation message for student type
  ///
  /// In en, this message translates to:
  /// **'Please choose your student type'**
  String get selectStudentType;

  /// Invalid phone number error message
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhone;

  /// Enter password again
  ///
  /// In en, this message translates to:
  /// **'Enter password again'**
  String get enterPasswordAgain;

  /// I agree to
  ///
  /// In en, this message translates to:
  /// **'I agree to'**
  String get iAgreeTo;

  /// Please accept the terms and conditions
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get pleaseAcceptTerms;

  /// Create Account
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Already have an account?
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Terms and conditions
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// Home page
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Courses
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// Progress
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Featured courses
  ///
  /// In en, this message translates to:
  /// **'Featured Courses'**
  String get featuredCourses;

  /// Home promo carousel when there are no slider items
  ///
  /// In en, this message translates to:
  /// **'No banners at the moment'**
  String get homePromoSliderEmpty;

  /// Categories
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @subcategories.
  ///
  /// In en, this message translates to:
  /// **'Subcategories'**
  String get subcategories;

  /// Category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Educational stage (top-level category) field label on register screen
  ///
  /// In en, this message translates to:
  /// **'Educational Stage'**
  String get educationalStage;

  /// Hint/validation text for the educational stage dropdown
  ///
  /// In en, this message translates to:
  /// **'Select your educational stage'**
  String get selectEducationalStage;

  /// Grade (subcategory) field label on register screen
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// Hint/validation text for the grade dropdown
  ///
  /// In en, this message translates to:
  /// **'Select your grade'**
  String get selectGrade;

  /// Start learning journey
  ///
  /// In en, this message translates to:
  /// **'Start your learning journey and enroll in your first course'**
  String get startLearningJourney;

  /// Discount text
  ///
  /// In en, this message translates to:
  /// **'50% off on all courses'**
  String get discount50;

  /// Subscribe button
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Newest
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// Highest rated
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get highestRated;

  /// Best selling
  ///
  /// In en, this message translates to:
  /// **'Best Selling'**
  String get bestSelling;

  /// Price low to high
  ///
  /// In en, this message translates to:
  /// **'Price: Low to High'**
  String get priceLowToHigh;

  /// Price high to low
  ///
  /// In en, this message translates to:
  /// **'Price: High to Low'**
  String get priceHighToLow;

  /// Courses loading error message
  ///
  /// In en, this message translates to:
  /// **'Error loading courses'**
  String get errorLoadingCourses;

  /// Instructor
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get instructor;

  /// Lessons
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// Lesson
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lesson;

  /// Course
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get course;

  /// Course description
  ///
  /// In en, this message translates to:
  /// **'This course is suitable for both beginners and professionals.'**
  String get courseSuitable;

  /// Enrollment success message
  ///
  /// In en, this message translates to:
  /// **'Enrolled in course successfully'**
  String get enrolledSuccessfully;

  /// Enrollment error message
  ///
  /// In en, this message translates to:
  /// **'Error enrolling in course'**
  String get errorEnrolling;

  /// Added to wishlist message
  ///
  /// In en, this message translates to:
  /// **'Added to wishlist'**
  String get addedToWishlist;

  /// Removed from wishlist message
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get removedFromWishlist;

  /// Wishlist error message
  ///
  /// In en, this message translates to:
  /// **'Error {action} wishlist'**
  String errorWishlist(String action);

  /// Adding to
  ///
  /// In en, this message translates to:
  /// **'adding to'**
  String get addingTo;

  /// Removing from
  ///
  /// In en, this message translates to:
  /// **'removing from'**
  String get removingFrom;

  /// Wishlist screen title and profile/settings entry
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlistTitle;

  /// Subtitle under wishlist entry on profile
  ///
  /// In en, this message translates to:
  /// **'Saved courses — open to view or remove'**
  String get wishlistMenuSubtitle;

  /// Empty wishlist heading
  ///
  /// In en, this message translates to:
  /// **'No saved courses'**
  String get wishlistEmptyTitle;

  /// Empty wishlist helper text
  ///
  /// In en, this message translates to:
  /// **'Open any course and tap the bookmark to add it here.'**
  String get wishlistEmptyDescription;

  /// Start exam
  ///
  /// In en, this message translates to:
  /// **'Start Exam'**
  String get startExam;

  /// Start exam error message
  ///
  /// In en, this message translates to:
  /// **'Error starting exam'**
  String get errorStartingExam;

  /// Submit exam
  ///
  /// In en, this message translates to:
  /// **'Submit Exam'**
  String get submitExam;

  /// Submit exam error message
  ///
  /// In en, this message translates to:
  /// **'Error submitting exam'**
  String get errorSubmittingExam;

  /// Practice exam
  ///
  /// In en, this message translates to:
  /// **'Practice Exam'**
  String get practiceExam;

  /// Question
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// Question number
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String questionNumber(int number);

  /// Next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Time taken
  ///
  /// In en, this message translates to:
  /// **'Time taken: {minutes} minutes'**
  String timeTaken(int minutes);

  /// Downloads
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// Download link message
  ///
  /// In en, this message translates to:
  /// **'Download link received. Download will start soon...'**
  String get downloadLinkReceived;

  /// Download error message
  ///
  /// In en, this message translates to:
  /// **'Error downloading: {error}'**
  String errorDownloading(String error);

  /// Delete success message
  ///
  /// In en, this message translates to:
  /// **'File deleted successfully'**
  String get fileDeleted;

  /// Delete error message
  ///
  /// In en, this message translates to:
  /// **'Error deleting: {error}'**
  String errorDeleting(String error);

  /// Certificates
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificates;

  /// Download success message
  ///
  /// In en, this message translates to:
  /// **'Downloaded successfully: {path}'**
  String downloadSuccessful(String path);

  /// File download error message
  ///
  /// In en, this message translates to:
  /// **'Error downloading file: {error}'**
  String errorDownloadingFile(String error);

  /// Share error message
  ///
  /// In en, this message translates to:
  /// **'Error sharing'**
  String get errorSharing;

  /// Student
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// Live courses
  ///
  /// In en, this message translates to:
  /// **'Live Courses'**
  String get liveCourses;

  /// Student dashboard: Live courses tile subtitle (not coming soon)
  ///
  /// In en, this message translates to:
  /// **'Join live sessions & reminders'**
  String get liveCoursesMenuSubtitle;

  /// Live courses list: sessions that have not started yet (header count / chip)
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get liveSessionsStatusScheduled;

  /// Registration success message
  ///
  /// In en, this message translates to:
  /// **'Registered for session successfully'**
  String get registeredSuccessfully;

  /// Registration error message
  ///
  /// In en, this message translates to:
  /// **'Error registering for session'**
  String get errorRegistering;

  /// Sunday
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// Monday
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// Tuesday
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// Wednesday
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// Thursday
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// Friday
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// Saturday
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// Enrolled lessons
  ///
  /// In en, this message translates to:
  /// **'Enrolled Lessons'**
  String get enrolledLessons;

  /// Saved files
  ///
  /// In en, this message translates to:
  /// **'Saved Files'**
  String get savedFiles;

  /// Main menu
  ///
  /// In en, this message translates to:
  /// **'Main Menu'**
  String get mainMenu;

  /// Logout
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout error message
  ///
  /// In en, this message translates to:
  /// **'Error logging out: {error}'**
  String errorLoggingOut(String error);

  /// Now
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// Lesson number
  ///
  /// In en, this message translates to:
  /// **'Lesson {current} of {total}'**
  String lessonNumber(int current, int total);

  /// All lessons completed
  ///
  /// In en, this message translates to:
  /// **'All lessons completed'**
  String get allLessonsCompleted;

  /// Previous lesson
  ///
  /// In en, this message translates to:
  /// **'Previous Lesson'**
  String get previousLesson;

  /// Next lesson
  ///
  /// In en, this message translates to:
  /// **'Next Lesson'**
  String get nextLesson;

  /// Lesson duration
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String duration(String duration);

  /// Not specified
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// Design
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get design;

  /// Programming
  ///
  /// In en, this message translates to:
  /// **'Programming'**
  String get programming;

  /// Marketing
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// Data
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// Checkout
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// Discount application success message
  ///
  /// In en, this message translates to:
  /// **'Discount applied successfully'**
  String get discountApplied;

  /// Discount check error message
  ///
  /// In en, this message translates to:
  /// **'Error checking discount code'**
  String get errorCheckingDiscount;

  /// Purchase success message
  ///
  /// In en, this message translates to:
  /// **'Purchase completed successfully'**
  String get purchaseSuccessful;

  /// Payment completion error message
  ///
  /// In en, this message translates to:
  /// **'Error completing payment'**
  String get errorCompletingPayment;

  /// Payment processing error message
  ///
  /// In en, this message translates to:
  /// **'Error processing payment'**
  String get errorProcessingPayment;

  /// 20% discount message
  ///
  /// In en, this message translates to:
  /// **'20% discount applied'**
  String get discount20;

  /// Discount
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// Total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Edit profile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Profile loading error message
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// Profile update success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// Profile update error message
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {error}'**
  String errorUpdatingProfile(String error);

  /// Country
  ///
  /// In en, this message translates to:
  /// **'Country (Optional)'**
  String get country;

  /// Timezone
  ///
  /// In en, this message translates to:
  /// **'Timezone (Optional)'**
  String get timezone;

  /// Name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// About You
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get bio;

  /// Save Changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Select Image Source
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// Camera
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Gallery
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Camera permission denied message
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied. Please allow camera access from settings'**
  String get cameraPermissionDenied;

  /// Gallery permission denied message
  ///
  /// In en, this message translates to:
  /// **'Gallery permission denied. Please allow photo access from settings'**
  String get galleryPermissionDenied;

  /// Error picking image message
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImage;

  /// Avatar uploaded success message
  ///
  /// In en, this message translates to:
  /// **'Avatar uploaded successfully'**
  String get avatarUploaded;

  /// Error uploading avatar message
  ///
  /// In en, this message translates to:
  /// **'Error uploading avatar: {error}'**
  String errorUploadingAvatar(String error);

  /// Password change success message
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChanged;

  /// Password change error message
  ///
  /// In en, this message translates to:
  /// **'Error changing password: {error}'**
  String errorChangingPassword(String error);

  /// Current password
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// New password
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Confirm password
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Enter current password message
  ///
  /// In en, this message translates to:
  /// **'Please enter current password'**
  String get pleaseEnterCurrentPassword;

  /// Enter new password message
  ///
  /// In en, this message translates to:
  /// **'Please enter new password'**
  String get pleaseEnterNewPassword;

  /// Confirm password message
  ///
  /// In en, this message translates to:
  /// **'Please confirm password'**
  String get pleaseConfirmPassword;

  /// Forgot password title
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// Back to login
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// Send success message
  ///
  /// In en, this message translates to:
  /// **'Sent successfully!'**
  String get sentSuccessfully;

  /// Password reset link sent message
  ///
  /// In en, this message translates to:
  /// **'Password reset link has been sent to your email'**
  String get resetPasswordSent;

  /// Reset password title
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// Reset password description
  ///
  /// In en, this message translates to:
  /// **'Enter your email to send a reset link'**
  String get resetPasswordDescription;

  /// Send reset link button
  ///
  /// In en, this message translates to:
  /// **'Send Link'**
  String get sendResetLink;

  /// Send to another email
  ///
  /// In en, this message translates to:
  /// **'Send to another email'**
  String get sendToAnotherEmail;

  /// Exam
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get exams;

  /// Question of
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionOf(int current, int total);

  /// Finish exam
  ///
  /// In en, this message translates to:
  /// **'Finish Exam'**
  String get finishExam;

  /// Final result
  ///
  /// In en, this message translates to:
  /// **'Final Result'**
  String get finalResult;

  /// Correct answers
  ///
  /// In en, this message translates to:
  /// **'Correct Answers'**
  String get correctAnswers;

  /// Wrong answers
  ///
  /// In en, this message translates to:
  /// **'Wrong Answers'**
  String get wrongAnswers;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Splash screen text
  ///
  /// In en, this message translates to:
  /// **'Knowledge is the light that illuminates your path'**
  String get science;

  /// Splash screen text
  ///
  /// In en, this message translates to:
  /// **'Success starts with a step'**
  String get success;

  /// Next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// Start now
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNow;

  /// My Courses
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get myCourses;

  /// Subject
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subjects;

  /// Number of lessons
  ///
  /// In en, this message translates to:
  /// **'{count} lessons'**
  String lessonsCount(int count);

  /// Courses count label
  ///
  /// In en, this message translates to:
  /// **'{count} courses'**
  String coursesCount(int count);

  /// Free
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// Paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// All Courses
  ///
  /// In en, this message translates to:
  /// **'All Courses'**
  String get allCourses;

  /// Number of courses available
  ///
  /// In en, this message translates to:
  /// **'{count} courses available'**
  String coursesAvailable(int count);

  /// Search for a course
  ///
  /// In en, this message translates to:
  /// **'Search for a course...'**
  String get searchCourse;

  /// No results
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// Try searching with different words
  ///
  /// In en, this message translates to:
  /// **'Try searching with different words or change filters'**
  String get tryDifferentSearch;

  /// Egyptian Pound
  ///
  /// In en, this message translates to:
  /// **'{amount} EGP'**
  String egyptianPound(int amount);

  /// No course data available
  ///
  /// In en, this message translates to:
  /// **'No course data available'**
  String get noCourseData;

  /// Course Title
  ///
  /// In en, this message translates to:
  /// **'Course Title'**
  String get courseTitle;

  /// Trial Exam
  ///
  /// In en, this message translates to:
  /// **'Trial Exam'**
  String get trialExam;

  /// No lessons available
  ///
  /// In en, this message translates to:
  /// **'No lessons available'**
  String get noLessonsAvailable;

  /// Certified certificate
  ///
  /// In en, this message translates to:
  /// **'Certified certificate upon completion'**
  String get certifiedCertificate;

  /// Loading exam
  ///
  /// In en, this message translates to:
  /// **'Loading exam...'**
  String get loadingExam;

  /// No trial exam available
  ///
  /// In en, this message translates to:
  /// **'No trial exam available'**
  String get noTrialExamAvailable;

  /// Start Exam
  ///
  /// In en, this message translates to:
  /// **'Start Exam'**
  String get startExamButton;

  /// Not Available
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// Enrolling
  ///
  /// In en, this message translates to:
  /// **'Enrolling...'**
  String get enrolling;

  /// Start Learning Now
  ///
  /// In en, this message translates to:
  /// **'Start Learning Now'**
  String get startLearningNow;

  /// Enroll Free
  ///
  /// In en, this message translates to:
  /// **'Enroll Free'**
  String get enrollFree;

  /// Enroll in Course
  ///
  /// In en, this message translates to:
  /// **'Enroll in Course'**
  String get enrollInCourse;

  /// Login required
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequired;

  /// No questions available
  ///
  /// In en, this message translates to:
  /// **'No questions available in exam'**
  String get noQuestionsAvailable;

  /// Finish Exam
  ///
  /// In en, this message translates to:
  /// **'Finish Exam'**
  String get finishExamButton;

  /// Loading questions
  ///
  /// In en, this message translates to:
  /// **'Loading questions...'**
  String get loadingQuestions;

  /// Finish
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// Shown after exam submit using API percentage field
  ///
  /// In en, this message translates to:
  /// **'Percentage: {percent}%'**
  String examResultPercentageLabel(int percent);

  /// Correct answers count after exam
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct answers'**
  String examResultCorrectSummary(int correct, int total);

  /// Headline when exam passed
  ///
  /// In en, this message translates to:
  /// **'Great job! 🎉'**
  String get examResultGreatJobTitle;

  /// Headline when exam not passed
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get examResultTryAgainTitle;

  /// Download link unavailable
  ///
  /// In en, this message translates to:
  /// **'Download link unavailable'**
  String get downloadLinkUnavailable;

  /// Downloading
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// Cannot access downloads folder
  ///
  /// In en, this message translates to:
  /// **'Cannot access downloads folder'**
  String get cannotAccessDownloads;

  /// Certificate of Completion
  ///
  /// In en, this message translates to:
  /// **'Certificate of Completion: {course}'**
  String certificateCompletion(String course);

  /// Certificate Number
  ///
  /// In en, this message translates to:
  /// **'Certificate Number: {number}'**
  String certificateNumber(String number);

  /// Verification Link
  ///
  /// In en, this message translates to:
  /// **'Verification Link: {url}'**
  String verificationLink(String url);

  /// Download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No certificates yet
  ///
  /// In en, this message translates to:
  /// **'No certificates yet'**
  String get noCertificatesYet;

  /// Complete courses to get certificates
  ///
  /// In en, this message translates to:
  /// **'Complete courses to get certified certificates'**
  String get completeCoursesForCertificates;

  /// Getting download link
  ///
  /// In en, this message translates to:
  /// **'Getting download link...'**
  String get gettingDownloadLink;

  /// Delete File
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// Confirm delete file
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file?'**
  String get confirmDeleteFile;

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No downloads
  ///
  /// In en, this message translates to:
  /// **'No downloads'**
  String get noDownloads;

  /// Course will open in offline mode
  ///
  /// In en, this message translates to:
  /// **'Course will open in offline mode'**
  String get willOpenOffline;

  /// No live sessions available
  ///
  /// In en, this message translates to:
  /// **'No live sessions available'**
  String get noLiveSessions;

  /// Sessions will be added soon
  ///
  /// In en, this message translates to:
  /// **'Upcoming sessions will be added soon'**
  String get sessionsComingSoon;

  /// Session link will open
  ///
  /// In en, this message translates to:
  /// **'Session link will open'**
  String get willOpenSessionLink;

  /// Session link unavailable
  ///
  /// In en, this message translates to:
  /// **'Session link unavailable'**
  String get sessionLinkUnavailable;

  /// Coming Soon
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Starts in
  ///
  /// In en, this message translates to:
  /// **'Starts in'**
  String get startsIn;

  /// hour
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour;

  /// minute
  ///
  /// In en, this message translates to:
  /// **'minute'**
  String get minute;

  /// Confirm logout
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// Logging out
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// My Exams
  ///
  /// In en, this message translates to:
  /// **'My Exams'**
  String get myExams;

  /// View all completed exams
  ///
  /// In en, this message translates to:
  /// **'View all completed exams'**
  String get viewAllExams;

  /// Exam
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get exam;

  /// No completed exams
  ///
  /// In en, this message translates to:
  /// **'No completed exams'**
  String get noCompletedExams;

  /// Start completing exams
  ///
  /// In en, this message translates to:
  /// **'Start completing exams to see your results here'**
  String get startCompletingExams;

  /// My exams list: exam has no submitted attempt yet
  ///
  /// In en, this message translates to:
  /// **'Not taken'**
  String get examListNotAttempted;

  /// A while ago
  ///
  /// In en, this message translates to:
  /// **'A while ago'**
  String get ago;

  /// Days ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 day ago} other {{count} days ago}}'**
  String daysAgo(int count);

  /// Hours ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 hour ago} other {{count} hours ago}}'**
  String hoursAgo(int count);

  /// Minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 minute ago} other {{count} minutes ago}}'**
  String minutesAgo(int count);

  /// Active courses
  ///
  /// In en, this message translates to:
  /// **'{count} active courses'**
  String activeCourse(int count);

  /// Delete Account
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Confirm delete account warning
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account? This cannot be undone. All your data, enrollments, and progress will be removed.'**
  String get confirmDeleteAccount;

  /// Password field hint for account deletion
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get deleteAccountPasswordHint;

  /// Loading text while deleting account
  ///
  /// In en, this message translates to:
  /// **'Deleting account...'**
  String get deletingAccount;

  /// Success message after account deletion
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted'**
  String get accountDeletedSuccessfully;

  /// Error deleting account
  ///
  /// In en, this message translates to:
  /// **'Error deleting account: {error}'**
  String errorDeletingAccount(String error);

  /// Validation when password is empty on delete
  ///
  /// In en, this message translates to:
  /// **'Password is required to delete your account'**
  String get passwordRequiredToDelete;

  /// My Account
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// Customize App
  ///
  /// In en, this message translates to:
  /// **'Customize App'**
  String get customizeApp;

  /// All Subjects
  ///
  /// In en, this message translates to:
  /// **'All Subjects'**
  String get allSubjects;

  /// Weekly
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// Monthly
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// Student Rating
  ///
  /// In en, this message translates to:
  /// **'Student Rating'**
  String get studentRating;

  /// Top 10 Students
  ///
  /// In en, this message translates to:
  /// **'Top 10 Students'**
  String get top10Students;

  /// My Exams
  ///
  /// In en, this message translates to:
  /// **'My Exams'**
  String get myExamsButton;

  /// View all completed exams
  ///
  /// In en, this message translates to:
  /// **'View all completed exams'**
  String get viewAllCompletedExams;

  /// Welcome
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name} 👋'**
  String welcome(String name);

  /// Visitor
  ///
  /// In en, this message translates to:
  /// **'Visitor'**
  String get visitor;

  /// Excellent Student
  ///
  /// In en, this message translates to:
  /// **'Excellent Student'**
  String get excellentStudent;

  /// Special Offer
  ///
  /// In en, this message translates to:
  /// **'Special Offer'**
  String get specialOffer;

  /// Subscribe Now
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNowButton;

  /// Enrolled Course
  ///
  /// In en, this message translates to:
  /// **'Enrolled Course'**
  String get enrolledCourse;

  /// Learning Hours
  ///
  /// In en, this message translates to:
  /// **'Learning Hours'**
  String get learningHours;

  /// Continue Learning
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get continueLearning;

  /// Recommended Courses
  ///
  /// In en, this message translates to:
  /// **'Recommended Courses'**
  String get recommendedCourses;

  /// View More
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// Search for a course, instructor, or topic
  ///
  /// In en, this message translates to:
  /// **'Search for a course, instructor, or topic...'**
  String get searchPlaceholder;

  /// No results found
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// Select the subject you want to learn
  ///
  /// In en, this message translates to:
  /// **'Select the subject you want to learn'**
  String get selectSubject;

  /// No categories
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get noCategories;

  /// Categories will be added soon
  ///
  /// In en, this message translates to:
  /// **'Categories will be added soon'**
  String get categoriesComingSoon;

  /// Passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// Password must be at least 8 characters
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// Password must include an uppercase letter
  ///
  /// In en, this message translates to:
  /// **'Password must include an uppercase letter'**
  String get passwordNeedsUppercase;

  /// Password must include a lowercase letter
  ///
  /// In en, this message translates to:
  /// **'Password must include a lowercase letter'**
  String get passwordNeedsLowercase;

  /// Password must include a number
  ///
  /// In en, this message translates to:
  /// **'Password must include a number'**
  String get passwordNeedsDigit;

  /// Password must include a special character
  ///
  /// In en, this message translates to:
  /// **'Password must include a special character'**
  String get passwordNeedsSpecial;

  /// Password contains invalid characters
  ///
  /// In en, this message translates to:
  /// **'Password may only contain letters and numbers'**
  String get passwordOnlyLettersAndDigits;

  /// Password must include a letter
  ///
  /// In en, this message translates to:
  /// **'Password must include a letter'**
  String get passwordNeedsLetter;

  /// Confirm New Password
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// Invalid coupon code
  ///
  /// In en, this message translates to:
  /// **'Invalid coupon code'**
  String get invalidCouponCode;

  /// Complete Purchase
  ///
  /// In en, this message translates to:
  /// **'Complete Purchase'**
  String get completePurchase;

  /// Enter coupon code
  ///
  /// In en, this message translates to:
  /// **'Enter coupon code'**
  String get enterCouponCode;

  /// Apply
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Payment Method
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Fawry
  ///
  /// In en, this message translates to:
  /// **'Fawry'**
  String get fawry;

  /// Pay at any Fawry branch
  ///
  /// In en, this message translates to:
  /// **'Pay at any Fawry branch'**
  String get payAtFawryBranch;

  /// E-Wallet
  ///
  /// In en, this message translates to:
  /// **'E-Wallet'**
  String get eWallet;

  /// E-Wallet description
  ///
  /// In en, this message translates to:
  /// **'Vodafone Cash - Etisalat Cash - Orange Cash'**
  String get walletDescription;

  /// Visa / Mastercard
  ///
  /// In en, this message translates to:
  /// **'Visa / Mastercard'**
  String get visaMastercard;

  /// Credit or Debit Card
  ///
  /// In en, this message translates to:
  /// **'Credit or Debit Card'**
  String get creditDebitCard;

  /// Order Summary
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// Course Price
  ///
  /// In en, this message translates to:
  /// **'Course Price'**
  String get coursePrice;

  /// Egyptian Pound
  ///
  /// In en, this message translates to:
  /// **'{amount} EGP'**
  String egyptianPoundAmount(String amount);

  /// Confirm Payment
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// Processing
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No course
  ///
  /// In en, this message translates to:
  /// **'No course'**
  String get noCourse;

  /// Date not specified
  ///
  /// In en, this message translates to:
  /// **'Date not specified'**
  String get dateNotSpecified;

  /// Certifies that
  ///
  /// In en, this message translates to:
  /// **'Certifies that'**
  String get certifiesThat;

  /// has completed this course with grade
  ///
  /// In en, this message translates to:
  /// **'has completed this course with grade'**
  String get hasCompletedWithGrade;

  /// Excellent
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// Mathematics
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get math;

  /// Literature
  ///
  /// In en, this message translates to:
  /// **'Literature'**
  String get literature;

  /// Biology
  ///
  /// In en, this message translates to:
  /// **'Biology'**
  String get biology;

  /// Physics
  ///
  /// In en, this message translates to:
  /// **'Physics'**
  String get physics;

  /// Chemistry
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get chemistry;

  /// Practical Engineering
  ///
  /// In en, this message translates to:
  /// **'Practical Engineering'**
  String get practicalEngineering;

  /// Creative Approaches to Plane Shapes
  ///
  /// In en, this message translates to:
  /// **'Creative Approaches to Plane Shapes'**
  String get creativePlaneShapes;

  /// Discoveries in Cellular Biology
  ///
  /// In en, this message translates to:
  /// **'Discoveries in Cellular Biology'**
  String get cellularBiologyDiscoveries;

  /// Introduction
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get introduction;

  /// What is Design?
  ///
  /// In en, this message translates to:
  /// **'What is Design?'**
  String get whatIsDesign;

  /// How to Create Wireframe
  ///
  /// In en, this message translates to:
  /// **'How to Create Wireframe'**
  String get howToCreateWireframe;

  /// Your First Design
  ///
  /// In en, this message translates to:
  /// **'Your First Design'**
  String get yourFirstDesign;

  /// Progress
  ///
  /// In en, this message translates to:
  /// **'Progress: {percent}%'**
  String progressPercent(int percent);

  /// Hello, Jacob
  ///
  /// In en, this message translates to:
  /// **'Hello, Jacob 👋'**
  String get helloJacob;

  /// Start your learning journey and enroll in your first course
  ///
  /// In en, this message translates to:
  /// **'Start your learning journey and enroll in your first course'**
  String get startLearningJourneyMessage;

  /// Learn Easily
  ///
  /// In en, this message translates to:
  /// **'Learn Easily'**
  String get learnEasily;

  /// Continuous Progress
  ///
  /// In en, this message translates to:
  /// **'Continuous Progress'**
  String get continuousProgress;

  /// Discover the best educational courses
  ///
  /// In en, this message translates to:
  /// **'Discover the best educational courses with professional teachers from around the world'**
  String get discoverBestCourses;

  /// Track your progress and get certificates
  ///
  /// In en, this message translates to:
  /// **'Track your progress and get certified certificates upon course completion'**
  String get trackProgressAndGetCertificates;

  /// Smart Learning Platform
  ///
  /// In en, this message translates to:
  /// **'Smart Learning Platform'**
  String get smartLearningPlatform;

  /// Certified and Secure Platform
  ///
  /// In en, this message translates to:
  /// **'Certified and Secure Platform'**
  String get certifiedAndSecure;

  /// Every day is a new opportunity to learn
  ///
  /// In en, this message translates to:
  /// **'Every day is a new opportunity to learn'**
  String get everyDayNewOpportunity;

  /// App version
  ///
  /// In en, this message translates to:
  /// **'v1.0.0'**
  String get version;

  /// Number of enrolled courses
  ///
  /// In en, this message translates to:
  /// **'{count} enrolled courses'**
  String enrolledCoursesCount(int count);

  /// Average Progress
  ///
  /// In en, this message translates to:
  /// **'Average Progress'**
  String get averageProgress;

  /// Completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Lesson from total
  ///
  /// In en, this message translates to:
  /// **'Lesson {current} of {total}'**
  String lessonFrom(int current, int total);

  /// Hour short
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourShort;

  /// Minute short unit for course duration
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minuteShort;

  /// Second short unit for course duration
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondShort;

  /// A while ago
  ///
  /// In en, this message translates to:
  /// **'A while ago'**
  String get timeAgo;

  /// No enrolled courses
  ///
  /// In en, this message translates to:
  /// **'You haven\'t enrolled in any courses yet'**
  String get noEnrolledCourses;

  /// Explore Courses
  ///
  /// In en, this message translates to:
  /// **'Explore Courses'**
  String get exploreCourses;

  /// No Title
  ///
  /// In en, this message translates to:
  /// **'No Title'**
  String get noTitle;

  /// Egyptian Pound short
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get egyptianPoundShort;

  /// Error loading notifications
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications: {error}'**
  String errorLoadingNotifications(String error);

  /// Error updating notification
  ///
  /// In en, this message translates to:
  /// **'Failed to update notification: {error}'**
  String errorUpdatingNotification(String error);

  /// Error updating notifications
  ///
  /// In en, this message translates to:
  /// **'Failed to update notifications: {error}'**
  String errorUpdatingNotifications(String error);

  /// New Notifications
  ///
  /// In en, this message translates to:
  /// **'New Notifications'**
  String get newNotifications;

  /// Number of new notifications
  ///
  /// In en, this message translates to:
  /// **'{count} new notifications'**
  String newNotificationsCount(int count);

  /// Mark All as Read
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllAsRead;

  /// New
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newSection;

  /// Past
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No Notifications
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get noNotifications;

  /// New notifications will appear here
  ///
  /// In en, this message translates to:
  /// **'New notifications will appear here'**
  String get newNotificationsWillAppear;

  /// Recently
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recently;

  /// Minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgoShort(int count);

  /// Hours ago
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgoShort(int count);

  /// Days ago
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgoShort(int count);

  /// Total Exams
  ///
  /// In en, this message translates to:
  /// **'Total Exams'**
  String get totalExams;

  /// Passed
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// Failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Undefined date
  ///
  /// In en, this message translates to:
  /// **'Undefined date'**
  String get undefinedDate;

  /// January
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthJanuary;

  /// February
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFebruary;

  /// March
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthMarch;

  /// April
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthApril;

  /// May
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// June
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthJune;

  /// July
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthJuly;

  /// August
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthAugust;

  /// September
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthSeptember;

  /// October
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthOctober;

  /// November
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthNovember;

  /// December
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthDecember;

  /// Downloaded files
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {downloaded file} other {downloaded files}}'**
  String downloadedFiles(int count);

  /// Storage
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// Storage used
  ///
  /// In en, this message translates to:
  /// **'{used} GB of {limit} GB used'**
  String storageUsed(String used, String limit);

  /// Storage used when displaying megabytes (avoids 0.0 GB for small usage)
  ///
  /// In en, this message translates to:
  /// **'{used} MB of {limit} MB used'**
  String storageUsedMb(String used, String limit);

  /// File
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// Undefined size
  ///
  /// In en, this message translates to:
  /// **'Undefined size'**
  String get undefinedSize;

  /// Watch Offline
  ///
  /// In en, this message translates to:
  /// **'Watch Offline'**
  String get watchOffline;

  /// File ID not available
  ///
  /// In en, this message translates to:
  /// **'File ID not available'**
  String get fileIdNotAvailable;

  /// Download link not available
  ///
  /// In en, this message translates to:
  /// **'Download link not available'**
  String get downloadLinkNotAvailable;

  /// Download link obtained
  ///
  /// In en, this message translates to:
  /// **'Download link obtained. Download will start soon...'**
  String get downloadLinkObtained;

  /// Course will open in offline mode
  ///
  /// In en, this message translates to:
  /// **'Course will open in offline mode'**
  String get courseWillOpenOffline;

  /// Course ID not available
  ///
  /// In en, this message translates to:
  /// **'Course ID not available'**
  String get courseIdNotAvailable;

  /// Download courses to watch offline
  ///
  /// In en, this message translates to:
  /// **'Download courses to watch offline'**
  String get downloadCoursesToWatchOffline;

  /// Number of sessions
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1 {session} other {sessions}} {status}'**
  String liveSessionsCount(int count, String status);

  /// live
  ///
  /// In en, this message translates to:
  /// **'live'**
  String get live;

  /// upcoming
  ///
  /// In en, this message translates to:
  /// **'upcoming'**
  String get upcoming;

  /// Live Session
  ///
  /// In en, this message translates to:
  /// **'Live Session'**
  String get liveSession;

  /// Live Now
  ///
  /// In en, this message translates to:
  /// **'Live Now'**
  String get liveNow;

  /// Remind Me
  ///
  /// In en, this message translates to:
  /// **'Remind Me'**
  String get remindMe;

  /// Join Now
  ///
  /// In en, this message translates to:
  /// **'Join Now'**
  String get joinNow;

  /// Course live session row when status is completed/cancelled
  ///
  /// In en, this message translates to:
  /// **'Session ended'**
  String get liveSessionButtonEnded;

  /// Course live session before start: button label (upcoming / notification intent)
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get liveSessionButtonUpcoming;

  /// Course details tab: live sessions for this course
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get courseLiveSessionsTab;

  /// Shown when url_launcher fails for a live session
  ///
  /// In en, this message translates to:
  /// **'Could not open the session link'**
  String get liveSessionOpenLinkFailed;

  /// Successfully registered for session
  ///
  /// In en, this message translates to:
  /// **'Successfully registered for session'**
  String get registeredForSession;

  /// Must login first
  ///
  /// In en, this message translates to:
  /// **'Must login first'**
  String get mustLoginFirst;

  /// day
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// second
  ///
  /// In en, this message translates to:
  /// **'second'**
  String get second;

  /// 1 hour
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// Achieved certificates
  ///
  /// In en, this message translates to:
  /// **'{count} achieved certificates'**
  String achievedCertificates(int count);

  /// Certificate of Completion
  ///
  /// In en, this message translates to:
  /// **'Certificate of Completion'**
  String get certificateOfCompletion;

  /// Download failed
  ///
  /// In en, this message translates to:
  /// **'Download failed: {code}'**
  String downloadFailed(int code);

  /// Certificate Number
  ///
  /// In en, this message translates to:
  /// **'Certificate Number'**
  String get certificateNumberLabel;

  /// Verification Link
  ///
  /// In en, this message translates to:
  /// **'Verification Link'**
  String get verificationLinkLabel;

  /// Center Attendance
  ///
  /// In en, this message translates to:
  /// **'Center Attendance'**
  String get centerAttendance;

  /// Center attendance description
  ///
  /// In en, this message translates to:
  /// **'Show this QR code at the center to mark your attendance'**
  String get centerAttendanceDescription;

  /// Loading QR code
  ///
  /// In en, this message translates to:
  /// **'Loading QR code...'**
  String get loadingQrCode;

  /// Error loading QR code
  ///
  /// In en, this message translates to:
  /// **'Error loading QR code'**
  String get errorLoadingQrCode;

  /// Scan QR code instruction
  ///
  /// In en, this message translates to:
  /// **'Show this QR code to the center staff to mark your attendance'**
  String get scanQrCodeInstruction;

  /// Refresh QR Code
  ///
  /// In en, this message translates to:
  /// **'Refresh QR Code'**
  String get refreshQrCode;

  /// Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Unknown error
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// Teachers section title
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachers;

  /// All teachers page title
  ///
  /// In en, this message translates to:
  /// **'All Teachers'**
  String get allTeachers;

  /// Fallback teacher title
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherFallback;

  /// Title for teacher courses section
  ///
  /// In en, this message translates to:
  /// **'Courses offered'**
  String get teacherCoursesTitle;

  /// Students count label
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String studentsCount(int count);

  /// Checkout payment method section title
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get choosePaymentMethod;

  /// Title for bank transfer account fields
  ///
  /// In en, this message translates to:
  /// **'Your bank account'**
  String get bankTransferYourDetails;

  /// Hint under bank transfer fields
  ///
  /// In en, this message translates to:
  /// **'Enter the account you transfer from so we can verify your payment.'**
  String get bankTransferHint;

  /// Bank account holder label
  ///
  /// In en, this message translates to:
  /// **'Account holder name'**
  String get accountHolderName;

  /// Bank account number field label
  ///
  /// In en, this message translates to:
  /// **'Account / IBAN number'**
  String get bankAccountNumberLabel;

  /// Optional transfer reference field
  ///
  /// In en, this message translates to:
  /// **'Transfer reference (optional)'**
  String get transferReferenceOptional;

  /// Validation when bank fields empty
  ///
  /// In en, this message translates to:
  /// **'Please enter account holder name and account number'**
  String get bankDetailsRequired;

  /// Course enrollment payment option — bank transfer
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get checkoutPaymentBankTitle;

  /// Course enrollment payment — bank description
  ///
  /// In en, this message translates to:
  /// **'Transfer to the academy bank account. You will enter your account details on the next step to verify payment.'**
  String get checkoutPaymentBankDescription;

  /// Course enrollment — pay at library with receipt
  ///
  /// In en, this message translates to:
  /// **'Purchase request'**
  String get checkoutPaymentLibraryTitle;

  /// Course enrollment — library payment description
  ///
  /// In en, this message translates to:
  /// **'Send a purchase request to the administration; pay at the academy and get activated after approval.'**
  String get checkoutPaymentLibraryDescription;

  /// Course enrollment — WhatsApp payment coordination
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get checkoutPaymentWhatsappTitle;

  /// Course enrollment — WhatsApp description
  ///
  /// In en, this message translates to:
  /// **'Contact us on WhatsApp to complete payment manually.'**
  String get checkoutPaymentWhatsappDescription;

  /// Shown when all course payment toggles are off in admin
  ///
  /// In en, this message translates to:
  /// **'No payment methods are available right now. Please contact support.'**
  String get checkoutNoPaymentMethods;

  /// Subtitle under payment method picker
  ///
  /// In en, this message translates to:
  /// **'Select a payment method to continue'**
  String get checkoutSelectPaymentSubtitle;

  /// Title for library cash payment instructions screen
  ///
  /// In en, this message translates to:
  /// **'Purchase request'**
  String get libraryPaymentProcessTitle;

  /// Subtitle explaining admin receives the process summary
  ///
  /// In en, this message translates to:
  /// **'Follow these steps, then send your request. A summary is also sent in the request message.'**
  String get libraryPaymentProcessSubtitle;

  /// Subtitle when payment channel is library without receipt_image_url
  ///
  /// In en, this message translates to:
  /// **'Send your purchase request below; the administration will review it and activate your course access after payment is confirmed.'**
  String get libraryPaymentProcessSubtitleNoReceipt;

  /// Intro subtitle on WhatsApp bank-transfer payment screen
  ///
  /// In en, this message translates to:
  /// **'Follow the two steps below, attach your receipt, then send your request to the administration.'**
  String get whatsappPaymentProcessSubtitle;

  /// WhatsApp payment step 1
  ///
  /// In en, this message translates to:
  /// **'Contact the coordinator on WhatsApp to request the bank account number for the transfer, then attach a photo of the receipt.'**
  String get whatsappPaymentStep1;

  /// WhatsApp payment step 2
  ///
  /// In en, this message translates to:
  /// **'Tap “Send request to administrator”.'**
  String get whatsappPaymentStep2;

  /// Note after WhatsApp payment steps about access after admin confirms
  ///
  /// In en, this message translates to:
  /// **'After payment is confirmed, your course material will be unlocked.'**
  String get whatsappPaymentAfterConfirmationNote;

  /// Step 3 copy for library flow without image upload
  ///
  /// In en, this message translates to:
  /// **'Complete the payment as directed by the administration (at the academy or via the agreed channel).'**
  String get libraryPaymentStep3NoReceipt;

  /// No description provided for @libraryPaymentStep1.
  ///
  /// In en, this message translates to:
  /// **'Send a purchase request for the course using the button below.'**
  String get libraryPaymentStep1;

  /// No description provided for @libraryPaymentStep2.
  ///
  /// In en, this message translates to:
  /// **'The administration receives and reviews your request.'**
  String get libraryPaymentStep2;

  /// No description provided for @libraryPaymentStep3.
  ///
  /// In en, this message translates to:
  /// **'Attach a clear photo of your receipt below if you already have one.'**
  String get libraryPaymentStep3;

  /// No description provided for @libraryPaymentStep4.
  ///
  /// In en, this message translates to:
  /// **'Once payment is confirmed, the course is activated on your account.'**
  String get libraryPaymentStep4;

  /// No description provided for @libraryPaymentNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes for the administrator (optional)'**
  String get libraryPaymentNotesLabel;

  /// No description provided for @libraryPaymentNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Receipt number, payment date, or other details'**
  String get libraryPaymentNotesHint;

  /// No description provided for @libraryPaymentAttachReceipt.
  ///
  /// In en, this message translates to:
  /// **'Choose receipt photo (required)'**
  String get libraryPaymentAttachReceipt;

  /// No description provided for @libraryPaymentChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get libraryPaymentChangePhoto;

  /// No description provided for @libraryPaymentRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get libraryPaymentRemovePhoto;

  /// No description provided for @libraryPaymentSendToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Send request to administrator'**
  String get libraryPaymentSendToAdmin;

  /// No description provided for @libraryPaymentUploadingReceipt.
  ///
  /// In en, this message translates to:
  /// **'Uploading receipt…'**
  String get libraryPaymentUploadingReceipt;

  /// No description provided for @libraryPaymentReceiptRequired.
  ///
  /// In en, this message translates to:
  /// **'Please choose a photo of your payment receipt.'**
  String get libraryPaymentReceiptRequired;

  /// After submitting library enrollment request to admin
  ///
  /// In en, this message translates to:
  /// **'Your request has been received. It is under review and we will notify you when it is processed.'**
  String get enrollmentRequestPendingReview;

  /// Bottom sheet title for WhatsApp receipt flow
  ///
  /// In en, this message translates to:
  /// **'Send your receipt on WhatsApp'**
  String get whatsappPaymentSendReceiptTitle;

  /// Instructions for WhatsApp receipt flow
  ///
  /// In en, this message translates to:
  /// **'Choose a clear photo of your payment receipt, then share it with us on WhatsApp so the admin can verify your payment.'**
  String get whatsappPaymentSendReceiptSubtitle;

  /// Picker button for WhatsApp receipt
  ///
  /// In en, this message translates to:
  /// **'Choose receipt photo'**
  String get whatsappPaymentPickReceiptButton;

  /// Opens system share with image for WhatsApp
  ///
  /// In en, this message translates to:
  /// **'Share receipt on WhatsApp'**
  String get whatsappPaymentShareReceiptButton;

  /// Validation when sharing without image
  ///
  /// In en, this message translates to:
  /// **'Please choose a photo of your payment receipt before sharing.'**
  String get whatsappPaymentReceiptRequired;

  /// Caption sent with shared receipt image
  ///
  /// In en, this message translates to:
  /// **'Payment receipt for course enrollment.\nCourse: {courseTitle}'**
  String whatsappReceiptShareCaption(String courseTitle);

  /// When Share.shareXFiles fails
  ///
  /// In en, this message translates to:
  /// **'Could not open the share sheet. Try again or send your receipt manually on WhatsApp.'**
  String get whatsappPaymentShareFailed;

  /// Prefilled text when opening WhatsApp from global FAB
  ///
  /// In en, this message translates to:
  /// **'Hello, I would like to contact the academy.'**
  String get globalWhatsappFabMessage;

  /// Snackbar when config has no WhatsApp number
  ///
  /// In en, this message translates to:
  /// **'WhatsApp contact is not available right now.'**
  String get globalWhatsappFabUnavailable;

  /// Short label animated beside global WhatsApp FAB
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get globalWhatsappFabContactLabel;

  /// Prefilled WhatsApp message after checkout
  ///
  /// In en, this message translates to:
  /// **'Hello, I want to complete payment for this course and will send my payment receipt in this chat.\nCourse: {courseTitle}'**
  String checkoutWhatsappPrefillMessage(String courseTitle);

  /// Skill track screen title
  ///
  /// In en, this message translates to:
  /// **'Course levels'**
  String get skillTrackTitle;

  /// Skill track intro
  ///
  /// In en, this message translates to:
  /// **'Available courses — higher levels unlock previous courses automatically.'**
  String get skillTrackSubtitle;

  /// Default unlock note on skill track
  ///
  /// In en, this message translates to:
  /// **'As you move up a level, all previous courses unlock automatically.'**
  String get skillTrackUnlockNote;

  /// Home entry card title for skill track
  ///
  /// In en, this message translates to:
  /// **'Course levels'**
  String get skillTrackHomeCta;

  /// Home entry card subtitle
  ///
  /// In en, this message translates to:
  /// **'5 levels — bundle unlock'**
  String get skillTrackHomeCtaSubtitle;

  /// Label above bundled courses on tier card
  ///
  /// In en, this message translates to:
  /// **'Also unlocks for free:'**
  String get skillTrackIncludedFree;

  /// Free tier price label
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get skillTrackFree;

  /// Badge when user already has tier
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get skillTrackEnrolled;

  /// Link on tier card
  ///
  /// In en, this message translates to:
  /// **'View course'**
  String get skillTrackViewCourse;

  /// Skill track load error
  ///
  /// In en, this message translates to:
  /// **'Could not load course levels. Pull to refresh or try again.'**
  String get skillTrackLoadError;

  /// Bundle banner title on course details
  ///
  /// In en, this message translates to:
  /// **'Included in this level'**
  String get skillTrackBundleBannerTitle;

  /// Bundle banner body on course details
  ///
  /// In en, this message translates to:
  /// **'Purchasing this level also unlocks {count} previous course(s) at no extra charge.'**
  String skillTrackBundleBannerBody(int count);

  /// Snackbar after checkout when bundle enrolls multiple courses
  ///
  /// In en, this message translates to:
  /// **'{count} courses are now unlocked on your account.'**
  String skillTrackBundleUnlockedMessage(int count);

  /// Row under payment methods that opens the activation code sheet
  ///
  /// In en, this message translates to:
  /// **'Have an activation code?'**
  String get haveActivationCode;

  /// Subtitle in the activation code sheet/dialog
  ///
  /// In en, this message translates to:
  /// **'Enter your code to unlock this course instantly.'**
  String get activationCodeSheetSubtitle;

  /// Title of the activation code entry sheet
  ///
  /// In en, this message translates to:
  /// **'Activation code'**
  String get activationCodeDialogTitle;

  /// Hint inside the activation code text field
  ///
  /// In en, this message translates to:
  /// **'Enter the activation code'**
  String get activationCodeFieldHint;

  /// Submit button for the activation code
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activationCodeSubmit;

  /// Validation error when the activation code field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter the activation code.'**
  String get activationCodeRequired;

  /// Snackbar when redeem succeeds but the server sends no message
  ///
  /// In en, this message translates to:
  /// **'Course activated successfully.'**
  String get activationCodeSuccessFallback;

  /// Fallback error when redeem fails without a server message
  ///
  /// In en, this message translates to:
  /// **'Could not activate this code. Check it and try again.'**
  String get activationCodeInvalidFallback;

  /// Intro subtitle on the bank-transfer enrollment request screen
  ///
  /// In en, this message translates to:
  /// **'Follow the steps below, then send your request to the administration.'**
  String get bankTransferProcessSubtitle;

  /// Bank transfer enrollment request step 1
  ///
  /// In en, this message translates to:
  /// **'Transfer the course fee to the academy\'s bank account (account details are shared by the academy).'**
  String get bankTransferStep1;

  /// Bank transfer enrollment request step 2
  ///
  /// In en, this message translates to:
  /// **'Write the sender name and transfer number or reference in the notes below.'**
  String get bankTransferStep2;

  /// Bank transfer enrollment request step 3
  ///
  /// In en, this message translates to:
  /// **'Attach a photo of the transfer receipt (optional but speeds up review), then send the request.'**
  String get bankTransferStep3;

  /// Receipt picker label when the receipt is not required
  ///
  /// In en, this message translates to:
  /// **'Choose receipt photo (optional)'**
  String get bankTransferAttachReceiptOptional;

  /// Title of the screen listing the student's enrollment requests
  ///
  /// In en, this message translates to:
  /// **'My enrollment requests'**
  String get myEnrollmentRequests;

  /// Empty state on the my enrollment requests screen
  ///
  /// In en, this message translates to:
  /// **'No enrollment requests yet.'**
  String get enrollmentRequestsEmpty;

  /// Fallback error on the my enrollment requests screen
  ///
  /// In en, this message translates to:
  /// **'Could not load enrollment requests.'**
  String get enrollmentRequestsLoadError;

  /// Status label for a pending enrollment request
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get enrollmentRequestStatusPending;

  /// Status label for an approved enrollment request
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get enrollmentRequestStatusApproved;

  /// Status label for a rejected enrollment request
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get enrollmentRequestStatusRejected;

  /// Label above the admin_notes rejection reason
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get enrollmentRequestRejectionReason;

  /// Label before the reviewed_at timestamp on a request card
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get enrollmentRequestReviewedAt;

  /// Default title for a live lesson
  ///
  /// In en, this message translates to:
  /// **'Live Lesson'**
  String get liveLesson;

  /// Title of the local reminder notification before a live session
  ///
  /// In en, this message translates to:
  /// **'Live session reminder'**
  String get liveSessionReminderTitle;

  /// Reminder notification body N minutes before a live session
  ///
  /// In en, this message translates to:
  /// **'{title} starts in {minutes} min'**
  String liveSessionReminderBody(String title, int minutes);

  /// Reminder notification body when a live session is starting
  ///
  /// In en, this message translates to:
  /// **'{title} is starting now'**
  String liveSessionReminderNowBody(String title);

  /// Snackbar shown after enabling a session reminder
  ///
  /// In en, this message translates to:
  /// **'Reminder set'**
  String get reminderSet;

  /// Button label when a session reminder is active
  ///
  /// In en, this message translates to:
  /// **'Reminder on'**
  String get reminderOn;

  /// Countdown label until a live session ends
  ///
  /// In en, this message translates to:
  /// **'Ends in'**
  String get endsIn;

  /// Hint shown under the countdown for an upcoming live session
  ///
  /// In en, this message translates to:
  /// **'The session has not started yet'**
  String get sessionNotStartedYet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
