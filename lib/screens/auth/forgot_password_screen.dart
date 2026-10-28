import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/global_whatsapp_support_fab.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/brand_ui.dart';
import 'auth_screen_styles.dart';

/// Forgot Password Screen
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _handleForgotPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await AuthService.instance.forgotPassword(
          email: _emailController.text.trim(),
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.readexPro(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    BrandUi.applyStatusBar(context);

    return Scaffold(
      backgroundColor: AuthScreenStyles.scaffoldBackground(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
          // Navy Header
          Container(
            decoration: AuthScreenStyles.headerDecoration(),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
                child: Column(
                  children: [
                    // Back Button & Title
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go(RouteNames.login),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AuthScreenStyles.headerControlBg(context),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AuthScreenStyles.headerForeground,
                              size: 18,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.forgotPasswordTitle,
                          style: AuthScreenStyles.headerTitleStyle(),
                        ),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 30),
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AuthScreenStyles.headerControlBg(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: AuthScreenStyles.headerForeground,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.resetPasswordTitle,
                      style: AuthScreenStyles.headerTitleStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.resetPasswordDescription,
                      textAlign: TextAlign.center,
                      style: AuthScreenStyles.headerSubtitleStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form Container
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                decoration: AuthScreenStyles.formSheetDecoration(context),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: _emailSent
                      ? _buildSuccessView(context)
                      : _buildForm(context),
                ),
              ),
            ),
          ),
        ],
      ),
          const GlobalWhatsappSupportFab(
            extraBottomAboveSafeArea: kWhatsappFabAuthScreens,
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Field
          _buildLabel(l10n.email),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: l10n.enterEmail,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            context: context,
          ),
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              style: AuthScreenStyles.primaryButtonStyle(context),
              child: _isLoading
                  ? AuthScreenStyles.loadingIndicator(context)
                  : Text(
                      l10n.sendResetLink,
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => context.go(RouteNames.login),
              child: Text(
                l10n.backToLogin,
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.appTheme.icon,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.goldPrimary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: context.appTheme.icon.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: context.appTheme.icon,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.sentSuccessfully,
          style: GoogleFonts.readexPro(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: context.cardTitle,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.resetPasswordSent,
          textAlign: TextAlign.center,
          style: GoogleFonts.readexPro(
            fontSize: 14,
            color: context.cardMetaText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text.trim(),
          textAlign: TextAlign.center,
          style: GoogleFonts.readexPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.appTheme.icon,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go(RouteNames.login),
            style: AuthScreenStyles.primaryButtonStyle(context),
            child: Text(
              l10n.backToLogin,
              style: GoogleFonts.readexPro(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
          },
          child: Text(
            l10n.sendToAnotherEmail,
            style: GoogleFonts.readexPro(
              fontSize: 14,
              color: context.cardMetaText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AuthScreenStyles.formLabelStyle(context));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: AuthScreenStyles.textFieldDecoration(context),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: AuthScreenStyles.fieldTextStyle(context),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AuthScreenStyles.fieldHintStyle(context),
          prefixIcon: Icon(
            icon,
            color: AuthScreenStyles.fieldIconColor(context),
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.fieldRequired;
          }
          if (keyboardType == TextInputType.emailAddress) {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return l10n.invalidEmail;
            }
          }
          return null;
        },
      ),
    );
  }
}
