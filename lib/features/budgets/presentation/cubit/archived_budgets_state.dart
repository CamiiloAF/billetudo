import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/budget_with_progress.dart';

enum ArchivedBudgetsStatus { loading, ready, failure }

/// State of the closed-budgets history (HU-11).
class ArchivedBudgetsState extends Equatable {
  const ArchivedBudgetsState({
    this.status = ArchivedBudgetsStatus.loading,
    this.budgets = const [],
    this.failure,
  });

  final ArchivedBudgetsStatus status;
  final List<BudgetWithProgress> budgets;
  final Failure? failure;

  bool get isLoading => status == ArchivedBudgetsStatus.loading;

  bool get isEmpty => status == ArchivedBudgetsStatus.ready && budgets.isEmpty;

  ArchivedBudgetsState copyWith({
    ArchivedBudgetsStatus? status,
    List<BudgetWithProgress>? budgets,
    Failure? failure,
  }) =>
      ArchivedBudgetsState(
        status: status ?? this.status,
        budgets: budgets ?? this.budgets,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, budgets, failure];
}
