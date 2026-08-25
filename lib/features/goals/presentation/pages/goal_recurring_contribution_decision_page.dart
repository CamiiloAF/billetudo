import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../cubit/goal_recurring_contribution_state.dart';

/// HU-16's "Aporte recurrente" entry sheet (`HOdfO`/`XB4rS`): lets the user
/// choose between creating a brand-new scheduled payment linked to the goal
/// or attributing an existing one, before either flow opens.
class GoalRecurringContributionDecisionPage extends StatelessWidget {
  const GoalRecurringContributionDecisionPage({
    required this.goalName,
    super.key,
  });

  final String goalName;

  /// Opens the sheet and resolves to the chosen [GoalRecurringContributionDecision],
  /// or `null` if dismissed.
  static Future<GoalRecurringContributionDecision?> show(
    BuildContext context, {
    required String goalName,
  }) =>
      BottomSheetBase.show<GoalRecurringContributionDecision>(
        context,
        builder: (context) =>
            GoalRecurringContributionDecisionPage(goalName: goalName),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetMessage(
          icon: LucideIcons.calendarClock,
          iconColor: colors.primaryOnSoft,
          iconBackground: colors.primarySoft,
          title: l10n.goalRecurringContributionDecisionTitle(goalName),
          message: l10n.goalRecurringContributionDecisionSubtitle,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('goal-recurring-contribution-create-new'),
            onPressed: () => Navigator.of(context)
                .pop(GoalRecurringContributionDecision.createNew),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: Text(l10n.goalRecurringContributionCreateNewCta),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('goal-recurring-contribution-link-existing'),
            onPressed: () => Navigator.of(context)
                .pop(GoalRecurringContributionDecision.linkExisting),
            style:
                OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(LucideIcons.link2, size: 18),
            label: Text(l10n.goalRecurringContributionLinkExistingCta),
          ),
        ),
      ],
    );
  }
}
