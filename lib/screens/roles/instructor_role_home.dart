import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/bookings/booking_status.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../models/trainer_marketplace.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../widgets/tutor_top_nav.dart';

/// Tutor "الرئيسية" tab — reference layout: greeting, next-lesson card,
/// availability toggle card.
class InstructorRoleHome extends StatefulWidget {
  const InstructorRoleHome({super.key});

  @override
  State<InstructorRoleHome> createState() => _InstructorRoleHomeState();
}

class _InstructorRoleHomeState extends State<InstructorRoleHome> {
  SessionBooking? _next;
  bool _accepting = false;
  String _status = '';
  String _name = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile =
          await TrainerMarketplaceService.instance.myTrainerProfile();
      final bookings = await TrainerMarketplaceService.instance
          .myBookings(role: 'instructor');
      bookings.sort(
          (a, b) => a.scheduledAtUtc.compareTo(b.scheduledAtUtc));
      final upcoming = bookings
          .where((item) =>
              item.scheduledAtUtc.isAfter(DateTime.now().toUtc()) &&
              item.status != BookingStatus.cancelled)
          .toList();
      if (!mounted) return;
      setState(() {
        _accepting = profile['is_accepting_bookings'] == true;
        _status = profile['verification_status']?.toString() ?? '';
        _name = (profile['name'] ??
                profile['display_name'] ??
                profile['full_name'] ??
                '')
            .toString();
        _next = upcoming.isEmpty ? null : upcoming.first;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _accepting = value);
    await TrainerMarketplaceService.instance
        .updateTrainerProfile({'is_accepting_bookings': value});
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('التغيير اترسل وبانتظار موافقة الأدمن')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Column(
        children: [
          const TutorTopNav(activeTab: 'home'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 40),
              children: [
                // ── Greeting ──
                Text(
                  _name.isNotEmpty
                      ? 'مرحبًا، أ. $_name 👋'
                      : 'مرحبًا 👋',
                  style: GoogleFonts.readexPro(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  'إليك ملخص نشاطك اليوم',
                  style: GoogleFonts.readexPro(
                      fontSize: 13, color: AppColors.inkMuted),
                ),

                if (_status.isNotEmpty && _status != 'approved')
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ملفك $_status. أي تعديل أو فيديو أو سعر يظهر للطلاب بعد موافقة الأدمن.',
                      style: GoogleFonts.readexPro(fontSize: 12),
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Next lesson card ──
                _card(child: _nextLessonContent()),

                const SizedBox(height: 16),

                // ── Availability toggle card ──
                _card(child: _availabilityRow()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextLessonContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 26),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final b = _next;
    if (b == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text('لا يوجد درس قادم',
              style: GoogleFonts.readexPro(
                  fontSize: 13, color: AppColors.inkMuted)),
        ),
      );
    }

    final day = DateFormat('EEEE d MMMM', 'ar')
        .format(b.scheduledAtUtc.toLocal());
    final start =
        DateFormat('HH:mm').format(b.scheduledAtUtc.toLocal());
    final end = DateFormat('HH:mm').format(b.endsAtUtc.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // card header: title + icon
        Row(
          children: [
            Expanded(
              child: Text(
                'الدرس القادم',
                textAlign: TextAlign.start,
                style: GoogleFonts.readexPro(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
            ),
            Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.brandTeal),
          ],
        ),
        const SizedBox(height: 14),

        // student row + arrow
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.chevron_left_rounded,
                size: 22, color: AppColors.inkSubtle),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        b.studentName ?? 'طالب',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.primarySoft,
                        child: Icon(Icons.person_rounded,
                            size: 18, color: AppColors.brandTeal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.offeringTitle ?? '',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.readexPro(
                        fontSize: 13, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('اليوم، $day',
                          style: GoogleFonts.readexPro(
                              fontSize: 13,
                              color: AppColors.inkSubtle)),
                      const SizedBox(width: 6),
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.inkSubtle),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('$end - $start',
                          style: GoogleFonts.readexPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                      const SizedBox(width: 6),
                      Icon(Icons.schedule_rounded,
                          size: 14, color: AppColors.inkSubtle),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // details button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => context.push(
              RouteNames.bookingDetails,
              extra: {'id': b.id, 'instructor': true},
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandTeal,
              side: BorderSide(color: AppColors.brandTeal, width: 1.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('عرض تفاصيل الدرس',
                style: GoogleFonts.readexPro(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _availabilityRow() => Row(
        children: [
          Switch(
            value: _accepting,
            activeThumbColor: AppColors.brandTeal,
            onChanged: _toggle,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'متاح للحجوزات عبر الإنترنت',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.readexPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  'يمكن للطلاب حجز دروس جديدة معك الآن',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.readexPro(
                      fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _accepting
                  ? const Color(0xFF22C55E)
                  : AppColors.inkSubtle,
              shape: BoxShape.circle,
            ),
          ),
        ],
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandInk.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );
}
