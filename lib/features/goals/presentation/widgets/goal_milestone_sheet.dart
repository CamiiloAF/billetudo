import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import 'goal_progress_ring.dart';

/// HU-06's 25/50/75% celebration (`E2RRw`/`YUwKy`/`CFFdo`): an arc filled to
/// the crossed threshold plus forward-looking copy. The 100% milestone opens
/// `GoalCompletedCelebrationPage` instead, never this sheet.
class GoalMilestoneSheet extends StatelessWidget {
  const GoalMilestoneSheet({
    required this.goalName,
    required this.milestonePct,
    super.key,
  });

  final String goalName;
  final int milestonePct;

  static Future<void> show(
    BuildContext context, {
    required String goalName,
    required int milestonePct,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => GoalMilestoneSheet(
          goalName: goalName,
          milestonePct: milestonePct,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GoalProgressRing(
          percent: milestonePct,
          size: 120,
          child: Text(
            l10n.goalMilestonePercent(milestonePct),
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: colors.primaryOnSoftStrong,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.goalMilestoneTitle(milestonePct),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.goalMilestoneMessage(goalName),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.goalMilestoneCta),
          ),
        ),
      ],
    );
  }
}
