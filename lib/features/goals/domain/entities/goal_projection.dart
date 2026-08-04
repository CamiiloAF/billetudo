import 'package:equatable/equatable.dart';

/// The shape of HU-05's projection for one goal.
enum GoalProjectionKind {
  /// No `targetDate` was set: no date projection is shown at all.
  noTargetDate,

  /// `targetDate` already passed: no projection, no failure state either —
  /// the UI offers "Ajustar la fecha" instead (HU-05).
  overdue,

  /// Fewer than one month of life, or zero movements: too little history to
  /// derive a pace, so a required monthly contribution is shown instead of an
  /// estimated date.
  insufficientHistory,

  /// Enough history exists but the last-3-complete-months pace is zero or
  /// negative: an estimated date would never arrive, so the monthly
  /// contribution needed is shown instead (kept positive, HU-05).
  noPace,

  /// A `targetDate`, enough history and a positive pace: an estimated
  /// arrival date is shown.
  projected,
}

/// Result of `GoalProjectionCalculator` for one goal (HU-05). Pure value
/// object: the calculator is stateless, this just carries its output.
class GoalProjection extends Equatable {
  const GoalProjection({
    required this.kind,
    this.estimatedDate,
    this.monthlyContributionNeededMinor,
    this.paceMinorPerMonth,
  });

  final GoalProjectionKind kind;

  /// Only set for [GoalProjectionKind.projected].
  final DateTime? estimatedDate;

  /// The monthly contribution that would reach the target by `targetDate`.
  /// Set for [GoalProjectionKind.insufficientHistory] and
  /// [GoalProjectionKind.noPace] (never requires history to compute).
  final int? monthlyContributionNeededMinor;

  /// Average net contribution (contribution − withdrawal) of the last 3
  /// complete months. Only set for [GoalProjectionKind.projected] and
  /// [GoalProjectionKind.noPace].
  final int? paceMinorPerMonth;

  @override
  List<Object?> get props => [
        kind,
        estimatedDate,
        monthlyContributionNeededMinor,
        paceMinorPerMonth,
      ];
}
