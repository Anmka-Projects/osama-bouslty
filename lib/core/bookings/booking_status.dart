enum BookingStatus {
  requested,
  pendingPayment,
  confirmed,
  scheduled,
  live,
  completed,
  cancelled,
  unknown;

  static BookingStatus parse(String? raw) {
    switch (raw) {
      case 'requested':
        return BookingStatus.requested;
      case 'pending_payment':
        return BookingStatus.pendingPayment;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'scheduled':
        return BookingStatus.scheduled;
      case 'live':
        return BookingStatus.live;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.unknown;
    }
  }

  String get apiValue {
    switch (this) {
      case BookingStatus.requested:
        return 'requested';
      case BookingStatus.pendingPayment:
        return 'pending_payment';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.scheduled:
        return 'scheduled';
      case BookingStatus.live:
        return 'live';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.unknown:
        return 'unknown';
    }
  }
}

enum BookingPaymentStatus {
  unpaid,
  pending,
  paid,
  failed,
  refunded,
  partiallyRefunded,
  unknown;

  static BookingPaymentStatus parse(String? raw) {
    switch (raw) {
      case 'unpaid':
        return BookingPaymentStatus.unpaid;
      case 'pending':
        return BookingPaymentStatus.pending;
      case 'paid':
        return BookingPaymentStatus.paid;
      case 'failed':
        return BookingPaymentStatus.failed;
      case 'refunded':
        return BookingPaymentStatus.refunded;
      case 'partially_refunded':
        return BookingPaymentStatus.partiallyRefunded;
      default:
        return BookingPaymentStatus.unknown;
    }
  }
}

/// Parses money without binary floating-point totals.
class MoneyText {
  static int minorUnits(dynamic value) {
    final raw = value?.toString() ?? '0';
    final negative = raw.trim().startsWith('-');
    final clean = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (clean.isEmpty) return 0;
    final parts = clean.split('.');
    final whole = int.tryParse(parts.first) ?? 0;
    final fracRaw = parts.length > 1 ? parts[1] : '0';
    final frac = int.tryParse((fracRaw + '00').substring(0, 2)) ?? 0;
    final minor = whole * 100 + frac;
    return negative ? -minor : minor;
  }

  static String format(dynamic value, String? currency) {
    final minor = minorUnits(value);
    final sign = minor < 0 ? '-' : '';
    final abs = minor.abs();
    final text = '$sign${abs ~/ 100}.${(abs % 100).toString().padLeft(2, '0')}';
    final code = (currency == null || currency.isEmpty) ? 'USD' : currency;
    return '$text $code';
  }
}
