import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/course_payment_methods_ui.dart';
import '../core/design/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/app_config.dart';
import '../services/app_config_service.dart';

/// WhatsApp shortcut using number from `GET /api/config/app` (cached in [AppConfigService]).
///
/// [extraBottomAboveSafeArea]: added on top of [MediaQuery.padding.bottom].
/// Use [kWhatsappFabAboveBottomNav] for a floating button above the bottom nav area;
/// use [kWhatsappFabAuthScreens] for auth screens.
const double kWhatsappFabAboveBottomNav = 88;
const double kWhatsappFabAuthScreens = 16;

/// Circular WhatsApp launcher (no positioning). Used in [BottomNav] and inside [GlobalWhatsappSupportFab].
class WhatsappSupportCircleButton extends StatefulWidget {
  const WhatsappSupportCircleButton({super.key});

  @override
  State<WhatsappSupportCircleButton> createState() =>
      _WhatsappSupportCircleButtonState();
}

class _WhatsappSupportCircleButtonState extends State<WhatsappSupportCircleButton> {
  static const String _assetPath = 'assets/images/whatsapp-logo-1.png';

  AppConfig? _config;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _canShowFab(AppConfig config) {
    final raw = CoursePaymentMethodsUi.resolveWhatsappNumber(config);
    if (raw == null || raw.trim().isEmpty) return false;
    final uri = CoursePaymentMethodsUi.whatsappLaunchUri(config);
    return uri != null;
  }

  Future<void> _load() async {
    final c = await AppConfigService.instance.getAppConfig();
    if (!mounted) return;
    setState(() {
      _config = c;
      _ready = true;
    });
  }

  Future<void> _onTap(BuildContext context) async {
    final config = _config;
    if (config == null) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final message = l10n.globalWhatsappFabMessage;

    final uri = CoursePaymentMethodsUi.whatsappLaunchUri(
      config,
      prefilledMessage: message,
    );

    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            l10n.globalWhatsappFabUnavailable,
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            l10n.globalWhatsappFabUnavailable,
            style: GoogleFonts.readexPro(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _config == null) {
      return const SizedBox.shrink();
    }

    if (!_canShowFab(_config!)) {
      return const SizedBox.shrink();
    }

    if (AppLocalizations.of(context) == null) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 8,
      shadowColor: Colors.black38,
      shape: const CircleBorder(),
      color: AppColors.primary,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        splashColor: AppColors.primaryForeground.withValues(alpha: 0.18),
        highlightColor: AppColors.primaryForeground.withValues(alpha: 0.1),
        onTap: () => _onTap(context),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Image.asset(
              _assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.chat_rounded,
                color: AppColors.primaryForeground,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating WhatsApp button (e.g. auth screens): anchored end + [extraBottomAboveSafeArea].
class GlobalWhatsappSupportFab extends StatelessWidget {
  const GlobalWhatsappSupportFab({
    super.key,
    this.extraBottomAboveSafeArea = kWhatsappFabAboveBottomNav,
  });

  final double extraBottomAboveSafeArea;

  @override
  Widget build(BuildContext context) {
    final bottom =
        MediaQuery.paddingOf(context).bottom + extraBottomAboveSafeArea;
    return PositionedDirectional(
      end: 14,
      bottom: bottom,
      child: const WhatsappSupportCircleButton(),
    );
  }
}
