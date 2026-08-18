import 'package:injectable/injectable.dart';

import '../entities/goal.dart';
import '../entities/goal_contribution.dart';
import '../entities/goal_with_progress.dart';

/// Pure domain service that derives a goal's progress from its
/// `GoalContribution` history. The **only** place `savedMinor` is computed —
/// no use case or repository is allowed to write a progress value directly
/// (`docs/requirements/fase-1/07-metas.md`, "Reglas de negocio y edge cases").
@lazySingleton
class GoalProgressCalculator {
  const GoalProgressCalculator();

  /// `SUM(contribution) - SUM(withdrawal)` over [contributions]. Never
  /// clamped to `targetMinor` or to zero — this is the raw historical truth,
  /// even for a completed goal after a withdrawal (HU-07 freezes only the
  /// *displayed* percentage, computed in [calculate]).
  int deriveSavedMinor(Iterable<GoalContribution> contributions) {
    var total = 0;
    for (final contribution in contributions) {
      total += contribution.signedMinor;
    }
    return total;
  }

  /// Builds the full [GoalWithProgress] (minus [GoalWithProgress.coherence],
  /// which is a cross-goal concern owned by `GoalCoherenceCalculator`).
  GoalWithProgress calculate({
    required Goal goal,
    required List<GoalContribution> contributions,
  }) {
    final savedMinor = deriveSavedMinor(contributions);
    final displayedPercent = displayPercentOf(goal: goal, savedMinor: savedMinor);
    final remainingMinor = goal.isCompleted
        ? 0
        : (savedMinor >= goal.targetMinor ? 0 : goal.targetMinor - savedMinor);
    return GoalWithProgress(
      goal: goal,
      savedMinor: savedMinor,
      displayedPercent: displayedPercent,
      remainingMinor: remainingMinor,
    );
  }

  /// The percentage the UI shows, 0-100. Frozen at 100 once the goal is
  /// completed (HU-07): a withdrawal afterwards never drops the shown bar,
  /// even though [deriveSavedMinor] keeps reflecting the real ledger.
  int displayPercentOf({required Goal goal, required int savedMinor}) {
    if (goal.isCompleted) {
      return 100;
    }
    if (goal.targetMinor <= 0) {
      return 0;
    }
    final raw = (savedMinor * 100) ~/ goal.targetMinor;
    if (raw < 0) return 0;
    if (raw > 100) return 100;
    return raw;
  }
}
