import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../categories/presentation/utils/category_appearance.dart';
import '../../domain/entities/budget_with_progress.dart';
import '../utils/budget_format.dart';

/// The `Archived Budget Row` component (`Ote7d`): a two-zone card, not a flat
/// row.
///
/// - Body (`p2xzBn`, padding 16): icon-wrap + name (`Du849`) + **scope**
///   (`x6Z1Jm`) on the left, "Cerrado <fecha>" (`qlbT0`) on the right; below,
///   the result line (`d3mO6P`) with `circle-check-big` / `circle-minus`.
/// - Footer (`P7vMK6`): a `$border` top rule and the "Reactivar" affordance
///   right-aligned, in `$primary-on-soft-strong`.
///
/// The result icon is present in **both** outcomes; only the overspent one
/// wears the semantic `expense` family.
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
    final resultColor = overspent ? colors.expenseText : colors.textSecondary;
    final closedAt = entry.budget.archivedAt;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.muted,
                        borderRadius: BorderRadius.circular(12),
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
                            // `Archived Budget Row`'s `Name` (`Du849`) is
                            // 15/700 — heavier than a live `Budget Line`.
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            BudgetFormat.scopeLabel(l10n, entry.scope),
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
                    if (closedAt != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        l10n.budgetClosedOn(BudgetFormat.dayMonth(closedAt)),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      overspent
                          ? LucideIcons.circleMinus
                          : LucideIcons.circleCheckBig,
                      size: 16,
                      color: resultColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: resultColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ArchivedBudgetRowFooter(onReactivate: onReactivate),
        ],
      ),
    );
  }
}

/// The card's footer zone (`P7vMK6`): a `$border` top rule and the
/// right-aligned "Reactivar" affordance.
class ArchivedBudgetRowFooter extends StatelessWidget {
  const ArchivedBudgetRowFooter({required this.onReactivate, super.key});

  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onReactivate,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              LucideIcons.archiveRestore,
              size: 18,
              color: colors.primaryOnSoftStrong,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.budgetReactivate,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.primaryOnSoftStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
