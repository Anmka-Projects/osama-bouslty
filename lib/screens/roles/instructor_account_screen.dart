import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../services/auth_service.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/tutor_top_nav.dart';
import '../../widgets/home_spot_video_player_sheet.dart';

/// Tutor "حسابي" tab — reference profile-editor layout.
class InstructorAccountScreen extends StatefulWidget {
  const InstructorAccountScreen({super.key});

  @override
  State<InstructorAccountScreen> createState() =>
      _InstructorAccountScreenState();
}

class _InstructorAccountScreenState extends State<InstructorAccountScreen> {
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  bool _uploadingVideo = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await TrainerMarketplaceService.instance.myTrainerProfile();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _str(List<String> keys) {
    for (final k in keys) {
      final v = _profile[k];
      if (v is List) {
        final joined = v
            .map((e) {
              if (e is Map) {
                return (e['name'] ?? e['title'] ?? '').toString();
              }
              return e.toString();
            })
            .where((e) => e.isNotEmpty)
            .join('، ');
        if (joined.isNotEmpty) return joined;
      } else if (v != null && v.toString().isNotEmpty) {
        return v.toString();
      }
    }
    return '—';
  }

  String _priceLabel() {
    final p = _str(const ['starting_price', 'hourly_rate', 'hourlyRate']);
    if (p == '—') return p;
    final c = _profile['currency']?.toString() ?? '';
    return c.isNotEmpty ? '$p $c' : p;
  }

