import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/localization/localization_helper.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_theme_extension.dart';
import '../l10n/app_localizations.dart';

/// Premium Course Card - Modern and Attractive Design
class PremiumCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? instructorColor;
  final Color? contentBackgroundColor;
  final Color? metaTextColor;
  final Color? metaIconColor;
  /// Applies home-screen card colors (white title, gold instructor, navy card).
  final bool useHomeCardStyle;

  const PremiumCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.titleColor,
    this.instructorColor,
    this.contentBackgroundColor,
    this.metaTextColor,
    this.metaIconColor,
    this.useHomeCardStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeExtension.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isFree = course['is_free'] ?? course['isFree'] ?? false;
    final imagePath = course['thumbnail'] ?? course['image'] ?? '';
    final categoryName = course['category'] is Map
        ? (course['category']?['name'] ?? '')
        : (course['category'] ?? '');
    final title = course['title'] ?? '';
    final instructorName = course['instructor'] is Map
        ? (course['instructor']?['name'] ?? '')
        : (course['instructor'] ?? '');
    final rating = course['rating'] ?? 0.0;
    final durationLabel = context.courseDurationLabel(course);
    final lessonsRaw = course['lessons_count'] ?? course['lessons'] ?? 0;
    final lessonsCount = lessonsRaw is int
        ? lessonsRaw
        : (lessonsRaw is List
            ? lessonsRaw.length
            : int.tryParse('$lessonsRaw') ?? 0);
    final price = course['price'] ?? 0.0;
    final rawCurrency = course['currency']?.toString().trim().toUpperCase();
    final currencyLabel = rawCurrency == 'EGP'
        ? l10n.egyptianPoundShort
        : (rawCurrency?.isNotEmpty == true ? rawCurrency! : l10n.egyptianPoundShort);

    final resolvedTitle = titleColor ?? theme.cardTitle;
    final resolvedInstructor =
        instructorColor ?? theme.cardAccentText;
    final resolvedCardBg = contentBackgroundColor ?? theme.card;
    final metaText = metaTextColor ?? theme.cardMetaText;
    final metaIcon = metaIconColor ?? theme.icon;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: resolvedCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    children: [
                      Container(
                        height: 130,
                        width: double.infinity,
                        color: theme.progressTrack,
                        child: imagePath.toString().isNotEmpty
                            ? (imagePath.toString().startsWith('http') ||
                                    imagePath.toString().startsWith('https')
                                ? Image.network(
                                    imagePath.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: theme.progressTrack,
                                      child: Icon(Icons.image,
                                          color: theme.icon, size: 40),
                                    ),
                                  )
                                : Image.asset(
                                    imagePath.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: theme.progressTrack,
                                      child: Icon(Icons.image,
                                          color: theme.icon, size: 40),
                                    ),
                                  ))
                            : Container(
                                color: theme.progressTrack,
                                child: Icon(Icons.image,
                                    color: theme.icon, size: 40),
                              ),
                      ),
                      Container(
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.navyDeep.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.brandWhite.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.brandWhite.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          categoryName.toString(),
                          style: GoogleFonts.readexPro(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandWhite,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isFree
                            ? [
                                AppColors.goldLight,
                                AppColors.goldPrimary,
                              ]
                            : [
                                AppColors.goldPrimary,
                                AppColors.goldDark,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldPrimary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isFree
                          ? l10n.free
                          : '${price is num ? price.toInt() : 0} $currencyLabel',
                      style: GoogleFonts.readexPro(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDeep,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: 16,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.headerGradient2,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navyDeep.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.brandWhite, size: 26),
                  ),
                ),
              ],
            ),
            if (useHomeCardStyle)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: resolvedCardBg,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
                child: _courseInfoColumn(
                  title: title,
                  instructorName: instructorName,
                  rating: rating,
                  durationLabel: durationLabel,
                  lessonsCount: lessonsCount,
                  l10n: l10n,
                  theme: theme,
                  titleColor: resolvedTitle,
                  instructorColor: resolvedInstructor,
                  metaText: metaText,
                  metaIcon: metaIcon,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
                child: _courseInfoColumn(
                  title: title,
                  instructorName: instructorName,
                  rating: rating,
                  durationLabel: durationLabel,
                  lessonsCount: lessonsCount,
                  l10n: l10n,
                  theme: theme,
                  titleColor: resolvedTitle,
                  instructorColor: resolvedInstructor,
                  metaText: metaText,
                  metaIcon: metaIcon,
                  useThemeSurfaces: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _courseInfoColumn({
    required dynamic title,
    required dynamic instructorName,
    required dynamic rating,
    required String durationLabel,
    required int lessonsCount,
    required AppLocalizations l10n,
    required AppThemeExtension theme,
    required Color metaText,
    required Color metaIcon,
    Color? titleColor,
    Color? instructorColor,
    bool useThemeSurfaces = false,
  }) {
    final chipBg = useThemeSurfaces
        ? theme.progressTrack
        : AppColors.goldPrimary.withValues(alpha: 0.2);

    return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toString(),
                    style: GoogleFonts.readexPro(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor ?? theme.foreground,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: chipBg,
                        ),
                        child: Icon(Icons.person, size: 14, color: metaIcon),
                      ),
                      Text(
                        instructorName.toString(),
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          color: instructorColor ?? theme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 14, color: metaIcon),
                            const SizedBox(width: 3),
                            Text(
                              rating.toString(),
                              style: GoogleFonts.readexPro(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: metaText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.access_time_rounded,
                          size: 14, color: metaIcon),
                      Text(
                        durationLabel,
                        style: GoogleFonts.readexPro(
                          fontSize: 11,
                          color: metaText.withValues(alpha: 0.85),
                        ),
                      ),
                      Icon(Icons.menu_book_rounded,
                          size: 14, color: metaIcon),
                      Text(
                        l10n.lessonsCount(lessonsCount),
                        style: GoogleFonts.readexPro(
                          fontSize: 11,
                          color: metaText.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
    );
  }
}
