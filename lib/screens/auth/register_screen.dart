import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../widgets/global_whatsapp_support_fab.dart';
import '../../core/categories/category_utils.dart';
import '../../core/validation/password_policy.dart';
import '../../services/auth_service.dart';
import '../../services/courses_service.dart';
import '../../l10n/app_localizations.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/brand_ui.dart';
import '../../core/legal/legal_urls.dart';
import 'auth_screen_styles.dart';

/// Register Screen - Clean Design like Account Page
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static final _egyptianLocalPhone = RegExp(r'^01[0125]\d{8}$');
  static final _egyptianInternationalPhone = RegExp(r'^\+201[0125]\d{8}$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _showPassword = false;
  bool _showPasswordConfirmation = false;
  bool _isLoading = false;
  bool _acceptTerms = false;
  // Student type selection is temporarily disabled in UI.
  final String _defaultStudentType = 'online';

  // Educational stage (top-level category) + grade (subcategory) pickers.
  List<Map<String, dynamic>> _categories = const [];
  bool _isLoadingCategories = true;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await CoursesService.instance.getCategories(requireAuth: false);
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  List<Map<String, dynamic>> get _stageCategories =>
      CategoryUtils.topLevel(_categories);

  Map<String, dynamic>? get _selectedStage {
    for (final c in _stageCategories) {
      if (c['id']?.toString() == _selectedCategoryId) return c;
    }
    return null;
  }

  List<Map<String, dynamic>> get _gradeOptions {
    final stage = _selectedStage;
    if (stage == null) return const [];
    return CategoryUtils.resolveChildren(stage, _categories);
  }

  String? _normalizePhoneForApi(String input) {
    final phone = input.trim();
    if (_egyptianLocalPhone.hasMatch(phone)) {
      return '+20${phone.substring(1)}';
    }
    if (_egyptianInternationalPhone.hasMatch(phone)) {
      return phone;
    }
    return null;
  }

  bool _isValidPhone(String input) => _normalizePhoneForApi(input) != null;

  Future<void> _handleRegister() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseAcceptTerms,
              style: GoogleFonts.readexPro(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      final l10n = AppLocalizations.of(context)!;
      final pwdPolicyError = _passwordController.text.isNotEmpty
          ? PasswordPolicy.validate(_passwordController.text, l10n)
          : null;
      if (pwdPolicyError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pwdPolicyError,
                style: GoogleFonts.readexPro(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      } else if (_passwordController.text.isNotEmpty &&
          _passwordConfirmationController.text.isNotEmpty &&
          _passwordController.text != _passwordConfirmationController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordMismatch,
                style: GoogleFonts.readexPro(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        final email = _emailController.text.trim();
        if (email.isNotEmpty &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.invalidEmail,
                  style: GoogleFonts.readexPro(color: Colors.white)),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          final phone = _phoneController.text.trim();
          if (phone.isNotEmpty && !_isValidPhone(phone)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.invalidPhone,
                    style: GoogleFonts.readexPro(color: Colors.white)),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final emailRaw = _emailController.text.trim();
      final normalizedPhone =
          _normalizePhoneForApi(_phoneController.text.trim());
      final authResponse = await AuthService.instance.register(
        name: _nameController.text.trim(),
        email: emailRaw.isEmpty ? null : emailRaw,
        phone: normalizedPhone!,
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
        acceptTerms: _acceptTerms,
        studentType: _defaultStudentType,
        categoryId: _selectedCategoryId,
        subcategoryId: _selectedSubcategoryId,
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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
                              AppLocalizations.of(context)!.register,
                              style: AuthScreenStyles.headerTitleStyle(),
                            ),
                            const Spacer(),
                            const SizedBox(width: 44),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.joinUsMessage,
                          style: AuthScreenStyles.headerSubtitleStyle(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Form Container
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: AuthScreenStyles.formSheetDecoration(context),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Field
                            _buildLabel(AppLocalizations.of(context)!.fullName),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nameController,
                              hint:
                                  AppLocalizations.of(context)!.pleaseEnterName,
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 16),

                            // Email Field (optional)
                            _buildLabel(
                                AppLocalizations.of(context)!.emailOptional),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'example@email.com',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isOptional: true,
                            ),
                            const SizedBox(height: 16),

                            // Phone Field
                            _buildLabel(AppLocalizations.of(context)!.phone),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _phoneController,
                              hint: AppLocalizations.of(context)!
                                  .phonePlaceholder,
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              maxLength: 11,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Student type selector is temporarily disabled.
                            // _buildLabel(AppLocalizations.of(context)!.studentType),
                            // const SizedBox(height: 8),
                            // _buildStudentTypeSelector(context),
                            // const SizedBox(height: 16),

                            // Educational stage (top-level category) + grade
                            // (subcategory) pickers.
                            if (_isLoadingCategories)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: context.appTheme.icon,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            else if (_stageCategories.isNotEmpty) ...[
                              _buildLabel(AppLocalizations.of(context)!
                                  .educationalStage),
                              const SizedBox(height: 8),
                              _buildCategoryDropdown(
                                value: _selectedCategoryId,
                                hint: AppLocalizations.of(context)!
                                    .selectEducationalStage,
                                icon: Icons.school_outlined,
                                options: _stageCategories,
                                onChanged: (v) => setState(() {
                                  _selectedCategoryId = v;
                                  _selectedSubcategoryId = null;
                                }),
                                validatorMessage: AppLocalizations.of(context)!
                                    .selectEducationalStage,
                              ),
                              const SizedBox(height: 16),
                              if (_gradeOptions.isNotEmpty) ...[
                                _buildLabel(
                                    AppLocalizations.of(context)!.grade),
                                const SizedBox(height: 8),
                                _buildCategoryDropdown(
                                  resetKey: ValueKey(_selectedCategoryId),
                                  value: _selectedSubcategoryId,
                                  hint:
                                      AppLocalizations.of(context)!.selectGrade,
                                  icon: Icons.grade_outlined,
                                  options: _gradeOptions,
                                  onChanged: (v) => setState(
                                      () => _selectedSubcategoryId = v),
                                  validatorMessage:
                                      AppLocalizations.of(context)!.selectGrade,
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],

                            // Password Field
                            _buildLabel(AppLocalizations.of(context)!.password),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hint: AppLocalizations.of(context)!.enterPassword,
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              passwordFieldType: 'password',
                            ),
                            const SizedBox(height: 16),

                            // Password Confirmation Field
                            _buildLabel(AppLocalizations.of(context)!
                                .confirmNewPassword),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordConfirmationController,
                              hint: AppLocalizations.of(context)!
                                  .enterPasswordAgain,
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              passwordFieldType: 'confirmation',
                            ),
                            const SizedBox(height: 16),

                            // Terms Checkbox + tappable legal link
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration:
                                  AuthScreenStyles.textFieldDecoration(context)
                                      .copyWith(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _acceptTerms = !_acceptTerms),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _acceptTerms
                                            ? context.appTheme.icon
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _acceptTerms
                                              ? context.appTheme.icon
                                              : context.appTheme.cardBorder,
                                          width: 2,
                                        ),
                                      ),
                                      child: _acceptTerms
                                          ? Icon(Icons.check,
                                              size: 14,
                                              color: AppColors.navyDeep)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        style:
                                            AuthScreenStyles.bodySecondaryStyle(
                                                    context)
                                                .copyWith(fontSize: 13),
                                        children: [
                                          TextSpan(
                                            text:
                                                '${AppLocalizations.of(context)!.iAgreeTo} ',
                                          ),
                                          WidgetSpan(
                                            alignment:
                                                PlaceholderAlignment.baseline,
                                            baseline: TextBaseline.alphabetic,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  LegalUrls.openPrivacy(
                                                      context),
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .termsAndConditions,
                                                style: AuthScreenStyles
                                                        .bodyLinkStyle(context)
                                                    .copyWith(
                                                  fontSize: 13,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: AuthScreenStyles.primaryButtonStyle(
                                    context),
                                child: _isLoading
                                    ? AuthScreenStyles.loadingIndicator(context)
                                    : Text(
                                        AppLocalizations.of(context)!
                                            .createAccount,
                                        style: GoogleFonts.readexPro(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Login Link
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .alreadyHaveAccount,
                                    style: AuthScreenStyles.bodySecondaryStyle(
                                        context),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.go(RouteNames.login),
                                    child: Text(
                                      AppLocalizations.of(context)!.login,
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

  Widget _buildCategoryDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<Map<String, dynamic>> options,
    required ValueChanged<String?> onChanged,
    required String validatorMessage,
    Key? resetKey,
  }) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      decoration: AuthScreenStyles.textFieldDecoration(context),
      child: DropdownButtonFormField<String>(
        key: resetKey,
        initialValue: value,
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AuthScreenStyles.fieldIconColor(context),
        ),
        dropdownColor: context.appTheme.card,
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
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        items: options.map((c) {
          final id = c['id']?.toString() ?? '';
          return DropdownMenuItem(
            value: id,
            child: Text(
              CategoryUtils.displayName(c, arabic: isAr),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (v) => (v == null || v.isEmpty) ? validatorMessage : null,
      ),
    );
  }

  // Student type selector is temporarily disabled.

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isOptional = false,
    TextInputType? keyboardType,
    String passwordFieldType = 'password',
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: AuthScreenStyles.textFieldDecoration(context),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword &&
            (passwordFieldType == 'password'
                ? !_showPassword
                : !_showPasswordConfirmation),
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        style: AuthScreenStyles.fieldTextStyle(context),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AuthScreenStyles.fieldHintStyle(context),
          counterText: maxLength != null ? '' : null,
          prefixIcon: Icon(
            icon,
            color: AuthScreenStyles.fieldIconColor(context),
            size: 22,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () => setState(() {
                    if (passwordFieldType == 'password') {
                      _showPassword = !_showPassword;
                    } else {
                      _showPasswordConfirmation = !_showPasswordConfirmation;
                    }
                  }),
                  icon: Icon(
                    (passwordFieldType == 'password'
                            ? _showPassword
                            : _showPasswordConfirmation)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AuthScreenStyles.fieldSuffixIconColor(context),
                    size: 22,
                  ),
                )
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        validator: (value) {
          final l10n = AppLocalizations.of(context)!;
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) {
            if (isOptional) {
              return null;
            }
            return l10n.fieldRequired;
          }
          if (keyboardType == TextInputType.emailAddress) {
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(trimmed)) {
              return l10n.invalidEmail;
            }
          }
          if (isPassword && passwordFieldType == 'password') {
            final pwdError = PasswordPolicy.validate(trimmed, l10n);
            if (pwdError != null) {
              return pwdError;
            }
          }
          if (isPassword && passwordFieldType == 'confirmation') {
            if (trimmed != _passwordController.text) {
              return l10n.passwordMismatch;
            }
          }
          if (keyboardType == TextInputType.phone) {
            if (!_isValidPhone(trimmed)) {
              return l10n.invalidPhone;
            }
          }
          return null;
        },
      ),
    );
  }
}
