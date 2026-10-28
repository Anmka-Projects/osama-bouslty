import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, TileMode;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../services/token_storage_service.dart';
import '../../services/fcm_registration_service.dart';
import '../../l10n/app_localizations.dart';

/// Splash Screen - Premium & Elegant Design with Smart Idea
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _contentController;
  late AnimationController _glowController;
  late AnimationController _line1Controller;
  late AnimationController _line2Controller;
  late AnimationController _line3Controller;
  late AnimationController _loadingController;

  // Logo
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;

  // Line 1 — elastic pop
  late Animation<double> _line1Opacity;
  late Animation<double> _line1Scale;
  late Animation<double> _line1Blur;

  // Line 2 — horizontal reveal from center
  late Animation<double> _line2Opacity;
  late Animation<double> _line2Reveal;
  late Animation<double> _line2ScaleY;

  // Line 3 — rise + stretch
  late Animation<double> _line3Opacity;
  late Animation<double> _line3SlideY;
  late Animation<double> _line3ScaleX;

  late Animation<double> _glowAnimation;
  late Animation<double> _bottomFade;

  // Smart idea: Educational tips that rotate
  int _currentTipIndex = 0;
  List<Map<String, dynamic>> get _educationalTips {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'icon': Icons.lightbulb_outline, 'text': l10n.science},
      {'icon': Icons.trending_up, 'text': l10n.everyDayNewOpportunity},
      {'icon': Icons.emoji_events_outlined, 'text': l10n.success},
    ];
  }

  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    // Content animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoRotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _line1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _line1Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _line1Controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _line1Scale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _line1Controller,
        curve: Curves.elasticOut,
      ),
    );
    _line1Blur = Tween<double>(begin: 8, end: 0).animate(
      CurvedAnimation(
        parent: _line1Controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _line2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _line2Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _line2Controller,
        curve: const Interval(0.15, 0.75, curve: Curves.easeOut),
      ),
    );
    _line2Reveal = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _line2Controller,
        curve: Curves.easeInOutCubic,
      ),
    );
    _line2ScaleY = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _line2Controller,
        curve: Curves.easeOutBack,
      ),
    );

    _line3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _line3Opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _line3Controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );
    _line3SlideY = Tween<double>(begin: 36, end: 0).animate(
      CurvedAnimation(
        parent: _line3Controller,
        curve: Curves.easeOutCubic,
      ),
    );
    _line3ScaleX = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _line3Controller,
        curve: Curves.easeOutBack,
      ),
    );

    _bottomFade = _line3Opacity;

    // Glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );

    // Loading animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
  }

  void _startAnimations() async {
    // Same stagger as before (300ms + 800ms) without book overlay
    await Future.delayed(const Duration(milliseconds: 1100));
    _contentController.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    await _line1Controller.forward();

    await Future.delayed(const Duration(milliseconds: 220));
    await _line2Controller.forward();

    await Future.delayed(const Duration(milliseconds: 220));
    await _line3Controller.forward();

    _loadingController.forward();

    // Start rotating tips
    _tipTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _educationalTips.length;
        });
      }
    });

    // Navigate after animation
    Timer(const Duration(milliseconds: 5200), () {
      _checkFirstLaunch();
    });
  }

  Future<void> _checkFirstLaunch() async {
    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🚀 SPLASH SCREEN - ROUTING');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    if (!mounted) return;

    // Check if logged in and route by role
    final isLoggedIn = await TokenStorageService.instance.isLoggedIn();
    if (!isLoggedIn) {
      if (kDebugMode) {
        print('🔓 Not logged in, going to login');
      }
      context.go(RouteNames.login);
      return;
    }

    unawaited(FcmRegistrationService.syncCurrentDeviceToken());

    final role = await TokenStorageService.instance.getUserRole();
    final roleLower = role?.toLowerCase() ?? 'student';
    if (kDebugMode) {
      print('✅ User has launched before, role: $roleLower');
    }
    if (roleLower == 'instructor' || roleLower == 'teacher') {
      context.go(RouteNames.instructorHome);
    } else {
      context.go(RouteNames.home);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _glowController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _line3Controller.dispose();
    _loadingController.dispose();
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.headerGradient3,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background Pattern
            _buildBackgroundPattern(size),

            // Floating Particles
            ...List.generate(15, (i) => _buildFloatingParticle(i, size)),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo Section with Book Animation
                  _buildLogoSection(),

                  const SizedBox(height: 40),

                  // Branded headline
                  _buildBrandedHeadline(),

                  const Spacer(flex: 1),

                  // Educational Tip - Smart Idea
                  _buildEducationalTip(),

                  const SizedBox(height: 40),

                  // Loading Progress
                  _buildLoadingSection(),

                  const Spacer(flex: 1),

                  // Bottom Branding
                  _buildBottomBranding(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern(Size size) {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -size.width * 0.3,
          right: -size.width * 0.3,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1 * _glowAnimation.value),
                      Colors.white.withOpacity(0),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom left circle
        Positioned(
          bottom: -size.width * 0.2,
          left: -size.width * 0.2,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.brandSaffron
                          .withValues(alpha: 0.15 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingParticle(int index, Size size) {
    final random = math.Random(index);
    final particleSize = random.nextDouble() * 6 + 3;
    final startX = random.nextDouble() * size.width;
    final startY = random.nextDouble() * size.height;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final offset =
            math.sin(_glowController.value * math.pi * 2 + index) * 20;
        return Positioned(
          left: startX + offset,
          top: startY + offset * 0.5,
          child: Container(
            width: particleSize,
            height: particleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.3 + _glowAnimation.value * 0.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_contentController, _glowController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 200 * _logoScaleAnimation.value,
              height: 200 * _logoScaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2 * _glowAnimation.value),
                  width: 2,
                ),
              ),
            ),
            // Middle glow ring
            Container(
              width: 170 * _logoScaleAnimation.value,
              height: 170 * _logoScaleAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.15 * _glowAnimation.value),
                  width: 1,
                ),
              ),
            ),
            // Glow effect
            Container(
              width: 160 * _glowAnimation.value,
              height: 160 * _glowAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Logo Container
            Transform.scale(
              scale: _logoScaleAnimation.value,
              child: Transform.rotate(
                angle: _logoRotateAnimation.value,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Image.asset(
                      'assets/images/brand/symbol.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.brandSaffron,
                              AppColors.accentInk,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Sparkle Badge
            Positioned(
              top: 0,
              right: 60,
              child: Transform.scale(
                scale: _logoScaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.darkAccentHover, AppColors.brandSaffron],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandSaffron.withValues(alpha: 0.5),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBrandedHeadline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          _buildLine1Animation(),
          const SizedBox(height: 14),
          _buildLine2Animation(),
          const SizedBox(height: 10),
          _buildLine3Animation(),
        ],
      ),
    );
  }

  /// Line 1: hero pop — scale + fade + soft blur dissolve.
  Widget _buildLine1Animation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_line1Controller, _glowController]),
      builder: (context, child) {
        final sigma = _line1Blur.value.clamp(0.0, 12.0);
        return Opacity(
          opacity: _line1Opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _line1Scale.value.clamp(0.0, 1.12),
            alignment: Alignment.center,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
                tileMode: TileMode.decal,
              ),
              child: child,
            ),
          ),
        );
      },
      child: Image.asset(
        'assets/images/brand/logo-ar-reverse.png',
        height: 68,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Line 2: cinematic wipe — expands from center horizontally.
  Widget _buildLine2Animation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_line2Controller, _glowController]),
      builder: (context, child) {
        return Opacity(
          opacity: _line2Opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scaleY: _line2ScaleY.value.clamp(0.0, 1.08),
            alignment: Alignment.center,
            child: ClipRect(
              child: Align(
                alignment: Alignment.center,
                widthFactor: _line2Reveal.value.clamp(0.0, 1.0),
                child: child,
              ),
            ),
          ),
        );
      },
      child: _brandGradientText(
        'المعلّم المناسب، والاتجاه الصحيح.',
        style: GoogleFonts.alexandria(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
        glowStrength: _glowAnimation.value * 0.85,
      ),
    );
  }

  /// Line 3: tagline rises from below with horizontal stretch.
  Widget _buildLine3Animation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_line3Controller, _glowController]),
      builder: (context, child) {
        return Opacity(
          opacity: _line3Opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _line3SlideY.value),
            child: Transform.scale(
              scaleX: _line3ScaleX.value.clamp(0.0, 1.08),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
      child: _brandGradientText(
        'THE RIGHT TUTOR · THE RIGHT DIRECTION',
        accent: true,
        style: GoogleFonts.readexPro(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.8,
          height: 1.3,
        ),
        glowStrength: _glowAnimation.value * 0.7,
      ),
    );
  }

  Widget _brandGradientText(
    String text, {
    required TextStyle style,
    double glowStrength = 1,
    bool accent = false,
  }) {
    final Color highlight =
        accent ? AppColors.brandSaffron : AppColors.brandSand;
    final Color mid = accent ? AppColors.brandSaffron : AppColors.brandSand;
    final Color low = accent ? AppColors.accentHover : AppColors.brandSandDeep;
    final baseStyle = style.copyWith(
      color: Colors.white,
      shadows: [
        Shadow(
          color: highlight.withValues(alpha: 0.4 * glowStrength),
          blurRadius: 14,
          offset: const Offset(0, 2),
        ),
        Shadow(
          color: highlight.withValues(alpha: 0.25 * glowStrength),
          blurRadius: 22,
        ),
      ],
    );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(
              highlight,
              mid,
              glowStrength * 0.12,
            )!,
            mid,
            Color.lerp(
              mid,
              low,
              0.2 + glowStrength * 0.08,
            )!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: baseStyle,
      ),
    );
  }

  Widget _buildEducationalTip() {
    final tip = _educationalTips[_currentTipIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_currentTipIndex),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tip['icon'] as IconData,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                tip['text'] as String,
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Column(
          children: [
            // Custom loading indicator
            Container(
              width: 180,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: _loadingController.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.darkAccentHover, AppColors.brandSaffron],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Loading dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    final delay = index * 0.3;
                    final value = ((_glowController.value + delay) % 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.4 + value * 0.6),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBranding() {
    return AnimatedBuilder(
      animation: _line3Controller,
      builder: (context, child) {
        return Opacity(
          opacity: (_bottomFade.value * 0.7).clamp(0.0, 1.0),
          child: child,
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 16,
                color: Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.certifiedAndSecure,
                style: GoogleFonts.readexPro(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'v1.0.0',
            style: GoogleFonts.readexPro(
              fontSize: 10,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
