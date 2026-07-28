import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_detail.dart';
import '../../domain/entities/goal_quick_amount.dart';

/// The lifecycle of the goal detail (HU-05/06/07/12/15).
enum GoalDetailStatus { loading, ready, failure }

class GoalDetailState extends Equatable {
  const GoalDetailState({
    this.status = GoalDetailStatus.loading,
    this.detail,
    this.movementsExpanded = false,
    this.quickAmounts = const <GoalQuickAmount>[],
    this.failure,
  });

  final GoalDetailStatus status;
  final GoalDetail? detail;

  /// The ledger peek (HU-05's `p6g6S`): the history starts collapsed to the
  /// first two rows and expands in-place on "Ver todos (N)".
  final bool movementsExpanded;

  /// The user's custom "aporte rápido" chips (design-system/billetudo/pages/
  /// metas.md § Aporte rápido), shown after the fixed $50.000/$100.000 pair
  /// and before "Otro monto"/"+ Nueva". Streamed independently of [detail]
  /// since it has its own table and its own lifecycle.
  final List<GoalQuickAmount> quickAmounts;

  final Failure? failure;

  bool get isArchived => detail?.progress.goal.isArchived ?? false;
  bool get isCompleted => detail?.progress.goal.isCompleted ?? false;

  GoalDetailState copyWith({
    GoalDetailStatus? status,
    GoalDetail? Function()? detail,
    bool? movementsExpanded,
    List<GoalQuickAmount>? quickAmounts,
    Failure? failure,
  }) =>
      GoalDetailState(
        status: status ?? this.status,
        detail: detail == null ? this.detail : detail(),
        movementsExpanded: movementsExpanded ?? this.movementsExpanded,
        quickAmounts: quickAmounts ?? this.quickAmounts,
        failure: failure,
      );

  @override
  List<Object?> get props =>
      [status, detail, movementsExpanded, quickAmounts, failure];
}
