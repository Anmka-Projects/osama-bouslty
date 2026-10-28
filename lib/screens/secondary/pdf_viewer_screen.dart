import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/design/app_colors.dart';
import '../../services/token_storage_service.dart';
import '../../core/design/app_theme_context.dart';

/// PDF Viewer Screen - Display PDF files using flutter_pdfview
class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String? title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;
  PDFViewController? _pdfViewController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  File? _tempPdfFile;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      // Offline: open a file already saved on disk (downloads / lesson PDF).
      String localSrc = widget.pdfUrl.trim();
      if (localSrc.startsWith('file://')) {
        localSrc = Uri.parse(localSrc).toFilePath();
      }
      final localFile = File(localSrc);
      if (await localFile.exists()) {
        if (mounted) {
          setState(() {
            _localPath = localFile.absolute.path;
            _isLoading = false;
            _tempPdfFile = null;
          });
        }
        return;
      }

      final token = await TokenStorageService.instance.getAccessToken();

      if (kDebugMode) {
        print('📄 Loading PDF: ${widget.pdfUrl}');
        print('🔑 Token exists: ${token != null && token.isNotEmpty}');
      }

      final candidates = ApiEndpoints.mediaDownloadUrlCandidates(widget.pdfUrl);
      if (kDebugMode && candidates.length > 1) {
        print('📎 PDF URL candidates: $candidates');
      }

      File? pdfFile;
      for (final url in candidates) {
        pdfFile = await _downloadPdfFromRemoteUrl(url, token);
        if (pdfFile != null) break;
      }

      if (pdfFile != null && pdfFile.existsSync()) {
        if (mounted) {
          setState(() {
            _localPath = pdfFile!.path;
            _isLoading = false;
            _tempPdfFile = pdfFile;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'فشل تحميل الملف. يرجى التحقق من الاتصال بالإنترنت أو أن الملف موجود.';
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading PDF: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'خطأ في تحميل الملف: ${e.toString()}';
        });
      }
    }
  }

  /// Tries Bearer, ?token=, then unauthenticated — server may use any of these.
  Future<File?> _downloadPdfFromRemoteUrl(String pdfUrl, String? token) async {
    const accept = 'application/pdf, application/octet-stream, */*';

    String withTokenQuery(String base) {
      if (token == null || token.isEmpty) return base;
      final uri = Uri.parse(base);
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        'token': token,
      }).toString();
    }

    bool looksPdf(http.Response r) {
      final ct = r.headers['content-type'] ?? '';
      if (ct.contains('pdf') || ct.contains('octet-stream')) return true;
      final b = r.bodyBytes;
      return b.length > 4 &&
          String.fromCharCodes(b.take(4)) == '%PDF';
    }

    if (token != null && token.isNotEmpty) {
      try {
        if (kDebugMode) {
          print('📥 PDF GET (Bearer): $pdfUrl');
        }
        final r = await http
            .get(
              Uri.parse(pdfUrl),
              headers: {
                'Accept': accept,
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 30));
        if (r.statusCode == 200 && looksPdf(r)) {
          return _savePdfToFile(r.bodyBytes);
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ PDF Bearer failed: $e');
        }
      }

      try {
        final u = withTokenQuery(pdfUrl);
        if (kDebugMode) {
          print('📥 PDF GET (?token=): $u');
        }
        final r = await http
            .get(
              Uri.parse(u),
              headers: {'Accept': accept},
            )
            .timeout(const Duration(seconds: 30));
        if (r.statusCode == 200 && looksPdf(r)) {
          return _savePdfToFile(r.bodyBytes);
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ PDF token query failed: $e');
        }
      }
    }

    try {
      if (kDebugMode) {
        print('📥 PDF GET (no auth): $pdfUrl');
      }
      final r = await http
          .get(
            Uri.parse(pdfUrl),
            headers: {'Accept': accept},
          )
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 200 && looksPdf(r)) {
        return _savePdfToFile(r.bodyBytes);
      }
      if (kDebugMode && r.statusCode != 200) {
        print('❌ PDF HTTP ${r.statusCode} for $pdfUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ PDF no-auth failed: $e');
      }
    }

    return null;
  }

  Future<File> _savePdfToFile(List<int> bytes) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = widget.pdfUrl.split('/').last.split('?').first;
    final fileExtension =
        fileName.contains('.') ? fileName.split('.').last : 'pdf';
    final file = File(
        '${tempDir.path}/pdf_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');

    await file.writeAsBytes(bytes);

    if (kDebugMode) {
      print('💾 PDF saved to temporary file: ${file.path}');
    }

    return file;
  }

  @override
  void dispose() {
    _pdfViewController?.dispose();
    // Clean up temporary PDF file
    if (_tempPdfFile != null) {
      try {
        _tempPdfFile!.deleteSync();
        if (kDebugMode) {
          print('🗑️ Deleted temporary PDF file: ${_tempPdfFile!.path}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error deleting temp PDF file: $e');
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
          color: context.appTheme.card,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.appTheme.icon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.appTheme.icon,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title ?? 'معاينة الملف',
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.cardTitle,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_isReady && _totalPages > 0)
                          Text(
                            'صفحة $_currentPage من $_totalPages',
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              color: context.cardMetaText,
                            ),
                          )
                        else
                          Text(
                            'PDF',
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              color: context.cardMetaText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Page navigation buttons
                  if (_isReady && _totalPages > 1) ...[
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _currentPage > 0
                          ? () {
                              _pdfViewController?.setPage(_currentPage - 1);
                            }
                          : null,
                      color: context.appTheme.icon,
                      iconSize: 24,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: _currentPage < _totalPages - 1
                          ? () {
                              _pdfViewController?.setPage(_currentPage + 1);
                            }
                          : null,
                      color: context.appTheme.icon,
                      iconSize: 24,
                    ),
                  ],
                ],
              ),
            ),

            // PDF Viewer
            Expanded(
              child: _isLoading
                  ? Container(
                      color: const Color(0xFFF5F5F5),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: context.appTheme.icon,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'جاري تحميل الملف...',
                              style: GoogleFonts.readexPro(
                                fontSize: 14,
                                color: context.cardMetaText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _errorMessage != null
                      ? Container(
                          color: const Color(0xFFF5F5F5),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.readexPro(
                                      fontSize: 16,
                                      color: context.cardTitle,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _isLoading = true;
                                          _errorMessage = null;
                                        });
                                        _loadPdf();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.appTheme.icon,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'إعادة المحاولة',
                                        style: GoogleFonts.readexPro(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : _localPath != null
                          ? PDFView(
                              filePath: _localPath!,
                              enableSwipe: true,
                              swipeHorizontal: false,
                              autoSpacing: true,
                              pageFling: true,
                              pageSnap: true,
                              defaultPage: _currentPage,
                              fitPolicy: FitPolicy.BOTH,
                              preventLinkNavigation: false,
                              onRender: (pages) {
                                if (mounted) {
                                  setState(() {
                                    _totalPages = pages ?? 0;
                                    _isReady = true;
                                  });
                                }
                              },
                              onError: (error) {
                                if (kDebugMode) {
                                  print('❌ PDF View error: $error');
                                }
                                if (mounted) {
                                  setState(() {
                                    _errorMessage =
                                        'خطأ في عرض الملف: ${error.toString()}';
                                  });
                                }
                              },
                              onPageError: (page, error) {
                                if (kDebugMode) {
                                  print(
                                      '❌ PDF Page error (page $page): $error');
                                }
                              },
                              onViewCreated: (PDFViewController controller) {
                                _pdfViewController = controller;
                              },
                              onLinkHandler: (String? uri) {
                                if (kDebugMode) {
                                  print('🔗 PDF Link clicked: $uri');
                                }
                              },
                              onPageChanged: (int? page, int? total) {
                                if (mounted) {
                                  setState(() {
                                    _currentPage = page ?? 0;
                                    _totalPages = total ?? 0;
                                  });
                                }
                              },
                            )
                          : Container(
                              color: const Color(0xFFF5F5F5),
                              child: Center(
                                child: Text(
                                  'لا يمكن عرض الملف',
                                  style: GoogleFonts.readexPro(
                                    fontSize: 14,
                                    color: context.cardMetaText,
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
