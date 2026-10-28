import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../services/profile_service.dart';
import '../../services/teacher_dashboard_service.dart';
import '../../core/design/app_theme_context.dart';

/// Instructor – Mark student attendance by QR code value.
///
/// Camera scanning via `mobile_scanner` was removed (it excludes arm64 on iOS
/// simulator). Instructors enter/paste the student's QR payload instead.
/// API: POST /api/attendance/scan with qr_code, course_id, session_title.
class InstructorScanQrScreen extends StatefulWidget {
  const InstructorScanQrScreen({super.key});

  @override
  State<InstructorScanQrScreen> createState() => _InstructorScanQrScreenState();
}

class _InstructorScanQrScreenState extends State<InstructorScanQrScreen> {
  final TextEditingController _sessionTitleController =
      TextEditingController(text: '');
  final TextEditingController _qrCodeController = TextEditingController();
  bool _isProcessing = false;
  String? _error;
  bool _coursesLoading = true;
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _sessionTitleController.dispose();
    _qrCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _coursesLoading = true);
    try {
      final profile = await ProfileService.instance.getProfile();
      final userId = profile['id']?.toString() ?? '';
      if (userId.isEmpty) {
        setState(() {
          _coursesLoading = false;
          _courses = [];
        });
        return;
      }
      final data = await TeacherDashboardService.instance.getMyCourses(
        instructorId: userId,
        limit: 100,
      );
      final list = data['data'] ?? data;
      final listMap = list is List
          ? list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _courses = listMap;
          _coursesLoading = false;
          if (_courses.isNotEmpty && _selectedCourseId == null) {
            _selectedCourseId = _courses.first['id']?.toString();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ InstructorScanQrScreen loadCourses: $e');
      if (mounted) {
        setState(() {
          _coursesLoading = false;
          _courses = [];
        });
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (_isProcessing) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final courseId = _selectedCourseId?.trim();
    final sessionTitle = _sessionTitleController.text.trim();
    final code = _qrCodeController.text.trim();

    if (courseId == null || courseId.isEmpty || sessionTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'اختر الدورة وأدخل عنوان الجلسة أولاً'
                : 'Select a course and enter session title first',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'أدخل كود QR الخاص بالطالب' : 'Enter the student QR code',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await TeacherDashboardService.instance.scanAttendance(
        code,
        courseId: courseId,
        sessionTitle: sessionTitle,
      );
      if (!mounted) return;
      _qrCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تم تسجيل الحضور بنجاح' : 'Attendance marked successfully',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _error ?? (isAr ? 'فشل تسجيل الحضور' : 'Failed to mark attendance'),
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.appTheme.icon,
        foregroundColor: Colors.white,
        title: Text(
          isAr ? 'تسجيل الحضور' : 'Mark Attendance',
          style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(RouteNames.instructorProfile),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isAr ? 'اختر الدورة والجلسة' : 'Course & session',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.appTheme.cardTitle,
            ),
          ),
          const SizedBox(height: 12),
          if (_coursesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: InputDecoration(
                filled: true,
                fillColor: context.appTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.readexPro(
                color: context.appTheme.cardTitle,
                fontSize: 14,
              ),
              hint: Text(
                isAr ? 'الدورة' : 'Course',
                style: GoogleFonts.readexPro(),
              ),
              items: _courses.map((c) {
                final id = c['id']?.toString() ?? '';
                final title = c['title']?.toString() ?? id;
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.readexPro(),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCourseId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sessionTitleController,
              style: GoogleFonts.readexPro(fontSize: 14),
              decoration: InputDecoration(
                hintText: isAr
                    ? 'عنوان الجلسة (مثل: المحاضرة الأولى)'
                    : 'Session title (e.g. Lecture 1)',
                hintStyle: GoogleFonts.readexPro(),
                filled: true,
                fillColor: context.appTheme.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            isAr ? 'كود QR للطالب' : 'Student QR code',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.appTheme.cardTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'أدخل أو الصق قيمة كود QR الخاص بالطالب لتسجيل الحضور.'
                : 'Enter or paste the student QR code value to mark attendance.',
            style: GoogleFonts.readexPro(
              fontSize: 13,
              color: context.appTheme.cardMetaText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _qrCodeController,
            style: GoogleFonts.readexPro(fontSize: 14),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitAttendance(),
            decoration: InputDecoration(
              hintText: isAr ? 'قيمة كود QR' : 'QR code value',
              hintStyle: GoogleFonts.readexPro(),
              prefixIcon: Icon(
                Icons.qr_code_rounded,
                color: context.appTheme.icon,
              ),
              filled: true,
              fillColor: context.appTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _submitAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appTheme.icon,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isAr ? 'تسجيل الحضور' : 'Mark attendance',
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
