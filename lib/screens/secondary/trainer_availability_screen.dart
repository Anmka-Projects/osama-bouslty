import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pod_player/pod_player.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/bookings/booking_error_mapper.dart';
import '../../core/bookings/booking_status.dart';
import '../../core/bookings/marketplace_copy.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/navigation/route_names.dart';
import '../../models/trainer_marketplace.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../services/chat_service.dart';
import '../../core/home/home_spot_video_utils.dart';

String formatBookingTime(DateTime utc, BuildContext context) {
  final local = utc.toLocal();
  final locale = Localizations.localeOf(context).toString();
  final formatted = DateFormat('EEE d MMM, h:mm a', locale).format(local);
  return '$formatted · ${local.timeZoneName}';
}

class TrainerIntroVideo extends StatefulWidget {
  const TrainerIntroVideo({super.key, required this.url});

  final String url;

  @override
  State<TrainerIntroVideo> createState() => _TrainerIntroVideoState();
}

class _TrainerIntroVideoState extends State<TrainerIntroVideo> {
  PodPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final source = parseHomeSpotVideoSource({'url': widget.url});
      if (!source.hasSource) throw Exception('Invalid video URL');
      final controller = PodPlayerController(
        playVideoFrom: source.youtubeWatchUrl != null
            ? PlayVideoFrom.youtube(source.youtubeWatchUrl!)
            : PlayVideoFrom.network(source.directUrl!),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: false,
          isLooping: false,
        ),
      );
      _controller = controller;
      await controller.initialise();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: FilledButton.icon(
          onPressed: () => launchUrl(Uri.parse(widget.url),
              mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('فتح الفيديو التعريفي'),
        ),
      );
    }
    if (controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: AppColors.brandDeepTeal,
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: PodVideoPlayer(controller: controller),
    );
  }
}

class TrainerMarketplacePanel extends StatefulWidget {
  const TrainerMarketplacePanel({super.key, required this.trainerId});

  final String trainerId;

  @override
  State<TrainerMarketplacePanel> createState() =>
      _TrainerMarketplacePanelState();
}

class _TrainerMarketplacePanelState extends State<TrainerMarketplacePanel> {
  TrainerProfileDetail? _detail;
  bool _loading = true;
  String? _error;

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
      final detail =
          await TrainerMarketplaceService.instance.trainer(widget.trainerId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(minHeight: 3),
      );
    }
    if (_error != null || _detail == null) return const SizedBox.shrink();
    final detail = _detail!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تعرّف على المعلم',
            style: GoogleFonts.readexPro(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.cardTitle)),
        if ((detail.introVideoUrl ?? '').startsWith('http')) ...[
          const SizedBox(height: 8),
          TrainerIntroVideo(url: detail.introVideoUrl!),
        ],
        const SizedBox(height: 8),
        if ((detail.bio ?? '').isNotEmpty)
          Text(detail.bio!,
              style: GoogleFonts.readexPro(
                  fontSize: 13, height: 1.5, color: context.cardMetaText)),
        if (detail.qualifications.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: detail.qualifications
                .map((item) => Chip(
                    label:
                        Text(item, style: GoogleFonts.readexPro(fontSize: 11))))
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        Text(copy.offerings,
            style: GoogleFonts.readexPro(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.cardTitle)),
        const SizedBox(height: 8),
        ...detail.offerings.map((offering) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.appTheme.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                  color: AppColors.brandTeal.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offering.title,
                    style: GoogleFonts.readexPro(
                        fontWeight: FontWeight.w800, color: context.cardTitle)),
                const SizedBox(height: 4),
                Text(
                  '${offering.durationMinutes} د · ${offering.sessionCount} ${copy.sessions}',
                  style: GoogleFonts.readexPro(
                      fontSize: 12, color: context.cardMetaText),
                ),
                if ((offering.description ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(offering.description!,
                        style: GoogleFonts.readexPro(
                            fontSize: 12, color: context.cardMetaText)),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      MoneyText.format(offering.payable, offering.currency),
                      style: GoogleFonts.readexPro(
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandTeal),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: detail.card.isAcceptingBookings
                          ? () => context
                                  .push(RouteNames.trainerAvailability, extra: {
                                'trainerId': detail.card.id,
                                'trainerName': detail.card.displayName,
                                'offering': {
                                  'id': offering.id,
                                  'title': offering.title,
                                  'payable': offering.payable,
                                  'currency': offering.currency,
                                  'duration_minutes': offering.durationMinutes,
                                },
                              })
                          : null,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandSaffron,
                          foregroundColor: AppColors.brandInk),
                      child: Text(copy.bookNow,
                          style: GoogleFonts.readexPro(
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        if (detail.reviews.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(copy.review,
              style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.w800, color: context.cardTitle)),
          ...detail.reviews.take(3).map((review) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(review['student_name']?.toString() ?? '',
                    style: GoogleFonts.readexPro(fontSize: 13)),
                subtitle: Text(review['comment']?.toString() ?? '',
                    style: GoogleFonts.readexPro(fontSize: 12)),
                trailing: Text('${review['rating'] ?? ''}★'),
              )),
        ],
      ],
    );
  }
}

