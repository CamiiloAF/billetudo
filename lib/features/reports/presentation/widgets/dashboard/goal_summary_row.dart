import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../goals/domain/entities/goal_with_progress.dart';
import '../../../../goals/presentation/widgets/goal_progress_ring.dart';

/// The `Goal Summary Row` component (`He7JZ`): a mini `Goal Ring` (`q1qGr`),
/// name + "$X de $Y" and the percent. HU-04's Resumen tab, one row per goal.
class GoalSummaryRow extends StatelessWidget {
  const GoalSummaryRow({required this.entry, required this.onTap, super.key});

  final GoalWithProgress entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    final goal = entry.goal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            GoalProgressRing(
              percent: entry.displayedPercent,
              size: 44,
              completed: goal.isCompleted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.reportsGoalSummaryAmountOfTarget(
                      money.formatSymbol(
                        entry.savedMinor,
                        currencyCode: goal.currency,
                      ),
                      money.formatSymbol(
                        goal.targetMinor,
                        currencyCode: goal.currency,
                      ),
                    ),
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
            const SizedBox(width: 6),
            Text(
              '${entry.displayedPercent}%',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
