import 'package:equatable/equatable.dart';

/// HU-15: progress-vive signals derived from `GoalContribution`s. Never a
/// monetary total (that would sum across currencies) — only a streak, a
/// count, or the next milestone.
class GoalMomentum extends Equatable {
  const GoalMomentum({
    required this.streakWeeks,
    this.nextMilestonePct,
    this.amountToNextMilestoneMinor,
  });

  /// Consecutive weeks (counting back from the current week) with at least
  /// one `contribution` movement. `0` when the current week has none yet —
  /// the streak is "broken", shown neutrally, never as a failure (HU-15).
  final int streakWeeks;

  /// The next 25/50/75/100 threshold not yet crossed (`Goal.lastMilestonePct`
  /// aware). `null` once the goal is fully celebrated (100 already reached).
  final int? nextMilestonePct;

  /// How much more `savedMinor` needs to reach [nextMilestonePct]. `null`
  /// alongside a `null` [nextMilestonePct].
  final int? amountToNextMilestoneMinor;

  @override
  List<Object?> get props => [
        streakWeeks,
        nextMilestonePct,
        amountToNextMilestoneMinor,
      ];
}
