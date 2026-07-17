import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/budget_with_progress.dart';
import '../../domain/usecases/get_active_budgets.dart';
import 'budgets_list_state.dart';

/// Drives the active budgets list (HU-04). Talks only to use cases.
@injectable
class BudgetsListCubit extends Cubit<BudgetsListState> {
  BudgetsListCubit(this._getActiveBudgets) : super(const BudgetsListState());

  final GetActiveBudgets _getActiveBudgets;

  StreamSubscription<Result<List<BudgetWithProgress>>>? _subscription;

  /// Subscribes to the list. Safe to call again to retry after an error.
  Future<void> start() async {
    await _subscription?.cancel();
    emit(const BudgetsListState());
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
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
