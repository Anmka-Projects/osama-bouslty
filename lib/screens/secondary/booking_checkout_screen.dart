import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/bookings/booking_error_mapper.dart';
import '../../core/bookings/booking_status.dart';
import '../../core/bookings/marketplace_copy.dart';
import '../../core/config/course_payment_methods_ui.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/navigation/route_names.dart';
import '../../l10n/app_localizations.dart';
import '../../models/trainer_marketplace.dart';
import '../../services/app_config_service.dart';
import '../../services/live_session_reminder_service.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../services/upload_service.dart';

class BookingCheckoutScreen extends StatefulWidget {
  const BookingCheckoutScreen({
    super.key,
    required this.trainerId,
    required this.offering,
    required this.slotId,
    required this.startsAtIso,
  });

  final String trainerId;
  final Map<String, dynamic> offering;
  final String slotId;
  final String startsAtIso;

  @override
  State<BookingCheckoutScreen> createState() => _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends State<BookingCheckoutScreen> {
  BookingQuote? _quote;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _method;
  String? _receiptUrl;
  final _notes = TextEditingController();
  List<Map<String, dynamic>> _methods = [];

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await AppConfigService.instance.fetchAppConfig();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final methods = CoursePaymentMethodsUi.availableMethods(config, l10n);
      final quote = await TrainerMarketplaceService.instance.quote(
        offeringId: widget.offering['id'].toString(),
        slotId: widget.slotId,
      );
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _methods = methods;
        _method = methods.isEmpty ? 'bank_transfer' : methods.first['id'] as String;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = BookingErrorMapper.message(error, context);
      });
      if (BookingErrorMapper.shouldReloadSlots(error)) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pickReceipt() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final url = await UploadService.instance.uploadImage(File(file.path));
    if (!mounted) return;
    setState(() => _receiptUrl = url);
  }

  Future<void> _submit() async {
    final quote = _quote;
    if (quote == null) return;
    if (quote.isExpired) {
      await _prepare();
      return;
    }
    setState(() => _submitting = true);
    try {
      final booking = await TrainerMarketplaceService.instance.createBooking(
        quoteId: quote.quoteId,
        paymentMethod: _method ?? 'bank_transfer',
        notes: _notes.text,
        receiptUrl: _receiptUrl,
      );
      if (!mounted) return;
      await LiveSessionReminderService.instance.scheduleSessionReminders(
        sessionId: 'booking-${booking.id}',
        courseId: '',
        sessionTitle: booking.offeringTitle ?? 'Session',
        start: booking.scheduledAtUtc.toLocal(),
        notificationTitle: MarketplaceCopy.of(context).myBookings,
        bodyBuilder: (minutes) => minutes == 0 ? 'الجلسة بدأت' : 'الجلسة بعد $minutes دقيقة',
        extra: {'type': 'booking', 'booking_id': booking.id},
      );
      if (!mounted) return;
      context.pushReplacement(RouteNames.bookingDetails, extra: booking.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(BookingErrorMapper.message(error, context))));
      if (BookingErrorMapper.shouldRefreshQuote(error)) await _prepare();
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    final starts = DateTime.tryParse(widget.startsAtIso)?.toLocal();
    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      appBar: AppBar(title: Text(copy.checkout, style: GoogleFonts.readexPro(fontWeight: FontWeight.w700))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: GoogleFonts.readexPro()))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(widget.offering['title']?.toString() ?? '', style: GoogleFonts.readexPro(fontSize: 18, fontWeight: FontWeight.w800)),
                    if (starts != null)
                      Text(DateFormat('EEE d MMM, h:mm a').format(starts), style: GoogleFonts.readexPro(color: context.cardMetaText)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(copy.quote, style: GoogleFonts.readexPro(fontWeight: FontWeight.w700)),
                          Text(MoneyText.format(_quote!.total, _quote!.currency), style: GoogleFonts.readexPro(fontSize: 22, fontWeight: FontWeight.w800)),
                          if (MoneyText.minorUnits(_quote!.discount) > 0)
                            Text('- ${MoneyText.format(_quote!.discount, _quote!.currency)}'),
                          Text(
                            copy.ar ? 'السعر صالح لحد ${_quote!.expiresAtUtc.toLocal().hour}:${_quote!.expiresAtUtc.toLocal().minute.toString().padLeft(2, '0')}' : 'Price holds until ${_quote!.expiresAtUtc.toLocal()}',
                            style: GoogleFonts.readexPro(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RadioGroup<String>(
                      groupValue: _method ?? '',
                      onChanged: (value) => setState(() => _method = value),
                      child: Column(
                        children: _methods.map((method) {
                          final id = method['id'] as String;
                          return RadioListTile<String>(
                            value: id,
                            title: Text(method['title']?.toString() ?? id, style: GoogleFonts.readexPro()),
                            subtitle: Text(method['subtitle']?.toString() ?? '', style: GoogleFonts.readexPro(fontSize: 12)),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickReceipt,
                      icon: const Icon(Icons.receipt_long),
                      label: Text(_receiptUrl == null ? copy.receipt : copy.ar ? 'الإيصال اترفع' : 'Receipt uploaded'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: copy.notes, border: const OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.brandTeal, minimumSize: const Size.fromHeight(52)),
                      child: Text(_submitting ? '...' : copy.payAndBook, style: GoogleFonts.readexPro(fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
    );
  }
}
