import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_activity_item.dart';
import '../../domain/entities/budget_period_view.dart';
import '../../domain/entities/budget_scope.dart';

enum BudgetDetailStatus { loading, ready, failure }

/// State of the budget detail (HU-04/HU-05). Holds the budget, its scope, the
/// selected period's view and how much of the activity is expanded ("Cargar
/// más", HU-04).
class BudgetDetailState extends Equatable {
  const BudgetDetailState({
    this.status = BudgetDetailStatus.loading,
    this.budget,
    this.scope,
    this.view,
    this.visibleActivityCount = activityPageSize,
    this.failure,
  });

  /// How many activity rows a "Cargar más" tap reveals.
  static const int activityPageSize = 8;

  final BudgetDetailStatus status;
  final Budget? budget;
  final BudgetScope? scope;
  final BudgetPeriodView? view;
  final int visibleActivityCount;
  final Failure? failure;

  bool get isLoading => status == BudgetDetailStatus.loading;

  /// The activity slice currently shown.
  List<BudgetActivityItem> get visibleActivity {
    final activity = view?.activity ?? const [];
    return activity.length <= visibleActivityCount
        ? activity
        : activity.sublist(0, visibleActivityCount);
  }

  bool get hasMoreActivity =>
      (view?.activity.length ?? 0) > visibleActivityCount;

  BudgetDetailState copyWith({
    BudgetDetailStatus? status,
    Budget? budget,
    BudgetScope? scope,
    BudgetPeriodView? view,
    int? visibleActivityCount,
    Failure? failure,
  }) =>
      BudgetDetailState(
        status: status ?? this.status,
        budget: budget ?? this.budget,
        scope: scope ?? this.scope,
        view: view ?? this.view,
        visibleActivityCount: visibleActivityCount ?? this.visibleActivityCount,
        failure: failure,
      );

  @override
  List<Object?> get props =>
      [status, budget, scope, view, visibleActivityCount, failure];
}
