import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../core/design/app_theme_context.dart';

import '../core/design/app_colors.dart';
import '../core/navigation/route_names.dart';
import '../core/skill_track/skill_track_catalog.dart';
import '../l10n/app_localizations.dart';
import '../services/skill_track_service.dart';

/// Skill-track ladder shown at the top of [AllCoursesScreen].
class SkillTrackSection extends StatefulWidget {
  const SkillTrackSection({super.key});

  @override
  State<SkillTrackSection> createState() => _SkillTrackSectionState();
}

class _SkillTrackSectionState extends State<SkillTrackSection> {
  bool _loading = true;
  SkillTrackData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SkillTrackService.instance.fetchSkillTrack();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openTier(Map<String, dynamic> tier) {
    final course = tier['course'] as Map<String, dynamic>?;
    final courseId = tier['course_id']?.toString();
    if (course != null && course.isNotEmpty) {
      context.push(RouteNames.courseDetails, extra: course);
      return;
    }
    if (courseId != null && courseId.isNotEmpty) {
      context.push(
        RouteNames.courseDetails,
        extra: {'id': courseId, 'title': tier['title']},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_loading) {
      return Skeletonizer(
        enabled: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            children: List.generate(
              3,
              (_) => Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
          color: context.appTheme.card,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final data = _data;
    if (data != null && !data.enabled) return const SizedBox.shrink();

    final tiers = data?.tiers ?? SkillTrackCatalog.catalogTierRows();
    final unlockNote = isAr
        ? (data?.unlockNoteAr ?? l10n.skillTrackUnlockNote)
        : (data?.unlockNoteEn ?? l10n.skillTrackUnlockNote);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.skillTrackTitle,
            style: GoogleFonts.readexPro(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.cardTitle,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.skillTrackSubtitle,
            style: GoogleFonts.readexPro(
              fontSize: 13,
              color: context.cardMetaText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    unlockNote,
                    style: GoogleFonts.readexPro(
                      fontSize: 12,
                      color: context.cardTitle,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...tiers.map(
            (tier) => SkillTrackTierCard(
              tier: tier,
              currency: data?.currency ?? SkillTrackCatalog.currency,
              isAr: isAr,
              l10n: l10n,
              onTap: () => _openTier(tier),
            ),
          ),
        ],
      ),
    );
  }
}

class SkillTrackTierCard extends StatelessWidget {
  final Map<String, dynamic> tier;
  final String currency;
  final bool isAr;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const SkillTrackTierCard({
    super.key,
    required this.tier,
    required this.currency,
    required this.isAr,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tierNum = tier['tier'] as int? ?? 0;
    final title = isAr
        ? (tier['title_ar'] ?? tier['title'])?.toString() ?? ''
        : tier['title']?.toString() ?? '';
    final isFree = tier['is_free'] == true;
    final price = tier['price'];
    final priceNum = price is num ? price : num.tryParse('$price') ?? 0;
    final isEnrolled = tier['is_enrolled'] == true;
    final includes = tier['bundle_includes'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.appTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$tierNum',
                        style: GoogleFonts.readexPro(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.readexPro(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.cardTitle,
                        ),
                      ),
                    ),
                    if (isEnrolled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          l10n.skillTrackEnrolled,
                          style: GoogleFonts.readexPro(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isFree
                      ? l10n.skillTrackFree
                      : '${priceNum.toInt()} $currency',
                  style: GoogleFonts.readexPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isFree
                        ? const Color(0xFF10B981)
                        : AppColors.primary,
                  ),
                ),
                if (includes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.skillTrackIncludedFree,
                    style: GoogleFonts.readexPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.cardMetaText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...includes.map((item) {
                    if (item is! Map) return const SizedBox.shrink();
                    final incTitle = isAr
                        ? (item['title_ar'] ?? item['title'])?.toString()
                        : item['title']?.toString();
                    if (incTitle == null || incTitle.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              incTitle,
                              style: GoogleFonts.readexPro(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
