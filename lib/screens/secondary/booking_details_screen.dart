import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/bookings/booking_error_mapper.dart';
import 'live_session_webview_screen.dart';
import '../../core/bookings/booking_status.dart';
import '../../core/bookings/marketplace_copy.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/navigation/route_names.dart';
import '../../models/trainer_marketplace.dart';
import '../../services/trainer_marketplace_service.dart';
import 'trainer_availability_screen.dart';
import '../../widgets/student_bottom_nav.dart';

class _BookingStyle {
  const _BookingStyle(this.label, this.icon, this.color, this.background);
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
}

_BookingStyle _bookingStyle(BookingStatus status) {
  switch (status) {
    case BookingStatus.requested:
      return const _BookingStyle('بانتظار موافقة المدرّس',
          Icons.hourglass_top_rounded, AppColors.info, AppColors.infoSoft);
    case BookingStatus.pendingPayment:
      return const _BookingStyle('بانتظار تأكيد الدفع',
          Icons.receipt_long_rounded, AppColors.warning, AppColors.warningSoft);
    case BookingStatus.confirmed:
      return const _BookingStyle('تم تأكيد الحجز', Icons.verified_rounded,
          AppColors.success, AppColors.successSoft);
    case BookingStatus.scheduled:
      return const _BookingStyle('الجلسة مجدولة', Icons.event_available_rounded,
          AppColors.brandTeal, AppColors.primarySoft);
    case BookingStatus.live:
      return const _BookingStyle('الجلسة مباشرة الآن', Icons.podcasts_rounded,
          AppColors.destructive, AppColors.dangerSoft);
    case BookingStatus.completed:
      return const _BookingStyle('جلسة مكتملة', Icons.check_circle_rounded,
          AppColors.success, AppColors.successSoft);
    case BookingStatus.cancelled:
      return const _BookingStyle('تم إلغاء الحجز', Icons.cancel_rounded,
          AppColors.destructive, AppColors.dangerSoft);
    case BookingStatus.unknown:
      return const _BookingStyle('حالة غير معروفة', Icons.help_outline_rounded,
          AppColors.inkMuted, AppColors.surfaceSunken);
  }
}

