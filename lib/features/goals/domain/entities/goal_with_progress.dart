import 'package:equatable/equatable.dart';

import 'goal.dart';
import 'goal_momentum.dart';

/// HU-12: an informative (never blocking) signal that the metas linked to one
/// account add up to more than the account actually holds. Computed per
/// account by `GoalCoherenceCalculator`, over active (non-archived,
/// non-trashed) goals only.
class GoalCoherenceSignal extends Equatable {
  const GoalCoherenceSignal({
    required this.accountId,
    required this.totalSavedMinor,
    required this.accountBalanceMinor,
    required this.currency,
  });

  final String accountId;

  /// Sum of `savedMinor` across every active goal linked to [accountId].
  final int totalSavedMinor;

  final int accountBalanceMinor;
  final String currency;

  /// How much the goals overshoot the real balance. Always > 0 — this signal
  /// only exists when there IS an overshoot (see
  /// `GoalCoherenceCalculator.calculate`).
  int get overshootMinor => totalSavedMinor - accountBalanceMinor;

  @override
  List<Object?> get props => [
        accountId,
        totalSavedMinor,
        accountBalanceMinor,
        currency,
      ];
}

/// A [Goal] plus everything derived from its `GoalContribution`s and its
/// linked account, ready for list/detail presentation without leaking Drift
/// types.
class GoalWithProgress extends Equatable {
  const GoalWithProgress({
    required this.goal,
    required this.savedMinor,
    required this.displayedPercent,
    required this.remainingMinor,
    this.coherence,
    this.momentum,
  });

  final Goal goal;

  /// The real derived progress: `SUM(contribution) - SUM(withdrawal)` over
  /// non-hidden movements. Never clamped — a completed goal's real figure can
  /// dip below `targetMinor` after a withdrawal without this changing.
  final int savedMinor;

  /// The percentage the UI shows, 0-100. Frozen at 100 once `goal.isCompleted`
  /// (HU-07), regardless of what [savedMinor] does afterwards.
  final int displayedPercent;

  /// `targetMinor - savedMinor`, floored at 0. Always 0 once
  /// `goal.isCompleted`.
  final int remainingMinor;

  /// Set only when the goal has an account and that account's goals overshoot
  /// its real balance (HU-12). `null` for a goal with no account, an
  /// archived goal, or one whose account is not over-assigned.
  final GoalCoherenceSignal? coherence;

  /// HU-15's per-goal streak/next-milestone shape, computed alongside the
  /// rest of the progress for every goal in the list (`GoalsListState`
  /// aggregates it into the list header's `GoalListMomentum`).
  final GoalMomentum? momentum;

  GoalWithProgress copyWith({
    GoalCoherenceSignal? coherence,
    GoalMomentum? momentum,
  }) =>
      GoalWithProgress(
        goal: goal,
        savedMinor: savedMinor,
        displayedPercent: displayedPercent,
        remainingMinor: remainingMinor,
        coherence: coherence ?? this.coherence,
        momentum: momentum ?? this.momentum,
      );

  @override
  List<Object?> get props =>
      [goal, savedMinor, displayedPercent, remainingMinor, coherence, momentum];
}
