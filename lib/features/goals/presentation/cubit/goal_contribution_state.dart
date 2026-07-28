import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_contribution.dart';

enum GoalContributionStatus { ready, saving, saved, failure }

/// The registrar-aporte/retiro sheet state (HU-03/HU-04, tracking-only
/// version: the "¿Mover dinero de una cuenta?" toggle has no approved frame
/// yet — see `docs/dev-runs`, follow-up tracked separately — so every write
/// here is a pure `GoalContribution` row, never a transfer).
class GoalContributionState extends Equatable {
  const GoalContributionState({
    required this.goalId,
    required this.direction,
    required this.currency,
    this.maxWithdrawableMinor = 0,
    this.status = GoalContributionStatus.ready,
    this.amountMinor = 0,
    required this.date,
    this.note = '',
    this.milestoneCrossed,
    this.failure,
  });

  final String goalId;
  final GoalMovementDirection direction;
  final String currency;

  /// HU-04's hard cap: a withdrawal can never exceed the goal's current
  /// derived `savedMinor`. Supplied by the caller (already known from the
  /// detail it opened from) so the sheet can bound the field without a
  /// second read.
  final int maxWithdrawableMinor;

  final GoalContributionStatus status;
  final int amountMinor;
  final DateTime date;
  final String note;

  /// HU-06: the single milestone threshold newly crossed by the last save,
  /// or `null` when none was. Read once by the page after `saved` to decide
  /// whether to open the celebration sheet/page.
  final int? milestoneCrossed;

  final Failure? failure;

  bool get isWithdrawal => direction == GoalMovementDirection.withdrawal;
  bool get isSaving => status == GoalContributionStatus.saving;

  bool get canSubmit =>
      amountMinor > 0 &&
      !isSaving &&
      (!isWithdrawal || amountMinor <= maxWithdrawableMinor);

  GoalContributionState copyWith({
    GoalContributionStatus? status,
    int? amountMinor,
    DateTime? date,
    String? note,
    int? Function()? milestoneCrossed,
    Failure? Function()? failure,
  }) =>
      GoalContributionState(
        goalId: goalId,
        direction: direction,
        currency: currency,
        maxWithdrawableMinor: maxWithdrawableMinor,
        status: status ?? this.status,
        amountMinor: amountMinor ?? this.amountMinor,
        date: date ?? this.date,
        note: note ?? this.note,
        milestoneCrossed:
            milestoneCrossed == null ? this.milestoneCrossed : milestoneCrossed(),
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [
        goalId,
        direction,
        currency,
        maxWithdrawableMinor,
        status,
        amountMinor,
        date,
        note,
        milestoneCrossed,
        failure,
      ];
}
