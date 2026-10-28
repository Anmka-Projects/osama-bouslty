import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/theme_provider.dart';
import '../../core/navigation/route_names.dart';
import '../../widgets/global_whatsapp_support_fab.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/brand_ui.dart';
import 'auth_screen_styles.dart';

/// Login Screen - Clean Design like Account Page
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ThemeProvider _themeProvider = ThemeProvider.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  // bool _googleLoading = false;
  // bool _appleLoading = false;

  Future<void> _toggleLanguage() async {
    final nextCode = _themeProvider.locale.languageCode == 'ar' ? 'en' : 'ar';
    await _themeProvider.setLanguage(Locale(nextCode));
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authResponse = await AuthService.instance.login(
          emailOrPhone: _emailOrPhoneController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        // Save launch flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasLaunched', true);

        // Navigate by role: instructor → instructor flow, else → student flow
        if (mounted) {
          final role = authResponse.user.role.toLowerCase();
          if (role == 'instructor' || role == 'teacher') {
            context.go(RouteNames.instructorHome);
          } else {
            context.go(RouteNames.home);
          }
        }
      } catch (e) {
        if (!mounted) return;

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
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Google and Apple auth - commented out
  // Future<void> _handleGoogleLogin() async {
  //   if (_googleLoading || _appleLoading) return;
  //   setState(() {
  //     _googleLoading = true;
  //     _appleLoading = false;
  //   });

  //   try {
  //     final authResponse = await AuthService.instance.signInWithGoogle();

  //     if (!mounted) return;

  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setBool('hasLaunched', true);

  //     if (mounted) {
  //       final role = authResponse.user.role.toLowerCase();
  //       if (role == 'instructor' || role == 'teacher') {
  //         context.go(RouteNames.instructorHome);
  //       } else {
  //         context.go(RouteNames.home);
  //       }
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           e.toString().replaceFirst('Exception: ', ''),
  //           style: GoogleFonts.readexPro(),
  //         ),
  //         backgroundColor: Colors.red,
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() => _googleLoading = false);
  //     }
  //   }
  // }

  // Future<void> _handleAppleLogin() async {
  //   if (_appleLoading || _googleLoading) return;
  //   setState(() {
  //     _appleLoading = true;
  //     _googleLoading = false;
  //   });

  //   try {
  //     final authResponse = await AuthService.instance.signInWithApple();

  //     if (!mounted) return;

  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setBool('hasLaunched', true);

  //     if (mounted) {
  //       final role = authResponse.user.role.toLowerCase();
  //       if (role == 'instructor' || role == 'teacher') {
  //         context.go(RouteNames.instructorHome);
  //       } else {
  //         context.go(RouteNames.home);
  //       }
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           e.toString().replaceFirst('Exception: ', ''),
  //           style: GoogleFonts.readexPro(),
  //         ),
  //         backgroundColor: Colors.red,
  //         duration: const Duration(seconds: 3),
  //       ),
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() => _appleLoading = false);
  //     }
  //   }
  // }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        // Back Button
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.go(RouteNames.splash),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      AuthScreenStyles.headerControlBg(context),
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
                              AppLocalizations.of(context)!.login,
                              style: AuthScreenStyles.headerTitleStyle(),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _toggleLanguage,
                              child: Container(
                                height: 36,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color:
                                      AuthScreenStyles.headerControlBg(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AuthScreenStyles.headerControlBorder(
                                        context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.language_rounded,
                                      color: AuthScreenStyles.headerForeground,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _themeProvider.locale.languageCode
                                          .toUpperCase(),
                                      style: GoogleFonts.readexPro(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AuthScreenStyles.headerForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Logo
                        Container(
                          width: 90,
                          height: 90,
                          decoration: AuthScreenStyles.logoDecoration(),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/brand/app-icon-1024.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.school_rounded,
                                size: 45,
                                color: context.appTheme.icon,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.welcomeBack,
                          style:
                              AuthScreenStyles.headerTitleStyle(fontSize: 22),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email or Phone Field
                            _buildLabel(
                                AppLocalizations.of(context)!.emailOrPhone),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailOrPhoneController,
                              hint: AppLocalizations.of(context)!
                                  .enterEmailOrPhone,
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            _buildLabel(AppLocalizations.of(context)!.password),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hint: AppLocalizations.of(context)!.enterPassword,
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ),
                            const SizedBox(height: 12),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () =>
                                    context.push(RouteNames.forgotPassword),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.forgotPassword,
                                  style: AuthScreenStyles.bodyLinkStyle(context)
                                      .copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: AuthScreenStyles.primaryButtonStyle(
                                    context),
                                child: _isLoading
                                    ? AuthScreenStyles.loadingIndicator(context)
                                    : Text(
                                        AppLocalizations.of(context)!.login,
                                        style: GoogleFonts.readexPro(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Apple and Google auth widget - commented out
                            // // Divider
                            // Row(
                            //   children: [
                            //     Expanded(child: Divider(color: Colors.grey[300])),
                            //     Padding(
                            //       padding:
                            //           const EdgeInsets.symmetric(horizontal: 16),
                            //       child: Text(
                            //         AppLocalizations.of(context)!.or,
                            //         style: GoogleFonts.readexPro(
                            //             color: context.textSecondary),
                            //       ),
                            //     ),
                            //     Expanded(child: Divider(color: Colors.grey[300])),
                            //   ],
                            // ),
                            // const SizedBox(height: 24),

                            // // Social Buttons
                            // Row(
                            //   children: [
                            //     Expanded(
                            //         child: _buildSocialButton(
                            //       icon: Icons.g_mobiledata_rounded,
                            //       label: AppLocalizations.of(context)!.google,
                            //       onPressed: (_isLoading || _appleLoading)
                            //           ? null
                            //           : _handleGoogleLogin,
                            //       isLoading: _googleLoading,
                            //     )),
                            //     const SizedBox(width: 12),
                            //     Expanded(
                            //         child: _buildSocialButton(
                            //       icon: Icons.apple_rounded,
                            //       label: AppLocalizations.of(context)!.apple,
                            //       onPressed: (_isLoading || _googleLoading)
                            //           ? null
                            //           : _handleAppleLogin,
                            //       isLoading: _appleLoading,
                            //     )),
                            //   ],
                            // ),

                            const SizedBox(height: 32),

                            // Register Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.noAccount,
                                    style: AuthScreenStyles.bodySecondaryStyle(
                                        context),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.go(RouteNames.register),
                                    child: Text(
                                      AppLocalizations.of(context)!.registerNow,
                                      style: AuthScreenStyles.bodyLinkStyle(
                                          context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildLabel(String text) {
    return Text(text, style: AuthScreenStyles.formLabelStyle(context));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: AuthScreenStyles.textFieldDecoration(context),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_showPassword,
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
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AuthScreenStyles.fieldSuffixIconColor(context),
                    size: 22,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.fieldRequired;
          }
          // Accept any input (email or phone) - validation will be done by backend
          return null;
        },
      ),
    );
  }

  // /* Apple and Google auth widget - commented out
  // Widget _buildSocialButton({
  //   required IconData icon,
  //   required String label,
  //   VoidCallback? onPressed,
  //   bool isLoading = false,
  // }) {
  //   final isDisabled = onPressed == null || isLoading;
  //   return Opacity(
  //     opacity: isDisabled ? 0.6 : 1,
  //     child: InkWell(
  //       onTap: isDisabled ? null : onPressed,
  //       borderRadius: BorderRadius.circular(14),
  //       child: Container(
  //         height: 50,
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(14),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.04),
  //               blurRadius: 10,
  //               offset: const Offset(0, 4),
  //             ),
  //           ],
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             if (isLoading)
  //               const SizedBox(
  //                 width: 20,
  //                 height: 20,
  //                 child: CircularProgressIndicator(
  //                   strokeWidth: 2,
  //                   color: context.appTheme.icon,
  //                 ),
  //               )
  //             else
  //               Icon(icon, size: 24, color: context.textPrimary),
  //             const SizedBox(width: 8),
  //             Text(
  //               label,
  //               style: GoogleFonts.readexPro(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color: context.textPrimary,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
