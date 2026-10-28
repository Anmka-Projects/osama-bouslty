import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_theme_extension.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/design/app_radius.dart';
import '../../core/navigation/route_names.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/legal/legal_urls.dart';
import '../../services/profile_service.dart';
import '../../services/qr_code_service.dart';
import '../../core/config/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/design/app_theme_context.dart';

/// Settings Screen - Pixel-perfect match to React version
/// Matches: components/screens/settings-screen.tsx
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  // QR Code for offline students
  String? _qrCode;
  bool _isLoadingQrCode = false;
  String? _qrCodeError;

  final ThemeProvider _themeProvider = ThemeProvider.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Listen to theme changes
    _themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleLanguage() async {
    final nextCode = _themeProvider.locale.languageCode == 'ar' ? 'en' : 'ar';
    await _themeProvider.setLanguage(Locale(nextCode));
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final name = nextCode == 'ar' ? l10n.arabic : l10n.english;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.languageChanged(name),
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ProfileService.instance.getProfile();
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📋 PROFILE DATA IN SETTINGS');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ Profile loaded successfully');
        print('📦 Full profile data: $profile');
        print('📦 Profile keys: ${profile.keys.toList()}');
        print('📦 Profile type: ${profile.runtimeType}');
        print('');
        print('🔍 Checking name field:');
        print('  profile["name"]: ${profile['name']}');
        print('  profile["name"] type: ${profile['name']?.runtimeType}');
        print('  profile["name"] toString: ${profile['name']?.toString()}');
        print('  profile["name"] is null: ${profile['name'] == null}');
        print(
            '  profile["name"] isEmpty: ${profile['name']?.toString().isEmpty ?? true}');
        print('');
        print('🔍 Checking user field (nested):');
        print('  profile["user"]: ${profile['user']}');
        if (profile['user'] != null) {
          final user = profile['user'] as Map<String, dynamic>?;
          print('  profile["user"]["name"]: ${user?['name']}');
        }
        print('');
        print('🔍 Other relevant fields:');
        print('  profile["email"]: ${profile['email']}');
        print('  profile["studentType"]: ${profile['studentType']}');
        print('  profile["student_type"]: ${profile['student_type']}');
        print(
            '  profile["studentType"] type: ${profile['studentType']?.runtimeType}');
        print(
            '  profile["student_type"] type: ${profile['student_type']?.runtimeType}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      setState(() {
        _profile = profile;
        _isLoading = false;
      });

      if (kDebugMode) {
        print('✅ State updated with profile');
        print('  _profile["name"]: ${_profile?['name']}');
        print(
            '  Will display: ${_profile?['name']?.toString() ?? AppLocalizations.of(context)!.user}');
      }

      // Load QR code if user is offline
      // Check both studentType (camelCase) and student_type (snake_case)
      final studentType = profile['studentType']?.toString() ??
          profile['student_type']?.toString();
      if (kDebugMode) {
        print('🔍 Settings - Student Type Check:');
        print('  studentType: $studentType');
        print('  profile["studentType"]: ${profile['studentType']}');
        print('  profile["student_type"]: ${profile['student_type']}');
        print('  Will show QR Code: ${studentType == 'offline'}');
      }
      if (studentType == 'offline') {
        _loadQrCode();
      }
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ ERROR LOADING PROFILE IN SETTINGS');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('Error: $e');
        print('Error type: ${e.runtimeType}');
        print('Stack trace: ${StackTrace.current}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      setState(() => _isLoading = false);
    }
  }

  AppThemeExtension get _theme => AppThemeExtension.of(context);

  Future<void> _loadQrCode() async {
    setState(() {
      _isLoadingQrCode = true;
      _qrCodeError = null;
    });

    try {
      final qrCode = await QrCodeService.instance.getMyQrCode();
      if (kDebugMode) {
        print(
            '✅ QR code loaded in settings: ${qrCode.length > 20 ? qrCode.substring(0, 20) : qrCode}...');
      }
      setState(() {
        _qrCode = qrCode;
        _isLoadingQrCode = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading QR code in settings: $e');
      }
      setState(() {
        _qrCodeError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingQrCode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _theme.scaffoldBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: _theme.icon,
          ),
        ),
      );
    }

    // Get student type for conditional rendering
    final studentType = _profile?['studentType']?.toString() ??
        _profile?['student_type']?.toString();

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 SETTINGS UI - BUILD METHOD - Student Type Check');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('_profile is null: ${_profile == null}');
      if (_profile != null) {
        print('_profile keys: ${_profile!.keys.toList()}');
        print('_profile["studentType"]: ${_profile!['studentType']}');
        print('_profile["student_type"]: ${_profile!['student_type']}');
      }
      print('Final studentType: $studentType');
      print('Will show QR Code section: ${studentType == 'offline'}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    return Scaffold(
      backgroundColor: _theme.scaffoldBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header - Purple gradient like Home
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.headerGradient2,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.largeCard),
                  bottomRight: Radius.circular(AppRadius.largeCard),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16, // pt-4
                bottom: 32, // pb-8
                left: 16, // px-4
                right: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, // w-10
                      height: 40, // h-10
                      decoration: const BoxDecoration(
                        color: AppColors.whiteOverlay20, // bg-white/20
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20, // w-5 h-5
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // gap-4
                  Text(
                    AppLocalizations.of(context)!.settings,
                    style: AppTextStyles.h3(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content - matches React: px-4 -mt-4
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -16), // -mt-4
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile section - matches React: bg-white rounded-3xl p-5 mb-6
                      Container(
                        margin: const EdgeInsets.only(bottom: 24), // mb-6
                        padding: const EdgeInsets.all(20), // p-5
                        decoration: BoxDecoration(
                          color: _theme.card,
                          borderRadius:
                              BorderRadius.circular(24), // rounded-3xl
                          border: Border.all(color: _theme.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: _theme.shadow,
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar - matches React: w-16 h-16 rounded-full
                            Container(
                              width: 64, // w-16
                              height: 64, // h-16
                              decoration: BoxDecoration(
                                color: AppColors.goldPrimary
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _theme.cardAccentText
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: ClipOval(
                                child: _profile?['avatar'] != null
                                    ? Image.network(
                                        ApiEndpoints.getImageUrl(
                                          _profile!['avatar']?.toString(),
                                        ),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Image.asset(
                                          'assets/images/user-avatar.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.person,
                                            size: 32,
                                            color: context.appTheme.icon,
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        'assets/images/user-avatar.png',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          Icons.person,
                                          size: 32,
                                          color: context.appTheme.icon,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16), // gap-4
                            // User info - matches React: flex-1
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile?['name']?.toString() ??
                                        AppLocalizations.of(context)!.user,
                                    style: AppTextStyles.h3(
                                      color: _theme.cardTitle,
                                    ),
                                  ),
                                  Text(
                                    _profile?['email']?.toString() ?? '',
                                    style: AppTextStyles.bodyMedium(
                                      color: _theme.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit button - matches React: w-10 h-10 rounded-xl
                            GestureDetector(
                              onTap: () async {
                                final result = await context.push(
                                  RouteNames.editProfile,
                                  extra: _profile,
                                );
                                if (result == true && mounted) {
                                  _loadProfile();
                                }
                              },
                              child: Container(
                                width: 40, // w-10
                                height: 40, // h-10
                                decoration: BoxDecoration(
                                  color: context.appTheme.cardMuted,
                                  borderRadius:
                                      BorderRadius.circular(12), // rounded-xl
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 20, // w-5 h-5
                                  color: context.appTheme.icon,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Settings title - matches React: text-lg font-bold mb-4
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16), // mb-4
                        child: Text(
                          AppLocalizations.of(context)!.generalSettings,
                          style: AppTextStyles.h4(
                            color: _theme.foreground,
                          ),
                        ),
                      ),

                      // Language (tap to switch Arabic ↔ English)
                      _buildSettingItem(
                        icon: Icons.language_rounded,
                        label: AppLocalizations.of(context)!.language,
                        value: _themeProvider.locale.languageCode == 'ar'
                            ? AppLocalizations.of(context)!.arabic
                            : AppLocalizations.of(context)!.english,
                        onTap: _toggleLanguage,
                      ),

                      // Chat - teacher/student messaging
                      _buildSettingItem(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat',
                        onTap: () => context.push(RouteNames.chatConversations),
                      ),

                      _buildSettingItem(
                        icon: Icons.bookmark_rounded,
                        label: AppLocalizations.of(context)!.wishlistTitle,
                        onTap: () => context.push(RouteNames.bookmarkCourses),
                      ),

                      _buildSettingItem(
                        icon: Icons.receipt_long_rounded,
                        label:
                            AppLocalizations.of(context)!.myEnrollmentRequests,
                        onTap: () =>
                            context.push(RouteNames.myEnrollmentRequests),
                      ),

                      _buildSettingItem(
                        icon: Icons.dark_mode_rounded,
                        label: AppLocalizations.of(context)!.darkMode,
                        hasToggle: true,
                        toggleValue: _themeProvider.isDarkMode,
                        onToggle: () {
                          _themeProvider.toggleDarkMode();
                        },
                      ),

                      // Change Password setting
                      _buildSettingItem(
                        icon: Icons.lock,
                        label: AppLocalizations.of(context)!.changePassword,
                        onTap: () {
                          context.push(RouteNames.changePassword);
                        },
                      ),

                      // Privacy Policy (opens hosted web page)
                      _buildSettingItem(
                        icon: Icons.shield,
                        label: AppLocalizations.of(context)!.privacyAndSecurity,
                        onTap: () => LegalUrls.openPrivacy(context),
                      ),

                      // Help setting
                      _buildSettingItem(
                        icon: Icons.help,
                        label: AppLocalizations.of(context)!.helpAndSupport,
                        onTap: () => context.push(RouteNames.helpSupport),
                      ),

                      // QR Code Section for offline students only
                      if (studentType == 'offline') ...[
                        const SizedBox(height: 24),
                        _buildQrCodeSection(),
                      ],

                      const SizedBox(height: 32),
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

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    String? value,
    bool hasToggle = false,
    bool toggleValue = false,
    VoidCallback? onToggle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: hasToggle ? onToggle : (onTap ?? () {}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), // mb-3
        padding: const EdgeInsets.all(16), // p-4
        decoration: BoxDecoration(
          color: context.appTheme.card,
          borderRadius: BorderRadius.circular(16), // rounded-2xl
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon and label - matches React: gap-3
            Row(
              children: [
                Container(
                  width: 40, // w-10
                  height: 40, // h-10
                  decoration: BoxDecoration(
                    color: context.appTheme.cardMuted,
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                  ),
                  child: Icon(
                    icon,
                    size: 20, // w-5 h-5
                    color: context.appTheme.icon,
                  ),
                ),
                const SizedBox(width: 12), // gap-3
                Text(
                  label,
                  style: AppTextStyles.bodyMedium(
                    color: _theme.foreground,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),

            // Value or toggle
            if (hasToggle)
              // Toggle switch - matches React custom toggle
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 48, // w-12
                  height: 28, // h-7
                  padding: const EdgeInsets.all(4), // p-1
                  decoration: BoxDecoration(
                    color:
                        toggleValue ? AppColors.goldPrimary : AppColors.muted,
                    borderRadius: BorderRadius.circular(999), // rounded-full
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: toggleValue
                        ? Alignment.centerLeft // RTL: toggle moves left when on
                        : Alignment.centerRight,
                    child: Container(
                      width: 20, // w-5
                      height: 20, // h-5
                      decoration: BoxDecoration(
                        color: context.appTheme.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  if (value != null)
                    Text(
                      value,
                      style: AppTextStyles.bodySmall(
                        color: _theme.mutedForeground,
                      ),
                    ),
                  const SizedBox(width: 8), // gap-2
                  Icon(
                    Icons.chevron_left,
                    size: 20, // w-5 h-5
                    color: _theme.mutedForeground,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _theme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _theme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: _theme.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.appTheme.cardMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 20,
                  color: context.appTheme.icon,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.centerAttendance,
                style: AppTextStyles.h4(
                  color: _theme.cardTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            l10n.centerAttendanceDescription,
            style: AppTextStyles.bodyMedium(
              color: _theme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // QR Code or Loading/Error
          if (_isLoadingQrCode)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: context.appTheme.icon,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.loadingQrCode,
                      style: AppTextStyles.bodySmall(
                        color: _theme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_qrCodeError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: _theme.icon,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.errorLoadingQrCode,
                      style: AppTextStyles.bodyMedium(
                        color: _theme.cardTitle,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _qrCodeError!,
                      style: AppTextStyles.bodySmall(
                        color: _theme.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loadQrCode,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(l10n.retry),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyDeep,
                        side: BorderSide(color: context.appTheme.icon),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_qrCode != null)
            Center(
              child: Column(
                children: [
                  // QR Code Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _theme.cardMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _theme.cardAccentText.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: QrImageView(
                      data: _qrCode!,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.navyDeep,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Instruction
                  Text(
                    l10n.scanQrCodeInstruction,
                    style: AppTextStyles.bodySmall(
                      color: _theme.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Refresh Button
                  OutlinedButton.icon(
                    onPressed: _loadQrCode,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.refreshQrCode),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyDeep,
                      side: BorderSide(color: context.appTheme.icon),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
