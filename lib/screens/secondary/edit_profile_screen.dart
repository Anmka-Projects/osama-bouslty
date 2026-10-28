import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/localization/localization_helper.dart';
import '../../core/navigation/route_names.dart';
import '../../services/profile_service.dart';
import '../../widgets/global_whatsapp_support_fab.dart';
import '../../core/design/app_theme_context.dart';

/// Edit Profile Screen - For updating user profile information
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;

  const EditProfileScreen({
    super.key,
    this.initialProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _countryController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _languageController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  Map<String, dynamic>? _profile;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    _timezoneController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile =
          widget.initialProfile ?? await ProfileService.instance.getProfile();

      setState(() {
        _profile = profile;
        _nameController.text = profile['name']?.toString() ?? '';
        _phoneController.text = profile['phone']?.toString() ?? '';
        _bioController.text = profile['bio']?.toString() ?? '';
        _countryController.text = profile['country']?.toString() ?? '';
        _timezoneController.text = profile['timezone']?.toString() ?? '';
        _languageController.text = profile['language']?.toString() ?? 'ar';
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading profile: $e');
      }
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.errorLoadingProfile,
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.selectImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: context.appTheme.icon),
              title: Text(context.l10n.camera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: context.appTheme.icon),
              title: Text(context.l10n.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Pick image from camera or gallery.
  /// Gallery uses file_picker (Photo Picker) - no READ_MEDIA_IMAGES needed.
  Future<void> _pickImage(ImageSource source) async {
    try {
      String? path;
      if (source == ImageSource.camera) {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        path = image?.path;
      } else {
        // Gallery: use file_picker (Photo Picker) - avoids READ_MEDIA_IMAGES
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        path = result?.files.singleOrNull?.path;
      }

      final validPath = path?.trim();
      if (validPath != null && validPath.isNotEmpty) {
        setState(() {
          _selectedImage = File(validPath);
        });
        // Upload image immediately
        await _uploadAvatar();
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image: $e');
      }
      if (mounted) {
        String errorMessage = context.l10n.errorPickingImage;

        // Check if it's a permission error
        if (e.toString().contains('permission') ||
            e.toString().contains('Permission')) {
          if (source == ImageSource.camera) {
            errorMessage = context.l10n.cameraPermissionDenied;
          } else {
            errorMessage = context.l10n.galleryPermissionDenied;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.errorPickingImage,
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

  /// Upload avatar image
  Future<void> _uploadAvatar() async {
    if (_selectedImage == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      if (kDebugMode) {
        print('📤 Starting avatar upload: ${_selectedImage!.path}');
      }

      final result =
          await ProfileService.instance.uploadAvatar(_selectedImage!.path);

      if (kDebugMode) {
        print('✅ Avatar upload result: $result');
      }

      if (mounted) {
        // Update profile with avatar URLs from response
        setState(() {
          _profile = {
            ...(_profile ?? {}),
            'avatar': result['avatar'] ?? result['data']?['avatar'],
            'avatar_thumbnail': result['avatar_thumbnail'] ??
                result['data']?['avatar_thumbnail'],
          };
        });

        if (kDebugMode) {
          print('📝 Updated profile with avatar: ${_profile?['avatar']}');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.avatarUploaded,
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading avatar: $e');
        print('❌ Error type: ${e.runtimeType}');
        if (e is Exception) {
          print('❌ Exception details: ${e.toString()}');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.errorUploadingAvatar(e.toString()),
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ProfileService.instance.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : null,
        timezone: _timezoneController.text.trim().isNotEmpty
            ? _timezoneController.text.trim()
            : null,
        language: _languageController.text.trim().isNotEmpty
            ? _languageController.text.trim()
            : null,
      );

      if (kDebugMode) {
        print('✅ Profile updated successfully');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.profileUpdated,
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating profile: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.errorUpdatingProfile(e.toString()),
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.cardTitle,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.editProfile,
          style: AppTextStyles.h3(color: context.cardTitle),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: context.appTheme.icon,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    // Profile Picture Section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.orangeLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.appTheme.icon,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: _isUploadingAvatar
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: context.appTheme.icon,
                                      ),
                                    )
                                  : _selectedImage != null
                                      ? Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : _profile?['avatar'] != null
                                          ? Image.network(
                                              _profile!['avatar']?.toString() ??
                                                  '',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Icon(
                                                Icons.person,
                                                size: 60,
                                                color: context.appTheme.icon,
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 60,
                                              color: context.appTheme.icon,
                                            ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingAvatar
                                  ? null
                                  : _showImageSourceDialog,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: context.appTheme.icon,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildWishlistTile(context),
                    const SizedBox(height: 20),

                    // Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: context.l10n.name,
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.l10n.pleaseEnterName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    _buildTextField(
                      controller: _phoneController,
                      label: context.l10n.phone,
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Bio Field
                    _buildTextField(
                      controller: _bioController,
                      label: context.l10n.bio,
                      icon: Icons.description,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    // Country Field
                    _buildTextField(
                      controller: _countryController,
                      label: context.l10n.country,
                      icon: Icons.public,
                    ),
                    const SizedBox(height: 16),

                    // Timezone Field
                    // _buildTextField(
                    //   controller: _timezoneController,
                    //   label: context.l10n.timezone,
                    //   icon: Icons.access_time,
                    // ),
                    const SizedBox(height: 16),

                    // Language Field
                    _buildTextField(
                      controller: _languageController,
                      label: context.l10n.language,
                      icon: Icons.language,
                      readOnly: true,
                      onTap: () {
                        // Show language picker
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(context.l10n.selectLanguage),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: Text(context.l10n.arabic),
                                  onTap: () {
                                    _languageController.text = 'ar';
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  title: Text(context.l10n.english),
                                  onTap: () {
                                    _languageController.text = 'en';
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appTheme.icon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              context.l10n.saveChanges,
                              style: GoogleFonts.readexPro(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                    ),
                  ),
                ),
          const GlobalWhatsappSupportFab(),
        ],
      ),
    );
  }

  Widget _buildWishlistTile(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(RouteNames.bookmarkCourses),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.bookmark_outline_rounded,
                  color: context.appTheme.icon, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.wishlistTitle,
                      style: GoogleFonts.readexPro(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.wishlistMenuSubtitle,
                      style: GoogleFonts.readexPro(
                        fontSize: 12,
                        color: context.cardMetaText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.cardMetaText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      style: GoogleFonts.readexPro(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: context.appTheme.icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.appTheme.icon, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
