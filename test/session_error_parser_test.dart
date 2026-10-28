import 'package:educational_app/core/auth/session_error_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isLoggedInFromAnotherDeviceMessage', () {
    test('returns true for english another-device message', () {
      const message = 'You have been logged in from another device';
      expect(isLoggedInFromAnotherDeviceMessage(message), isTrue);
    });

    test('returns true for arabic another-device message', () {
      const message = 'تم تسجيل الدخول من جهاز آخر';
      expect(isLoggedInFromAnotherDeviceMessage(message), isTrue);
    });

    test('returns false for unrelated unauthorized message', () {
      const message = 'Unauthorized access token';
      expect(isLoggedInFromAnotherDeviceMessage(message), isFalse);
    });
  });
}
