import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../categories/presentation/utils/category_appearance.dart';

/// The neutral icon-wrap that opens the budget icon picker (`a3gGPM/Q9XuL`):
/// 52×52, `$muted`, no color — `Budgets` stores an icon but never a color.
///
/// The small `Edit Badge` (`oIyvH`, 18×18 `$surface` ringed in `$border` with
/// a 10px `pencil`) overlaps the bottom-right corner so the wrap reads as
/// tappable instead of decorative.
class BudgetIconButton extends StatelessWidget {
  const BudgetIconButton({required this.icon, required this.onTap, super.key});

  final String? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusField),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(AppTheme.radiusField),
              ),
              child: Icon(
                // Nothing picked yet is its own state: the neutral
                // placeholder, never `sparkles` (the AI/nudge glyph).
                icon == null
                    ? CategoryAppearance.placeholderIcon
                    : CategoryAppearance.iconFor(icon),
                size: 22,
                color: colors.primaryOnSoft,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  LucideIcons.pencil,
                  size: 10,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
