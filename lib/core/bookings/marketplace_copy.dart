import 'package:flutter/material.dart';

class MarketplaceCopy {
  MarketplaceCopy(this.ar);

  final bool ar;

  factory MarketplaceCopy.of(BuildContext context) {
    return MarketplaceCopy(Localizations.localeOf(context).languageCode == 'ar');
  }

  String get trainers => ar ? 'المدربون' : 'Trainers';
  String get bookSession => ar ? 'احجز جلسة' : 'Book a session';
  String get bookNow => ar ? 'احجز الآن' : 'Book now';
  String get myBookings => ar ? 'حجوزاتي' : 'My bookings';
  String get offerings => ar ? 'الجلسات والباقات' : 'Sessions and packages';
  String get availability => ar ? 'المواعيد المتاحة' : 'Available times';
  String get noSlots => ar ? 'لا توجد مواعيد في هذه الفترة' : 'No open times in this range';
  String get checkout => ar ? 'تأكيد الحجز' : 'Confirm booking';
  String get quote => ar ? 'السعر المعتمد' : 'Confirmed price';
  String get notes => ar ? 'ملاحظة للمدرب' : 'Note for the trainer';
  String get payAndBook => ar ? 'ادفع واحجز' : 'Pay and book';
  String get receipt => ar ? 'إيصال الدفع' : 'Payment receipt';
  String get upcoming => ar ? 'القادمة' : 'Upcoming';
  String get live => ar ? 'مباشر' : 'Live';
  String get completed => ar ? 'المكتملة' : 'Completed';
  String get cancelled => ar ? 'الملغية' : 'Cancelled';
  String get join => ar ? 'ادخل الجلسة' : 'Join session';
  String get cancel => ar ? 'إلغاء الحجز' : 'Cancel booking';
  String get reschedule => ar ? 'تغيير الموعد' : 'Reschedule';
  String get review => ar ? 'قيّم الجلسة' : 'Review session';
  String get chat => ar ? 'محادثة الحجز' : 'Booking chat';
  String get emptyBookings => ar ? 'لسه ما عندكش حجوزات' : 'You have no bookings yet';
  String get trainerBookings => ar ? 'حجوزات الطلاب' : 'Student bookings';
  String get manageAvailability => ar ? 'مواعيد الحجز' : 'Booking hours';
  String get trainerProfile => ar ? 'ملف المدرب' : 'Trainer profile';
  String get payouts => ar ? 'طلبات السحب' : 'Payouts';
  String get meetingLink => ar ? 'رابط الجلسة' : 'Session link';
  String get save => ar ? 'حفظ' : 'Save';
  String get retry => ar ? 'إعادة المحاولة' : 'Try again';
  String get fromPrice => ar ? 'يبدأ من' : 'From';
  String get sessions => ar ? 'جلسة' : 'sessions';
  String get experience => ar ? 'سنوات خبرة' : 'years';
  String get match => ar ? 'رشّح لي مدرب' : 'Match me';
  String get timezoneLabel => ar ? 'التوقيت' : 'Timezone';
  String get pendingPayment => ar ? 'بانتظار تأكيد الدفع' : 'Waiting for payment approval';
  String get requestPayout => ar ? 'اطلب سحب' : 'Request payout';
  String get availableBalance => ar ? 'المتاح' : 'Available';
  String get publishLink => ar ? 'نشر رابط الدخول' : 'Publish join link';
  String get fallbackBrowser => ar ? 'فتح في المتصفح' : 'Open in browser';
  String get permissionNeeded =>
      ar ? 'محتاجين الميكروفون والكاميرا عشان الجلسة' : 'Camera and microphone are needed for the session';
}
