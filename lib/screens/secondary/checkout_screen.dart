import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/courses/course_pricing_utils.dart';
import '../../core/live/live_lesson_utils.dart';
import '../../core/config/course_payment_methods_ui.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/design/app_radius.dart';
import '../../models/app_config.dart';
import '../../services/app_config_service.dart';
import '../../services/payments_service.dart';
import '../../core/skill_track/skill_track_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_theme_extension.dart';

/// Checkout Screen - Pixel-perfect match to React version
/// Matches: components/screens/checkout-screen.tsx
class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? course;

  /// When set, this checkout purchases a single live lesson instead of the
  /// whole course (`item_type: lesson` + `lesson_id` — see
  /// `docs/LIVE_LESSONS_BACKEND.md`).
  final Map<String, dynamic>? lesson;
  final String? initialPaymentMethod;

  const CheckoutScreen({
    super.key,
    this.course,
    this.lesson,
    this.initialPaymentMethod,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  AppThemeExtension get _theme => AppThemeExtension.of(context);

  String? _selectedPayment;
  String _couponCode = '';
  bool _couponApplied = false;
  bool _isProcessing = false;
  bool _isValidatingCoupon = false;
  String? _checkoutSessionId;
  AppConfig? _appConfig;
  bool _paymentConfigLoading = true;

  final _bankAccountHolderController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankTransferReferenceController = TextEditingController();

  // Pricing from API
  double _originalPrice = 0.0;
  double _discountAmount = 0.0;
  double _finalPrice = 0.0;
  String _currencyCode = 'EGP';

  @override
  void initState() {
    super.initState();
    _selectedPayment = widget.initialPaymentMethod;
    _loadInitialPrice();
    _loadPaymentConfig();
  }

  Future<void> _loadPaymentConfig() async {
    setState(() => _paymentConfigLoading = true);
    final config = await AppConfigService.instance.fetchAppConfig();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final methods = CoursePaymentMethodsUi.availableMethods(config, l10n);
    final ids = methods.map((m) => m['id'] as String).toSet();
    String? next = _selectedPayment;
    if (next == null || !ids.contains(next)) {
      next = methods.isEmpty ? null : methods.first['id'] as String;
    }
    setState(() {
      _appConfig = config;
      _paymentConfigLoading = false;
      _selectedPayment = next;
    });
  }

  @override
  void dispose() {
    _bankAccountHolderController.dispose();
    _bankAccountNumberController.dispose();
    _bankTransferReferenceController.dispose();
    super.dispose();
  }

  void _loadInitialPrice() {
    final rawCurrency =
        widget.course?['currency']?.toString().trim().toUpperCase();
    _currencyCode = rawCurrency?.isNotEmpty == true ? rawCurrency! : 'EGP';

    final lesson = widget.lesson;
    if (lesson != null) {
      _originalPrice = LiveLessonUtils.price(lesson);
      _finalPrice = _originalPrice;
      return;
    }

    final course = widget.course;
    if (course == null) {
      _originalPrice = 0;
      _finalPrice = 0;
      return;
    }

    final pricing = CoursePricingUtils.resolve(course);
    _originalPrice = pricing.displayPrice.toDouble();
    _finalPrice = _originalPrice;
  }

  String _formatAmount(double amount, {bool withMinus = false}) {
    final value = '${amount.toStringAsFixed(2)} $_currencyCode';
    return withMinus ? '-$value' : value;
  }

  Future<void> _handleApplyCoupon() async {
    if (_couponCode.isEmpty) return;

    final course = widget.course;
    if (course == null || course['id'] == null) return;

    final courseId = course['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    setState(() => _isValidatingCoupon = true);

    try {
      final result = await PaymentsService.instance.validateCoupon(
        code: _couponCode,
        courseId: courseId,
      );

      if (kDebugMode) {
        print('✅ Coupon validated: $result');
      }

      if (result['is_valid'] == true) {
        setState(() {
          _couponApplied = true;
          _discountAmount =
              (result['discount_amount'] as num?)?.toDouble() ?? 0.0;
          _finalPrice =
              (result['final_price'] as num?)?.toDouble() ?? _originalPrice;
          _isValidatingCoupon = false;
        });

        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ?? l10n.discountApplied,
                style: GoogleFonts.readexPro(),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        setState(() => _isValidatingCoupon = false);
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.invalidCouponCode,
                style: GoogleFonts.readexPro(),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error validating coupon: $e');
      }

      setState(() => _isValidatingCoupon = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('401') ||
                      e.toString().contains('Unauthorized')
                  ? l10n.loginRequired
                  : e.toString().contains('Invalid') ||
                          e.toString().contains('غير صحيح')
                      ? l10n.invalidCouponCode
                      : l10n.errorCheckingDiscount,
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleCheckout() async {
    if (_selectedPayment == null || _appConfig == null) return;
    final l10n = AppLocalizations.of(context)!;
    final paymentMethods =
        CoursePaymentMethodsUi.availableMethods(_appConfig!, l10n);
    if (paymentMethods.isEmpty) return;

    final course = widget.course;
    if (course == null || course['id'] == null) return;

    final courseId = course['id']?.toString();
    if (courseId == null || courseId.isEmpty) return;

    // Use selected method ID directly as API payment_method value.
    final paymentMethod = _selectedPayment!;

    if (paymentMethod == 'bank_account') {
      final holder = _bankAccountHolderController.text.trim();
      final acct = _bankAccountNumberController.text.trim();
      if (holder.isEmpty || acct.isEmpty) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.bankDetailsRequired,
                style: GoogleFonts.readexPro(),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      // Initiate checkout
      final checkoutData = await PaymentsService.instance.initiateCheckout(
        courseId: courseId,
        lessonId: widget.lesson?['id']?.toString(),
        paymentMethod: paymentMethod,
        couponCode: _couponApplied ? _couponCode : null,
        accountHolderName: paymentMethod == 'bank_account'
            ? _bankAccountHolderController.text.trim()
            : null,
        bankAccountNumber: paymentMethod == 'bank_account'
            ? _bankAccountNumberController.text.trim()
            : null,
        transferReference: paymentMethod == 'bank_account'
            ? _bankTransferReferenceController.text.trim()
            : null,
      );

      if (kDebugMode) {
        print('✅ Checkout initiated: $checkoutData');
      }

      setState(() {
        _checkoutSessionId = checkoutData['checkout_session_id']?.toString();
      });

      // Update pricing from API response
      if (checkoutData['pricing'] != null) {
        final pricing = checkoutData['pricing'] as Map<String, dynamic>;
        setState(() {
          final pricingCurrency =
              pricing['currency']?.toString().trim().toUpperCase();
          if (pricingCurrency != null && pricingCurrency.isNotEmpty) {
            _currencyCode = pricingCurrency;
          }
          _originalPrice =
              (pricing['original_price'] as num?)?.toDouble() ?? _originalPrice;
          _discountAmount =
              (pricing['discount_amount'] as num?)?.toDouble() ?? 0.0;
          if (pricing['coupon_discount'] != null) {
            _discountAmount +=
                (pricing['coupon_discount'] as num?)?.toDouble() ?? 0.0;
          }
          _finalPrice =
              (pricing['final_price'] as num?)?.toDouble() ?? _originalPrice;
        });
      }

      // Complete checkout (in real app, this would be done after payment gateway)
      if (_checkoutSessionId != null) {
        try {
          final completeData = await PaymentsService.instance.completeCheckout(
            checkoutSessionId: _checkoutSessionId!,
            paymentMethod: paymentMethod,
            paymentToken:
                'tok_${DateTime.now().millisecondsSinceEpoch}', // Mock token
            accountHolderName: paymentMethod == 'bank_account'
                ? _bankAccountHolderController.text.trim()
                : null,
            bankAccountNumber: paymentMethod == 'bank_account'
                ? _bankAccountNumberController.text.trim()
                : null,
            transferReference: paymentMethod == 'bank_account'
                ? _bankTransferReferenceController.text.trim().isNotEmpty
                    ? _bankTransferReferenceController.text.trim()
                    : null
                : null,
          );

          if (kDebugMode) {
            print('✅ Checkout completed: $completeData');
          }

          setState(() => _isProcessing = false);

          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            final bundleCount =
                SkillTrackUtils.enrolledBundleCount(completeData);
            final snackText = bundleCount != null
                ? l10n.skillTrackBundleUnlockedMessage(bundleCount)
                : (completeData['message']?.toString() ??
                    l10n.purchaseSuccessful);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  snackText,
                  style: GoogleFonts.readexPro(),
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            if (paymentMethod == 'whatsapp' && _appConfig != null) {
              final courseTitle = course['title']?.toString().trim();
              final titleForMsg = courseTitle != null && courseTitle.isNotEmpty
                  ? courseTitle
                  : '—';
              final msg = l10n.checkoutWhatsappPrefillMessage(titleForMsg);
              final wa = CoursePaymentMethodsUi.whatsappLaunchUri(_appConfig!,
                  prefilledMessage: msg);
              if (wa != null) {
                await launchUrl(wa, mode: LaunchMode.externalApplication);
              }
            }

            if (!mounted) return;
            // Navigate back and refresh course details
            context.pop(true); // Return true to indicate success
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error completing checkout: $e');
          }

          setState(() => _isProcessing = false);

          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.errorCompletingPayment,
                  style: GoogleFonts.readexPro(),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initiating checkout: $e');
      }

      setState(() => _isProcessing = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('401') ||
                      e.toString().contains('Unauthorized')
                  ? l10n.loginRequired
                  : l10n.errorProcessingPayment,
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final course = widget.course;
    if (course == null) {
      return Scaffold(
        backgroundColor: context.appTheme.scaffoldBackground,
        body: Center(child: Text(l10n.noCourse)),
      );
    }

    final paymentMethods = _appConfig == null
        ? <Map<String, dynamic>>[]
        : CoursePaymentMethodsUi.availableMethods(_appConfig!, l10n);

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header - matches React: bg-[var(--purple)] rounded-b-[3rem] pt-4 pb-8 px-4
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
                    l10n.completePurchase,
                    style: AppTextStyles.h3(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content - matches React: px-4 -mt-4 space-y-4
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -16), // -mt-4
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16), // px-4
                  child: Column(
                    children: [
                      // Course Summary Card - matches React: bg-white rounded-3xl p-4 shadow-lg
                      Container(
                        margin: const EdgeInsets.only(bottom: 16), // space-y-4
                        padding: const EdgeInsets.all(16), // p-4
                        decoration: BoxDecoration(
                          color: context.appTheme.card,
                          borderRadius:
                              BorderRadius.circular(24), // rounded-3xl
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Course image - matches React: w-20 h-20 rounded-2xl
                            Container(
                              width: 80, // w-20
                              height: 80, // h-20
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(16), // rounded-2xl
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _buildCourseImage(course),
                              ),
                            ),
                            const SizedBox(width: 16), // gap-4
                            // Course info - matches React: flex-1
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.lesson?['title']?.toString() ??
                                        course['title']?.toString() ??
                                        l10n.courseTitle,
                                    style: AppTextStyles.bodyMedium(
                                      color: _theme.cardTitle,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4), // mb-1
                                  Text(
                                    course['instructor'] is Map
                                        ? (course['instructor'] as Map)['name']
                                                ?.toString() ??
                                            l10n.instructor
                                        : course['instructor']?.toString() ??
                                            l10n.instructor,
                                    style: AppTextStyles.bodySmall(
                                      color: _theme.cardAccentText,
                                    ),
                                  ),
                                  const SizedBox(height: 8), // mb-2
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 12, // w-3 h-3
                                        color: _theme.icon,
                                      ),
                                      const SizedBox(width: 4), // gap-1
                                      Text(
                                        '${course['rating'] ?? 4.8}',
                                        style: AppTextStyles.labelSmall(
                                          color: _theme.cardMetaText,
                                        ),
                                      ),
                                      const SizedBox(width: 12), // gap-3
                                      Icon(
                                        Icons.access_time,
                                        size: 12, // w-3 h-3
                                        color: _theme.cardMetaText,
                                      ),
                                      const SizedBox(width: 4), // gap-1
                                      Text(
                                        '${course['hours'] ?? 48}س',
                                        style: AppTextStyles.labelSmall(
                                          color: _theme.cardMetaText,
                                        ),
                                      ),
                                      const SizedBox(width: 12), // gap-3
                                      Icon(
                                        Icons.menu_book,
                                        size: 12, // w-3 h-3
                                        color: _theme.cardMetaText,
                                      ),
                                      const SizedBox(width: 4), // gap-1
                                      Text(
                                        l10n.lessonsCount(
                                            (course['lessons'] as List?)
                                                    ?.length ??
                                                22),
                                        style: AppTextStyles.labelSmall(
                                          color: _theme.cardMetaText,
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

                      // Coupon Section - matches React: bg-white rounded-2xl p-4 shadow-sm
                      Container(
                        margin: const EdgeInsets.only(bottom: 16), // space-y-4
                        padding: const EdgeInsets.all(16), // p-4
                        decoration: BoxDecoration(
                          color: context.appTheme.card,
                          borderRadius:
                              BorderRadius.circular(16), // rounded-2xl
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_offer,
                                  size: 20, // w-5 h-5
                                  color: context.appTheme.icon,
                                ),
                                const SizedBox(width: 8), // gap-2
                                Text(
                                  l10n.discount,
                                  style: AppTextStyles.bodyMedium(
                                    color: _theme.cardTitle,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12), // mb-3
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16, // px-4
                                      vertical: 12, // py-3
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.appTheme.cardMuted,
                                      borderRadius: BorderRadius.circular(
                                          12), // rounded-xl
                                    ),
                                    child: TextField(
                                      enabled: !_couponApplied,
                                      decoration: InputDecoration(
                                        hintText: l10n.enterCouponCode,
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintStyle: TextStyle(
                                          color: _theme.cardMetaText,
                                        ),
                                      ),
                                      style: AppTextStyles.bodyMedium(
                                        color: _theme.cardTitle,
                                      ),
                                      onChanged: (value) {
                                        _couponCode = value;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8), // gap-2
                                GestureDetector(
                                  onTap: (_couponApplied ||
                                          _couponCode.isEmpty ||
                                          _isValidatingCoupon)
                                      ? null
                                      : _handleApplyCoupon,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24, // px-6
                                      vertical: 12, // py-3
                                    ),
                                    decoration: BoxDecoration(
                                      color: _couponApplied
                                          ? AppColors.goldPrimary
                                              .withValues(alpha: 0.2)
                                          : (_isValidatingCoupon
                                              ? _theme.progressTrack
                                              : _theme.icon),
                                      borderRadius: BorderRadius.circular(
                                          12), // rounded-xl
                                    ),
                                    child: _isValidatingCoupon
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      _theme.iconMuted),
                                            ),
                                          )
                                        : _couponApplied
                                            ? Icon(
                                                Icons.check,
                                                size: 20, // w-5 h-5
                                                color: AppColors.navyDeep,
                                              )
                                            : Text(
                                                l10n.apply,
                                                style: AppTextStyles.bodyMedium(
                                                  color: AppColors.navyDeep,
                                                ).copyWith(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                  ),
                                ),
                              ],
                            ),
                            if (_couponApplied) ...[
                              const SizedBox(height: 8), // mt-2
                              Text(
                                l10n.discount20,
                                style: AppTextStyles.bodySmall(
                                  color: _theme.cardAccentText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Payment methods + bank transfer details
                      Container(
                        margin: const EdgeInsets.only(bottom: 16), // space-y-4
                        padding: const EdgeInsets.all(16), // p-4
                        decoration: BoxDecoration(
                          color: context.appTheme.card,
                          borderRadius:
                              BorderRadius.circular(16), // rounded-2xl
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 16), // mb-4
                              child: Text(
                                l10n.choosePaymentMethod,
                                style: AppTextStyles.bodyMedium(
                                  color: _theme.cardTitle,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (_paymentConfigLoading)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: context.appTheme.icon,
                                  ),
                                ),
                              )
                            else if (paymentMethods.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  l10n.checkoutNoPaymentMethods,
                                  style: AppTextStyles.bodySmall(
                                    color: _theme.cardMetaText,
                                  ),
                                ),
                              )
                            else
                              ...paymentMethods.map((method) {
                                final id = method['id'] as String;
                                final selected = _selectedPayment == id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () =>
                                          setState(() => _selectedPayment = id),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.goldPrimary
                                                  .withValues(alpha: 0.12)
                                              : _theme.card,
                                          border: Border.all(
                                            color: selected
                                                ? _theme.icon
                                                : _theme.cardBorder,
                                            width: selected ? 2 : 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? _theme.icon
                                                    : _theme.progressTrack,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                method['icon'] as IconData,
                                                size: 22,
                                                color: selected
                                                    ? AppColors.navyDeep
                                                    : _theme.icon,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    method['title'] as String,
                                                    style: AppTextStyles
                                                        .bodyMedium(
                                                      color: _theme.cardTitle,
                                                    ).copyWith(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  Text(
                                                    method['subtitle']
                                                        as String,
                                                    style: AppTextStyles
                                                        .labelSmall(
                                                      color:
                                                          _theme.cardMetaText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (selected)
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: _theme.icon,
                                                size: 22,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            if (_selectedPayment == 'bank_account') ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.appTheme.cardMuted,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _theme.cardAccentText
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.bankTransferYourDetails,
                                      style: AppTextStyles.bodyMedium(
                                        color: _theme.cardTitle,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.bankTransferHint,
                                      style: AppTextStyles.labelSmall(
                                        color: _theme.cardMetaText,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      l10n.accountHolderName,
                                      style: AppTextStyles.labelSmall(
                                        color: _theme.cardTitle,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _bankAccountHolderController,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: _theme.card,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _theme.cardBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _theme.cardBorder,
                                          ),
                                        ),
                                      ),
                                      style: AppTextStyles.bodyMedium(
                                        color: _theme.cardTitle,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.bankAccountNumberLabel,
                                      style: AppTextStyles.labelSmall(
                                        color: _theme.cardTitle,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: _bankAccountNumberController,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: _theme.card,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _theme.cardBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _theme.cardBorder,
                                          ),
                                        ),
                                      ),
                                      style: AppTextStyles.bodyMedium(
                                        color: _theme.cardTitle,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.transferReferenceOptional,
                                      style: AppTextStyles.labelSmall(
                                        color: _theme.cardTitle,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller:
                                          _bankTransferReferenceController,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.done,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: _theme.card,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _theme.cardBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _theme.cardBorder,
                                          ),
                                        ),
                                      ),
                                      style: AppTextStyles.bodyMedium(
                                        color: _theme.cardTitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Price Summary - matches React: bg-white rounded-2xl p-4 shadow-sm
                      Container(
                        margin: const EdgeInsets.only(bottom: 16), // space-y-4
                        padding: const EdgeInsets.all(16), // p-4
                        decoration: BoxDecoration(
                          color: context.appTheme.card,
                          borderRadius:
                              BorderRadius.circular(16), // rounded-2xl
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 16), // mb-4
                              child: Text(
                                l10n.orderSummary,
                                style: AppTextStyles.bodyMedium(
                                  color: _theme.cardTitle,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Price rows - matches React: space-y-3
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.coursePrice,
                                  style: AppTextStyles.bodyMedium(
                                    color: _theme.cardMetaText,
                                  ),
                                ),
                                Text(
                                  _formatAmount(_originalPrice),
                                  style: AppTextStyles.bodyMedium(
                                    color: _theme.cardTitle,
                                  ).copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (_couponApplied && _discountAmount > 0) ...[
                              const SizedBox(height: 12), // space-y-3
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.discount,
                                    style: AppTextStyles.bodyMedium(
                                      color: _theme.cardAccentText,
                                    ),
                                  ),
                                  Text(
                                    _formatAmount(_discountAmount,
                                        withMinus: true),
                                    style: AppTextStyles.bodyMedium(
                                      color: _theme.cardAccentText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              color: _theme.cardBorder,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.total,
                                  style: AppTextStyles.bodyMedium(
                                    color: _theme.cardTitle,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _formatAmount(_finalPrice),
                                  style: AppTextStyles.h2(
                                    color: _theme.icon,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Checkout Button - matches React
                      GestureDetector(
                        onTap: _selectedPayment == null ||
                                _isProcessing ||
                                _paymentConfigLoading ||
                                paymentMethods.isEmpty
                            ? null
                            : _handleCheckout,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16), // py-4
                          decoration: BoxDecoration(
                            gradient: _selectedPayment != null &&
                                    !_isProcessing &&
                                    !_paymentConfigLoading &&
                                    paymentMethods.isNotEmpty
                                ? const LinearGradient(
                                    colors: [
                                      AppColors.goldLight,
                                      AppColors.goldPrimary,
                                    ],
                                  )
                                : null,
                            color: _selectedPayment != null &&
                                    !_isProcessing &&
                                    !_paymentConfigLoading &&
                                    paymentMethods.isNotEmpty
                                ? null
                                : _theme.progressTrack,
                            borderRadius:
                                BorderRadius.circular(16), // rounded-2xl
                          ),
                          child: Center(
                            child: Text(
                              _isProcessing
                                  ? l10n.processing
                                  : l10n.confirmPayment,
                              style: AppTextStyles.buttonLarge(
                                color: _selectedPayment != null &&
                                        !_isProcessing &&
                                        !_paymentConfigLoading &&
                                        paymentMethods.isNotEmpty
                                    ? AppColors.navyDeep
                                    : _theme.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),

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

  Widget _buildCourseImage(Map<String, dynamic> course) {
    // Try thumbnail first, then image, then banner
    String? imageUrl;
    if (course['thumbnail'] != null) {
      imageUrl = course['thumbnail']?.toString();
    } else if (course['image'] != null) {
      imageUrl = course['image']?.toString();
    } else if (course['banner'] != null) {
      imageUrl = course['banner']?.toString();
    }

    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        imageUrl.startsWith('http')) {
      // Network image
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: context.appTheme.icon.withOpacity(0.1),
          child: Icon(
            Icons.image,
            color: context.appTheme.icon,
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: context.appTheme.icon.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                color: context.appTheme.icon,
                strokeWidth: 2,
              ),
            ),
          );
        },
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      // Asset image
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: context.appTheme.icon.withOpacity(0.1),
          child: Icon(
            Icons.image,
            color: context.appTheme.icon,
          ),
        ),
      );
    } else {
      // Placeholder
      return Container(
        color: context.appTheme.icon.withOpacity(0.1),
        child: Icon(
          Icons.menu_book_rounded,
          color: context.appTheme.icon,
          size: 40,
        ),
      );
    }
  }
}
