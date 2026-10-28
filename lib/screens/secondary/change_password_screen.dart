import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/validation/password_policy.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/localization/localization_helper.dart';
import '../../services/profile_service.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_theme_extension.dart';
import '../auth/auth_screen_styles.dart';

/// Change Password Screen - For changing user password
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  AppThemeExtension get _theme => AppThemeExtension.of(context);

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ProfileService.instance.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        newPasswordConfirmation: _confirmPasswordController.text,
      );

      if (kDebugMode) {
        print('✅ Password changed successfully');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تغيير كلمة المرور بنجاح',
              style: GoogleFonts.readexPro(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.goldPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error changing password: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.errorChangingPassword(e.toString()),
              style: GoogleFonts.readexPro(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: _theme.scaffoldBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _theme.icon,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.changePassword,
          style: AppTextStyles.h3(color: _theme.foreground),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Current Password Field
              _buildPasswordField(
                controller: _currentPasswordController,
                label: context.l10n.currentPassword,
                obscureText: _obscureCurrentPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureCurrentPassword = !_obscureCurrentPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.pleaseEnterCurrentPassword;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // New Password Field
              _buildPasswordField(
                controller: _newPasswordController,
                label: context.l10n.newPassword,
                obscureText: _obscureNewPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.pleaseEnterNewPassword;
                  }
                  return PasswordPolicy.validate(value, context.l10n);
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: context.l10n.confirmPassword,
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.pleaseConfirmPassword;
                  }
                  if (value != _newPasswordController.text) {
                    return context.l10n.passwordMismatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Change Password Button
              ElevatedButton(
                onPressed: _isSaving ? null : _changePassword,
                style: AuthScreenStyles.primaryButtonStyle(context).copyWith(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: _isSaving
                    ? AuthScreenStyles.loadingIndicator(context)
                    : Text(
                        context.l10n.changePassword,
                        style: GoogleFonts.readexPro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDeep,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final theme = _theme;
    final borderRadius = BorderRadius.circular(12);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.readexPro(fontSize: 15, color: theme.cardTitle),
      cursorColor: theme.icon,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.readexPro(
          color: theme.mutedForeground,
        ),
        floatingLabelStyle: GoogleFonts.readexPro(
          color: theme.cardAccentText,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.icon),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: theme.cardMetaText.withValues(alpha: 0.7),
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: theme.card,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: theme.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: theme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: theme.icon, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: GoogleFonts.readexPro(
          color: Colors.red[300],
          fontSize: 12,
        ),
      ),
    );
  }
}
