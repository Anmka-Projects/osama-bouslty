import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_theme_extension.dart';
import '../../core/live/live_lesson_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../services/live_session_reminder_service.dart';
import '../../widgets/live_countdown_badge.dart';
import 'live_session_webview_screen.dart';

/// In-app live lesson/session screen.
///
/// Shows a countdown to the session start, a "Remind me" action that
/// schedules local notifications, and opens the meeting link inside a
/// WebView once the session can be joined.
class LiveLessonScreen extends StatefulWidget {
  final Map<String, dynamic>? lesson;
  final String? courseId;
  final String? courseTitle;

  const LiveLessonScreen({
    super.key,
    this.lesson,
    this.courseId,
    this.courseTitle,
  });

  @override
  State<LiveLessonScreen> createState() => _LiveLessonScreenState();
}

class _LiveLessonScreenState extends State<LiveLessonScreen> {
  AppThemeExtension get _theme => AppThemeExtension.of(context);

  Timer? _statusTimer;
  bool _reminderScheduled = false;
  bool _reminderBusy = false;

  Map<String, dynamic> get _lesson =>
      widget.lesson ?? const <String, dynamic>{};

  String? get _link => LiveLessonUtils.liveLink(_lesson);
  DateTime? get _start => LiveLessonUtils.scheduledAt(_lesson);
  DateTime? get _end => LiveLessonUtils.endsAt(_lesson);

  LiveLessonStatus get _status => LiveLessonUtils.status(_lesson);

  String get _sessionKey =>
      _lesson['id']?.toString() ?? _lesson['title']?.toString() ?? 'live';

  @override
  void initState() {
    super.initState();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _loadReminderState();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<void> _loadReminderState() async {
    final pending =
        await LiveSessionReminderService.instance.hasPendingReminders(
      _sessionKey,
    );
    if (mounted) setState(() => _reminderScheduled = pending);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleReminder() async {
    if (_reminderBusy) return;
    setState(() => _reminderBusy = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      if (_reminderScheduled) {
        await LiveSessionReminderService.instance
            .cancelSessionReminders(_sessionKey);
        if (mounted) setState(() => _reminderScheduled = false);
      } else {
        final start = _start;
        if (start == null) return;
        final title = _lesson['title']?.toString() ?? l10n.liveLesson;
        await LiveSessionReminderService.instance.scheduleSessionReminders(
          sessionId: _sessionKey,
          courseId: widget.courseId ?? '',
          lessonId: _lesson['id']?.toString(),
          sessionTitle: title,
          start: start,
          notificationTitle: l10n.liveSessionReminderTitle,
          bodyBuilder: (minutes) => minutes <= 0
              ? l10n.liveSessionReminderNowBody(title)
              : l10n.liveSessionReminderBody(title, minutes),
        );
        if (mounted) setState(() => _reminderScheduled = true);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ reminder toggle failed: $e');
    } finally {
      if (mounted) setState(() => _reminderBusy = false);
      if (mounted && _reminderScheduled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.reminderSet,
              style: GoogleFonts.readexPro(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  void _join() {
    final link = _link;
    if (link == null || link.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(l10n.sessionLinkUnavailable, style: GoogleFonts.readexPro()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveSessionWebViewScreen(
          url: link,
          title: _lesson['title']?.toString(),
        ),
      ),
    );
  }

  String _formatWhen(BuildContext context) {
    final start = _start;
    if (start == null) return '—';
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMEd(locale).add_jm().format(start.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      body: Column(
        children: [
          _buildHeader(l10n),
          Expanded(
            child: _buildInfoPanel(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final status = _status;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.headerGradient2,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 14,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.whiteOverlay20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lesson['title']?.toString() ?? l10n.liveLesson,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.readexPro(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.courseTitle ?? l10n.liveSession,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.readexPro(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (status == LiveLessonStatus.live)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.liveNow,
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else
            LiveSessionCountdown(
              start: _start,
              end: _end,
              startsLabel: l10n.startsIn,
              endsLabel: l10n.endsIn,
              endedLabel: l10n.liveSessionButtonEnded,
              compact: true,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(AppLocalizations l10n) {
    final status = _status;
    final canJoin = LiveLessonUtils.canJoinNow(_lesson);
    final durationMinutes = LiveLessonUtils.durationMinutes(_lesson);
    final platform = LiveLessonUtils.platform(_lesson);

    if (status == LiveLessonStatus.ended ||
        status == LiveLessonStatus.cancelled) {
      return _centeredPanel(
        icon: Icons.videocam_off_rounded,
        title: l10n.liveSessionButtonEnded,
        subtitle: _formatWhen(context),
      );
    }

    final showCountdown = status == LiveLessonStatus.upcoming && !canJoin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: _theme.icon.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.live_tv_rounded,
              size: 46,
              color: _theme.icon,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _lesson['title']?.toString() ?? l10n.liveLesson,
            textAlign: TextAlign.center,
            style: GoogleFonts.readexPro(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _theme.cardTitle,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, size: 16, color: _theme.cardMetaText),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _formatWhen(context),
                  style: GoogleFonts.readexPro(
                    fontSize: 13,
                    color: _theme.cardMetaText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (durationMinutes > 0)
                _metaChip(
                  Icons.timelapse_outlined,
                  '$durationMinutes min',
                ),
              if (platform != null)
                _metaChip(Icons.videocam_outlined, platform),
            ],
          ),
          const SizedBox(height: 28),
          if (_start != null)
            LiveSessionCountdown(
              start: _start,
              end: _end,
              startsLabel: l10n.startsIn,
              endsLabel: l10n.endsIn,
              endedLabel: l10n.liveSessionButtonEnded,
              backgroundColor: _theme.icon.withOpacity(0.9),
            ),
          if (showCountdown) ...[
            const SizedBox(height: 12),
            Text(
              l10n.sessionNotStartedYet,
              style: GoogleFonts.readexPro(
                fontSize: 13,
                color: _theme.cardMetaText,
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canJoin ? _join : null,
              style: FilledButton.styleFrom(
                backgroundColor: _theme.icon,
                disabledBackgroundColor: _theme.progressTrack,
                foregroundColor: AppColors.navyDeep,
                disabledForegroundColor: _theme.mutedForeground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.login_rounded),
              label: Text(
                canJoin ? l10n.joinNow : l10n.liveSessionButtonUpcoming,
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (status == LiveLessonStatus.upcoming && _start != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _reminderBusy ? null : _toggleReminder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _theme.icon,
                  side: BorderSide(color: _theme.icon),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  _reminderScheduled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                ),
                label: Text(
                  _reminderScheduled ? l10n.reminderOn : l10n.remindMe,
                  style: GoogleFonts.readexPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _theme.cardMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _theme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _theme.cardMetaText),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.readexPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _theme.cardMetaText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _centeredPanel({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _theme.cardMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: _theme.cardMetaText),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.readexPro(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _theme.cardTitle,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  color: _theme.cardMetaText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
