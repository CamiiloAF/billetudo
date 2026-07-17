import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/budget_with_progress.dart';

enum BudgetsListStatus { loading, ready, failure }

/// State of the active budgets list (HU-04). `ready` splits into "with data"
/// and "empty" via [isEmpty] — the difference is the content, not the load.
class BudgetsListState extends Equatable {
  const BudgetsListState({
    this.status = BudgetsListStatus.loading,
    this.budgets = const [],
    this.failure,
  });

  final BudgetsListStatus status;
  final List<BudgetWithProgress> budgets;
  final Failure? failure;

  bool get isLoading => status == BudgetsListStatus.loading;

  bool get isEmpty =>
      status == BudgetsListStatus.ready && budgets.isEmpty;

  BudgetsListState copyWith({
    BudgetsListStatus? status,
    List<BudgetWithProgress>? budgets,
    Failure? failure,
  }) =>
      BudgetsListState(
        status: status ?? this.status,
        budgets: budgets ?? this.budgets,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, budgets, failure];
}
