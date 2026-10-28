import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_theme_extension.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_radius.dart';
import '../../core/navigation/route_names.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/localization/localization_helper.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/premium_course_card.dart';
import '../../widgets/home_spot_videos_row.dart';
import '../../services/home_service.dart';
import '../../services/sliders_service.dart';
import '../../services/profile_service.dart';
import '../../services/notifications_service.dart';
import '../../services/teachers_service.dart';
import '../../l10n/app_localizations.dart';
import '../../data/sample_teachers.dart';

/// Home Screen — promo slider, stats, teachers, course discovery.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppThemeExtension get _appTheme => AppThemeExtension.of(context);

  final _searchController = TextEditingController();

  // API Data
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;
  int _notificationsCount = 0;
  List<Map<String, dynamic>> _featuredCourses = [];
  List<Map<String, dynamic>> _popularCourses = [];
  List<Map<String, dynamic>> _continueLearning = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _sliders = [];
  List<Map<String, dynamic>> _homeSpotVideos = [];

  ShimmerEffect get _homeShimmerEffect => ShimmerEffect(
        baseColor: _appTheme.skeletonBase,
        highlightColor: _appTheme.skeletonHighlight,
        begin: const AlignmentDirectional(-1.0, 0.0),
        end: const AlignmentDirectional(1.0, 0.0),
        duration: const Duration(milliseconds: 1500),
      );

  Widget _wrapHomeSkeleton({
    required Widget child,
    PaintingEffect? effect,
    Color? containersColor,
  }) {
    return Skeletonizer(
      enabled: true,
      effect: effect ?? _homeShimmerEffect,
      containersColor: containersColor ?? _appTheme.skeletonContainer,
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final slidersFuture = SlidersService.instance.getSliders();
    try {
      // Load home data (sliders fetch runs in parallel)
      final homeData = await HomeService.instance.getHomeData();
      final sliders = await slidersFuture;

      // Load user profile if logged in
      try {
        final profile = await ProfileService.instance.getProfile();
        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('🖼️ HOME SCREEN - PROFILE AVATAR');
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
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
        if (mounted) {
          setState(() => _userProfile = profile);
        }
      } catch (e) {
        // User might not be logged in, continue
        if (kDebugMode) {
          print('❌ Error loading profile in home screen: $e');
        }
      }

      // Load notifications count if logged in
      try {
        final notifications =
            await NotificationsService.instance.getNotifications(
          unreadOnly: true,
          perPage: 1,
        );
        if (mounted) {
          setState(
            () => _notificationsCount =
                notifications['meta']?['unread_count'] ?? 0,
          );
        }
      } catch (e) {
        // User might not be logged in, continue
      }

      // Load teachers from API
      List<Map<String, dynamic>> teachers = [];
      try {
        final teachersResponse = await TeachersService.instance.getTeachers(
          page: 1,
          perPage: 10, // Load first 10 teachers for the slider
          sort: 'rating',
        );
        final data = teachersResponse['data'];
        if (data is Map<String, dynamic> && data['teachers'] != null) {
          teachers = List<Map<String, dynamic>>.from(data['teachers']);
        } else if (data is List) {
          teachers = List<Map<String, dynamic>>.from(data);
        }
      } catch (e) {
        // Fallback to sample teachers if API fails
        teachers = List<Map<String, dynamic>>.from(kSampleTeachers);
      }

      if (!mounted) return;
      setState(() {
        _sliders = sliders;
        _featuredCourses = List<Map<String, dynamic>>.from(
          homeData['featured_courses'] ?? [],
        );
        _popularCourses = List<Map<String, dynamic>>.from(
          homeData['popular_courses'] ?? [],
        );
        _continueLearning = List<Map<String, dynamic>>.from(
          homeData['continue_learning'] ?? [],
        );
        _categories = List<Map<String, dynamic>>.from(
          homeData['categories'] ?? [],
        );
        _teachers = teachers;
        _homeSpotVideos = List<Map<String, dynamic>>.from(
          homeData['home_spot_videos'] ?? [],
        );
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      List<Map<String, dynamic>> slidersOnErr = [];
      try {
        slidersOnErr = await slidersFuture;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _featuredCourses = [];
        _popularCourses = [];
        _continueLearning = [];
        _categories = [];
        _sliders = slidersOnErr;
        _homeSpotVideos = [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _allCourses =>
      [..._featuredCourses, ..._popularCourses, ..._continueLearning];

  void _handleTeacherTap(Map<String, dynamic> teacher) {
    if (!mounted) return;
    context.push(RouteNames.teacherDetails, extra: teacher);
  }

  void _handleCourseClick(Map<String, dynamic> course) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('hasLaunched') ?? false;
    final isFree = course['isFree'] == true || course['is_free'] == true;

    if (!isFree && !isLoggedIn) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.loginRequired),
            content: Text(l10n.loginRequired),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid),
                child: Text(l10n.login,
                    style: const TextStyle(color: AppColors.brandWhite)),
              ),
            ],
          ),
        );
        if (result == true && mounted) {
          context.push(RouteNames.login);
        }
      }
      return;
    }

    if (mounted) {
      context.push(RouteNames.courseDetails, extra: course);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
    );

    final statusBarHeight = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _appTheme.scaffoldBackground,
      body: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 430),
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width > 430
                  ? (MediaQuery.of(context).size.width - 430) / 2
                  : 0,
            ),
            child: Column(
              children: [
                // Enhanced Header
                _buildHeader(statusBarHeight),
                const SizedBox(height: 15),

                if (_isLoading && _errorMessage == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: _appTheme.progressTrack,
                        color: _appTheme.icon,
                      ),
                    ),
                  ),

                // Content
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: _errorMessage != null
                        ? RefreshIndicator(
                            color: _appTheme.icon,
                            onRefresh: () => _loadHomeData(),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: BouncingScrollPhysics(),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: _buildErrorView(),
                                  ),
                                );
                              },
                            ),
                          )
                        : RefreshIndicator(
                            color: _appTheme.icon,
                            onRefresh: () => _loadHomeData(),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isLoading)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 0),
                                      child: _buildPromoSliderSkeleton(),
                                    )
                                  else if (_sliders.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 0),
                                      child: _buildPromoCarousel(),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 0),
                                      child: _buildPromoSliderEmpty(),
                                    ),
                                  SizedBox(height: 20),

                                  // Home spot videos (dashboard-controlled; replaces stat cards)
                                  if (_isLoading)
                                    const HomeSpotVideosRowSkeleton()
                                  else if (_homeSpotVideos.isNotEmpty)
                                    HomeSpotVideosRow(videos: _homeSpotVideos),

                                  if (_isLoading || _homeSpotVideos.isNotEmpty)
                                    const SizedBox(height: 24),

                                  // Teachers slider
                                  _buildSectionHeader(l10n.teachers, () {
                                    context.push(
                                      RouteNames.teachers,
                                      extra: _teachers,
                                    );
                                  }),
                                  const SizedBox(height: 16),
                                  if (_isLoading && _teachers.isEmpty)
                                    _buildTeachersSliderSkeleton()
                                  else
                                    _buildTeachersSlider(l10n),

                                  const SizedBox(height: 28),

                                  // Featured Courses
                                  if (_isLoading) ...[
                                    _buildSectionHeader(
                                        AppLocalizations.of(context)!
                                            .featuredCourses,
                                        () {}),
                                    const SizedBox(height: 16),
                                    _buildFeaturedCoursesSkeleton(),
                                    const SizedBox(height: 28),
                                  ] else if (_featuredCourses.isNotEmpty) ...[
                                    _buildSectionHeader(
                                        AppLocalizations.of(context)!
                                            .featuredCourses, () {
                                      context.push(RouteNames.allCourses);
                                    }),
                                    const SizedBox(height: 16),
                                    _buildFeaturedCourses(),
                                    const SizedBox(height: 28),
                                  ],

                                  // Categories — temporarily hidden
                                  // if (_isLoading) ...[
                                  //   _buildSectionHeader(
                                  //       AppLocalizations.of(context)!.categories,
                                  //       () {}),
                                  //   const SizedBox(height: 16),
                                  //   _buildCategoriesSkeleton(),
                                  //   const SizedBox(height: 28),
                                  // ] else if (_categories.isNotEmpty) ...[
                                  //   _buildSectionHeader(
                                  //       AppLocalizations.of(context)!.categories,
                                  //       () {
                                  //     context.push(RouteNames.categories);
                                  //   }),
                                  //   const SizedBox(height: 16),
                                  //   _buildCategories(),
                                  //   const SizedBox(height: 28),
                                  // ],

                                  // Continue Learning
                                  if (_isLoading) ...[
                                    _buildSectionHeader(
                                        AppLocalizations.of(context)!
                                            .continueLearning,
                                        () {}),
                                    const SizedBox(height: 16),
                                    _buildContinueLearningSkeleton(),
                                    const SizedBox(height: 28),
                                  ] else if (_continueLearning.isNotEmpty) ...[
                                    _buildSectionHeader(
                                        AppLocalizations.of(context)!
                                            .continueLearning, () {
                                      context.push(RouteNames.enrolled);
                                    }),
                                    const SizedBox(height: 16),
                                    _buildContinueLearning(),
                                    const SizedBox(height: 28),
                                  ],

                                  // Popular Courses
                                  if (_isLoading) ...[
                                    _buildSectionHeader(
                                        AppLocalizations.of(context)!
                                            .recommendedCourses,
                                        () {}),
                                    const SizedBox(height: 16),
                                    _buildRecommendedCoursesSkeleton(),
                                  ] else if (_popularCourses.isNotEmpty) ...[
                                    _buildSectionHeader(
                                        AppLocalizations.of(context)!
                                            .recommendedCourses, () {
                                      context.push(RouteNames.allCourses);
                                    }),
                                    const SizedBox(height: 16),
                                    _buildRecommendedCourses(),
                                  ],

                                  const SizedBox(height: 140),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Navigation
          const BottomNav(activeTab: 'home'),
        ],
      ),
    );
  }

  Widget _buildHeader(double statusBarHeight) {
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
            color: AppColors.navyDeep.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative educational icons - transparent
          Positioned(
            top: statusBarHeight + 60,
            right: 20,
            child: Icon(
              Icons.menu_book_rounded,
              size: 40,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            top: statusBarHeight + 30,
            left: 40,
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 30,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 60,
            child: Icon(
              Icons.science_outlined,
              size: 35,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            child: Icon(
              Icons.calculate_outlined,
              size: 28,
              color: Colors.white.withOpacity(0.06),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              top: statusBarHeight + 16,
              left: 20,
              right: 20,
              bottom: 56,
            ),
            child: Column(
              children: [
                // Top Row - Student Avatar, User & Notifications
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Student Avatar and welcome
                    Expanded(
                      child: Row(
                        children: [
                          // Student Avatar instead of logo
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _userProfile?['avatar'] != null
                                  ? Image.network(
                                      ApiEndpoints.getImageUrl(
                                        _userProfile!['avatar']?.toString(),
                                      ),
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.white,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.iconPrimary,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        if (kDebugMode) {
                                          print(
                                              '❌ Error loading avatar image: $error');
                                          print(
                                              '   Avatar URL: ${ApiEndpoints.getImageUrl(_userProfile!['avatar']?.toString())}');
                                          print('   Stack trace: $stackTrace');
                                        }
                                        return Image.asset(
                                          'assets/images/student-avatar.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: Colors.white,
                                            child: const Icon(
                                              Icons.person,
                                              color: AppColors.iconPrimary,
                                              size: 28,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/images/student-avatar.png',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        color: Colors.white,
                                        child: const Icon(
                                          Icons.person,
                                          color: AppColors.iconPrimary,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.welcome(
                                      _userProfile?['name']?.toString() ??
                                          AppLocalizations.of(context)!
                                              .visitor),
                                  style: GoogleFonts.readexPro(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star,
                                                color: AppColors.rating,
                                                size: 14),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .excellentStudent,
                                                style: GoogleFonts.readexPro(
                                                  fontSize: 11,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
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
                    ),
                    // Actions
                    Row(
                      children: [
                        // Settings
                        _buildHeaderButton(
                          icon: Icons.settings_outlined,
                          onTap: () => context.push(RouteNames.settings),
                        ),
                        const SizedBox(width: 8),
                        // Notifications with badge
                        _buildHeaderButton(
                          icon: Icons.notifications_none_rounded,
                          badge: _notificationsCount > 0
                              ? _notificationsCount.toString()
                              : null,
                          onTap: () => context.push(RouteNames.notifications),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Enhanced Oval Search Bar
                _buildSearchBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const double _promoSliderHeight = 176;

  Widget _buildPromoSliderSkeleton() {
    return _wrapHomeSkeleton(
      containersColor: _appTheme.promoEmptyFill,
      child: Container(
        height: _promoSliderHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _appTheme.card,
          borderRadius: BorderRadius.circular(AppRadius.largeCard),
        ),
      ),
    );
  }

  /// Loaded successfully but API returned no slider items.
  Widget _buildPromoSliderEmpty() {
    return Semantics(
      label: AppLocalizations.of(context)!.homePromoSliderEmpty,
      child: Container(
        height: _promoSliderHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _appTheme.promoEmptyFill,
          borderRadius: BorderRadius.circular(AppRadius.largeCard),
          border: Border.all(color: _appTheme.cardBorder, width: 1),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_carousel_outlined,
              size: 36,
              color: _appTheme.icon.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.homePromoSliderEmpty,
                textAlign: TextAlign.center,
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _appTheme.mutedForeground,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCarousel() {
    if (_sliders.isEmpty) return const SizedBox.shrink();

    final multi = _sliders.length > 1;

    return CarouselSlider(
      options: CarouselOptions(
        height: _promoSliderHeight,
        viewportFraction: 1,
        enableInfiniteScroll: multi,
        autoPlay: multi,
        autoPlayInterval: const Duration(seconds: 2),
        autoPlayAnimationDuration: const Duration(milliseconds: 700),
        autoPlayCurve: Curves.fastOutSlowIn,
        pauseAutoPlayOnTouch: true,
        scrollPhysics: const BouncingScrollPhysics(),
        enlargeCenterPage: false,
      ),
      items: _sliders.map((s) {
        final url = s['image']?.toString() ?? '';
        return Builder(
          builder: (context) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.largeCard),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: _promoSliderHeight,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: _appTheme.cardMuted,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _appTheme.icon,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: _appTheme.cardMuted,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: _appTheme.iconMuted.withValues(alpha: 0.6),
                    size: 40,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildHeaderButton(
      {required IconData icon, String? badge, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.badgeBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.readexPro(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.badgeForeground,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _appTheme.searchBarFill,
        borderRadius: BorderRadius.circular(30), // Oval shape
        border: Border.all(color: _appTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: _appTheme.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.readexPro(
          fontSize: 15,
          color: _appTheme.foreground,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchPlaceholder,
          hintStyle: GoogleFonts.readexPro(
            fontSize: 14,
            color: _appTheme.mutedForeground,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 20, left: 12),
            child: Icon(Icons.search_rounded, color: _appTheme.icon, size: 24),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.headerGradient2,
              ),
              borderRadius: BorderRadius.circular(20), // Oval suffix
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppColors.brandWhite, size: 18),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
        onTap: () {
          // Show search overlay
          _showSearchOverlay(context);
        },
        readOnly: true,
      ),
    );
  }

  void _showSearchOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _appTheme.sheetBackground,
      builder: (context) => _SearchOverlay(
        allCourses: _allCourses,
        onCourseSelected: (course) {
          Navigator.pop(context);
          _handleCourseClick(course);
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.readexPro(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _appTheme.foreground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _appTheme.progressTrack,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _appTheme.cardBorder, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.viewMore,
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _appTheme.foreground,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: _appTheme.icon),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersSlider(AppLocalizations l10n) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 8),
        itemCount: _teachers.length,
        itemBuilder: (context, index) {
          final teacher = _teachers[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _handleTeacherTap(teacher),
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _appTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.cardBorderDark,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _appTheme.shadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              AppColors.goldPrimary.withValues(alpha: 0.2),
                          backgroundImage: NetworkImage(
                            teacher['avatar']?.toString() ?? '',
                          ),
                          onBackgroundImageError: (_, __) {},
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacher['name']?.toString() ?? '',
                                style: GoogleFonts.readexPro(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _appTheme.cardTitle,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                teacher['title']?.toString() ?? '',
                                style: GoogleFonts.readexPro(
                                  fontSize: 12,
                                  color: _appTheme.cardAccentText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      teacher['bio']?.toString() ?? '',
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: _appTheme.cardMetaText.withValues(alpha: 0.85),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: _appTheme.icon),
                        const SizedBox(width: 4),
                        Text(
                          (teacher['rating'] ?? 0).toString(),
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _appTheme.cardMetaText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.people_alt_rounded,
                            size: 16, color: _appTheme.icon),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            l10n.studentsCount(
                                (teacher['students'] as int?) ?? 0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              color: _appTheme.cardMetaText
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.goldPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppColors.goldPrimary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            l10n.coursesCount(
                              (teacher['courses_count'] as int?) ??
                                  (teacher['courses'] as List?)?.length ??
                                  0,
                            ),
                            style: GoogleFonts.readexPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _appTheme.cardAccentText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTeachersSliderSkeleton() {
    return _wrapHomeSkeleton(
      child: SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 8),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _appTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _appTheme.cardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _appTheme.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: _appTheme.skeletonBase,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 14,
                                width: 80,
                                decoration: BoxDecoration(
                                  color: _appTheme.skeletonBase,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 12,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: _appTheme.skeletonBase,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _appTheme.skeletonBase,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 150,
                      decoration: BoxDecoration(
                        color: _appTheme.skeletonBase,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          height: 16,
                          width: 30,
                          decoration: BoxDecoration(
                            color: _appTheme.skeletonBase,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 16,
                          width: 50,
                          decoration: BoxDecoration(
                            color: _appTheme.skeletonBase,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 24,
                          width: 60,
                          decoration: BoxDecoration(
                            color: _appTheme.skeletonBase,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedCourses() {
    if (_featuredCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 285,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 8),
        itemCount: _featuredCourses.length,
        itemBuilder: (context, index) {
          final course = _featuredCourses[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PremiumCourseCard(
              course: course,
              useHomeCardStyle: true,
              onTap: () => _handleCourseClick(course),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: _appTheme.iconMuted,
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: GoogleFonts.readexPro(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _appTheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                fontSize: 14,
                color: _appTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _loadHomeData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'إعادة المحاولة',
                style: GoogleFonts.readexPro(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                foregroundColor: AppColors.brandWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return AppColors.goldPrimary;
    if (colorValue is Color) return colorValue;
    if (colorValue is String) {
      // Handle hex color strings like "#0E6DA3" or "0E6DA3"
      String hex = colorValue.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return AppColors.goldPrimary;
  }

  Widget _getCategoryIcon(dynamic iconValue, Color color) {
    if (iconValue == null) {
      return Icon(Icons.category, color: color, size: 26);
    }

    // If it's already an IconData, use it directly
    if (iconValue is IconData) {
      return Icon(iconValue, color: color, size: 26);
    }

    // If it's a string, map it to an IconData
    if (iconValue is String) {
      final iconMap = {
        'design_services': Icons.design_services,
        'code': Icons.code,
        'trending_up': Icons.trending_up,
        'analytics': Icons.analytics,
        'school': Icons.school,
        'computer': Icons.computer,
        'business': Icons.business,
        'science': Icons.science,
        'palette': Icons.palette,
        'language': Icons.language,
        'music_note': Icons.music_note,
        'fitness_center': Icons.fitness_center,
        'restaurant': Icons.restaurant,
        'local_movies': Icons.local_movies,
        'photo_camera': Icons.photo_camera,
        'briefcase': Icons.business_center,
        'book': Icons.menu_book,
        'calculate': Icons.calculate,
        'bolt': Icons.bolt,
      };

      // Try to find the icon by name (case-insensitive)
      final iconName = iconValue.toLowerCase().replaceAll(' ', '_');
      final iconData = iconMap[iconName];

      if (iconData != null) {
        return Icon(iconData, color: color, size: 26);
      }

      // If icon is a URL, try to load the image, fallback to default icon on error
      if (iconValue.startsWith('http://') ||
          iconValue.startsWith('https://') ||
          iconValue.startsWith('/')) {
        return Image.network(
          iconValue,
          width: 26,
          height: 26,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Return default icon on error, not an image
            return Icon(Icons.category, color: color, size: 26);
          },
        );
      }
    }

    // Default fallback
    return Icon(Icons.category, color: color, size: 26);
  }

  Widget _buildCategories() {
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final categoryColor = _parseColor(cat['color']);
            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
              child: GestureDetector(
                onTap: () {
                  final categoryId = cat['id']?.toString();
                  if (categoryId != null && categoryId.isNotEmpty) {
                    context.push(RouteNames.allCourses, extra: {
                      'categoryId': categoryId,
                      'categoryName': cat['name']?.toString() ??
                          cat['label']?.toString() ??
                          '',
                    });
                  } else {
                    context.push(RouteNames.allCourses);
                  }
                },
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _appTheme.cardMuted,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _getCategoryIcon(cat['icon'], categoryColor),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          cat['name'] ?? cat['label'] ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _appTheme.foreground,
                          ),
                        ),
                      ),
                      Text(
                        '${cat['courses_count'] ?? cat['count'] ?? 0} دورة',
                        style: GoogleFonts.readexPro(
                          fontSize: 10,
                          color: _appTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecommendedCourses() {
    if (_popularCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _popularCourses.take(4).map((course) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHorizontalCourseCard(course),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContinueLearning() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _continueLearning.take(4).map((course) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHorizontalCourseCard(course),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHorizontalCourseCard(Map<String, dynamic> course) {
    final isEnrolled = course['is_enrolled'] == true ||
        course['enrollment_status']?.toString().toLowerCase() == 'enrolled';
    final durationLabel = context.courseDurationLabel(course);

    return GestureDetector(
      onTap: () => _handleCourseClick(course),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _appTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorderDark, width: 1),
          boxShadow: [
            BoxShadow(
              color: _appTheme.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: course['thumbnail'] != null
                    ? Image.network(
                        course['thumbnail']?.toString() ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => course['image'] != null
                            ? Image.asset(
                                course['image']?.toString() ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _appTheme.progressTrack,
                                  child: Icon(Icons.image,
                                      color: _appTheme.icon, size: 30),
                                ),
                              )
                            : Container(
                                color: _appTheme.progressTrack,
                                child: Icon(Icons.image,
                                    color: _appTheme.icon, size: 30),
                              ),
                      )
                    : course['image'] != null
                        ? Image.asset(
                            course['image']?.toString() ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _appTheme.progressTrack,
                              child: Icon(Icons.image,
                                  color: _appTheme.icon, size: 30),
                            ),
                          )
                        : Container(
                            color: _appTheme.progressTrack,
                            child: Icon(Icons.image,
                                color: _appTheme.icon, size: 30),
                          ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                AppColors.goldPrimary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          course['category']?['name'] ??
                              course['category'] ??
                              '',
                          style: GoogleFonts.readexPro(
                              fontSize: 10,
                              color: _appTheme.cardAccentText,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      if ((course['is_free'] ?? course['isFree']) == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppColors.goldPrimary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.free,
                            style: GoogleFonts.readexPro(
                                fontSize: 10,
                                color: _appTheme.cardTitle,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course['title'] ?? '',
                    style: GoogleFonts.readexPro(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _appTheme.cardTitle,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course['instructor']?['name'] ?? course['instructor'] ?? '',
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      color: _appTheme.cardAccentText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: _appTheme.icon),
                      const SizedBox(width: 4),
                      Text(
                        '${course['rating'] ?? 0}',
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _appTheme.cardMetaText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.access_time_rounded,
                          size: 14, color: _appTheme.icon),
                      const SizedBox(width: 4),
                      Text(
                        durationLabel,
                        style: GoogleFonts.readexPro(
                          fontSize: 11,
                          color: _appTheme.cardMetaText.withValues(alpha: 0.85),
                        ),
                      ),
                      if (isEnrolled) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.people_rounded,
                            size: 14, color: _appTheme.icon),
                        const SizedBox(width: 4),
                        Text(
                          '${course['students_count'] ?? course['students'] ?? 0}',
                          style: GoogleFonts.readexPro(
                            fontSize: 11,
                            color:
                                _appTheme.cardMetaText.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Skeleton Loading Widgets
  Widget _buildFeaturedCoursesSkeleton() {
    return _wrapHomeSkeleton(
      child: SizedBox(
        height: 285,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 8),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 280,
                decoration: BoxDecoration(
                  color: _appTheme.cardMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: _appTheme.skeletonBase,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: _appTheme.skeletonBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _appTheme.skeletonBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              color: _appTheme.skeletonBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                height: 12,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: _appTheme.skeletonBase,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 12,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: _appTheme.skeletonBase,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesSkeleton() {
    return _wrapHomeSkeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _appTheme.cardMuted,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _appTheme.skeletonBase,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        width: 50,
                        decoration: BoxDecoration(
                          color: _appTheme.skeletonBase,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 10,
                        width: 40,
                        decoration: BoxDecoration(
                          color: _appTheme.skeletonBase,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContinueLearningSkeleton() {
    return _wrapHomeSkeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(2, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _appTheme.cardMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: _appTheme.skeletonBase,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 60,
                            decoration: BoxDecoration(
                              color: _appTheme.skeletonBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _appTheme.skeletonBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: _appTheme.skeletonBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                height: 10,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: _appTheme.skeletonBase,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 10,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: _appTheme.skeletonBase,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecommendedCoursesSkeleton() {
    return _wrapHomeSkeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _appTheme.cardMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: _appTheme.skeletonBase,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 60,
                            decoration: BoxDecoration(
                              color: _appTheme.skeletonBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _appTheme.skeletonBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: _appTheme.skeletonBase,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                height: 10,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: _appTheme.skeletonBase,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 10,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: _appTheme.skeletonBase,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// Search Overlay Widget
class _SearchOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> allCourses;
  final Function(Map<String, dynamic>) onCourseSelected;

  const _SearchOverlay({
    required this.allCourses,
    required this.onCourseSelected,
  });

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  AppThemeExtension get _appTheme => AppThemeExtension.of(context);

  final _searchController = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> get _filteredCourses {
    if (_query.isEmpty) return widget.allCourses;
    return widget.allCourses.where((course) {
      final title = course['title']?.toString() ?? '';
      final instructor = course['instructor'] is Map
          ? (course['instructor'] as Map)['name']?.toString() ?? ''
          : course['instructor']?.toString() ?? '';
      final category = course['category'] is Map
          ? (course['category'] as Map)['name']?.toString() ?? ''
          : course['category']?.toString() ?? '';

      return title.contains(_query) ||
          instructor.contains(_query) ||
          category.contains(_query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: _appTheme.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _appTheme.skeletonBase,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: _appTheme.searchBarFill,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  color: _appTheme.foreground,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchPlaceholder,
                  hintStyle: GoogleFonts.readexPro(
                    fontSize: 14,
                    color: _appTheme.mutedForeground,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(right: 16, left: 12),
                    child: Icon(Icons.search_rounded, color: _appTheme.icon),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _filteredCourses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: _appTheme.skeletonBase),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noResultsFound,
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            color: _appTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = _filteredCourses[index];
                      return GestureDetector(
                        onTap: () => widget.onCourseSelected(course),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _appTheme.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.cardBorderDark,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (course['thumbnail'] != null ||
                                        course['image'] != null)
                                    ? Image.network(
                                        course['thumbnail']?.toString() ?? '',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            course['image'] != null
                                                ? Image.asset(
                                                    course['image']
                                                            ?.toString() ??
                                                        '',
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: _appTheme.icon
                                                          .withOpacity(0.1),
                                                      child: Icon(Icons.image,
                                                          color:
                                                              _appTheme.icon),
                                                    ),
                                                  )
                                                : Container(
                                                    width: 60,
                                                    height: 60,
                                                    color: _appTheme.icon
                                                        .withOpacity(0.1),
                                                    child: Icon(Icons.image,
                                                        color: _appTheme.icon),
                                                  ),
                                      )
                                    : course['image'] != null
                                        ? Image.asset(
                                            course['image']?.toString() ?? '',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                              width: 60,
                                              height: 60,
                                              color: _appTheme.icon
                                                  .withOpacity(0.1),
                                              child: Icon(Icons.image,
                                                  color: _appTheme.icon),
                                            ),
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color:
                                                _appTheme.icon.withOpacity(0.1),
                                            child: Icon(Icons.image,
                                                color: _appTheme.icon),
                                          ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course['title']?.toString() ?? '',
                                      style: GoogleFonts.readexPro(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _appTheme.cardTitle,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      course['instructor'] is Map
                                          ? (course['instructor']
                                                      as Map)['name']
                                                  ?.toString() ??
                                              ''
                                          : course['instructor']?.toString() ??
                                              '',
                                      style: GoogleFonts.readexPro(
                                        fontSize: 12,
                                        color: _appTheme.cardAccentText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (course['isFree'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.chipSuccessBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.free,
                                    style: GoogleFonts.readexPro(
                                      fontSize: 11,
                                      color: AppColors.chipSuccessForeground,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// 1- وفيها زرار عرض المزيد تدخلك علي صفحه كل المعلمين  اعمل سلايدر المعلمون
// 2- لو ضغط علي اي معلم يفتح صفحه سينجل للمدرس تعرض الصوره واسمو بشكل رايق ونبذه عنو وتحتها كورساتو
