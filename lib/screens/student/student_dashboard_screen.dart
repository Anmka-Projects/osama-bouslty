import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/navigation/route_names.dart';
import '../../core/api/api_endpoints.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/brand_ui.dart';
import '../../core/design/app_theme_extension.dart';

/// Student Dashboard Screen - Simple Modern Design
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  AppThemeExtension get _theme => AppThemeExtension.of(context);

  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileService.instance.getProfile();
      if (!mounted) return;
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🖼️ STUDENT DASHBOARD - PROFILE AVATAR');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('Profile avatar raw: ${profile['avatar']}');
        print('Profile avatar type: ${profile['avatar']?.runtimeType}');
        if (profile['avatar'] != null) {
          final avatarUrl =
              ApiEndpoints.getImageUrl(profile['avatar']?.toString());
          print('Profile avatar URL: $avatarUrl');
          print('Avatar URL length: ${avatarUrl.length}');
          print('Avatar URL is empty: ${avatarUrl.isEmpty}');
        } else {
          print('⚠️ Profile avatar is null');
        }
        print('✅ Profile loaded: ${profile['name']}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      setState(() {
        _profile = profile;
        _statistics = profile['statistics'] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading profile: $e');
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          AppLocalizations.of(context)!.logout,
          style: GoogleFonts.readexPro(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.appTheme.cardTitle,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.confirmLogout,
          style: GoogleFonts.readexPro(
            fontSize: 14,
            color: context.appTheme.cardMetaText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.readexPro(
                color: context.cardMetaText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context)!.logout,
              style: GoogleFonts.readexPro(
                color: context.appTheme.icon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.loggingOut,
                style: GoogleFonts.readexPro(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Call logout API
      await AuthService.instance.logout();

      if (!context.mounted) return;

      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasLaunched');

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to splash/login screen
      if (context.mounted) {
        context.go(RouteNames.splash);
      }
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                .errorLoggingOut(e.toString().replaceFirst('Exception: ', '')),
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          l10n.deleteAccount,
          style: GoogleFonts.readexPro(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[400],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.confirmDeleteAccount,
              style: GoogleFonts.readexPro(
                fontSize: 14,
                color: context.appTheme.cardMetaText,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              style: GoogleFonts.readexPro(
                fontSize: 14,
                color: context.appTheme.cardTitle,
              ),
              decoration: InputDecoration(
                hintText: l10n.deleteAccountPasswordHint,
                hintStyle: GoogleFonts.readexPro(
                  fontSize: 13,
                  color: context.appTheme.cardMetaText,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.readexPro(
                color: context.cardMetaText,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.passwordRequiredToDelete,
                      style: GoogleFonts.readexPro(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: Text(
              l10n.deleteAccount,
              style: GoogleFonts.readexPro(
                color: Colors.red[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    final password = passwordController.text.trim();
    passwordController.dispose();

    if (shouldDelete != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                l10n.deletingAccount,
                style: GoogleFonts.readexPro(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await AuthService.instance.deleteAccount(password: password);

      if (!context.mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hasLaunched');

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.accountDeletedSuccessfully,
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        context.go(RouteNames.splash);
      }
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorDeletingAccount(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    BrandUi.applyStatusBar(context);

    final enrolledCourses = _statistics?['enrolled_courses'] ?? 0;
    final totalHours = _statistics?['total_learning_hours'] ?? 0;
    final l10n = AppLocalizations.of(context)!;

    // Get student type from profile
    final studentType = _profile?['studentType'] as String? ??
        _profile?['student_type'] as String?;

    // Build all menu items
    final allMenuItems = [
      {
        'icon': Icons.menu_book_rounded,
        'label': l10n.enrolledLessons,
        'subtitle': l10n.activeCourse(enrolledCourses),
        'onTap': () => context.push(RouteNames.enrolled),
        'showFor': ['online', 'offline'],
      },
      {
        'icon': Icons.assignment_rounded,
        'label': l10n.myExams,
        'subtitle': l10n.viewAllExams,
        'onTap': () => context.push(RouteNames.myExams),
        'showFor': ['online', 'offline'],
      },
      {
        'icon': Icons.videocam_rounded,
        'label': l10n.liveCourses,
        'subtitle': l10n.liveCoursesMenuSubtitle,
        'onTap': () => context.push(RouteNames.liveCourses),
        'showFor': ['online'],
      },
      {
        'icon': Icons.download_rounded,
        'label': l10n.downloads,
        'subtitle': l10n.savedFiles,
        'onTap': () => context.push(RouteNames.downloads),
        'showFor': ['online'],
      },
      {
        'icon': Icons.qr_code_scanner_rounded,
        'label': l10n.centerAttendance,
        'subtitle': l10n.scanQrCodeInstruction,
        'onTap': () => context.push(RouteNames.centerAttendance),
        'showFor': ['offline'],
      },
      {
        'icon': Icons.chat_bubble_rounded,
        'label': 'Chat',
        'subtitle': 'Message teachers',
        'onTap': () => context.push(RouteNames.chatConversations),
        'showFor': ['online', 'offline'],
      },
      {
        'icon': Icons.settings_rounded,
        'label': l10n.settings,
        'subtitle': l10n.customizeApp,
        'onTap': () => context.push(RouteNames.settings),
        'showFor': ['online', 'offline'],
      },
    ];

    // Filter menu items based on student type
    final menuItems = allMenuItems.where((item) {
      final showFor = item['showFor'] as List<String>;
      // If studentType is null, show all items (fallback)
      if (studentType == null) return true;
      return showFor.contains(studentType);
    }).toList();

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              _buildHeader(context, enrolledCourses, totalHours),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: _theme.icon,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.mainMenu,
                              style: GoogleFonts.readexPro(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _theme.foreground,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Menu Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: menuItems.length,
                              itemBuilder: (context, index) {
                                final item = menuItems[index];
                                return _buildMenuItem(
                                  icon: item['icon'] as IconData,
                                  label: item['label'] as String,
                                  subtitle: item['subtitle'] as String,
                                  onTap: item['onTap'] as VoidCallback,
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Logout Button
                            GestureDetector(
                              onTap: () => _handleLogout(context),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Colors.red[300],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.logout,
                                      style: GoogleFonts.readexPro(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[300],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Delete Account
                            Center(
                              child: TextButton(
                                onPressed: () => _handleDeleteAccount(context),
                                child: Text(
                                  AppLocalizations.of(context)!.deleteAccount,
                                  style: GoogleFonts.readexPro(
                                      fontSize: 13, color: Colors.red[300]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),

          // Bottom Navigation
          const BottomNav(activeTab: 'dashboard'),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, int enrolledCourses, int totalHours) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.headerGradient2,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.largeCard),
          bottomRight: Radius.circular(AppRadius.largeCard),
        ),
        boxShadow: [
          BoxShadow(
            color: context.appTheme.icon.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.go(RouteNames.home),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.goldPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.myAccount,
                    style: GoogleFonts.readexPro(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(RouteNames.settings),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.goldPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Profile Section
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _profile?['avatar'] != null
                      ? Image.network(
                          ApiEndpoints.getImageUrl(
                            _profile!['avatar']?.toString(),
                          ),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.white,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.appTheme.icon,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            if (kDebugMode) {
                              print(
                                  '❌ Error loading avatar image in dashboard: $error');
                              print(
                                  '   Avatar URL: ${ApiEndpoints.getImageUrl(_profile!['avatar']?.toString())}');
                              print('   Stack trace: $stackTrace');
                            }
                            return Image.asset(
                              'assets/images/student-avatar.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  size: 45,
                                  color: context.appTheme.icon,
                                ),
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/student-avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 45,
                              color: context.appTheme.icon,
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _profile?['name']?.toString() ??
                    AppLocalizations.of(context)!.user,
                style: GoogleFonts.readexPro(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.goldPrimary,
                ),
              ),
              Text(
                _profile?['email']?.toString() ?? '',
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  color: AppColors.goldLight,
                ),
              ),

              const SizedBox(height: 16),

              // Stats Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStat(
                        '$enrolledCourses',
                        AppLocalizations.of(context)!.course,
                        Icons.play_circle_fill_rounded),
                    Container(
                      width: 1,
                      height: 25,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: AppColors.goldPrimary.withValues(alpha: 0.35),
                    ),
                    _buildStat(
                        '$totalHours',
                        AppLocalizations.of(context)!.hour,
                        Icons.access_time_filled_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.goldLight),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.readexPro(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.brandWhite,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.readexPro(
            fontSize: 11,
            color: AppColors.brandWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = _theme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.progressTrack,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.cardAccentText.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(icon, color: theme.icon, size: 24),
            ),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.readexPro(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.cardTitle,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.readexPro(
                fontSize: 11,
                color: theme.cardMetaText.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
