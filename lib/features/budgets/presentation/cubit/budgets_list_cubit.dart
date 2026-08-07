import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/budget_with_progress.dart';
import '../../domain/usecases/get_active_budgets.dart';
import '../../domain/usecases/reconcile_budget_scopes.dart';
import '../../domain/usecases/watch_featured_budget_progress.dart';
import 'budgets_list_state.dart';

/// Drives the active budgets list (HU-04). Talks only to use cases.
@injectable
class BudgetsListCubit extends Cubit<BudgetsListState> {
  BudgetsListCubit(
    this._getActiveBudgets,
    this._reconcileBudgetScopes,
    this._watchFeaturedBudgetProgress,
  ) : super(const BudgetsListState());

  final GetActiveBudgets _getActiveBudgets;
  final ReconcileBudgetScopes _reconcileBudgetScopes;

  /// Same use case Home's hero relies on, so the list's star badge
  /// (`BudgetLine.isFeatured`) always reflects `BudgetHeroSelector.pick`'s
  /// result — manual pick or automatic fallback — never the raw manual
  /// `AppSettings.featuredBudgetId` alone.
  final WatchFeaturedBudgetProgress _watchFeaturedBudgetProgress;

  StreamSubscription<Result<List<BudgetWithProgress>>>? _subscription;
  StreamSubscription<Result<BudgetWithProgress?>>? _featuredSubscription;

  /// Subscribes to the list. Safe to call again to retry after an error.
  Future<void> start() async {
    await _subscription?.cancel();
    await _featuredSubscription?.cancel();
    emit(const BudgetsListState());
    // Fix #14: un-freeze any budget saved with a materialized "Todas"/whole-root
    // scope before the list reads it. Idempotent, so it is safe every open.
    await _reconcileBudgetScopes();
    if (isClosed) {
      return;
    }
    _subscription = _getActiveBudgets().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: BudgetsListStatus.failure,
            failure: failure,
          ),
          (budgets) => state.copyWith(
            status: BudgetsListStatus.ready,
            budgets: budgets,
          ),
        ),
      );
    });
    _featuredSubscription = _watchFeaturedBudgetProgress().listen((result) {
      if (isClosed) {
        return;
      }
      // A failure here just means the badge stays as it was — never
      // downgrades the list itself to an error state over a secondary
      // signal.
      result.fold(
        (failure) {},
        (featured) => emit(
          state.copyWith(featuredBudgetId: () => featured?.budget.id),
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _featuredSubscription?.cancel();
    return super.close();
  }
}
