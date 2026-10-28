import '../../l10n/app_localizations.dart';

List<String> libraryPaymentStepTextsNoReceipt(AppLocalizations l10n) => [
      l10n.libraryPaymentStep1,
      l10n.libraryPaymentStep2,
      l10n.libraryPaymentStep3NoReceipt,
      l10n.libraryPaymentStep4,
    ];

List<String> libraryPaymentStepTextsWithReceipt(AppLocalizations l10n) => [
      l10n.libraryPaymentStep1,
      l10n.libraryPaymentStep2,
      l10n.libraryPaymentStep3,
      l10n.libraryPaymentStep4,
    ];

/// WhatsApp bank transfer: two steps only (see [LibraryPaymentProcessScreen] when `whatsapp`).
List<String> whatsappPaymentStepTexts(AppLocalizations l10n) => [
      l10n.whatsappPaymentStep1,
      l10n.whatsappPaymentStep2,
    ];

/// Bank transfer enrollment request steps
/// (`docs/FLUTTER_ENROLLMENT_REQUESTS_AND_ACTIVATION_CODES.md` §1.1 —
/// `payment_method: bank_transfer`, receipt optional).
List<String> bankTransferStepTexts(AppLocalizations l10n) => [
      l10n.bankTransferStep1,
      l10n.bankTransferStep2,
      l10n.bankTransferStep3,
    ];

/// Admin `message` body for purchase request / bank transfer / WhatsApp flows
/// (same shape as [LibraryPaymentProcessScreen]).
///
/// [mode] is one of `library`, `bank_transfer`, `whatsapp`.
String buildLibraryPaymentAdminMessage(
  AppLocalizations l10n, {
  required Map<String, dynamic>? course,
  String mode = 'library',
  String? studentNotes,
}) {
  final courseTitle = course?['title']?.toString() ?? '—';
  final courseId = course?['id']?.toString() ?? '—';
  final steps = switch (mode) {
    'whatsapp' => whatsappPaymentStepTexts(l10n),
    'bank_transfer' => bankTransferStepTexts(l10n),
    _ => libraryPaymentStepTextsNoReceipt(l10n),
  };
  final header = switch (mode) {
    'whatsapp' => '--- WhatsApp payment request ---',
    'bank_transfer' => '--- Bank transfer payment request ---',
    _ => '--- Purchase request ---',
  };
  final buffer = StringBuffer();
  buffer.writeln(header);
  buffer.writeln('Course: $courseTitle');
  buffer.writeln('Course ID: $courseId');
  buffer.writeln('Submitted: ${DateTime.now().toIso8601String()}');
  buffer.writeln();
  buffer.writeln('Payment process (acknowledged by student):');
  for (var i = 0; i < steps.length; i++) {
    buffer.writeln('${i + 1}. ${steps[i]}');
  }
  if (mode == 'whatsapp') {
    buffer.writeln();
    buffer.writeln(l10n.whatsappPaymentAfterConfirmationNote);
  }
  final note = studentNotes?.trim() ?? '';
  if (note.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('Student notes: $note');
  }
  return buffer.toString();
}
