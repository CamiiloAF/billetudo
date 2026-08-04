import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../../budgets/presentation/widgets/budget_line.dart';
import '../report_card.dart';
import 'report_card_empty.dart';

/// The `Card Presupuestos` section of Resumen (HU-04): reuses `Budget Line`
/// (`FSL69`) verbatim from Presupuestos — no re-implementation, no color
/// migration (that migration to `$primary-data` is pending separate
/// approval, see `design-system/billetudo/pages/graficas.md`).
class BudgetSummarySection extends StatelessWidget {
  const BudgetSummarySection({
    required this.budgets,
    required this.onTapBudget,
    required this.onCreateBudget,
    super.key,
  });

  final List<BudgetWithProgress> budgets;
  final ValueChanged<BudgetWithProgress> onTapBudget;
  final VoidCallback onCreateBudget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (budgets.isEmpty) {
      return ReportCard(
        title: l10n.reportsDashboardBudgetsTitle,
        subtitle: l10n.reportsDashboardBudgetsEmptySubtitle,
        child: ReportCardEmpty(
          icon: LucideIcons.wallet,
          message: l10n.reportsDashboardBudgetsEmptyMessage,
          cta: FilledButton.icon(
            onPressed: onCreateBudget,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.budgetFormCreateCta),
          ),
        ),
      );
    }

    return ReportCard(
      title: l10n.reportsDashboardBudgetsTitle,
      subtitle: l10n.reportsDashboardBudgetsSubtitle(budgets.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in budgets) ...[
            BudgetLine(entry: entry, onTap: () => onTapBudget(entry)),
            if (entry != budgets.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
