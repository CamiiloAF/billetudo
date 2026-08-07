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
    this.featuredBudgetId,
  });

  final BudgetsListStatus status;
  final List<BudgetWithProgress> budgets;
  final Failure? failure;

  /// The budget `BudgetHeroSelector.pick` actually resolves for Home's hero
  /// — manual pick if still active, otherwise the automatic global+monthly
  /// fallback. Drives the list's star badge (`BudgetLine.isFeatured`) so it
  /// never disagrees with what the hero shows, regardless of whether the
  /// selection is manual or automatic (`design-system/billetudo/pages/
  /// presupuestos.md`, "Destacar presupuesto en Inicio").
  final String? featuredBudgetId;

  bool get isLoading => status == BudgetsListStatus.loading;

  bool get isEmpty => status == BudgetsListStatus.ready && budgets.isEmpty;

  BudgetsListState copyWith({
    BudgetsListStatus? status,
    List<BudgetWithProgress>? budgets,
    Failure? failure,
    String? Function()? featuredBudgetId,
  }) =>
      BudgetsListState(
        status: status ?? this.status,
        budgets: budgets ?? this.budgets,
        failure: failure,
        featuredBudgetId: featuredBudgetId != null
            ? featuredBudgetId()
            : this.featuredBudgetId,
      );

  @override
  List<Object?> get props => [status, budgets, failure, featuredBudgetId];
}
