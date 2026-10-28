import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_text_styles.dart';
import '../../services/app_config_service.dart';
import '../../core/design/app_theme_extension.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  AppThemeExtension get _theme => AppThemeExtension.of(context);

  bool _isLoading = true;
  List<String> _phoneNumbers = const [];
  List<String> _whatsappNumbers = const [];

  @override
  void initState() {
    super.initState();
    _loadSupportContacts();
  }

  Future<void> _loadSupportContacts() async {
    try {
      final config = await AppConfigService.instance.getAppConfig();

      if (mounted) {
        setState(() {
          _phoneNumbers = _extractPhoneNumbers(config.support.phone);
          _whatsappNumbers = _extractPhoneNumbers(config.support.whatsapp);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('HelpSupportScreen: failed to load support config: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> _extractPhoneNumbers(String source) {
    if (source.isEmpty) return <String>[];
    final parts = source.split(RegExp(r'[-,;/\s]+'));
    final normalized = parts
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    return normalized.toSet().toList();
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open phone dialer',
            style: GoogleFonts.readexPro(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await launchUrl(uri);
  }

  String _whatsappDigits(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      return '20${digits.substring(1)}';
    }
    return digits;
  }

  Future<void> _openWhatsapp(String phone) async {
    final uri = Uri.parse('https://wa.me/${_whatsappDigits(phone)}');
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open WhatsApp',
            style: GoogleFonts.readexPro(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
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
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 32,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.goldPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Help & Support',
                    style: AppTextStyles.h3(color: AppColors.goldPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: theme.icon),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadow,
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact us',
                                style: AppTextStyles.h4(
                                  color: theme.cardTitle,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reach support quickly using any number below.',
                                style: AppTextStyles.bodySmall(
                                  color: theme.cardMetaText
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._phoneNumbers.map(
                                (phone) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SupportPhoneTile(
                                    phone: phone,
                                    onCall: () => _callNumber(phone),
                                  ),
                                ),
                              ),
                              ..._whatsappNumbers.map(
                                (phone) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _SupportWhatsappTile(
                                    phone: phone,
                                    onOpen: () => _openWhatsapp(phone),
                                  ),
                                ),
                              ),
                              if (_phoneNumbers.isEmpty &&
                                  _whatsappNumbers.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Contact numbers are not available right now.',
                                    style: AppTextStyles.bodySmall(
                                      color: theme.cardMetaText
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportWhatsappTile extends StatelessWidget {
  final String phone;
  final VoidCallback onOpen;

  const _SupportWhatsappTile({
    required this.phone,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeExtension.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/whatsapp-logo-1.png',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              phone,
              style: AppTextStyles.bodyMedium(
                color: theme.cardTitle,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.chat_rounded,
                size: 18, color: Color(0xFF25D366)),
            label: Text(
              'WhatsApp',
              style: GoogleFonts.readexPro(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF25D366),
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportPhoneTile extends StatelessWidget {
  final String phone;
  final VoidCallback onCall;

  const _SupportPhoneTile({
    required this.phone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeExtension.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_rounded, color: theme.icon),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              phone,
              style: AppTextStyles.bodyMedium(
                color: theme.cardTitle,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onCall,
            icon: Icon(Icons.call_rounded, size: 18, color: theme.icon),
            label: Text(
              'Call',
              style: GoogleFonts.readexPro(
                fontWeight: FontWeight.w700,
                color: theme.cardAccentText,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: theme.icon,
            ),
          ),
        ],
      ),
    );
  }
}
