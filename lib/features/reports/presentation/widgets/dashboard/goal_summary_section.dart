import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../goals/domain/entities/goal_with_progress.dart';
import '../report_card.dart';
import 'goal_summary_row.dart';
import 'report_card_empty.dart';

/// The `Card Metas` section of Resumen (HU-04): a `Goal Summary Row`
/// (`He7JZ`) per active goal. Not in the change map's explicit file list —
/// added alongside `BudgetSummarySection` so both cards share the same
/// `ReportCard`/`ReportCardEmpty` shape.
class GoalSummarySection extends StatelessWidget {
  const GoalSummarySection({
    required this.goals,
    required this.onTapGoal,
    required this.onCreateGoal,
    super.key,
  });

  final List<GoalWithProgress> goals;
  final ValueChanged<GoalWithProgress> onTapGoal;
  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (goals.isEmpty) {
      return ReportCard(
        title: l10n.reportsDashboardGoalsTitle,
        subtitle: l10n.reportsDashboardGoalsEmptySubtitle,
        child: ReportCardEmpty(
          icon: LucideIcons.target,
          message: l10n.reportsDashboardGoalsEmptyMessage,
          cta: OutlinedButton.icon(
            onPressed: onCreateGoal,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.goalFormCreateCta),
          ),
        ),
      );
    }

    return ReportCard(
      title: l10n.reportsDashboardGoalsTitle,
      subtitle: l10n.reportsDashboardGoalsSubtitle(goals.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in goals)
            GoalSummaryRow(entry: entry, onTap: () => onTapGoal(entry)),
        ],
      ),
    );
  }
}
