import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/budget_with_progress.dart';
import '../../domain/usecases/get_archived_budgets.dart';
import '../../domain/usecases/reactivate_budget.dart';
import 'archived_budgets_state.dart';

/// Drives the closed-budgets history and its reactivate action (HU-10/HU-11).
@injectable
class ArchivedBudgetsCubit extends Cubit<ArchivedBudgetsState> {
  ArchivedBudgetsCubit(this._getArchivedBudgets, this._reactivateBudget)
      : super(const ArchivedBudgetsState());

  final GetArchivedBudgets _getArchivedBudgets;
  final ReactivateBudget _reactivateBudget;

  StreamSubscription<Result<List<BudgetWithProgress>>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    emit(const ArchivedBudgetsState());
    _subscription = _getArchivedBudgets().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: ArchivedBudgetsStatus.failure,
            failure: failure,
          ),
          (budgets) => state.copyWith(
            status: ArchivedBudgetsStatus.ready,
            budgets: budgets,
          ),
        ),
      );
    });
  }

  /// HU-10: brings a closed budget back to active. The stream drops it from the
  /// history on its own once `archivedAt` is cleared.
  Future<void> reactivate(String id) => _reactivateBudget(id);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