class TrainerAvailabilityScreen extends StatefulWidget {
  const TrainerAvailabilityScreen(
      {super.key,
      required this.trainerId,
      required this.trainerName,
      required this.offering});

  final String trainerId;
  final String trainerName;
  final Map<String, dynamic> offering;

  @override
  State<TrainerAvailabilityScreen> createState() =>
      _TrainerAvailabilityScreenState();
}

class _TrainerAvailabilityScreenState extends State<TrainerAvailabilityScreen> {
  bool _loading = true;
  String? _error;
  List<AvailabilitySlot> _slots = [];
  DateTime? _selectedDay;
  AvailabilitySlot? _selectedSlot;
  late Map<String, dynamic> _offering;
  bool _contacting = false;

  Future<void> _contactTrainer() async {
    if (_contacting) return;
    setState(() => _contacting = true);
    try {
      final conversation =
          await ChatService.instance.createOrGetConversation(widget.trainerId);
      final id = conversation['id']?.toString() ??
          conversation['conversationId']?.toString() ??
          '';
      if (!mounted || id.isEmpty) return;
      context.push(
        RouteNames.chatMessages.replaceAll(':conversationId', id),
        extra: {
          'conversation': conversation,
          'otherUser': {'id': widget.trainerId, 'name': widget.trainerName},
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))),
        );
      }
    } finally {
      if (mounted) setState(() => _contacting = false);
    }
  }

  Widget _contactCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.brandTeal.withValues(alpha: 0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('مش لاقي موعد مناسب؟',
              style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 5),
          Text(
              'تواصل مع المعلم واتفقوا على الموعد، وبعد ما يفتحه هتقدر تحجزه من هنا.',
              textAlign: TextAlign.end,
              style: GoogleFonts.readexPro(
                  fontSize: 12, color: AppColors.inkMuted)),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _contacting ? null : _contactTrainer,
            icon: _contacting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('تواصل مع المعلم'),
          ),
        ]),
      );

  @override
  void initState() {
    super.initState();
    _offering = Map<String, dynamic>.from(widget.offering);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        TrainerMarketplaceService.instance.availability(widget.trainerId),
        if ((_offering['id']?.toString() ?? '').isEmpty)
          TrainerMarketplaceService.instance.trainer(widget.trainerId),
      ]);
      final slots = results.first as List<AvailabilitySlot>;
      if (!mounted) return;
      if (results.length > 1) {
        final detail = results[1] as TrainerProfileDetail;
        if (detail.offerings.isEmpty) {
          throw Exception('لا توجد جلسات أو باقات متاحة للحجز');
        }
        final first = detail.offerings.first;
        _offering = {
          'id': first.id,
          'title': first.title,
          'payable': first.payable,
          'currency': first.currency,
          'duration_minutes': first.durationMinutes,
        };
      }
      setState(() {
        _slots = slots.where((slot) => slot.available).toList()
          ..sort((a, b) => a.startsAtUtc.compareTo(b.startsAtUtc));
        _loading = false;
        if (_slots.isNotEmpty) {
          final d = _slots.first.startsAtUtc.toLocal();
          _selectedDay = DateTime(d.year, d.month, d.day);
          _selectedSlot = _slots.firstWhere(
              (s) => _sameDay(s.startsAtUtc.toLocal(), _selectedDay!),
              orElse: () => _slots.first);
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BookingErrorMapper.message(error, context);
      });
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> get _days {
    final seen = <String, DateTime>{};
    for (final s in _slots) {
      final d = s.startsAtUtc.toLocal();
      seen.putIfAbsent(DateFormat('yyyy-MM-dd').format(d),
          () => DateTime(d.year, d.month, d.day));
    }
    return seen.values.toList()..sort();
  }

  List<AvailabilitySlot> get _daySlots => _selectedDay == null
      ? const []
      : _slots
          .where((s) => _sameDay(s.startsAtUtc.toLocal(), _selectedDay!))
          .toList();

  void _shiftDay(int dir) {
    final days = _days;
    if (days.isEmpty || _selectedDay == null) return;
    final i = days.indexOf(_selectedDay!);
    final next = i + dir;
    if (next < 0 || next >= days.length) return;
    setState(() {
      _selectedDay = days[next];
      _selectedSlot = _daySlots.isEmpty ? null : _daySlots.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    final duration = int.tryParse(
            '${_offering['duration_minutes'] ?? _offering['duration'] ?? 60}') ??
        60;
    final price = _offering['payable'] ?? _offering['price'] ?? '';
    final currency = _offering['currency']?.toString() ?? '';
    final offeringTitle = _offering['title']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.brandSand,
      appBar: AppBar(
        title: Text('حجز درس',
            style: GoogleFonts.readexPro(
                fontWeight: FontWeight.w800, color: AppColors.ink)),
        centerTitle: true,
        backgroundColor: AppColors.surfaceRaised,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      bottomNavigationBar: _loading || _slots.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _selectedSlot == null
                        ? null
                        : () =>
                            context.push(RouteNames.bookingCheckout, extra: {
                              'trainerId': widget.trainerId,
                              'offering': _offering,
                              'slotId': _selectedSlot!.slotId,
                              'startsAt':
                                  _selectedSlot!.startsAtUtc.toIso8601String(),
                            }),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandTeal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    child: Text('تأكيد الحجز',
                        style: GoogleFonts.readexPro(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _contactCard(),
                    const SizedBox(height: 16),
                    _message(copy, _error!, _load),
                  ],
                )
              : _slots.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _contactCard(),
                        const SizedBox(height: 16),
                        _message(copy, copy.noSlots, _load)
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      children: [
                        _contactCard(),
                        const SizedBox(height: 16),
                        // trainer header
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(widget.trainerName,
                                            textAlign: TextAlign.end,
                                            style: GoogleFonts.readexPro(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.ink)),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.verified_rounded,
                                          size: 17, color: Color(0xFF2196F3)),
                                    ],
                                  ),
                                  Text(offeringTitle,
                                      textAlign: TextAlign.end,
                                      style: GoogleFonts.readexPro(
                                          fontSize: 12,
                                          color: AppColors.inkMuted)),
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
                        const SizedBox(height: 18),

                        _sectionTitle('أختر التاريخ'),
                        const SizedBox(height: 8),
                        _dayStrip(),
                        const SizedBox(height: 16),

                        _sectionTitle('أختر الوقت'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _daySlots.map((slot) {
                            final selected =
                                slot.slotId == _selectedSlot?.slotId;
                            return _selectChip(
                              label: DateFormat('h:mm a', 'ar')
                                  .format(slot.startsAtUtc.toLocal()),
                              selected: selected,
                              onTap: () => setState(() => _selectedSlot = slot),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        _sectionTitle('مدة الدرس'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _selectChip(
                                label: '$duration دقيقة',
                                selected: true,
                                onTap: () {}),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // booking summary card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            children: [
                              _summaryRow('الدرس',
                                  offeringTitle.isEmpty ? '—' : offeringTitle),
                              _summaryRow('المدة', '$duration دقيقة'),
                              _summaryRow(
                                  'السعر',
                                  price.toString().isEmpty
                                      ? '—'
                                      : MoneyText.format(price, currency),
                                  highlight: true),
                              if (_selectedSlot != null)
                                _summaryRow(
                                    'الموعد',
                                    DateFormat('EEEE d MMMM · h:mm a', 'ar')
                                        .format(_selectedSlot!.startsAtUtc
                                            .toLocal())),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      textAlign: TextAlign.end,
      style: GoogleFonts.readexPro(
          fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink));

  Widget _dayStrip() {
    final days = _days;
    return Row(
      children: [
        _arrow(Icons.chevron_left_rounded, () => _shiftDay(-1)),
        const SizedBox(width: 4),
        ...days.take(6).map((d) {
          final selected = _sameDay(d, _selectedDay!);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedDay = d;
                _selectedSlot = _daySlots.isEmpty ? null : _daySlots.first;
              }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color:
                      selected ? AppColors.brandTeal : AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: selected ? AppColors.brandTeal : AppColors.line),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('E', 'ar').format(d),
                        style: GoogleFonts.readexPro(
                            fontSize: 10.5,
                            color:
                                selected ? Colors.white : AppColors.inkMuted)),
                    const SizedBox(height: 3),
                    Text('${d.day}',
                        style: GoogleFonts.readexPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : AppColors.ink)),
                    Text(DateFormat('MMMM', 'ar').format(d),
                        style: GoogleFonts.readexPro(
                            fontSize: 9,
                            color: selected
                                ? Colors.white70
                                : AppColors.inkMuted)),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        _arrow(Icons.chevron_right_rounded, () => _shiftDay(1)),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 20, color: AppColors.inkSubtle),
      );

  Widget _selectChip(
          {required String label,
          required bool selected,
          required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandTeal : AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? AppColors.brandTeal : AppColors.line),
          ),
          child: Text(label,
              style: GoogleFonts.readexPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.ink)),
        ),
      );

  Widget _summaryRow(String label, String value, {bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value,
                style: GoogleFonts.readexPro(
                    fontSize: 13.5,
                    fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                    color: highlight ? AppColors.brandSaffron : AppColors.ink)),
            Text(label,
                style: GoogleFonts.readexPro(
                    fontSize: 13, color: AppColors.inkMuted)),
          ],
        ),
      );

  Widget _message(MarketplaceCopy copy, String text, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                textAlign: TextAlign.center, style: GoogleFonts.readexPro()),
            const SizedBox(height: 12),
            FilledButton(onPressed: retry, child: Text(copy.retry)),
          ],
        ),
      ),
    );
  }
}

