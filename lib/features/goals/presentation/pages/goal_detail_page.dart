import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/entities/goal_detail.dart';
import '../../domain/entities/goal_projection.dart';
import '../../domain/entities/goal_with_progress.dart';
import '../cubit/goal_detail_cubit.dart';
import '../cubit/goal_detail_state.dart';
import '../utils/goal_format.dart';
import '../utils/goal_icon_appearance.dart';
import '../widgets/goal_movement_row.dart';
import '../widgets/goal_progress_ring.dart';
import '../widgets/goal_quick_amount_row.dart';
import '../widgets/sheets/confirm_archive_goal_sheet.dart';
import '../widgets/sheets/confirm_delete_goal_sheet.dart';
import '../widgets/sheets/goal_actions_sheet.dart';
import '../widgets/sheets/goal_contribution_sheet.dart';

/// The goal detail (HU-05/06/07/12/15): arc héroe + "Te faltan $X" + forward
/// projection, quick-amount chips + Aportar/Retirar, and the movement peek
/// that expands in-place (`p6g6S`).
class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({
    required this.onEdit,
    required this.onOpenCompletedCelebration,
    required this.onOpenMilestone,
    this.onOpenTransaction,
    super.key,
  });

  final ValueChanged<String> onEdit;

  /// Opens the 100% full-screen celebration (HU-07). Fired once, right after
  /// a contribution's crossed milestone is `100`.
  final void Function(GoalWithProgress progress) onOpenCompletedCelebration;

  /// Opens the 25/50/75% celebration sheet (HU-06).
  final void Function(String goalName, int milestonePct) onOpenMilestone;

  final ValueChanged<String>? onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalDetailCubit, GoalDetailState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                GoalDetailHeader(state: state, onEdit: onEdit),
                Expanded(
                  child: switch (state.status) {
                    GoalDetailStatus.loading =>
                      const Center(child: CircularProgressIndicator()),
                    GoalDetailStatus.failure => ErrorState(
                        title: AppLocalizations.of(context).goalsErrorTitle,
                        onRetry: context.read<GoalDetailCubit>().retry,
                      ),
                    GoalDetailStatus.ready => GoalDetailBody(
                        detail: state.detail!,
                        movementsExpanded: state.movementsExpanded,
                        onOpenCompletedCelebration: onOpenCompletedCelebration,
                        onOpenMilestone: onOpenMilestone,
                        onOpenTransaction: onOpenTransaction,
                      ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GoalDetailHeader extends StatelessWidget {
  const GoalDetailHeader({required this.state, required this.onEdit, super.key});

  final GoalDetailState state;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final detail = state.detail;

    return PageHeader(
      title: l10n.goalDetailTitle,
      trailing: detail == null
          ? null
          : PageHeaderCircleButton(
              icon: LucideIcons.ellipsis,
              background: colors.muted,
              foreground: colors.textPrimary,
              tooltip: l10n.goalActionsTooltip,
              onPressed: () => unawaited(_openActions(context, detail)),
            ),
    );
  }

  Future<void> _openActions(BuildContext context, GoalDetail detail) async {
    final goal = detail.progress.goal;
    final action = await GoalActionsSheet.show(
      context,
      goalName: goal.name,
      archived: goal.isArchived,
    );
    if (!context.mounted || action == null) {
      return;
    }
    final cubit = context.read<GoalDetailCubit>();
    switch (action) {
      case GoalActionsSheetAction.edit:
        onEdit(goal.id);
      case GoalActionsSheetAction.archive:
        final confirmed =
            await ConfirmArchiveGoalSheet.show(context, archiving: true);
        if (confirmed ?? false) {
          await cubit.archive();
        }
      case GoalActionsSheetAction.unarchive:
        final confirmed =
            await ConfirmArchiveGoalSheet.show(context, archiving: false);
        if (confirmed ?? false) {
          await cubit.unarchive();
        }
      case GoalActionsSheetAction.delete:
        final confirmed = await ConfirmDeleteGoalSheet.show(context);
        if ((confirmed ?? false) && context.mounted) {
          await cubit.delete();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
    }
  }
}

class GoalDetailBody extends StatelessWidget {
  const GoalDetailBody({
    required this.detail,
    required this.movementsExpanded,
    required this.onOpenCompletedCelebration,
    required this.onOpenMilestone,
    this.onOpenTransaction,
    super.key,
  });

  final GoalDetail detail;
  final bool movementsExpanded;
  final void Function(GoalWithProgress progress) onOpenCompletedCelebration;
  final void Function(String goalName, int milestonePct) onOpenMilestone;
  final ValueChanged<String>? onOpenTransaction;

  static const int _peekCount = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final progress = detail.progress;
    final goal = progress.goal;
    final completed = goal.isCompleted;
    final history = detail.history;
    final visible =
        movementsExpanded ? history : history.take(_peekCount).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Center(
          child: GoalProgressRing(
            percent: progress.displayedPercent,
            size: 168,
            strokeWidth: 12,
            completed: completed,
            child: Icon(
              GoalIconAppearance.iconFor(goal.icon),
              size: 32,
              color: completed ? colors.incomeText : colors.primaryOnSoftStrong,
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
        const SizedBox(height: 24),
        if (!goal.isArchived) ...[
          if (!completed) ...[
            GoalQuickAmountRow(
              currency: goal.currency,
              onQuickAmount: (amountMinor) => unawaited(
                _quickContribute(context, goal.id, goal.currency, amountMinor),
              ),
              onOther: () => unawaited(
                _openContribute(context, goal.id, goal.currency),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: progress.savedMinor <= 0
                      ? null
                      : () => unawaited(
                            _openWithdraw(
                              context,
                              goal.id,
                              goal.currency,
                              progress.savedMinor,
                            ),
                          ),
                  child: Text(l10n.goalWithdrawCta),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => unawaited(
                    _openContribute(context, goal.id, goal.currency),
                  ),
                  child: Text(l10n.goalContributeCta),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.goalMovementsTitle(history.length),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (!movementsExpanded && history.length > _peekCount)
              TextButton(
                onPressed: context.read<GoalDetailCubit>().expandMovements,
                child: Text(l10n.goalMovementsSeeAll(history.length)),
              ),
          ],
        ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.goalMovementsEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          )
        else
          for (final movement in visible)
            GoalMovementRow(
              movement: movement,
              currency: goal.currency,
              onTap: movement.transactionId == null
                  ? null
                  : () => onOpenTransaction?.call(movement.transactionId!),
            ),
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

  Future<void> _quickContribute(
    BuildContext context,
    String goalId,
    String currency,
    int amountMinor,
  ) async {
    final cubit = context.read<GoalDetailCubit>();
    final result = await cubit.quickContribute(amountMinor);
    if (!context.mounted) {
      return;
    }
    result.fold((_) {}, (milestone) => _handleMilestone(context, cubit, milestone));
  }

  Future<void> _openContribute(
    BuildContext context,
    String goalId,
    String currency,
  ) async {
    final cubit = context.read<GoalDetailCubit>();
    final milestone = await GoalContributionSheet.show(
      context,
      goalId: goalId,
      direction: GoalMovementDirection.contribution,
      currency: currency,
    );
    if (context.mounted) {
      _handleMilestone(context, cubit, milestone);
    }
  }

  Future<void> _openWithdraw(
    BuildContext context,
    String goalId,
    String currency,
    int maxWithdrawableMinor,
  ) async {
    await GoalContributionSheet.show(
      context,
      goalId: goalId,
      direction: GoalMovementDirection.withdrawal,
      currency: currency,
      maxWithdrawableMinor: maxWithdrawableMinor,
    );
  }

  void _handleMilestone(
    BuildContext context,
    GoalDetailCubit cubit,
    int? milestone,
  ) {
    if (milestone == null) {
      return;
    }
    final progress = detail.progress;
    if (milestone >= 100) {
      onOpenCompletedCelebration(progress);
    } else {
      onOpenMilestone(progress.goal.name, milestone);
    }
  }
}
