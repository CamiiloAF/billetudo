import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../../goals/domain/entities/goal_with_progress.dart';
import 'reports_dashboard_hero_figure.dart';

/// The `Hero Resumen` (`MKEqE`): the first element of Resumen's scrollable
/// zone, above `Card Presupuestos` — two neutral figures ("Presupuestos ·
/// N activos · $X disponibles" and "Metas · N en curso · $X ahorrados").
///
/// **Stats Row goes neutral** (nota `TvFBN`, `design-system/billetudo/pages/
/// graficas.md`): both values render in `$text-primary`, never a status
/// color — the green is reserved for a protagonist figure elsewhere in the
/// deck, and these are backing data. Neither figure uses `Chart Legend Item`
/// (`DyQfQ`): they are section labels, not a graphed series' legend.
class ReportsDashboardHero extends StatelessWidget {
  const ReportsDashboardHero({
    required this.budgets,
    required this.goals,
    super.key,
  });

  final List<BudgetWithProgress> budgets;
  final List<GoalWithProgress> goals;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();

    final availableMinor =
        budgets.fold<int>(0, (sum, b) => sum + b.progress.remainingMinor);
    final savedMinor = goals.fold<int>(0, (sum, g) => sum + g.savedMinor);
    final budgetsCurrency =
        budgets.isEmpty ? 'COP' : budgets.first.budget.currency;
    final goalsCurrency = goals.isEmpty ? 'COP' : goals.first.goal.currency;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ReportsDashboardHeroFigure(
              label: l10n.reportsDashboardBudgetsTitle,
              value: '${budgets.length}',
              sub: l10n.reportsDashboardHeroBudgetsAvailable(
                money.formatSymbol(
                  availableMinor,
                  currencyCode: budgetsCurrency,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ReportsDashboardHeroFigure(
              label: l10n.reportsDashboardGoalsTitle,
              value: '${goals.length}',
              sub: l10n.reportsDashboardHeroGoalsSaved(
                money.formatSymbol(savedMinor, currencyCode: goalsCurrency),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