_BookingStyle _paymentStyle(BookingPaymentStatus status) {
  switch (status) {
    case BookingPaymentStatus.paid:
      return const _BookingStyle('مدفوع', Icons.check_circle_rounded,
          AppColors.success, AppColors.successSoft);
    case BookingPaymentStatus.pending:
      return const _BookingStyle('الدفع قيد المراجعة', Icons.schedule_rounded,
          AppColors.warning, AppColors.warningSoft);
    case BookingPaymentStatus.unpaid:
      return const _BookingStyle('غير مدفوع', Icons.payments_outlined,
          AppColors.warning, AppColors.warningSoft);
    case BookingPaymentStatus.failed:
      return const _BookingStyle('فشل الدفع', Icons.error_outline_rounded,
          AppColors.destructive, AppColors.dangerSoft);
    case BookingPaymentStatus.refunded:
      return const _BookingStyle('تم رد المبلغ', Icons.replay_rounded,
          AppColors.info, AppColors.infoSoft);
    case BookingPaymentStatus.partiallyRefunded:
      return const _BookingStyle('تم رد جزء من المبلغ', Icons.replay_rounded,
          AppColors.info, AppColors.infoSoft);
    case BookingPaymentStatus.unknown:
      return const _BookingStyle(
          'حالة الدفع غير معروفة',
          Icons.help_outline_rounded,
          AppColors.inkMuted,
          AppColors.surfaceSunken);
  }
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, this.asInstructor = false});

  final bool asInstructor;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool _loading = true;
  String? _error;
  List<SessionBooking> _rows = [];
  String _filter = 'upcoming';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await TrainerMarketplaceService.instance.myBookings(
        role: widget.asInstructor ? 'instructor' : 'student',
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BookingErrorMapper.message(error, context);
      });
    }
  }

  Timer? _tick;

  List<SessionBooking> get _upcoming => _rows
      .where((r) =>
          r.status != BookingStatus.completed &&
          r.status != BookingStatus.cancelled)
      .toList()
    ..sort((a, b) => a.scheduledAtUtc.compareTo(b.scheduledAtUtc));

  List<SessionBooking> get _done => _rows
      .where((r) =>
          r.status == BookingStatus.completed ||
          r.status == BookingStatus.cancelled)
      .toList()
    ..sort((a, b) => b.scheduledAtUtc.compareTo(a.scheduledAtUtc));

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _tick ??=
        Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  Future<void> _join(SessionBooking b) async {
    final copy = MarketplaceCopy.of(context);
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted || !mic.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(copy.permissionNeeded)));
    }
    try {
      final join = await TrainerMarketplaceService.instance.join(b.id);
      final url = join['join_url']?.toString() ?? '';
      if (!mounted || url.isEmpty) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveSessionWebViewScreen(
            url: url,
            title: b.offeringTitle ?? copy.join,
            stayInApp: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    _startTicker();
    final upcoming = _upcoming;
    final done = _done;
    final onUpcoming = _filter == 'upcoming';

    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              color: AppColors.surfaceRaised,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                children: [
                  Text(widget.asInstructor ? copy.trainerBookings : 'دروسي',
                      style: GoogleFonts.readexPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(height: 12),
                  _segmented(upcoming.length),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: GoogleFonts.readexPro(
                                color: AppColors.inkMuted)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                          children: onUpcoming
                              ? _upcomingContent(upcoming, done, copy)
                              : _doneContent(done, copy),
                        ),
                      ),
          ),
          if (!widget.asInstructor)
            const StudentBottomNav(activeTab: 'lessons'),
        ],
      ),
    );
  }

  Widget _segmented(int upcomingCount) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _segItem('القادمة ($upcomingCount)', 'upcoming'),
            _segItem('المنجزة', 'completed'),
          ],
        ),
      );

  Widget _segItem(String label, String value) {
    final active = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.brandTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.inkMuted)),
        ),
      ),
    );
  }

  List<Widget> _upcomingContent(List<SessionBooking> upcoming,
      List<SessionBooking> done, MarketplaceCopy copy) {
    if (upcoming.isEmpty) {
      return [
        const SizedBox(height: 48),
        _emptyState(
          icon: Icons.calendar_month_outlined,
          title: copy.emptyBookings,
          subtitle: widget.asInstructor
              ? 'طلبات الطلاب الجديدة ستظهر هنا فور وصولها.'
              : 'اختر المدرّس والموعد المناسب، وتابع الحجز من هنا.',
          action: widget.asInstructor ? null : 'استكشف المدرّسين',
        ),
      ];
    }
    final next = upcoming.first;
    final rest = upcoming.skip(1).toList();
    return [
      Text('الدرس القادم',
          style: GoogleFonts.readexPro(
              fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const SizedBox(height: 10),
      _nextLessonCard(next),
      if (rest.isNotEmpty) ...[
        const SizedBox(height: 18),
        Text('باقي المواعيد',
            style: GoogleFonts.readexPro(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        ...rest.map((b) => _compactRow(b)),
      ],
    ];
  }

  List<Widget> _doneContent(List<SessionBooking> done, MarketplaceCopy copy) {
    if (done.isEmpty) {
      return [
        const SizedBox(height: 48),
        _emptyState(
          icon: Icons.history_rounded,
          title: 'لا توجد جلسات سابقة',
          subtitle: 'الجلسات المكتملة أو الملغاة ستظهر هنا.',
        ),
      ];
    }
    return [
      Text('دروس سابقة',
          style: GoogleFonts.readexPro(
              fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const SizedBox(height: 8),
      ...done.map((b) => _compactRow(b, completed: true)),
    ];
  }

  Widget _nextLessonCard(SessionBooking b) {
    final local = b.scheduledAtUtc.toLocal();
    final diff = local.difference(DateTime.now());
    final minutes = b.endsAtUtc.difference(b.scheduledAtUtc).inMinutes;
    final h = diff.inHours.clamp(0, 99);
    final m = diff.inMinutes.remainder(60).clamp(0, 59);
    final s = diff.inSeconds.remainder(60).clamp(0, 59);
    final canJoin = b.canJoin;
    final status = _bookingStyle(b.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandInk.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _statusPill(status),
              const Spacer(),
              Text('الحجز #${b.id.length > 8 ? b.id.substring(0, 8) : b.id}',
                  style: GoogleFonts.readexPro(
                      fontSize: 10, color: AppColors.inkSubtle)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(b.offeringTitle ?? 'درس',
                              textAlign: TextAlign.end,
                              style: GoogleFonts.readexPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            size: 15, color: Color(0xFF2196F3)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                        widget.asInstructor
                            ? (b.studentName ?? '')
                            : 'أ. ${b.trainerName ?? ''}',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.readexPro(
                            fontSize: 13, color: AppColors.inkMuted)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                            DateFormat('EEEE، d MMMM yyyy', 'ar').format(local),
                            style: GoogleFonts.readexPro(
                                fontSize: 12, color: AppColors.inkSubtle)),
                        const SizedBox(width: 6),
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppColors.inkSubtle),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                            '${DateFormat('h:mm').format(b.endsAtUtc.toLocal())} - ${DateFormat('h:mm').format(local)} م ($minutes دقيقة)',
                            style: GoogleFonts.readexPro(
                                fontSize: 12, color: AppColors.inkSubtle)),
                        const SizedBox(width: 6),
                        Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.inkSubtle),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySoft,
                child: Icon(Icons.person_rounded,
                    size: 22, color: AppColors.brandTeal),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: diff.isNegative
                ? Text('الدرس بدأ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.readexPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandSaffron))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _countPart(s.toString().padLeft(2, '0'), 'ثانية'),
                      _countSep(),
                      _countPart(m.toString().padLeft(2, '0'), 'دقيقة'),
                      _countSep(),
                      _countPart(h.toString().padLeft(2, '0'), 'ساعة'),
                      const SizedBox(width: 10),
                      Text('يبدأ الدرس خلال',
                          style: GoogleFonts.readexPro(
                              fontSize: 12, color: AppColors.ink)),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: canJoin ? () => _join(b) : null,
              icon: const Icon(Icons.videocam_rounded, size: 20),
              label: Text('انضم للدرس',
                  style: GoogleFonts.readexPro(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandTeal,
                disabledBackgroundColor:
                    AppColors.inkSubtle.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _openDetails(b),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text('عرض كل تفاصيل الحجز',
                  style: GoogleFonts.readexPro(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(SessionBooking booking) async {
    await context.push(RouteNames.bookingDetails, extra: {
      'id': booking.id,
      'instructor': widget.asInstructor,
    });
    if (mounted) _load();
  }

  Widget _statusPill(_BookingStyle style) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 13, color: style.color),
            const SizedBox(width: 4),
            Text(style.label,
                style: GoogleFonts.readexPro(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: style.color)),
          ],
        ),
      );

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? action,
  }) =>
      Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                    color: AppColors.primarySoft, shape: BoxShape.circle),
                child: Icon(icon, size: 32, color: AppColors.brandTeal),
              ),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.readexPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.readexPro(
                      fontSize: 12.5, height: 1.5, color: AppColors.inkMuted)),
              if (action != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push(RouteNames.teachers),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: Text(action),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _countPart(String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.readexPro(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandTeal)),
          Text(label,
              style: GoogleFonts.readexPro(
                  fontSize: 10, color: AppColors.inkMuted)),
        ],
      );

  Widget _countSep() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(':',
            style: GoogleFonts.readexPro(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.brandTeal)),
      );

  Widget _compactRow(SessionBooking b, {bool completed = false}) {
    final local = b.scheduledAtUtc.toLocal();
    final doneStatus = b.status == BookingStatus.completed;
    return GestureDetector(
      onTap: () => _openDetails(b),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(Icons.chevron_left_rounded,
                size: 20, color: AppColors.inkSubtle),
            const SizedBox(width: 8),
            if (completed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(doneStatus ? Icons.check_circle : Icons.cancel,
                        size: 12,
                        color: doneStatus
                            ? const Color(0xFF16A34A)
                            : AppColors.destructive),
                    const SizedBox(width: 3),
                    Text(doneStatus ? 'مكتمل' : 'ملغي',
                        style: GoogleFonts.readexPro(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: doneStatus
                                ? const Color(0xFF16A34A)
                                : AppColors.destructive)),
                  ],
                ),
              )
            else
              Text(DateFormat('HH:mm').format(local),
                  style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandTeal)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(b.offeringTitle ?? 'درس',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.readexPro(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  Text(
                      '${widget.asInstructor ? (b.studentName ?? '') : 'أ. ${b.trainerName ?? ''}'} · ${DateFormat('EEEE، d MMMM', 'ar').format(local)}',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.readexPro(
                          fontSize: 11, color: AppColors.inkMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.person_rounded,
                  size: 16, color: AppColors.brandTeal),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen(
      {super.key, required this.bookingId, this.asInstructor = false});

  final String bookingId;
  final bool asInstructor;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  SessionBooking? _booking;
  bool _loading = true;
  String? _error;
  final _reason = TextEditingController();
  final _link = TextEditingController();
  List<AvailabilitySlot> _slots = [];
  bool _pickingSlot = false;
  bool _bookFromPackage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking =
          await TrainerMarketplaceService.instance.booking(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BookingErrorMapper.message(error, context);
      });
    }
  }

  Future<void> _join() async {
    final copy = MarketplaceCopy.of(context);
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    if (!cam.isGranted || !mic.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(copy.permissionNeeded)));
    }
    try {
      final join =
          await TrainerMarketplaceService.instance.join(widget.bookingId);
      final url = join['join_url']?.toString() ?? '';
      if (!mounted || url.isEmpty) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LiveSessionWebViewScreen(
            url: url,
            title: _booking?.offeringTitle ?? copy.join,
            stayInApp: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  Future<void> _cancel() async {
    final booking = _booking;
    if (booking == null) return;
    try {
      await TrainerMarketplaceService.instance.cancel(booking.id, _reason.text);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  Future<void> _openSlots({bool fromPackage = false}) async {
    final trainerId = _booking?.trainerId;
    if (trainerId == null || trainerId.isEmpty) return;
    setState(() {
      _pickingSlot = true;
      _bookFromPackage = fromPackage;
      _slots = [];
    });
    try {
      final slots =
          await TrainerMarketplaceService.instance.availability(trainerId);
      if (!mounted) return;
      setState(() {
        _slots = slots.where((slot) => slot.available).take(12).toList();
        _pickingSlot = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _pickingSlot = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  Future<void> _useSlot(AvailabilitySlot slot) async {
    final booking = _booking;
    if (booking == null) return;
    try {
      if (_bookFromPackage &&
          booking.sessionsRemaining > 0 &&
          (booking.packagePurchaseId ?? '').isNotEmpty) {
        await TrainerMarketplaceService.instance.createBooking(
          packagePurchaseId: booking.packagePurchaseId,
          slotId: slot.slotId,
          paymentMethod: 'package',
        );
      } else {
        await TrainerMarketplaceService.instance.reschedule(
          booking.id,
          slotId: slot.slotId,
          version: booking.scheduleVersion,
        );
      }
      if (!mounted) return;
      setState(() => _slots = []);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  Future<void> _publish() async {
    try {
      await TrainerMarketplaceService.instance
          .publishMeeting(widget.bookingId, joinUrl: _link.text.trim());
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  Future<void> _confirmCancel() async {
    final copy = MarketplaceCopy.of(context);
    _reason.clear();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.cancel,
                style: GoogleFonts.readexPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 6),
            Text('اكتب سبب الإلغاء لتوثيقه للطرف الآخر.',
                style: GoogleFonts.readexPro(
                    fontSize: 12.5, color: AppColors.inkMuted)),
            const SizedBox(height: 14),
            TextField(
              controller: _reason,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'سبب الإلغاء',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.destructive,
                  minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('تأكيد إلغاء الحجز',
                  style: GoogleFonts.readexPro(fontWeight: FontWeight.w700)),
            ),
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('رجوع')),
          ],
        ),
      ),
    );
    if (confirmed == true) await _cancel();
  }

  String _joinHint(SessionBooking booking) {
    if (booking.canJoin) return 'غرفة الجلسة جاهزة الآن';
    switch (booking.joinBlockReason) {
      case 'PAYMENT_REQUIRED':
        return 'الدخول يتاح بعد اعتماد الدفع';
      case 'MEETING_NOT_READY':
        return 'رابط الجلسة لم يُنشر بعد';
      case 'JOIN_WINDOW_CLOSED':
        return 'الدخول يتاح قبل الموعد بـ 15 دقيقة';
      case 'BOOKING_NOT_JOINABLE':
        return 'الحالة الحالية لا تسمح بالدخول';
      default:
        return 'سيظهر زر الدخول عند فتح غرفة الجلسة';
    }
  }

  Widget _detailCard({required String title, required List<Widget> children}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandInk.withValues(alpha: 0.035),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                textAlign: TextAlign.end,
                style: GoogleFonts.readexPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            const SizedBox(height: 13),
            ...children,
          ],
        ),
      );

  Widget _detailRow(IconData icon, String label, String value,
          {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppColors.brandTeal),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.readexPro(
                    fontSize: 12, color: AppColors.inkMuted)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.readexPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? AppColors.ink)),
            ),
          ],
        ),
      );

  Widget _detailPill(_BookingStyle style) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 15, color: style.color),
            const SizedBox(width: 5),
            Text(style.label,
                style: GoogleFonts.readexPro(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: style.color)),
          ],
        ),
      );

  Widget _progressTimeline(SessionBooking booking) {
    final cancelled = booking.status == BookingStatus.cancelled;
    final paid = booking.paymentStatus == BookingPaymentStatus.paid;
    final scheduled = [
      BookingStatus.confirmed,
      BookingStatus.scheduled,
      BookingStatus.live,
      BookingStatus.completed,
    ].contains(booking.status);
    final completed = booking.status == BookingStatus.completed;
    final steps = <(String, bool)>[
      ('تم إرسال الطلب', true),
      ('تم اعتماد الدفع', paid),
      ('تم تأكيد الجلسة', scheduled),
      ('اكتملت الجلسة', completed),
    ];
    if (cancelled) {
      return Row(children: [
        const Icon(Icons.cancel_rounded, color: AppColors.destructive),
        const SizedBox(width: 8),
        Text('توقف مسار الحجز بسبب الإلغاء',
            style: GoogleFonts.readexPro(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.destructive)),
      ]);
    }
    return Row(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        return Expanded(
          child: Column(
            children: [
              Row(children: [
                if (index > 0)
                  Expanded(
                      child: Container(
                          height: 2,
                          color:
                              step.$2 ? AppColors.brandTeal : AppColors.line)),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        step.$2 ? AppColors.brandTeal : AppColors.surfaceSunken,
                  ),
                  child: Icon(step.$2 ? Icons.check : Icons.circle,
                      size: step.$2 ? 15 : 7,
                      color: step.$2 ? Colors.white : AppColors.inkSubtle),
                ),
                if (index < steps.length - 1)
                  Expanded(
                      child: Container(
                          height: 2,
                          color: steps[index + 1].$2
                              ? AppColors.brandTeal
                              : AppColors.line)),
              ]),
              const SizedBox(height: 6),
              Text(step.$1,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.readexPro(
                      fontSize: 9.5,
                      height: 1.3,
                      color: step.$2 ? AppColors.ink : AppColors.inkSubtle)),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    final booking = _booking;
    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      appBar: AppBar(
        title: Text('تفاصيل الحجز',
            style: GoogleFonts.readexPro(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
              tooltip: 'تحديث',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 42, color: AppColors.inkSubtle),
                    const SizedBox(height: 10),
                    Text(_error!, style: GoogleFonts.readexPro()),
                    TextButton(onPressed: _load, child: Text(copy.retry)),
                  ]),
                )
              : booking == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: AppColors.headerGradient2,
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [
                                  _detailPill(_bookingStyle(booking.status)),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'نسخ رقم الحجز',
                                    onPressed: () async {
                                      await Clipboard.setData(
                                          ClipboardData(text: booking.id));
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content:
                                                  Text('تم نسخ رقم الحجز')));
                                    },
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 18, color: Colors.white70),
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                Text(booking.offeringTitle ?? 'جلسة مباشرة',
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.readexPro(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white)),
                                const SizedBox(height: 5),
                                Text(
                                    widget.asInstructor
                                        ? 'الطالب: ${booking.studentName ?? '—'}'
                                        : 'المدرّس: ${booking.trainerName ?? '—'}',
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.readexPro(
                                        fontSize: 13, color: Colors.white70)),
                                const SizedBox(height: 14),
                                Text('رقم الحجز: ${booking.id}',
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.readexPro(
                                        fontSize: 10.5, color: Colors.white54)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _detailCard(
                            title: 'تقدم الحجز',
                            children: [_progressTimeline(booking)],
                          ),
                          const SizedBox(height: 14),
                          _detailCard(
                            title: 'موعد الجلسة',
                            children: [
                              _detailRow(
                                  Icons.calendar_today_rounded,
                                  'التاريخ',
                                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(
                                      booking.scheduledAtUtc.toLocal())),
                              _detailRow(Icons.schedule_rounded, 'الوقت',
                                  '${DateFormat('h:mm a', 'ar').format(booking.scheduledAtUtc.toLocal())} — ${DateFormat('h:mm a', 'ar').format(booking.endsAtUtc.toLocal())}'),
                              _detailRow(
                                  Icons.language_rounded,
                                  'التوقيت',
                                  booking.scheduledAtUtc
                                      .toLocal()
                                      .timeZoneName),
                              const Divider(height: 22),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: booking.canJoin
                                      ? AppColors.successSoft
                                      : AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(children: [
                                  Icon(
                                      booking.canJoin
                                          ? Icons.videocam_rounded
                                          : Icons.info_outline_rounded,
                                      color: booking.canJoin
                                          ? AppColors.success
                                          : AppColors.brandTeal),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(_joinHint(booking),
                                        textAlign: TextAlign.end,
                                        style: GoogleFonts.readexPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: booking.canJoin
                                                ? AppColors.success
                                                : AppColors.brandTeal)),
                                  ),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _detailCard(
                            title: 'الدفع والباقة',
                            children: [
                              Row(children: [
                                _detailPill(
                                    _paymentStyle(booking.paymentStatus)),
                                const Spacer(),
                                Text(
                                    MoneyText.format(
                                        booking.amount, booking.currency),
                                    style: GoogleFonts.readexPro(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.brandTeal)),
                              ]),
                              if ((booking.paymentMethod ?? '').isNotEmpty)
                                _detailRow(
                                    Icons.account_balance_wallet_outlined,
                                    'طريقة الدفع',
                                    booking.paymentMethod!),
                              if (booking.sessionsRemaining > 0)
                                _detailRow(
                                    Icons.confirmation_number_outlined,
                                    'الجلسات المتبقية',
                                    '${booking.sessionsRemaining} جلسة'),
                            ],
                          ),
                          if ((booking.studentNotes ?? '').isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _detailCard(title: 'ملاحظات الحجز', children: [
                              Text(booking.studentNotes!,
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.readexPro(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: AppColors.inkMuted)),
                            ]),
                          ],
                          const SizedBox(height: 14),
                          _detailCard(title: 'الإجراءات', children: [
                            if (booking.canJoin)
                              FilledButton.icon(
                                onPressed: _join,
                                icon: const Icon(Icons.videocam_rounded),
                                label: Text(copy.join),
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.brandTeal,
                                    minimumSize: const Size.fromHeight(50)),
                              ),
                            if ((booking.conversationId ?? '').isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => context
                                    .push('/chat/${booking.conversationId}'),
                                icon: const Icon(
                                    Icons.chat_bubble_outline_rounded),
                                label: Text(copy.chat),
                              ),
                            if (booking.canReschedule)
                              OutlinedButton.icon(
                                onPressed: () => _openSlots(),
                                icon: const Icon(Icons.event_repeat_rounded),
                                label: Text(copy.reschedule),
                              ),
                            if (booking.sessionsRemaining > 0)
                              OutlinedButton.icon(
                                onPressed: () => _openSlots(fromPackage: true),
                                icon: const Icon(
                                    Icons.add_circle_outline_rounded),
                                label: Text(
                                    'احجز جلسة من الباقة (${booking.sessionsRemaining})'),
                              ),
                            if (booking.canReview)
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await context.push(RouteNames.bookingReview,
                                      extra: booking.id);
                                  _load();
                                },
                                icon: const Icon(Icons.star_outline_rounded),
                                label: Text(copy.review),
                              ),
                            if (booking.canCancel)
                              TextButton.icon(
                                onPressed: _confirmCancel,
                                icon: const Icon(Icons.cancel_outlined,
                                    color: AppColors.destructive),
                                label: Text(copy.cancel,
                                    style: const TextStyle(
                                        color: AppColors.destructive)),
                              ),
                            if (_pickingSlot && _slots.isEmpty)
                              const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: LinearProgressIndicator()),
                            if (_slots.isNotEmpty) ...[
                              const Divider(height: 24),
                              Text('اختر الموعد الجديد',
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.readexPro(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _slots
                                    .map((slot) => ActionChip(
                                          label: Text(formatBookingTime(
                                              slot.startsAtUtc, context)),
                                          onPressed: () => _useSlot(slot),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ]),
                          if (widget.asInstructor) ...[
                            const SizedBox(height: 14),
                            _detailCard(title: copy.publishLink, children: [
                              TextField(
                                controller: _link,
                                keyboardType: TextInputType.url,
                                decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.link_rounded),
                                    hintText: 'https://',
                                    labelText: copy.meetingLink),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                  onPressed: _publish,
                                  icon: const Icon(Icons.publish_rounded),
                                  label: Text(copy.publishLink)),
                            ]),
                          ],
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(
                                  'https://bouslty.anmka.com/trainers/${booking.trainerId ?? ''}');
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            },
                            icon:
                                const Icon(Icons.open_in_new_rounded, size: 17),
                            label: Text(copy.fallbackBrowser),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class BookingReviewScreen extends StatefulWidget {
  const BookingReviewScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends State<BookingReviewScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await TrainerMarketplaceService.instance
          .review(widget.bookingId, rating: _rating, comment: _comment.text);
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(copy.review)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = value),
                  icon: Icon(
                      value <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36),
                );
              }),
            ),
            TextField(
                controller: _comment,
                maxLines: 4,
                decoration:
                    const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _saving ? null : _save, child: Text(copy.save)),
          ],
        ),
      ),
    );
  }
}
