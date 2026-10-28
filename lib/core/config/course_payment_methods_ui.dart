import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_config.dart';

/// Build payment options for course enrollment from [AppConfig.coursePaymentMethods]
/// and `GET /api/config/app` (see `docs/FLUTTER_COURSE_PAYMENT_METHODS.md`).
class CoursePaymentMethodsUi {
  CoursePaymentMethodsUi._();

  /// E.164 or local digits; falls back to global payment / support WhatsApp.
  static String? resolveWhatsappNumber(AppConfig config) {
    final pm = config.coursePaymentMethods;
    final primary = pm.whatsappNumberE164?.trim();
    if (primary != null && primary.isNotEmpty) return primary;
    final pay = config.paymentWhatsappNumber.trim();
    if (pay.isNotEmpty) return pay;
    final sup = config.support.whatsapp.trim();
    if (sup.isNotEmpty) return sup;
    final social = config.socialLinks.whatsapp.trim();
    if (social.isNotEmpty) return social;
    return null;
  }

  /// Shown when `whatsapp_enabled` is true: need a resolvable number to open [wa.me](https://wa.me).
  static bool shouldShowWhatsappOption(AppConfig config) {
    final pm = config.coursePaymentMethods;
    if (!pm.whatsappEnabled) return false;
    final n = resolveWhatsappNumber(config);
    return n != null && n.isNotEmpty;
  }

  static List<Map<String, dynamic>> availableMethods(
    AppConfig config,
    AppLocalizations l10n,
  ) {
    final pm = config.coursePaymentMethods;
    final list = <Map<String, dynamic>>[];

    if (pm.bankTransferEnabled) {
      list.add({
        'id': 'bank_account',
        'title': l10n.checkoutPaymentBankTitle,
        'subtitle': l10n.checkoutPaymentBankDescription,
        'icon': Icons.account_balance,
      });
    }
    if (pm.libraryReceiptEnabled) {
      list.add({
        'id': 'library_cash',
        'title': l10n.checkoutPaymentLibraryTitle,
        'subtitle': l10n.checkoutPaymentLibraryDescription,
        'icon': Icons.request_quote_rounded,
      });
    }
    if (shouldShowWhatsappOption(config)) {
      list.add({
        'id': 'whatsapp',
        'title': l10n.checkoutPaymentWhatsappTitle,
        'subtitle': l10n.checkoutPaymentWhatsappDescription,
        'icon': Icons.chat_rounded,
      });
    }
    return list;
  }

  static Uri? whatsappLaunchUri(
    AppConfig config, {
    String? prefilledMessage,
  }) {
    final raw = resolveWhatsappNumber(config);
    if (raw == null || raw.isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    final q = prefilledMessage != null && prefilledMessage.isNotEmpty
        ? '?text=${Uri.encodeComponent(prefilledMessage)}'
        : '';
    return Uri.parse('https://wa.me/$digits$q');
  }
}
