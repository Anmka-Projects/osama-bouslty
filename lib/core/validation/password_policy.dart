import '../../l10n/app_localizations.dart';

/// Password rules: ≥8 characters, letters and digits only, at least one letter and one digit.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;

  static String? validate(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length < minLength) {
      return l10n.passwordMinLength;
    }
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
      return l10n.passwordOnlyLettersAndDigits;
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return l10n.passwordNeedsDigit;
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return l10n.passwordNeedsLetter;
    }
    return null;
  }
}
