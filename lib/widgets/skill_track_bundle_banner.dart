import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design/app_theme_context.dart';

import '../core/design/app_colors.dart';
import '../core/skill_track/skill_track_catalog.dart';
import '../core/skill_track/skill_track_utils.dart';
import '../l10n/app_localizations.dart';

/// Shows included courses when purchasing a skill-track tier.
class SkillTrackBundleBanner extends StatelessWidget {
  final Map<String, dynamic> course;

  const SkillTrackBundleBanner({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final tier = SkillTrackUtils.tierFromCourse(course);
    var items = SkillTrackUtils.bundleIncludesFromCourse(course);
    if (items.isEmpty && tier != null && tier > 1) {
      items = SkillTrackCatalog.bundleIncludesForTier(tier);
    }
    if (items.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final isAr = locale.languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.skillTrackBundleBannerTitle,
                    style: GoogleFonts.readexPro(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.cardTitle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.skillTrackBundleBannerBody(items.length),
              style: GoogleFonts.readexPro(
                fontSize: 13,
                color: context.cardMetaText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            ...items.map((item) {
              final title = isAr
                  ? (item['title_ar'] ?? item['title'])?.toString()
                  : item['title']?.toString();
              if (title == null || title.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.readexPro(
                          fontSize: 13,
                          color: context.cardTitle,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