  Future<void> _editField(String title, List<String> keys, String current,
      {String? field}) async {
    final controller =
        TextEditingController(text: current == '—' ? '' : current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title,
            style: GoogleFonts.readexPro(
                fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          maxLines: null,
          minLines: 2,
          style: GoogleFonts.readexPro(
              fontSize: 15, fontWeight: FontWeight.w600, height: 1.45),
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: title,
            filled: true,
            fillColor: AppColors.brandSand,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.brandTeal, width: 1.6),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.readexPro())),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brandTeal),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('حفظ', style: GoogleFonts.readexPro()),
          ),
        ],
      ),
    );
    if (result == null || field == null) return;
    try {
      dynamic value = result;
      if (field == 'specialties' || field == 'qualifications') {
        final items = result
            .split(RegExp(r'[،,]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        value = field == 'qualifications'
            ? items.map((title) => {'title': title}).toList()
            : items;
      } else if (field == 'years_experience' || field == 'starting_price') {
        value = num.tryParse(result) ?? result;
      }
      await TrainerMarketplaceService.instance
          .updateTrainerProfile({field: value});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم الحفظ', style: GoogleFonts.readexPro())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل الحفظ — في انتظار صيغة الحقل',
              style: GoogleFonts.readexPro())));
    }
  }

  /// "استبدال الفيديو" — bottom sheet: pick from gallery or paste a link.
  Future<void> _changeVideo() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text('الفيديو التعريفي',
                style: GoogleFonts.readexPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.video_library_outlined,
                  color: AppColors.brandTeal),
              title: Text('اختيار فيديو من المعرض',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.readexPro(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: Icon(Icons.link_rounded, color: AppColors.brandTeal),
              title: Text('إدخال رابط فيديو',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.readexPro(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, 'link'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == 'gallery') {
      await _pickFromGallery();
    } else if (choice == 'link') {
      await _editField('رابط الفيديو التعريفي', const ['intro_video_url'], '',
          field: 'intro_video_url');
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _uploadingVideo = true);
    try {
      final url = await UploadService.instance.uploadVideo(File(picked.path));
      await TrainerMarketplaceService.instance
          .updateTrainerProfile({'intro_video_url': url});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('تم رفع الفيديو بنجاح', style: GoogleFonts.readexPro())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل رفع الفيديو', style: GoogleFonts.readexPro())));
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingAvatar = true);
    try {
      final url = await UploadService.instance.uploadImage(File(picked.path));
      await TrainerMarketplaceService.instance
          .updateTrainerProfile({'avatar_url': url});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('تم تحديث الصورة الشخصية', style: GoogleFonts.readexPro())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل رفع الصورة', style: GoogleFonts.readexPro())));
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _str(const ['name', 'display_name', 'full_name']);
    final avatar = _profile['avatar']?.toString() ??
        _profile['avatar_url']?.toString() ??
        '';
    final video = _str(const ['intro_video_url', 'intro_video']);

    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Column(
        children: [
          const TutorTopNav(activeTab: 'account'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                    children: [
                      _header(name),
                      const SizedBox(height: 18),
                      _avatar(avatar, name),
                      const SizedBox(height: 18),
                      _infoRow('الاسم الظاهر',
                          _str(const ['display_name', 'name']), 'display_name'),
                      _infoRow('المسمى التعريفي',
                          _str(const ['headline', 'title']), 'headline'),
                      _infoRow('نبذة عنك', _str(const ['bio']), 'bio'),
                      _infoRow(
                          'المادة',
                          _str(const ['specialties', 'subject', 'specialty']),
                          'specialties'),
                      _infoRow(
                          'المؤهلات',
                          _str(const ['qualifications', 'qualification']),
                          'qualifications'),
                      _infoRow(
                          'الخبرة',
                          _str(const [
                            'years_experience',
                            'experience',
                            'experience_years'
                          ]),
                          'years_experience'),
                      _infoRow(
                          'الأجر بالساعة', _priceLabel(), 'starting_price'),
                      const SizedBox(height: 22),
                      _videoHeader(),
                      const SizedBox(height: 12),
                      _videoCard(video),
                      const SizedBox(height: 14),
                      _videoButtons(),
                      const SizedBox(height: 22),
                      _linkRow(Icons.payments_outlined, 'الأرباح',
                          () => context.push(RouteNames.instructorEarnings)),
                      _linkRow(Icons.schedule_rounded, 'أوقات التوفر',
                          () => context.push(RouteNames.instructorMarketplace)),
                      const SizedBox(height: 12),
                      _logoutButton(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(String name) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تعديل الملف الشخصي',
                    style: GoogleFonts.readexPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('حدّث معلوماتك ليظهر ملفك بشكل أفضل للطلاب',
                    style: GoogleFonts.readexPro(
                        fontSize: 12, color: AppColors.inkMuted)),
                if (name.isNotEmpty && name != '—')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('أ. $name',
                        style: GoogleFonts.readexPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandTeal)),
                  ),
              ],
            ),
          ),
          Icon(Icons.edit_note_rounded, size: 22, color: AppColors.brandTeal),
        ],
      );

  Widget _avatar(String avatar, String name) => Center(
        child: Column(
          children: [
            InkWell(
              onTap: _uploadingAvatar ? null : _pickAvatar,
              borderRadius: BorderRadius.circular(48),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: AppColors.primarySoft,
                    backgroundImage: avatar.isNotEmpty
                        ? NetworkImage(ApiEndpoints.getImageUrl(avatar))
                        : null,
                    child: avatar.isEmpty
                        ? Icon(Icons.person_rounded,
                            size: 40, color: AppColors.brandTeal)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _uploadingAvatar
                          ? const Padding(
                              padding: EdgeInsets.all(5),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.photo_camera_outlined,
                              size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _uploadingAvatar ? null : _pickAvatar,
              child: Text('اختيار صورة شخصية',
                  style: GoogleFonts.readexPro(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandTeal)),
            ),
          ],
        ),
      );

  Widget _infoRow(String label, String value, String? field) => InkWell(
        onTap: field == null
            ? null
            : () => _editField(label, [field], value, field: field),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.inkSubtle),
                  const Spacer(),
                  Text(label,
                      style: GoogleFonts.readexPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkMuted)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: value == '—' ? AppColors.inkSubtle : AppColors.ink,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _videoHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('فيديو تعريفي',
                  style: GoogleFonts.readexPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              Text('عرّف بنفسك وخبراتك للطلاب (حتى 3 دقائق)',
                  style: GoogleFonts.readexPro(
                      fontSize: 11, color: AppColors.inkMuted)),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.play_circle_outline_rounded,
              size: 20, color: AppColors.brandTeal),
        ],
      );

  Future<void> _previewVideo() async {
    final video = _str(const ['intro_video_url', 'intro_video']);
    if (video == '—') return;
    await HomeSpotVideoPlayerSheet.show(
      context,
      video: {'url': video, 'title': 'الفيديو التعريفي'},
    );
  }

  Widget _videoCard(String video) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: video == '—' ? null : _previewVideo,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceRaised,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: video == '—'
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_outlined,
                          size: 36, color: Colors.white54),
                      const SizedBox(height: 6),
                      Text('لا يوجد فيديو بعد',
                          style: GoogleFonts.readexPro(
                              fontSize: 12, color: Colors.white54)),
                    ],
                  )
                : const Icon(Icons.play_circle_fill_rounded,
                    size: 48, color: Colors.white),
          ),
        ),
      );

  Widget _videoButtons() => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _previewVideo,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text('معاينة الملف',
                  style: GoogleFonts.readexPro(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandTeal,
                side: BorderSide(color: AppColors.brandTeal),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: _uploadingVideo ? null : _changeVideo,
              icon: _uploadingVideo
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload_rounded, size: 18),
              label: Text(_uploadingVideo ? 'جاري الرفع…' : 'استبدال الفيديو',
                  style: GoogleFonts.readexPro(fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );

  Widget _linkRow(IconData icon, String label, VoidCallback onTap) => Material(
        color: Colors.transparent,
        child: ListTile(
          tileColor: Colors.transparent,
          onTap: onTap,
          leading: Icon(Icons.chevron_left_rounded,
              color: AppColors.inkSubtle, size: 20),
          title: Text(label,
              textAlign: TextAlign.end,
              style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          trailing: Icon(icon, size: 20, color: AppColors.brandTeal),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      );

  Widget _logoutButton() => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await AuthService.instance.logout();
            if (mounted) context.go(RouteNames.login);
          },
          icon: Icon(Icons.logout_rounded,
              size: 18, color: AppColors.destructive),
          label: Text('تسجيل الخروج',
              style: GoogleFonts.readexPro(
                  fontSize: 14, color: AppColors.destructive)),
          style: OutlinedButton.styleFrom(
            side:
                BorderSide(color: AppColors.destructive.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
