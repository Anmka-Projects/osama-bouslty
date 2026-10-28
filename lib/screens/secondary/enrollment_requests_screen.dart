import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_radius.dart';
import '../../core/design/app_text_styles.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_theme_extension.dart';
import '../../core/navigation/route_names.dart';
import '../../l10n/app_localizations.dart';
import '../../services/enrollment_requests_service.dart';

/// "طلباتي" — lists the student's enrollment requests with status +
/// `admin_notes` (rejection reason).
/// `GET /api/enrollment-requests` (doc §1.2).
class EnrollmentRequestsScreen extends StatefulWidget {
  const EnrollmentRequestsScreen({super.key});

  @override
  State<EnrollmentRequestsScreen> createState() =>
      _EnrollmentRequestsScreenState();
}

class _EnrollmentRequestsScreenState extends State<EnrollmentRequestsScreen> {
  AppThemeExtension get _theme => AppThemeExtension.of(context);

  final _scrollController = ScrollController();

  String? _statusFilter; // null = all
  final List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  static const _perPage = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_loading || _loadingMore || _page >= _totalPages) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _totalPages = 1;
        _requests.clear();
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final result =
          await EnrollmentRequestsService.instance.getEnrollmentRequestsPage(
        status: _statusFilter,
        page: _page,
        perPage: _perPage,
      );
      if (!mounted) return;
      setState(() {
        _requests.addAll(result.requests);
        _totalPages = result.totalPages;
        _page += 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _setFilter(String? status) {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
    _load(reset: true);
  }

  String _statusLabel(AppLocalizations l10n, String? status) {
    return switch (status?.toLowerCase()) {
      'approved' => l10n.enrollmentRequestStatusApproved,
      'rejected' => l10n.enrollmentRequestStatusRejected,
      _ => l10n.enrollmentRequestStatusPending,
    };
  }

  Color _statusColor(String? status) {
    return switch (status?.toLowerCase()) {
      'approved' => const Color(0xFF10B981),
      'rejected' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return DateFormat('d MMM yyyy, h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _theme.scaffoldBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header — same purple gradient style as other secondary screens
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.headerGradient2,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.largeCard),
                  bottomRight: Radius.circular(AppRadius.largeCard),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 32,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.whiteOverlay20,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    l10n.myEnrollmentRequests,
                    style: AppTextStyles.h3(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Status filter chips
            Transform.translate(
              offset: const Offset(0, -16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip(l10n.all, null),
                    _filterChip(l10n.enrollmentRequestStatusPending, 'pending'),
                    _filterChip(
                        l10n.enrollmentRequestStatusApproved, 'approved'),
                    _filterChip(
                        l10n.enrollmentRequestStatusRejected, 'rejected'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -8),
                child: _buildBody(l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.readexPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _theme.cardTitle,
          ),
        ),
        selected: selected,
        onSelected: (_) => _setFilter(value),
        selectedColor: context.appTheme.icon,
        backgroundColor: _theme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _theme.cardBorder),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: _theme.icon),
      );
    }

    if (_error != null && _requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: _theme.iconMuted),
              const SizedBox(height: 12),
              Text(
                _error!.isNotEmpty ? _error! : l10n.enrollmentRequestsLoadError,
                style:
                    GoogleFonts.readexPro(fontSize: 14, color: _theme.cardMetaText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n.retry, style: GoogleFonts.readexPro()),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Icon(Icons.receipt_long_rounded, size: 56, color: _theme.iconMuted),
            const SizedBox(height: 12),
            Text(
              l10n.enrollmentRequestsEmpty,
              style:
                  GoogleFonts.readexPro(fontSize: 15, color: _theme.cardMetaText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _requests.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _requests.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: _theme.icon),
              ),
            );
          }
          return _buildRequestCard(l10n, _requests[index]);
        },
      ),
    );
  }

  Widget _buildRequestCard(
      AppLocalizations l10n, Map<String, dynamic> request) {
    final status = request['status']?.toString().toLowerCase();
    final statusColor = _statusColor(status);
    final course =
        request['course'] is Map ? request['course'] as Map : const {};
    final courseTitle = course['title']?.toString() ?? '—';
    final thumbnail = ApiEndpoints.getImageUrl(
      course['thumbnail']?.toString(),
    );
    final instructor = course['instructor_name']?.toString() ??
        course['instructor']?.toString();
    final price = course['price'];
    final paymentMethod = request['payment_method']?.toString();
    final adminNotes = request['admin_notes']?.toString().trim();
    final createdAt = _formatDate(request['created_at']?.toString());
    final reviewedAt = _formatDate(request['reviewed_at']?.toString());
    final receiptUrl = request['receipt_image_url']?.toString();

    return GestureDetector(
      onTap: () {
        final courseId = course['id']?.toString();
        if (courseId == null || courseId.isEmpty) return;
        context.push(RouteNames.courseDetails, extra: {
          'id': courseId,
          'title': courseTitle,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _theme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _theme.cardBorder),
          boxShadow: [
            BoxShadow(
              color: _theme.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: thumbnail.isNotEmpty
                        ? Image.network(
                            thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                          )
                        : _thumbPlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              courseTitle,
                              style: GoogleFonts.readexPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _theme.cardTitle,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(l10n, status),
                              style: GoogleFonts.readexPro(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (instructor != null && instructor.isNotEmpty)
                        Text(
                          instructor,
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            color: _theme.cardMetaText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (price != null)
                            Text(
                              '$price ${l10n.egyptianPoundShort}',
                              style: GoogleFonts.readexPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _theme.cardAccentText,
                              ),
                            ),
                          const Spacer(),
                          if (paymentMethod != null && paymentMethod.isNotEmpty)
                            Text(
                              _paymentMethodLabel(l10n, paymentMethod),
                              style: GoogleFonts.readexPro(
                                fontSize: 11,
                                color: _theme.cardMetaText,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Rejection reason / admin note (doc: show `admin_notes` to the
            // student when status == "rejected").
            if (status == 'rejected' &&
                adminNotes != null &&
                adminNotes.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.enrollmentRequestRejectionReason,
                            style: GoogleFonts.readexPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                          Text(
                            adminNotes,
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              height: 1.4,
                              color: _theme.cardTitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 13, color: _theme.cardMetaText),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      createdAt,
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        color: _theme.cardMetaText,
                      ),
                    ),
                  ),
                  if (receiptUrl != null && receiptUrl.isNotEmpty)
                    Icon(Icons.attach_file_rounded,
                        size: 14, color: _theme.cardMetaText),
                ],
              ),
            ),
            if (reviewedAt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${l10n.enrollmentRequestReviewedAt}: $reviewedAt',
                  style: GoogleFonts.readexPro(
                    fontSize: 11,
                    color: _theme.cardMetaText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: _theme.cardMuted,
      child: Icon(Icons.school_rounded, color: _theme.iconMuted),
    );
  }

  String _paymentMethodLabel(AppLocalizations l10n, String method) {
    return switch (method.toLowerCase()) {
      'bank_transfer' => l10n.checkoutPaymentBankTitle,
      'whatsapp' => l10n.checkoutPaymentWhatsappTitle,
      'library' => l10n.checkoutPaymentLibraryTitle,
      _ => method,
    };
  }
}
