import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/bookings/booking_error_mapper.dart';
import '../../core/design/app_colors.dart';
import '../../models/trainer_marketplace.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../widgets/tutor_top_nav.dart';

class InstructorRequestsScreen extends StatefulWidget {
  const InstructorRequestsScreen({super.key});

  @override
  State<InstructorRequestsScreen> createState() =>
      _InstructorRequestsScreenState();
}

class _InstructorRequestsScreenState extends State<InstructorRequestsScreen> {
  List<SessionBooking> _rows = [];
  bool _loading = true;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await TrainerMarketplaceService.instance
          .myBookings(role: 'instructor', status: 'requested');
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  Future<void> _answer(SessionBooking booking, bool accept) async {
    setState(() => _busy.add(booking.id));
    try {
      await TrainerMarketplaceService.instance
          .respondToRequest(booking.id, accept: accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(accept ? 'تم قبول الطلب' : 'تم رفض الطلب'),
        backgroundColor:
            accept ? AppColors.brandTeal : AppColors.inkSubtle,
      ));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(BookingErrorMapper.message(error, context))));
    } finally {
      if (mounted) setState(() => _busy.remove(booking.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Column(
        children: [
          const TutorTopNav(activeTab: 'requests'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                Text(
                  'طلبات الحجز',
                  style: GoogleFonts.readexPro(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'طلبات جديدة ومعلقة من الطلاب',
                  style: GoogleFonts.readexPro(
                      fontSize: 14, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator())),
                if (!_loading && _rows.isEmpty)
                  _emptyState(),
                for (final booking in _rows) _requestCard(booking),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded,
                size: 48, color: AppColors.inkSubtle),
            const SizedBox(height: 10),
            Text('لا توجد طلبات جديدة',
                style: GoogleFonts.readexPro(
                    fontSize: 15, color: AppColors.inkMuted)),
          ],
        ),
      );

  Widget _requestCard(SessionBooking booking) {
    final busy = _busy.contains(booking.id);
    final dateStr = DateFormat('EEEE d MMMM', 'ar')
        .format(booking.scheduledAtUtc.toLocal());
    final timeStr = _timeRange(booking);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "طلب جديد" tag
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'طلب جديد',
              style: GoogleFonts.readexPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandTeal),
            ),
          ),
          const SizedBox(height: 12),

          // student row
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  (booking.studentName ?? 'ط').trim().isNotEmpty
                      ? booking.studentName!.trim()[0]
                      : 'ط',
                  style: GoogleFonts.readexPro(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandTeal,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.studentName ?? 'طالب',
                      style: GoogleFonts.readexPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    Text(
                      booking.offeringTitle ?? '',
                      style: GoogleFonts.readexPro(
                          fontSize: 13, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // date + time
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 15, color: AppColors.inkSubtle),
              const SizedBox(width: 6),
              Text(dateStr,
                  style: GoogleFonts.readexPro(
                      fontSize: 13, color: AppColors.inkSubtle)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 15, color: AppColors.inkSubtle),
              const SizedBox(width: 6),
              Text(timeStr,
                  style: GoogleFonts.readexPro(
                      fontSize: 13, color: AppColors.inkSubtle)),
            ],
          ),

          const SizedBox(height: 16),
          // accept / decline buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed:
                        busy ? null : () => _answer(booking, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkSubtle,
                      side: BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('رفض',
                        style: GoogleFonts.readexPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed:
                        busy ? null : () => _answer(booking, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandTeal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Text('قبول',
                            style: GoogleFonts.readexPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeRange(SessionBooking booking) {
    final start = DateFormat('HH:mm').format(booking.scheduledAtUtc.toLocal());
    final end = DateFormat('HH:mm').format(booking.endsAtUtc.toLocal());
    return '$start - $end';
  }
}
