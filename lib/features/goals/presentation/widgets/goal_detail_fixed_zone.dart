import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/goal_detail.dart';
import '../../domain/entities/goal_projection.dart';
import '../utils/goal_format.dart';
import '../utils/goal_icon_appearance.dart';
import 'goal_account_unavailable_banner.dart';
import 'goal_progress_ring.dart';

/// The zona fija (`q4bxSf`): arc héroe + framing texts, then the
/// Aportar/Retirar row and the "cuenta con lápida" banner when it applies.
/// Anchored under the page header, outside the scrollable — decision
/// 2026-08-17 in `design-system/billetudo/pages/metas.md` § Integración con
/// Pagos Programados, needed once the recurring-contribution entry card made
/// the whole screen taller than the movement peek could clip to.
class GoalDetailFixedZone extends StatelessWidget {
  const GoalDetailFixedZone({
    required this.detail,
    required this.hasUsableLinkedAccount,
    required this.accountUnavailable,
    required this.onEdit,
    required this.onOpenWithdraw,
    required this.onOpenContribute,
    super.key,
  });

  final GoalDetail detail;
  final bool hasUsableLinkedAccount;
  final bool accountUnavailable;
  final ValueChanged<String> onEdit;
  final void Function(int maxWithdrawableMinor) onOpenWithdraw;
  final VoidCallback onOpenContribute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final progress = detail.progress;
    final goal = progress.goal;
    final completed = goal.isCompleted;

    return Column(
      children: [
        Center(
          child: GoalProgressRing(
            percent: progress.displayedPercent,
            size: 168,
            strokeWidth: 12,
            completed: completed,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  GoalIconAppearance.iconFor(goal.icon),
                  size: 34,
                  color: completed ? colors.incomeText : colors.primaryOnSoft,
                ),
                const SizedBox(height: 6),
                Text(
                  '${progress.displayedPercent}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: completed
                        ? colors.incomeText
                        : colors.primaryOnSoftStrong,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            goal.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            completed
                ? l10n.goalDetailAchieved(
                    GoalFormat.amount(progress.savedMinor, goal.currency),
                  )
                : l10n.goalDetailRemaining(
                    GoalFormat.amount(progress.remainingMinor, goal.currency),
                  ),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: completed ? colors.incomeText : colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _projectionText(l10n, context, detail.projection),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Center(
          child: Text(
            accountUnavailable
                ? l10n.goalDetailSavedOfTargetNoAccount(
                    GoalFormat.amount(progress.savedMinor, goal.currency),
                    GoalFormat.amount(goal.targetMinor, goal.currency),
                  )
                : l10n.goalDetailSavedOfTarget(
                    GoalFormat.amount(progress.savedMinor, goal.currency),
                    GoalFormat.amount(goal.targetMinor, goal.currency),
                  ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!goal.isArchived) ...[
          Row(
            children: [
              Expanded(
                child: detail.projection.kind == GoalProjectionKind.overdue
                    ? OutlinedButton.icon(
                        onPressed: () => onEdit(goal.id),
                        icon: const Icon(LucideIcons.calendar, size: 16),
                        label: Text(l10n.goalAdjustDateCta),
                      )
                    : OutlinedButton.icon(
                        onPressed: progress.savedMinor <= 0
                            ? null
                            : () => onOpenWithdraw(progress.savedMinor),
                        icon: const Icon(LucideIcons.arrowDownLeft, size: 16),
                        label: Text(l10n.goalWithdrawCta),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenContribute,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: Text(l10n.goalContributeCta),
                ),
              ),
            ],
          ),
          if (accountUnavailable) ...[
            const SizedBox(height: 14),
            GoalAccountUnavailableBanner(
              onLinkAnother: () => onEdit(goal.id),
            ),
          ],
        ],
      ],
    );
  }

  String _projectionText(
    AppLocalizations l10n,
    BuildContext context,
    GoalProjection projection,
  ) {
    switch (projection.kind) {
      case GoalProjectionKind.noTargetDate:
        return l10n.goalProjectionNoTargetDate;
      case GoalProjectionKind.overdue:
        return l10n.goalProjectionOverdue;
      case GoalProjectionKind.insufficientHistory:
      case GoalProjectionKind.noPace:
        final needed = projection.monthlyContributionNeededMinor;
        return needed == null
            ? l10n.goalProjectionInsufficientHistory
            : l10n.goalProjectionMonthlyNeeded(
                GoalFormat.amount(needed, detail.progress.goal.currency),
              );
      case GoalProjectionKind.projected:
        final date = projection.estimatedDate;
        return date == null
            ? l10n.goalProjectionInsufficientHistory
            : l10n.goalProjectionOnPace(GoalFormat.monthYear(context, date));
    }
  }
}
