import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_config_service.dart';

/// Opens Terms / Privacy pages from app config, with production fallbacks.
///
/// Pages are hosted on the marketing site; see `docs/PRIVACY_TERMS_WEBSITE.md`.
class LegalUrls {
  LegalUrls._();

  static const String fallbackPrivacyUrl =
      'https://bouslty.anmka.com/privacy';
  static const String fallbackTermsUrl = 'https://bouslty.anmka.com/terms';

  static Future<String> privacyUrl() async {
    final config = await AppConfigService.instance.getAppConfig();
    final url = config.legal.privacyUrl.trim();
    return url.isNotEmpty ? url : fallbackPrivacyUrl;
  }

  static Future<String> termsUrl() async {
    final config = await AppConfigService.instance.getAppConfig();
    final url = config.legal.termsUrl.trim();
    return url.isNotEmpty ? url : fallbackTermsUrl;
  }

  static Future<void> openPrivacy(BuildContext context) async {
    final url = await privacyUrl();
    if (!context.mounted) return;
    await _open(context, url);
  }

  static Future<void> openTerms(BuildContext context) async {
    final url = await termsUrl();
    if (!context.mounted) return;
    await _open(context, url);
  }

  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      if (!context.mounted) return;
      _showError(context);
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showError(context);
    }
  }

  static void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to open link',
          style: GoogleFonts.readexPro(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
