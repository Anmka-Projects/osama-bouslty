import 'dart:io';
import '../../core/design/app_theme_context.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design/app_colors.dart';
import '../../core/enrollment/library_payment_admin_message.dart';
import '../../l10n/app_localizations.dart';
import '../../services/enrollment_requests_service.dart';
import '../../services/upload_service.dart';

/// Same steps + receipt flow for **library**, **bank_transfer**, and
/// **WhatsApp** enrollment requests.
class LibraryPaymentProcessScreen extends StatefulWidget {
  const LibraryPaymentProcessScreen({
    super.key,
    this.course,
    this.enrollmentPaymentMethod = 'library',
  });

  final Map<String, dynamic>? course;

  /// API `payment_method`: `library`, `bank_transfer`, or `whatsapp`.
  final String enrollmentPaymentMethod;

  @override
  State<LibraryPaymentProcessScreen> createState() =>
      _LibraryPaymentProcessScreenState();
}

class _LibraryPaymentProcessScreenState
    extends State<LibraryPaymentProcessScreen> {
  final _notesController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _receiptFile;
  bool _uploading = false;

  String get _apiPaymentMethod {
    final p = widget.enrollmentPaymentMethod.toLowerCase().trim();
    if (p == 'whatsapp') return 'whatsapp';
    if (p == 'bank_transfer') return 'bank_transfer';
    return 'library';
  }

  bool get _requiresReceipt => _apiPaymentMethod == 'whatsapp';
  bool get _showsReceiptPicker => _apiPaymentMethod != 'library';

  List<String> _stepTitlesForUi(AppLocalizations l10n) =>
      switch (_apiPaymentMethod) {
        'whatsapp' => whatsappPaymentStepTexts(l10n),
        'bank_transfer' => bankTransferStepTexts(l10n),
        _ => libraryPaymentStepTextsNoReceipt(l10n),
      };

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _buildAdminMessage(AppLocalizations l10n) {
    return buildLibraryPaymentAdminMessage(
      l10n,
      course: widget.course,
      mode: _apiPaymentMethod,
      studentNotes: _notesController.text,
    );
  }

  Future<void> _pickReceipt() async {
    final x = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _receiptFile = File(x.path));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_apiPaymentMethod == 'library') {
      if (!mounted) return;
      context.pop(<String, dynamic>{
        'message': _buildAdminMessage(l10n),
        'payment_method': _apiPaymentMethod,
      });
      return;
    }

    if (_requiresReceipt && _receiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.whatsappPaymentReceiptRequired,
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    setState(() => _uploading = true);
    String? receiptForApi;
    try {
      if (_receiptFile != null) {
        final url = await UploadService.instance.uploadImage(_receiptFile!);
        receiptForApi = normalizeEnrollmentReceiptImageUrl(url);
        if (receiptForApi.isEmpty) {
          throw Exception('Invalid receipt URL from server');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }

    final message = _buildAdminMessage(l10n);

    if (!mounted) return;
    context.pop(<String, dynamic>{
      'message': message,
      'receipt_image_url': receiptForApi,
      'payment_method': _apiPaymentMethod,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final courseTitle = widget.course?['title']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          switch (_apiPaymentMethod) {
            'whatsapp' => l10n.checkoutPaymentWhatsappTitle,
            'bank_transfer' => l10n.checkoutPaymentBankTitle,
            _ => l10n.libraryPaymentProcessTitle,
          },
          style: GoogleFonts.readexPro(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.appTheme.card,
        foregroundColor: context.sectionTitle,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (courseTitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  courseTitle,
                  style: GoogleFonts.readexPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.appTheme.icon,
                  ),
                ),
              ),
            Text(
              switch (_apiPaymentMethod) {
                'whatsapp' => l10n.whatsappPaymentProcessSubtitle,
                'bank_transfer' => l10n.bankTransferProcessSubtitle,
                _ => l10n.libraryPaymentProcessSubtitleNoReceipt,
              },
              style: GoogleFonts.readexPro(
                fontSize: 14,
                height: 1.45,
                color: context.cardMetaText,
              ),
            ),
            const SizedBox(height: 20),
            ..._stepTitlesForUi(l10n).asMap().entries.map(
                  (e) => _StepCard(index: e.key + 1, text: e.value),
                ),
            if (_apiPaymentMethod == 'whatsapp') ...[
              const SizedBox(height: 12),
              Text(
                l10n.whatsappPaymentAfterConfirmationNote,
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: context.cardMetaText,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              l10n.libraryPaymentNotesLabel,
              style: GoogleFonts.readexPro(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.libraryPaymentNotesHint,
                hintStyle: GoogleFonts.readexPro(
                  color: context.cardMetaText,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              style: GoogleFonts.readexPro(fontSize: 14),
            ),
            if (_showsReceiptPicker) ...[
              const SizedBox(height: 20),
              Text(
                _requiresReceipt
                    ? l10n.libraryPaymentAttachReceipt
                    : l10n.bankTransferAttachReceiptOptional,
                style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickReceipt,
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 20),
                    label: Text(
                      _receiptFile == null
                          ? (_requiresReceipt
                              ? l10n.libraryPaymentAttachReceipt
                              : l10n.bankTransferAttachReceiptOptional)
                          : l10n.libraryPaymentChangePhoto,
                      style: GoogleFonts.readexPro(),
                    ),
                  ),
                  if (_receiptFile != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _uploading
                          ? null
                          : () => setState(() => _receiptFile = null),
                      child: Text(
                        l10n.libraryPaymentRemovePhoto,
                        style: GoogleFonts.readexPro(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
              if (_receiptFile != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _receiptFile!,
                    height: 160,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _uploading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: context.appTheme.icon,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _uploading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.libraryPaymentUploadingReceipt,
                          style: GoogleFonts.readexPro(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      l10n.libraryPaymentSendToAdmin,
                      style: GoogleFonts.readexPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.purple.withOpacity(0.12),
              child: Text(
                '$index',
                style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.bold,
                  color: context.appTheme.icon,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.readexPro(
                  fontSize: 14,
                  height: 1.45,
                  color: context.cardTitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
