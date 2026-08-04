import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_contribution.dart';

/// The state of Movimientos link mode for Metas (HU-03 "Enlazar un
/// movimiento"): the goal being linked to (for the banner) and whether a
/// link is in flight or failed.
enum GoalLinkStatus { idle, linking, failure }

class GoalLinkState extends Equatable {
  const GoalLinkState({
    required this.goalId,
    required this.goalName,
    required this.direction,
    this.status = GoalLinkStatus.idle,
    this.failure,
  });

  final String goalId;
  final String goalName;
  final GoalMovementDirection direction;
  final GoalLinkStatus status;
  final Failure? failure;

  GoalLinkState copyWith({
    GoalLinkStatus? status,
    Failure? Function()? failure,
  }) =>
      GoalLinkState(
        goalId: goalId,
        goalName: goalName,
        direction: direction,
        status: status ?? this.status,
        failure: failure == null ? this.failure : failure(),
      );

  @override
  List<Object?> get props => [goalId, goalName, direction, status, failure];
}
