import 'package:equatable/equatable.dart';

/// HU-15 at the goals **list** level: a single, cross-goal, non-monetary
/// momentum signal — never a total (that would sum different currencies).
/// `GoalListMomentumCalculator` derives it from every active goal's own
/// `GoalMomentum`.
class GoalListMomentum extends Equatable {
  const GoalListMomentum({
    required this.streakWeeks,
    this.weeksSinceLastContribution,
    this.nextMilestoneGoalName,
    this.nextMilestonePct,
    this.amountToNextMilestoneMinor,
    this.currency,
  });

  /// The best (highest) ongoing streak among the active goals. `0` when none
  /// currently has one.
  final int streakWeeks;

  /// Only set when [streakWeeks] is `0`: the fewest weeks since a
  /// contribution among the goals that have ever had one — i.e. the most
  /// recent activity across the whole list. `null` when a streak is active,
  /// or when no active goal has ever received a contribution.
  final int? weeksSinceLastContribution;

  /// The name of the goal closest to its next milestone (smallest
  /// `amountToNextMilestoneMinor`). `null` when no active goal has a pending
  /// milestone.
  final String? nextMilestoneGoalName;

  final int? nextMilestonePct;

  /// [nextMilestoneGoalName]'s own currency — never summed across goals.
  final int? amountToNextMilestoneMinor;

  final String? currency;

  /// Whether there is anything to say at all: either an active/broken streak
  /// with real history, or a pending milestone to point to. `false` means the
  /// list header should not render (e.g. every goal is brand new).
  bool get hasSignal =>
      streakWeeks > 0 || weeksSinceLastContribution != null || hasMilestone;

  bool get hasMilestone =>
      nextMilestoneGoalName != null &&
      nextMilestonePct != null &&
      amountToNextMilestoneMinor != null &&
      currency != null;

  @override
  List<Object?> get props => [
        streakWeeks,
        weeksSinceLastContribution,
        nextMilestoneGoalName,
        nextMilestonePct,
        amountToNextMilestoneMinor,
        currency,
      ];
}
