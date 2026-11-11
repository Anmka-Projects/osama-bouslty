import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/design/app_colors.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../widgets/tutor_top_nav.dart';

/// Tutor earnings — reference design: balance card + withdraw + history.
class InstructorEarningsTabScreen extends StatefulWidget {
  const InstructorEarningsTabScreen({super.key});

  @override
  State<InstructorEarningsTabScreen> createState() =>
      _InstructorEarningsTabScreenState();
}

class _InstructorEarningsTabScreenState
    extends State<InstructorEarningsTabScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await TrainerMarketplaceService.instance.earnings();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _balance {
    for (final k in const [
      'available_balance',
      'availableBalance',
      'available',
      'balance',
      'total_available',
      'pending_balance',
    ]) {
      final v = _data[k];
      if (v is num) return v.toDouble();
    }
    final summary = _data['summary'];
    if (summary is Map) {
      for (final k in const ['available', 'balance']) {
        final v = summary[k];
        if (v is num) return v.toDouble();
      }
    }
    return 0;
  }

  List<Map<String, dynamic>> get _transactions {
    for (final k in const [
      'entries',
      'transactions',
      'payouts',
      'history',
      'records',
      'recent',
    ]) {
      final v = _data[k];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  Future<void> _requestPayout() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('طلب سحب', style: GoogleFonts.readexPro(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ (USD)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: GoogleFonts.readexPro())),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('إرسال', style: GoogleFonts.readexPro()),
          ),
        ],
      ),
    );
    if (ok != true || amount.text.trim().isEmpty) return;
    try {
      await TrainerMarketplaceService.instance.requestPayout(amount.text.trim(),
          note: note.text.trim().isEmpty ? null : note.text.trim());
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم إرسال طلب السحب', style: GoogleFonts.readexPro())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل إرسال الطلب', style: GoogleFonts.readexPro())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Column(
        children: [
          const TutorTopNav(activeTab: 'account'),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                    children: [
                      _title(),
                      const SizedBox(height: 18),
                      _balanceCard(),
                      const SizedBox(height: 14),
                      _withdrawButton(),
                      const SizedBox(height: 24),
                      _historyTitle(),
                      const SizedBox(height: 10),
                      if (_transactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text('لا توجد عمليات بعد',
                                style: GoogleFonts.readexPro(
                                    fontSize: 13, color: AppColors.inkMuted)),
                          ),
                        )
                      else
                        ..._transactions.map(_txRow),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _title() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الأرباح',
                    style: GoogleFonts.readexPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('إدارة أرباحك وعمليات السحب',
                    style: GoogleFonts.readexPro(
                        fontSize: 12, color: AppColors.inkMuted)),
              ],
            ),
          ),
          Icon(Icons.payments_outlined, size: 20, color: AppColors.brandTeal),
        ],
      );

  Widget _balanceCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('الرصيد المتاح للسحب',
                    style: GoogleFonts.readexPro(
                        fontSize: 13, color: AppColors.inkMuted)),
                const SizedBox(width: 6),
                Icon(Icons.account_balance_wallet_outlined,
                    size: 16, color: AppColors.brandTeal),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat('#,##0.00').format(_balance)} USD',
              style: GoogleFonts.readexPro(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink),
            ),
          ],
        ),
      );

  Widget _withdrawButton() => SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: _requestPayout,
          icon: const Icon(Icons.account_balance_rounded, size: 20),
          label: Text('طلب سحب',
              style: GoogleFonts.readexPro(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandTeal,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  Widget _historyTitle() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('سجل العمليات',
              style: GoogleFonts.readexPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          const SizedBox(width: 6),
          Icon(Icons.history_rounded, size: 18, color: AppColors.inkSubtle),
        ],
      );

  Widget _txRow(Map<String, dynamic> tx) {
    final raw = tx['amount'] ?? tx['total'] ?? 0;
    final amount = raw is num ? raw.toDouble() : 0;
    final type = (tx['type'] ?? tx['kind'] ?? '').toString();
    final isOut =
        amount < 0 || type.contains('payout') || type.contains('withdraw');
    final title = (tx['description'] ??
            tx['title'] ??
            tx['label'] ??
            (isOut ? 'سحب إلى الحساب البنكي' : 'أجر درس'))
        .toString();
    final dateRaw =
        (tx['created_at'] ?? tx['createdAt'] ?? tx['date'] ?? '').toString();
    final date = DateTime.tryParse(dateRaw);
    final dateStr = date != null
        ? DateFormat('d MMMM yyyy', 'ar').format(date.toLocal())
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            '${isOut ? '-' : '+'}${NumberFormat('#,##0.00').format(amount.abs())} USD',
            style: GoogleFonts.readexPro(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isOut ? AppColors.destructive : const Color(0xFF16A34A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                if (dateStr.isNotEmpty)
                  Text(dateStr,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.readexPro(
                          fontSize: 11, color: AppColors.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            isOut ? Icons.account_balance_rounded : Icons.school_outlined,
            size: 18,
            color: AppColors.inkSubtle,
          ),
        ],
      ),
    );
  }
}
