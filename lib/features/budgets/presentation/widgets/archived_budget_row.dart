import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/budget_with_progress.dart';
import '../utils/budget_format.dart';

/// The `Archived Budget Row` component (`Ote7d`): a closed budget in the history
/// (HU-11) — name + period label + real result (within/over), overspend in
/// `$expense-text` with a `circle-minus`. Offers reactivate.
class ArchivedBudgetRow extends StatelessWidget {
  const ArchivedBudgetRow({
    required this.entry,
    required this.onReactivate,
    super.key,
  });

  final BudgetWithProgress entry;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final overspent = entry.progress.isOverspent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              CategoryAppearance.iconFor(entry.budget.icon),
              size: 20,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
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
                Row(
                  children: [
                    Text(
                      BudgetFormat.periodLabel(l10n, entry.budget.period),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    if (overspent)
                      Icon(
                        LucideIcons.circleMinus,
                        size: 13,
                        color: colors.expenseText,
                      ),
                    if (overspent) const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        overspent
                            ? l10n.budgetResultOverspent(
                                const MoneyFormatter().formatSymbol(
                                  -entry.progress.remainingMinor,
                                  currencyCode: entry.budget.currency,
                                ),
                              )
                            : l10n.budgetResultWithin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: overspent
                              ? colors.expenseText
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onReactivate,
            child: Text(l10n.budgetReactivate),
          ),
        ],
      ),
    );
  }
}
