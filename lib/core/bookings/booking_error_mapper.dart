import 'package:flutter/widgets.dart';
import '../api/api_client.dart';
import 'marketplace_copy.dart';

class BookingErrorMapper {
  static String message(Object error, BuildContext context) {
    final copy = MarketplaceCopy.of(context);
    final code = error is ApiException ? error.code : null;
    switch (code) {
      case 'SLOT_NO_LONGER_AVAILABLE':
        return copy.ar
            ? 'الميعاد ده اتاخد. اختار ميعاد تاني.'
            : 'That time was just taken. Pick another one.';
      case 'QUOTE_EXPIRED':
        return copy.ar
            ? 'السعر انتهت صلاحيته. هنحسبه من جديد.'
            : 'The price expired. We will refresh it.';
      case 'PAYMENT_REQUIRED':
        return copy.ar
            ? 'الدفع لسه مش متأكد.'
            : 'Payment is still required.';
      case 'BOOKING_NOT_JOINABLE':
        return copy.ar
            ? 'الجلسة مش قابلة للدخول دلوقتي.'
            : 'This session cannot be joined right now.';
      case 'JOIN_WINDOW_CLOSED':
        return copy.ar
            ? 'وقت الدخول خلّص أو لسه بدري.'
            : 'The join window is closed.';
      case 'MEETING_NOT_READY':
        return copy.ar
            ? 'المدرب لسه مرفّعش رابط الجلسة.'
            : 'The trainer has not published the session link yet.';
      case 'RESCHEDULE_CONFLICT':
        return copy.ar
            ? 'الميعاد اتغيّر. حدّث الصفحة واختار من جديد.'
            : 'The schedule changed. Refresh and choose again.';
      case 'CANCELLATION_NOT_ALLOWED':
        return copy.ar
            ? 'الإلغاء مش متاح في الوقت ده.'
            : 'Cancellation is not allowed this close to the session.';
      case 'REVIEW_NOT_ALLOWED':
        return copy.ar ? 'التقييم مش متاح.' : 'A review is not allowed.';
      case 'PAYOUT_NOT_ALLOWED':
        return copy.ar
            ? 'مبلغ السحب أكبر من الرصيد المتاح.'
            : 'That payout is above the available balance.';
      default:
        final text = error.toString().replaceFirst('Exception: ', '');
        return text;
    }
  }

  static bool shouldReloadSlots(Object error) {
    final code = error is ApiException ? error.code : null;
    return code == 'SLOT_NO_LONGER_AVAILABLE' || code == 'RESCHEDULE_CONFLICT';
  }

  static bool shouldRefreshQuote(Object error) {
    return error is ApiException && error.code == 'QUOTE_EXPIRED';
  }
}
