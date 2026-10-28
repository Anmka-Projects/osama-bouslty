import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ticking countdown badge for live sessions.
///
/// - Before [start]: shows `startsLabel` + time remaining until start.
/// - Between [start] and [end] (when [end] given): shows `endsLabel` +
///   remaining session time.
/// - After [end]: shows [endedLabel].
///
/// Rebuilds every second; cheap to use inside list items.
class LiveSessionCountdown extends StatefulWidget {
  final DateTime? start;
  final DateTime? end;
  final String startsLabel;
  final String endsLabel;
  final String endedLabel;

  /// Compact mode shrinks padding/font for use inside lesson list tiles.
  final bool compact;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onStatusChanged;

  const LiveSessionCountdown({
    super.key,
    required this.start,
    this.end,
    required this.startsLabel,
    required this.endsLabel,
    required this.endedLabel,
    this.compact = false,
    this.backgroundColor,
    this.foregroundColor,
    this.onStatusChanged,
  });

  /// `02:14:33` style. When >= 24h prefixes days (`2d 04:12:33`).
  static String formatRemaining(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final days = d.inDays;
    final h = d.inHours % 24;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    final hms = '${two(h)}:${two(m)}:${two(s)}';
    return days > 0 ? '${days}d $hms' : hms;
  }

  @override
  State<LiveSessionCountdown> createState() => _LiveSessionCountdownState();
}

class _LiveSessionCountdownState extends State<LiveSessionCountdown> {
  Timer? _timer;
  int _phase = -2; // -2 init, -1 before-start, 0 during, 1 ended, 2 no-timer

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final phase = _computePhase();
    if (!mounted) return;
    if (phase != _phase) {
      setState(() => _phase = phase);
      widget.onStatusChanged?.call();
    } else {
      setState(() {});
    }
  }

  int _computePhase() {
    final now = DateTime.now();
    final start = widget.start?.toLocal();
    if (start == null) return 2;
    if (now.isBefore(start)) return -1;
    final end = widget.end?.toLocal();
    if (end != null && now.isAfter(end)) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    String label;
    switch (_phase) {
      case -1:
        final remaining = widget.start!.toLocal().difference(DateTime.now());
        label =
            '${widget.startsLabel} ${LiveSessionCountdown.formatRemaining(remaining)}';
        break;
      case 0:
        if (widget.end != null) {
          final remaining = widget.end!.toLocal().difference(DateTime.now());
          label =
              '${widget.endsLabel} ${LiveSessionCountdown.formatRemaining(remaining)}';
        } else {
          label = widget.endsLabel;
        }
        break;
      case 1:
        label = widget.endedLabel;
        break;
      default:
        return const SizedBox.shrink();
    }

    final fg = widget.foregroundColor ?? Colors.white;
    final bg = widget.backgroundColor ?? Colors.black.withOpacity(0.45);

    return Container(
      padding: widget.compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.compact ? 8 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: widget.compact ? 12 : 15, color: fg),
          SizedBox(width: widget.compact ? 4 : 6),
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: GoogleFonts.readexPro(
              fontSize: widget.compact ? 11 : 13,
              fontWeight: FontWeight.w700,
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
