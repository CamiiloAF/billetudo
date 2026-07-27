import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../domain/entities/month_spending.dart';
import 'home_hero_budget_progress.dart';

/// The compact hero (HU-03): "Gastado en <mes>", the month total, a month
/// selector chip and one of three states below the amount — a budget progress
/// bar, an invitation to budget, or "aún no hay gastos".
///
/// It never invents a spending cap: without a budget the app knows no limit,
/// so instead of a fake progress bar it nudges the budgeting habit. With a
/// qualifying budget (`aOhoY`), [budgetProgress] drives a real progress bar
/// instead.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    required this.spending,
    required this.monthLabel,
    required this.onMonthTap,
    required this.onCreateBudget,
    this.budgetProgress,
    super.key,
  });

  final MonthSpending spending;

  /// The active global-monthly budget's progress for the visible month
  /// (HU-03, `aOhoY`), or `null` when none qualifies — see
  /// `WatchGlobalMonthlyBudgetProgress`.
  final BudgetWithProgress? budgetProgress;

  /// The visible month, already localized (e.g. "julio").
  final String monthLabel;

  final VoidCallback onMonthTap;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final amount = const MoneyFormatter().formatSymbol(
      spending.displayTotalMinor,
      currencyCode: spending.displayCurrency,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryDeep, colors.primary],
        ),
        borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeSpentInMonth(monthLabel),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              MonthSelectorChip(label: monthLabel, onTap: onMonthTap),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.displaySmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (budgetProgress case final progress?)
            HomeHeroBudgetProgress(
              progress: progress.progress,
              currency: progress.budget.currency,
            )
          else if (spending.hasExpenses)
            BudgetInvitationLink(onTap: onCreateBudget)
          else
            Text(
              l10n.homeNoSpendingYet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onPrimary,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }
}

/// The tappable month pill in the hero (HU-04), sized to a ≥44pt tap target.
class MonthSelectorChip extends StatelessWidget {
  const MonthSelectorChip({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.onPrimary.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: colors.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetInvitationLink extends StatelessWidget {
  const BudgetInvitationLink({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeBudgetInvitation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.arrowRight, size: 18, color: colors.onPrimary),
          ],
        ),
      ),
    );
  }
}
