import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/entities/goal_detail.dart';
import '../../domain/entities/goal_quick_amount.dart';

/// The lifecycle of the goal detail (HU-05/06/07/12/15).
enum GoalDetailStatus { loading, ready, failure }

class GoalDetailState extends Equatable {
  const GoalDetailState({
    this.status = GoalDetailStatus.loading,
    this.detail,
    this.visibleMovementsCount = movementsPageSize,
    this.quickAmounts = const <GoalQuickAmount>[],
    this.failure,
  });

  /// How many history rows a "Ver más" tap reveals, following
  /// `BudgetDetailState.activityPageSize`'s exact pattern.
  static const int movementsPageSize = 8;

  final GoalDetailStatus status;
  final GoalDetail? detail;

  /// How many of the history's newest-first rows are currently shown
  /// (HU-05's `p6g6S`): starts at [movementsPageSize] and grows by the same
  /// page size on every "Ver más" tap, never all at once.
  final int visibleMovementsCount;

  /// The user's custom "aporte rápido" chips (design-system/billetudo/pages/
  /// metas.md § Aporte rápido), shown after the fixed $50.000/$100.000 pair
  /// and before "Otro monto"/"+ Nueva". Streamed independently of [detail]
  /// since it has its own table and its own lifecycle.
  final List<GoalQuickAmount> quickAmounts;

  final Failure? failure;

  bool get isArchived => detail?.progress.goal.isArchived ?? false;
  bool get isCompleted => detail?.progress.goal.isCompleted ?? false;

  /// The history slice currently shown, newest-first, capped to
  /// [visibleMovementsCount].
  List<GoalContribution> get visibleMovements {
    final history = detail?.history ?? const <GoalContribution>[];
    return history.length <= visibleMovementsCount
        ? history
        : history.sublist(0, visibleMovementsCount);
  }

  bool get hasMoreMovements =>
      (detail?.history.length ?? 0) > visibleMovementsCount;

  GoalDetailState copyWith({
    GoalDetailStatus? status,
    GoalDetail? Function()? detail,
    int? visibleMovementsCount,
    List<GoalQuickAmount>? quickAmounts,
    Failure? failure,
  }) =>
      GoalDetailState(
        status: status ?? this.status,
        detail: detail == null ? this.detail : detail(),
        visibleMovementsCount:
            visibleMovementsCount ?? this.visibleMovementsCount,
        quickAmounts: quickAmounts ?? this.quickAmounts,
        failure: failure,
      );

  @override
  List<Object?> get props =>
      [status, detail, visibleMovementsCount, quickAmounts, failure];
}
