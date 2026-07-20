import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The "Programado" entry point (`s09qcC`/`pb88i`, HU-12): its own card under
/// the hero, tappable to open the period's scheduled-payment list. Hidden
/// entirely by the caller when nothing is scheduled in the window (`kLUl7`
/// shows no trace of it) — this widget always renders itself when built.
///
/// [atRisk] switches the whole card (icon-wrap, sub and amount) to
/// `$amber`/`$amber-text` for a projected overdraw ("riesgo de sobregiro
/// proyectado"), the same documented exception to the sober palette as the
/// progress bar's "programado" segment (`BudgetProgressBar`).
class BudgetScheduledEntryCard extends StatelessWidget {
  const BudgetScheduledEntryCard({
    required this.sub,
    required this.amountLabel,
    required this.atRisk,
    required this.onTap,
    required this.label,
    super.key,
  });

  /// "Programado" (`budgetScheduledLabel`), already localized.
  final String label;

  /// "N pagos próximos" (sano) or "Excedería el presupuesto por $Y" (risk),
  /// already localized.
  final String sub;

  /// The scheduled total, already formatted with its currency symbol.
  final String amountLabel;
  final bool atRisk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final tint = atRisk ? colors.amber : colors.primary;
    final tintSoft = atRisk ? colors.amberSoft : colors.primarySoft;
    final subColor = atRisk ? colors.amberText : colors.textSecondary;
    final amountColor = atRisk ? colors.amberText : colors.textPrimary;

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
                color: tintSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.calendarClock, size: 18, color: tint),
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
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amountLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight,
                size: 16, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
