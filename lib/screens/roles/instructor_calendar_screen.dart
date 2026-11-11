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

/// Tutor "الجدول" tab — week strip + day's sessions + edit-availability.
class InstructorCalendarScreen extends StatefulWidget {
  const InstructorCalendarScreen({super.key});

  @override
  State<InstructorCalendarScreen> createState() =>
      _InstructorCalendarScreenState();
}

class _InstructorCalendarScreenState
    extends State<InstructorCalendarScreen> {
  late DateTime _selected;
  late DateTime _weekStart;
  List<SessionBooking> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _weekStart = _selected.subtract(Duration(days: _selected.weekday % 7));
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await TrainerMarketplaceService.instance
          .myBookings(role: 'instructor');
      if (!mounted) return;
      setState(() {
        _bookings = list
            .where((b) => b.status != BookingStatus.cancelled)
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SessionBooking> get _dayBookings => _bookings.where((b) {
        final d = b.scheduledAtUtc.toLocal();
        return d.year == _selected.year &&
            d.month == _selected.month &&
            d.day == _selected.day;
      }).toList()
    ..sort((a, b) => a.scheduledAtUtc.compareTo(b.scheduledAtUtc));

  void _shiftWeek(int weeks) => setState(() =>
      _weekStart = _weekStart.add(Duration(days: 7 * weeks)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Column(
        children: [
          const TutorTopNav(activeTab: 'calendar'),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : ListView(
                    padding:
                        const EdgeInsets.fromLTRB(18, 20, 18, 32),
                    children: [
                      _title(),
                      const SizedBox(height: 18),
                      _weekStrip(),
                      const SizedBox(height: 22),
                      Text(
                        'مواعيد ${DateFormat('EEEE d MMMM', 'ar').format(_selected)}',
                        style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink),
                      ),
                      const SizedBox(height: 12),
                      if (_dayBookings.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24),
                          child: Center(
                            child: Text('لا توجد مواعيد',
                                style: GoogleFonts.readexPro(
                                    fontSize: 13,
                                    color: AppColors.inkMuted)),
                          ),
                        )
                      else
                        ..._dayBookings.map(_sessionCard),
                      const SizedBox(height: 22),
                      _editAvailabilityButton(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _title() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('جدول المواعيد',
                    style: GoogleFonts.readexPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('دروسك ومواعيدك لهذا الأسبوع',
                    style: GoogleFonts.readexPro(
                        fontSize: 12, color: AppColors.inkMuted)),
              ],
            ),
          ),
          Icon(Icons.calendar_today_rounded,
              size: 20, color: AppColors.brandTeal),
        ],
      );

  Widget _weekStrip() {
    final days = List.generate(
        7, (i) => _weekStart.add(Duration(days: i)));
    return Row(
      children: [
        _navArrow(Icons.chevron_left_rounded,
            () => _shiftWeek(-1)),
        const SizedBox(width: 4),
        ...days.map((d) {
          final isSelected = d == _selected;
          final isToday = d ==
              DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = d),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandTeal
                      : isToday
                          ? AppColors.primarySoft
                          : AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSelected
                          ? AppColors.brandTeal
                          : AppColors.line),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('E', 'ar').format(d),
                      style: GoogleFonts.readexPro(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white
                              : AppColors.inkMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: GoogleFonts.readexPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        _navArrow(Icons.chevron_right_rounded,
            () => _shiftWeek(1)),
      ],
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Icon(icon,
            size: 20, color: AppColors.inkSubtle),
      );

  Widget _sessionCard(SessionBooking b) {
    final start =
        DateFormat('HH:mm').format(b.scheduledAtUtc.toLocal());
    final end =
        DateFormat('HH:mm').format(b.endsAtUtc.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        onTap: () => context.push(RouteNames.bookingDetails,
            extra: {'id': b.id, 'instructor': true}),
        child: Row(
          children: [
            Text('$end - $start',
                style: GoogleFonts.readexPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      Text(b.studentName ?? 'طالب',
                          style: GoogleFonts.readexPro(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            AppColors.primarySoft,
                        child: Icon(Icons.person_rounded,
                            size: 16,
                            color: AppColors.brandTeal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(b.offeringTitle ?? '',
                      textAlign: TextAlign.end,
                      style: GoogleFonts.readexPro(
                          fontSize: 12,
                          color: AppColors.inkMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editAvailabilityButton() => SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () =>
              context.push(RouteNames.instructorMarketplace),
          icon: Icon(Icons.edit_calendar_outlined,
              size: 20, color: AppColors.brandTeal),
          label: Text('تعديل أوقات التوفر',
              style: GoogleFonts.readexPro(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brandTeal,
            side: BorderSide(
                color: AppColors.brandTeal, width: 1.6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
}
