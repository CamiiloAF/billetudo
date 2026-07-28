import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_detail.dart';

/// The lifecycle of the goal detail (HU-05/06/07/12/15).
enum GoalDetailStatus { loading, ready, failure }

class GoalDetailState extends Equatable {
  const GoalDetailState({
    this.status = GoalDetailStatus.loading,
    this.detail,
    this.movementsExpanded = false,
    this.failure,
  });

  final GoalDetailStatus status;
  final GoalDetail? detail;

  /// The ledger peek (HU-05's `p6g6S`): the history starts collapsed to the
  /// first two rows and expands in-place on "Ver todos (N)".
  final bool movementsExpanded;

  final Failure? failure;

  bool get isArchived => detail?.progress.goal.isArchived ?? false;
  bool get isCompleted => detail?.progress.goal.isCompleted ?? false;

  GoalDetailState copyWith({
    GoalDetailStatus? status,
    GoalDetail? Function()? detail,
    bool? movementsExpanded,
    Failure? failure,
  }) =>
      GoalDetailState(
        status: status ?? this.status,
        detail: detail == null ? this.detail : detail(),
        movementsExpanded: movementsExpanded ?? this.movementsExpanded,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, detail, movementsExpanded, failure];
}
