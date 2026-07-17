import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/budget_with_progress.dart';
import '../utils/budget_format.dart';
import 'budget_progress_bar.dart';

/// The `Budget Line` component (`FSL69`): 3 data points + bar (HU-04).
///
/// Sober color model: the icon-wrap is neutral `$muted` on every card; only an
/// overspent budget shifts to the semantic `expense` family (soft wrap, red
/// amount/percent). Tone stays positive: "Te quedan $X", "Excedido por $X" —
/// never "Te pasaste".
class BudgetLine extends StatelessWidget {
  const BudgetLine({required this.entry, required this.onTap, super.key});

  final BudgetWithProgress entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final progress = entry.progress;
    final overspent = progress.isOverspent;

    const money = MoneyFormatter();
    final headlineAmount = money.format(
      overspent ? -progress.remainingMinor : progress.remainingMinor,
      currencyCode: entry.budget.currency,
    );

    final meta = [
      BudgetFormat.scopeLabel(l10n, entry.scope),
      BudgetFormat.temporalAnchor(l10n, entry.budget, entry.window),
      l10n.budgetPercent(progress.percent),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: overspent ? colors.expenseSoft : colors.muted,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    CategoryAppearance.iconFor(entry.budget.icon),
                    size: 22,
                    color: overspent ? colors.expense : colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.budget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: overspent
                              ? colors.expenseText
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      overspent
                          ? l10n.budgetOverspentLabel
                          : l10n.budgetRemainingLabel,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      headlineAmount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            overspent ? colors.expenseText : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            BudgetProgressBar(
              fraction: progress.fraction,
              overspent: overspent,
            ),
          ],
        ),
      ),
    );
  }
}
