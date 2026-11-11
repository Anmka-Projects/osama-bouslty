import 'package:flutter_test/flutter_test.dart';
import 'package:educational_app/core/bookings/booking_status.dart';

void main() {
  test('booking status keeps unknown values unknown', () {
    expect(BookingStatus.parse('completed'), BookingStatus.completed);
    expect(BookingStatus.parse('pending_payment'), BookingStatus.pendingPayment);
    expect(BookingStatus.parse('mystery'), BookingStatus.unknown);
    expect(BookingStatus.parse(null), BookingStatus.unknown);
    expect(BookingStatus.unknown.apiValue, 'unknown');
  });

  test('money parsing uses minor units', () {
    expect(MoneyText.minorUnits('230.50'), 23050);
    expect(MoneyText.minorUnits('230.5'), 23050);
    expect(MoneyText.minorUnits(230), 23000);
    expect(MoneyText.minorUnits('-1.25'), -125);
    expect(MoneyText.format('880.00', 'EGP'), '880.00 EGP');
  });

  test('payment status does not treat unknown as paid', () {
    expect(BookingPaymentStatus.parse('paid'), BookingPaymentStatus.paid);
    expect(BookingPaymentStatus.parse('partially_refunded'), BookingPaymentStatus.partiallyRefunded);
    expect(BookingPaymentStatus.parse('settled'), BookingPaymentStatus.unknown);
  });
}
