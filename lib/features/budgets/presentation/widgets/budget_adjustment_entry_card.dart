import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// "Ajuste de monto" banner (`AYsw7`/`s0ZlV`, within `reulY`/`ujbZf`): the
/// pending amount override for the window the stepper is showing, under the
/// hero, before "Movimientos del período". Instances the same `Entry Row`
/// shape (`s09qcC`) as `BudgetScheduledEntryCard` (HU-12's "Programado"), but
/// with `repeat-1` (not `calendar-clock`) and **no amount on the right** — the
/// amount and range live in [sub] instead ("$850.000 · 21 ago – 20 sep"), the
/// design's deliberate way to tell the two entries apart at a glance. Tapping
/// it reopens the sheet in "editar/cancelar" mode, prefilled.
class BudgetAdjustmentEntryCard extends StatelessWidget {
  const BudgetAdjustmentEntryCard({
    required this.label,
    required this.sub,
    required this.onTap,
    super.key,
  });

  /// "Ajuste de monto" (`budgetAdjustBannerLabel`), already localized.
  final String label;

  /// "$850.000 · 21 ago – 20 sep", already localized/formatted.
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.repeat1, size: 18, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(LucideIcons.chevronRight,
                size: 16, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
