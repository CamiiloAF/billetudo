import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/goal_list_momentum.dart';
import '../utils/goal_format.dart';

/// HU-15's list header (`p5fGpk`/`SjW95` Momentum Hero): a streak (or a
/// neutral invite to retake a broken one, never worded as a failure) plus the
/// next milestone across all active goals — never a monetary total (that
/// would sum different currencies).
///
/// `null`/`!hasSignal` from `GoalsListState.momentum` means the caller should
/// not render this widget at all (e.g. every goal is brand new).
class GoalMomentumHeader extends StatelessWidget {
  const GoalMomentumHeader({required this.momentum, super.key});

  final GoalListMomentum momentum;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isBroken = momentum.streakWeeks == 0;
    final weeksSince = momentum.weeksSinceLastContribution;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isBroken ? LucideIcons.rotateCcw : LucideIcons.flame,
                  size: 24,
                  color: colors.primaryOnSoft,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBroken
                          ? l10n.goalMomentumBrokenTitle
                          : l10n.goalMomentumStreak(momentum.streakWeeks),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isBroken
                          ? l10n.goalMomentumBrokenSub(weeksSince ?? 0)
                          : l10n.goalMomentumStreakSub,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (momentum.hasMilestone) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.flag, size: 15, color: colors.primaryOnSoft),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.goalMomentumMilestone(
                        momentum.nextMilestonePct!,
                        momentum.nextMilestoneGoalName!,
                        GoalFormat.amount(
                          momentum.amountToNextMilestoneMinor!,
                          momentum.currency!,
                        ),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
