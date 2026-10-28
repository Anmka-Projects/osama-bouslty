import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../services/qr_code_service.dart';
import '../../services/profile_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_theme_extension.dart';
import '../../core/design/brand_ui.dart';

/// Center Attendance Screen - Display QR Code and Student Stats
class CenterAttendanceScreen extends StatefulWidget {
  const CenterAttendanceScreen({super.key});

  @override
  State<CenterAttendanceScreen> createState() => _CenterAttendanceScreenState();
}

class _CenterAttendanceScreenState extends State<CenterAttendanceScreen> {
  AppThemeExtension get _theme => AppThemeExtension.of(context);

  bool _isLoading = true;
  bool _isLoadingProfile = true;
  String? _qrCode;
  String? _error;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load both QR code and profile in parallel
    await Future.wait([
      _loadQrCode(),
      _loadProfile(),
    ]);
  }

  Future<void> _loadQrCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final qrCode = await QrCodeService.instance.getMyQrCode();
      if (kDebugMode) {
        print(
            '✅ QR code loaded: ${qrCode.length > 20 ? qrCode.substring(0, 20) : qrCode}...');
      }
      setState(() {
        _qrCode = qrCode;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading QR code: $e');
      }
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final profile = await ProfileService.instance.getProfile();
      if (kDebugMode) {
        print('✅ Profile loaded: ${profile['name']}');
      }
      setState(() {
        _profile = profile;
        _statistics = profile['statistics'] as Map<String, dynamic>?;
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading profile: $e');
      }
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    BrandUi.applyStatusBar(context);

    final l10n = AppLocalizations.of(context)!;

    final enrolledCourses = _statistics?['enrolled_courses'] ?? 0;
    final certificates = _statistics?['certificates_earned'] ?? 0;
    final totalHours = _statistics?['total_learning_hours'] ?? 0;

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Profile and Stats
            _buildHeader(context, l10n, enrolledCourses, certificates, totalHours),

            // Content
            Expanded(
              child: _isLoading || _isLoadingProfile
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: _theme.icon),
                          const SizedBox(height: 16),
                          Text(
                            l10n.loadingQrCode,
                            style: GoogleFonts.readexPro(
                              fontSize: 14,
                              color: _theme.cardMetaText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _error != null
                      ? _buildErrorState(context, l10n)
                      : _buildContent(context, l10n, enrolledCourses, certificates, totalHours),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    int enrolledCourses,
    int certificates,
    int totalHours,
  ) {
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
            color: _theme.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            // Top Row with Back and Refresh
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.centerAttendance,
                    style: GoogleFonts.readexPro(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _loadData,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Profile Section
            Row(
              children: [
                // Avatar
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
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
                            _profile!['avatar']?.toString() ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 35,
                                color: context.appTheme.icon,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 35,
                              color: context.appTheme.icon,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // Name and Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile?['name']?.toString() ?? l10n.user,
                        style: GoogleFonts.readexPro(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile?['email']?.toString() ?? '',
                        style: GoogleFonts.readexPro(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    '$enrolledCourses',
                    l10n.course,
                    Icons.play_circle_fill_rounded,
                  ),
                  Container(
                    width: 1,
                    height: 25,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStat(
                    '$certificates',
                    l10n.certificates,
                    Icons.emoji_events_rounded,
                  ),
                  Container(
                    width: 1,
                    height: 25,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStat(
                    '$totalHours',
                    l10n.hour,
                    Icons.access_time_filled_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.readexPro(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.readexPro(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: _theme.icon,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.errorLoadingQrCode,
              style: GoogleFonts.readexPro(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _theme.cardTitle,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? l10n.unknownError,
              style: GoogleFonts.readexPro(
                fontSize: 14,
                color: _theme.cardMetaText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _theme.icon,
                foregroundColor: AppColors.navyDeep,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.retry,
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    int enrolledCourses,
    int certificates,
    int totalHours,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
          color: _theme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _theme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: _theme.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 48,
                  color: _theme.icon,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.centerAttendanceDescription,
                  style: GoogleFonts.readexPro(
                    fontSize: 14,
                    color: _theme.cardMetaText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // QR Code Card
          Container(
            padding: const EdgeInsets.all(32),
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
              children: [
                // QR Code
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
                    data: _qrCode ?? '',
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.navyDeep,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions
                Text(
                  l10n.scanQrCodeInstruction,
                  style: GoogleFonts.readexPro(
                    fontSize: 13,
                    color: _theme.cardMetaText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Refresh Button
          OutlinedButton.icon(
            onPressed: _loadQrCode,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(
              l10n.refreshQrCode,
              style: GoogleFonts.readexPro(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navyDeep,
              side: BorderSide(color: _theme.icon, width: 1.5),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
