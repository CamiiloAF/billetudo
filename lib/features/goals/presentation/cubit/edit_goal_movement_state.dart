import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_contribution.dart';

enum EditGoalMovementStatus { ready, saving, saved, failure }

/// The "Editar movimiento" sheet's own state, for a tracking-only
/// [GoalContribution] (`transactionId == null`). Deliberately separate from
/// `GoalContributionState` — this sheet only ever rewrites monto/fecha/nota
/// of the SAME row, never creates a transfer, so it carries none of
/// `GoalContributionState`'s account/presupuesto fields.
class EditGoalMovementState extends Equatable {
  const EditGoalMovementState({
    required this.contributionId,
    required this.goalId,
    required this.goalName,
    required this.direction,
    required this.currency,
    this.status = EditGoalMovementStatus.ready,
    this.amountMinor = 0,
    required this.date,
    this.note = '',
    this.failure,
  });

  final String contributionId;
  final String goalId;
  final String goalName;
  final GoalMovementDirection direction;
  final String currency;

  final EditGoalMovementStatus status;
  final int amountMinor;
  final DateTime date;
  final String note;
  final Failure? failure;

  bool get isWithdrawal => direction == GoalMovementDirection.withdrawal;
  bool get isSaving => status == EditGoalMovementStatus.saving;
  bool get canSubmit => amountMinor > 0 && !isSaving;

  EditGoalMovementState copyWith({
    EditGoalMovementStatus? status,
    int? amountMinor,
    DateTime? date,
    String? note,
    Failure? Function()? failure,
  }) =>
      EditGoalMovementState(
        contributionId: contributionId,
        goalId: goalId,
        goalName: goalName,
        direction: direction,
        currency: currency,
        status: status ?? this.status,
        amountMinor: amountMinor ?? this.amountMinor,
        date: date ?? this.date,
        note: note ?? this.note,
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [
        contributionId,
        goalId,
        goalName,
        direction,
        currency,
        status,
        amountMinor,
        date,
        note,
        failure,
      ];
}
