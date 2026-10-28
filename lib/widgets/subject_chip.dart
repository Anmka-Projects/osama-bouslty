import 'package:flutter/material.dart';
import '../core/design/app_text_styles.dart';
import '../core/design/app_theme_context.dart';

/// Subject Chip Widget - Pixel-perfect match to React version
/// Matches: components/ui/subject-chip.tsx
class SubjectChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const SubjectChip({
    super.key,
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16, // px-4
          vertical: 8, // py-2
        ),
        decoration: BoxDecoration(
          color: isActive ? theme.icon : theme.card,
          borderRadius: BorderRadius.circular(999), // rounded-full
          border: Border.all(
            color: isActive ? Colors.transparent : theme.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8), // gap-2
            Text(
              label,
              style: AppTextStyles.bodySmall(
                color: isActive
                    ? theme.headerForeground
                    : context.sectionTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
