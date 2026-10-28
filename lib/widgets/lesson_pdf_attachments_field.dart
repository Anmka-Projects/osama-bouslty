import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_theme_context.dart';
import '../services/upload_service.dart';

/// One PDF slot for a video lesson (title + uploaded URL).
class LessonPdfAttachment {
  String title;
  String url;

  LessonPdfAttachment({this.title = '', required this.url});

  Map<String, dynamic> toResourceJson() => {
        'title': title.trim().isEmpty ? 'PDF' : title.trim(),
        'url': url,
        'type': 'pdf',
        'file_type': 'application/pdf',
      };

  static LessonPdfAttachment? fromDynamic(dynamic item) {
    if (item is! Map) return null;
    final m = Map<String, dynamic>.from(item);
    final url = m['url']?.toString() ?? m['file']?.toString() ?? '';
    if (url.isEmpty) return null;
    final type = (m['type']?.toString() ?? m['file_type']?.toString() ?? '')
        .toLowerCase();
    if (!type.contains('pdf') && !url.toLowerCase().contains('.pdf')) {
      return null;
    }
    return LessonPdfAttachment(
      title: m['title']?.toString() ?? m['name']?.toString() ?? '',
      url: url,
    );
  }
}

/// Parses up to [maxCount] PDF attachments from a lesson map.
List<LessonPdfAttachment> lessonPdfAttachmentsFromLesson(
  Map<String, dynamic>? lesson, {
  int maxCount = 3,
}) {
  if (lesson == null) return [];
  final seen = <String>{};
  final out = <LessonPdfAttachment>[];

  void add(LessonPdfAttachment? a) {
    if (a == null || a.url.isEmpty || seen.contains(a.url)) return;
    if (out.length >= maxCount) return;
    seen.add(a.url);
    out.add(a);
  }

  final resources = lesson['resources'];
  if (resources is List) {
    for (final item in resources) {
      add(LessonPdfAttachment.fromDynamic(item));
    }
  }

  for (final key in ['fileUrl', 'file_url', 'content_pdf']) {
    final url = lesson[key]?.toString() ?? '';
    if (url.isNotEmpty) {
      add(LessonPdfAttachment(title: '', url: url));
    }
  }

  return out;
}

List<Map<String, dynamic>> lessonPdfResourcesPayload(
  List<LessonPdfAttachment> attachments,
) {
  return attachments
      .where((a) => a.url.trim().isNotEmpty)
      .take(3)
      .map((a) => a.toResourceJson())
      .toList();
}

/// Up to 3 PDF uploads for video (or file) lessons — instructor form.
class LessonPdfAttachmentsField extends StatefulWidget {
  final bool isAr;
  final List<LessonPdfAttachment> initialAttachments;
  final void Function(List<LessonPdfAttachment> attachments) onChanged;
  final int maxAttachments;

  const LessonPdfAttachmentsField({
    super.key,
    required this.isAr,
    required this.initialAttachments,
    required this.onChanged,
    this.maxAttachments = 3,
  });

  @override
  State<LessonPdfAttachmentsField> createState() =>
      _LessonPdfAttachmentsFieldState();
}

class _LessonPdfAttachmentsFieldState extends State<LessonPdfAttachmentsField> {
  late List<LessonPdfAttachment> _items;
  final Map<int, bool> _uploading = {};

  @override
  void initState() {
    super.initState();
    _items = List<LessonPdfAttachment>.from(widget.initialAttachments);
    if (_items.isEmpty) {
      _items.add(LessonPdfAttachment(url: ''));
    }
  }

  void _notify() {
    widget.onChanged(
      _items.where((e) => e.url.trim().isNotEmpty).toList(),
    );
  }

  void _addSlot() {
    if (_items.length >= widget.maxAttachments) return;
    setState(() {
      _items.add(LessonPdfAttachment(url: ''));
    });
  }

  void _removeAt(int index) {
    setState(() {
      _items.removeAt(index);
      if (_items.isEmpty) {
        _items.add(LessonPdfAttachment(url: ''));
      }
      _notify();
    });
  }

  Future<void> _pickAndUpload(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final path = file.path;
      if (path == null) return;
      final f = File(path);
      if (!await f.exists()) return;

      setState(() => _uploading[index] = true);

      final url = await UploadService.instance.uploadPdf(f);
      if (!mounted) return;
      setState(() {
        _items[index].url = url;
        if (_items[index].title.trim().isEmpty) {
          _items[index].title = file.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
        }
        _uploading.remove(index);
      });
      _notify();
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading.remove(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isAr ? 'فشل رفع الملف' : 'Upload failed',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _items.length < widget.maxAttachments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isAr
              ? 'ملفات PDF مع الفيديو (حتى ${widget.maxAttachments})'
              : 'PDF files with video (up to ${widget.maxAttachments})',
          style: GoogleFonts.readexPro(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.cardMetaText,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_items.length, (index) {
          final item = _items[index];
          final busy = _uploading[index] == true;
          final hasUrl = item.url.trim().isNotEmpty;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.isAr ? 'ملف ${index + 1}' : 'File ${index + 1}',
                        style: GoogleFonts.readexPro(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (_items.length > 1 || hasUrl)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: busy ? null : () => _removeAt(index),
                          tooltip: widget.isAr ? 'إزالة' : 'Remove',
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    key: ValueKey('pdf-title-$index-${item.url}'),
                    initialValue: item.title,
                    onChanged: (v) {
                      item.title = v;
                      _notify();
                    },
                    decoration: InputDecoration(
                      hintText: widget.isAr
                          ? 'عنوان الملف (اختياري)'
                          : 'File title (optional)',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: GoogleFonts.readexPro(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => _pickAndUpload(index),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      busy
                          ? (widget.isAr ? 'جاري الرفع...' : 'Uploading...')
                          : hasUrl
                              ? (widget.isAr ? 'استبدال PDF' : 'Replace PDF')
                              : (widget.isAr ? 'رفع PDF' : 'Upload PDF'),
                      style: GoogleFonts.readexPro(fontSize: 13),
                    ),
                  ),
                  if (hasUrl) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.picture_as_pdf_rounded,
                            color: AppColors.destructive, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            Uri.tryParse(item.url)?.pathSegments.last ?? item.url,
                            style: GoogleFonts.readexPro(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 18),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        if (canAdd)
          TextButton.icon(
            onPressed: _addSlot,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              widget.isAr ? 'إضافة ملف PDF آخر' : 'Add another PDF',
              style: GoogleFonts.readexPro(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