class TrainerMatchScreen extends StatefulWidget {
  const TrainerMatchScreen({super.key});

  @override
  State<TrainerMatchScreen> createState() => _TrainerMatchScreenState();
}

class _TrainerMatchScreenState extends State<TrainerMatchScreen> {
  final _query = TextEditingController();
  String _language = 'ar';
  bool _loading = false;
  List<TrainerCard> _results = [];

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final data = await TrainerMarketplaceService.instance
          .listTrainers(query: _query.text, language: _language);
      if (!mounted) return;
      setState(() {
        _results = (data['trainers'] as List).cast<TrainerCard>();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BookingErrorMapper.message(error, context))));
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(copy.match,
              style: GoogleFonts.readexPro(fontWeight: FontWeight.w700))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _query,
            decoration: InputDecoration(
                labelText: copy.trainers, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ar', label: Text('العربية')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {_language},
            onSelectionChanged: (value) =>
                setState(() => _language = value.first),
          ),
          const SizedBox(height: 12),
          FilledButton(
              onPressed: _loading ? null : _search, child: Text(copy.match)),
          const SizedBox(height: 16),
          ..._results.map((trainer) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: (trainer.avatarUrl ?? '').isEmpty
                      ? null
                      : NetworkImage(
                          ApiEndpoints.getImageUrl(trainer.avatarUrl)),
                  child: const Icon(Icons.person),
                ),
                title: Text(trainer.displayName),
                subtitle: Text(trainer.headline ?? ''),
                trailing: Text(trainer.startingPrice == null
                    ? ''
                    : MoneyText.format(
                        trainer.startingPrice, trainer.currency)),
                onTap: () => context.push(RouteNames.teacherDetails, extra: {
                  'id': trainer.id,
                  'name': trainer.displayName,
                  'title': trainer.headline,
                  'avatar': ApiEndpoints.getImageUrl(trainer.avatarUrl),
                }),
              )),
        ],
      ),
    );
  }
}
