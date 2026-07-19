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
  const BudgetLine({
    required this.entry,
    required this.onTap,
    this.envelopeMode = false,
    super.key,
  });

  final BudgetWithProgress entry;
  final VoidCallback onTap;

  /// In "Modo sobres" the row answers "how much did I put in this envelope?",
  /// so the right stack shows **Asignado + the budgeted amount** instead of
  /// what is left (`D1G5hl` overrides `avgVb`/`doPZl` this way), and the card
  /// is denser (padding 16 instead of 18).
  final bool envelopeMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final progress = entry.progress;
    final overspent = progress.isOverspent;

    const money = MoneyFormatter();
    final headlineAmount = money.formatSymbol(
      envelopeMode
          ? entry.budget.amountMinor
          : overspent
              ? -progress.remainingMinor
              : progress.remainingMinor,
      currencyCode: entry.budget.currency,
    );
    final headlineLabel = envelopeMode
        ? l10n.budgetAssignedLabel
        : overspent
            ? l10n.budgetOverspentLabel
            : l10n.budgetRemainingLabel;
    // The assigned amount is not a result, so it never turns red — only the
    // remaining/overspent reading carries the semantic `expense` family.
    final amountIsRed = overspent && !envelopeMode;

    // The percent is NOT part of this string: `FSL69` anchors it to the right
    // edge of its own row (`vdyCS`), so a long scope can never truncate it.
    final meta = [
      BudgetFormat.scopeLabel(l10n, entry.scope),
      BudgetFormat.temporalAnchor(l10n, entry.budget, entry.window),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: EdgeInsets.all(envelopeMode ? 16 : 18),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // `FSL69/Olsr9` — icon + name on the left, the "Te quedan / $X"
            // stack on the right.
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: overspent ? colors.expenseSoft : colors.muted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CategoryAppearance.iconFor(entry.budget.icon),
                    size: 20,
                    color: overspent ? colors.expense : colors.primaryOnSoft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.budget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      headlineLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: amountIsRed
                            ? colors.expenseText
                            : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      headlineAmount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: amountIsRed
                            ? colors.expenseText
                            : colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // `FSL69/oLUrn` — the meta gets the full width and the percent is
            // pinned to the right, so the ellipsis can never eat it. The meta
            // stays `$text-secondary` even when overspent: red is a signal
            // with meaning here (the amount and the percent), not ambience.
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.budgetPercent(progress.percent),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        overspent ? colors.expenseText : colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BudgetProgressBar(
              fraction: progress.fraction,
              overspent: overspent,
              height: 6,
            ),
          ],
        ),
      ),
    );
  }
}
