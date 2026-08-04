import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

/// Outcome of evaluating a new raw progress percentage against a goal's
/// previously-celebrated threshold (HU-06).
class GoalMilestoneOutcome extends Equatable {
  const GoalMilestoneOutcome({
    required this.lastMilestonePct,
    this.crossedMilestonePct,
  });

  /// The value `Goal.lastMilestonePct` must be persisted as.
  final int lastMilestonePct;

  /// The single threshold to celebrate now, or `null` when nothing new was
  /// crossed (either no threshold was reached, or it was already celebrated).
  final int? crossedMilestonePct;

  @override
  List<Object?> get props => [lastMilestonePct, crossedMilestonePct];
}

/// Pure, stateless domain service implementing HU-06's idempotent milestone
/// celebration: 25/50/75/100, celebrated once each, never re-triggered by a
/// withdrawal-induced dip and back-up.
@lazySingleton
class GoalMilestoneTracker {
  const GoalMilestoneTracker();

  static const List<int> thresholds = [25, 50, 75, 100];

  /// Call after every contribution/withdrawal. [previousLastMilestonePct] is
  /// the goal's current `lastMilestonePct`; [newRawPercent] is the goal's raw
  /// progress (uncapped by completion-freeze) after the movement, as a
  /// fractional percentage of `targetMinor` (may be > 100).
  ///
  /// Only ever celebrates the **highest** threshold newly crossed (HU-06: a
  /// single aporte jumping 0% -> 80% celebrates 75, not 25/50/75 in
  /// sequence), and never celebrates a threshold at or below what was already
  /// celebrated — including when the percentage *dropped* back through it.
  GoalMilestoneOutcome evaluate({
    required int previousLastMilestonePct,
    required num newRawPercent,
  }) {
    final capped = newRawPercent > 100 ? 100 : (newRawPercent < 0 ? 0 : newRawPercent);
    int? crossed;
    for (final threshold in thresholds) {
      if (capped >= threshold && threshold > previousLastMilestonePct) {
        crossed = threshold;
      }
    }
    return GoalMilestoneOutcome(
      lastMilestonePct: crossed ?? previousLastMilestonePct,
      crossedMilestonePct: crossed,
    );
  }

  /// HU-06 reconciliation rule for `UpdateGoal`: raising `targetMinor` can
  /// push the progress back below an already-celebrated threshold.
  /// `lastMilestonePct` then "only resets... to the umbral vigente, not to
  /// 0" — never celebrates again on the way back up past it, and never moves
  /// upward here (only [evaluate], driven by an actual movement, celebrates).
  int reconcileAfterTargetChange({
    required int currentLastMilestonePct,
    required num newRawPercent,
  }) {
    final capped = newRawPercent > 100 ? 100 : (newRawPercent < 0 ? 0 : newRawPercent);
    var highestReached = 0;
    for (final threshold in thresholds) {
      if (capped >= threshold) {
        highestReached = threshold;
      }
    }
    return highestReached < currentLastMilestonePct
        ? highestReached
        : currentLastMilestonePct;
  }
}
