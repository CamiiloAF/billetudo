import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/budget_period_option.dart';
import '../../domain/usecases/watch_budget_period_options.dart';

enum BudgetPeriodFilterStatus { loading, ready, failure }

/// The Movimientos "Presupuesto" sheet's own selection, edited freely and
/// only handed back to `TransactionsListCubit` when the user taps "Aplicar"
/// — same non-mutating-until-applied shape as `AccountFilterState`.
class BudgetPeriodFilterState extends Equatable {
  const BudgetPeriodFilterState({
    this.status = BudgetPeriodFilterStatus.loading,
    this.options = const <BudgetPeriodOption>[],
    this.selectedBudgetId,
    this.failure,
  });

  final BudgetPeriodFilterStatus status;
  final List<BudgetPeriodOption> options;

  /// `null` means "no budget chosen" — the sheet's cleared/default state.
  final String? selectedBudgetId;

  final Failure? failure;

  BudgetPeriodFilterState copyWith({
    BudgetPeriodFilterStatus? status,
    List<BudgetPeriodOption>? options,
    String? selectedBudgetId,
    bool clearSelected = false,
    Failure? failure,
  }) =>
      BudgetPeriodFilterState(
        status: status ?? this.status,
        options: options ?? this.options,
        selectedBudgetId: clearSelected
            ? null
            : (selectedBudgetId ?? this.selectedBudgetId),
        failure: failure,
      );

  @override
  List<Object?> get props => [status, options, selectedBudgetId, failure];
}

/// Drives the "Presupuesto" filter sheet: a live list of active budgets
/// ([WatchBudgetPeriodOptions]) plus a single-selection working copy, exactly
/// paralleling `AccountFilterCubit`/`DateFilterCubit` — nothing reaches
/// `TransactionsListCubit` until the sheet's "Aplicar".
///
/// Re-resolves the selected budget's current period window live every time
/// the sheet reopens (via [WatchBudgetPeriodOptions]) instead of reusing a
/// window frozen at the moment it was first selected.
@injectable
class BudgetPeriodFilterCubit extends Cubit<BudgetPeriodFilterState> {
  BudgetPeriodFilterCubit(this._watchBudgetPeriodOptions)
      : super(const BudgetPeriodFilterState());

  final WatchBudgetPeriodOptions _watchBudgetPeriodOptions;

  StreamSubscription<Result<List<BudgetPeriodOption>>>? _subscription;

  /// Opens the sheet with [initialBudgetId] (the filter's current value, or
  /// `null` when no budget is currently applied).
  Future<void> start(String? initialBudgetId) async {
    await _subscription?.cancel();
    emit(BudgetPeriodFilterState(selectedBudgetId: initialBudgetId));
    _subscription = _watchBudgetPeriodOptions().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: BudgetPeriodFilterStatus.failure,
            failure: failure,
          ),
          (options) => state.copyWith(
            status: BudgetPeriodFilterStatus.ready,
            options: options,
          ),
        ),
      );
    });
  }

  /// Selects [budgetId] as the sole working choice — single selection, so
  /// picking a new budget replaces the previous one instead of adding to it.
  void select(String budgetId) =>
      emit(state.copyWith(selectedBudgetId: budgetId));

  /// Clears the working selection back to "no budget" — HU-06's "Limpiar".
  void clear() => emit(state.copyWith(clearSelected: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
