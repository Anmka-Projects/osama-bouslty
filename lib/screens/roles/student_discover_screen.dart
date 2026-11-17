import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../models/trainer_marketplace.dart';
import '../../services/trainer_marketplace_service.dart';
import '../../services/currency_service.dart';
import '../../widgets/bottom_nav.dart';

class StudentDiscoverScreen extends StatefulWidget {
  const StudentDiscoverScreen({super.key});

  @override
  State<StudentDiscoverScreen> createState() => _StudentDiscoverScreenState();
}

class _StudentDiscoverScreenState extends State<StudentDiscoverScreen> {
  final _search = TextEditingController();
  final _subjects = const ['الرياضيات', 'اللغة العربية', 'العلوم', 'اللغة الإنجليزية'];
  List<TrainerCard> _trainers = [];
  String? _subject;
  bool _availableOnly = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await TrainerMarketplaceService.instance.listTrainers(query: _search.text);
      final rows = (data['trainers'] as List?)?.whereType<TrainerCard>().toList() ?? [];
      if (!mounted) return;
      setState(() {
        _trainers = rows;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<TrainerCard> get _visible {
    return _trainers.where((trainer) {
      if (_availableOnly && !trainer.isAcceptingBookings) return false;
      if (_subject == null) return true;
      final haystack = '${trainer.headline ?? ''} ${trainer.specialties.join(' ')} ${trainer.subjects.join(' ')} ${trainer.displayName}';
      return haystack.contains(_subject!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final showingResults = _search.text.trim().isNotEmpty || _subject != null;
    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
              children: [
                Text(showingResults ? 'نتائج المعلمين' : 'مرحبًا', style: GoogleFonts.readexPro(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.brandInk)),
                const SizedBox(height: 6),
                Text(
                  showingResults ? '${_visible.length} معلمًا متاحًا' : 'ابحث عن معلمك المناسب وابدأ التعلم',
                  style: GoogleFonts.readexPro(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مادة',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.search_rounded, color: AppColors.brandTeal)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppColors.line)),
                  ),
                ),
                const SizedBox(height: 22),
                Text('المواد المتاحة', style: GoogleFonts.readexPro(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ..._subjects.map((subject) {
                  final selected = _subject == subject;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: selected ? AppColors.brandTeal : AppColors.line),
                        ),
                        title: Text(subject, textAlign: TextAlign.right, style: GoogleFonts.readexPro(fontWeight: FontWeight.w700)),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => setState(() => _subject = selected ? null : subject),
                      ),
                    ),
                  );
                }),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _availableOnly,
                  activeThumbColor: AppColors.brandTeal,
                  title: Text('متاح الآن فقط', textAlign: TextAlign.right, style: GoogleFonts.readexPro(fontWeight: FontWeight.w700)),
                  onChanged: (value) => setState(() => _availableOnly = value),
                ),
                if (_loading) const LinearProgressIndicator(color: AppColors.brandTeal),
                ..._visible.map(_card),
              ],
            ),
          ),
          const BottomNav(activeTab: 'home'),
        ],
      ),
    );
  }

  Widget _card(TrainerCard trainer) {
    final price = trainer.startingPrice == null
        ? ''
        : '${CurrencyService.instance.format(trainer.startingPrice, trainer.currency)} / الساعة';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Column(
        children: [
          if ((trainer.badgeLabel ?? '').isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(20)),
                child: Text(trainer.badgeLabel!, style: GoogleFonts.readexPro(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(trainer.displayName, style: GoogleFonts.readexPro(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(trainer.headline ?? trainer.specialties.join(' · '), style: GoogleFonts.readexPro(color: AppColors.inkMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${trainer.ratingAverage.toStringAsFixed(1)} ★  (${trainer.ratingCount})', style: GoogleFonts.readexPro(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primarySoft,
                backgroundImage: (trainer.avatarUrl ?? '').isEmpty ? null : NetworkImage(ApiEndpoints.getImageUrl(trainer.avatarUrl)),
                child: (trainer.avatarUrl ?? '').isEmpty ? Text(trainer.displayName.characters.first) : null,
              ),
            ],
          ),
          if ((trainer.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(trainer.bio!, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.readexPro(fontSize: 12, color: AppColors.inkMuted)),
          ],
          const SizedBox(height: 6),
          Text('${trainer.hoursCount} ساعة · ${trainer.studentsCount} طالب · ${trainer.ratingAverage.toStringAsFixed(1)} ★', textAlign: TextAlign.right, style: GoogleFonts.readexPro(fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: () => context.push(RouteNames.teacherDetails, extra: {'id': trainer.id, 'name': trainer.displayName}),
                child: Text('احجز الآن', style: GoogleFonts.readexPro(color: AppColors.brandTeal, fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              if (trainer.isAcceptingBookings)
                Text('متاح الآن', style: GoogleFonts.readexPro(color: const Color(0xFF1B8A4A), fontWeight: FontWeight.w700, fontSize: 12)),
              if (price.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(price, style: GoogleFonts.readexPro(fontWeight: FontWeight.w800)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
