import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_detail_data.dart';
import '../../domain/usecases/create_budget.dart';
import '../../domain/usecases/get_budget_by_id.dart';
import '../../domain/usecases/update_budget.dart';
import 'budget_form_state.dart';

/// Drives creating and editing a budget (HU-01/HU-03/HU-09).
///
/// It collects raw field values and hands a draft to a use case; it does not
/// re-implement a single validation rule — those live in
/// `BudgetDraft.validated`, shared with any other caller.
@injectable
class BudgetFormCubit extends Cubit<BudgetFormState> {
  BudgetFormCubit(
    this._createBudget,
    this._updateBudget,
    this._getBudgetById,
  ) : super(BudgetFormState.loading());

  final CreateBudget _createBudget;
  final UpdateBudget _updateBudget;
  final GetBudgetById _getBudgetById;

  /// Loads the budget to edit, or prepares an empty form when [id] is null.
  Future<void> load(String? id) async {
    if (id == null) {
      emit(BudgetFormState.initial(DateTime.now()));
      return;
    }

    emit(BudgetFormState.loading());
    final result = await _getBudgetById(id).first;
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
            state.copyWith(status: BudgetFormStatus.failure, failure: failure));
      case Right(value: final data):
        emit(_formFor(data));
    }
  }

  BudgetFormState _formFor(BudgetDetailData data) {
    final budget = data.budget;
    final oneOff = budget.isOneOff;
    return BudgetFormState(
      status: BudgetFormStatus.ready,
      id: budget.id,
      name: budget.name,
      icon: budget.icon,
      amountMinor: budget.amountMinor,
      currency: budget.currency,
      recurring: !oneOff,
      // A one-off is stored as `custom`; the periodicity picker only shows the
      // recurring options, so keep a sensible default there.
      period: oneOff ? BudgetPeriod.monthly : budget.period,
      startDate: budget.startDate,
      endDate: budget.endDate,
      alertThresholdPct: budget.alertThresholdPct,
      accountIds: data.scope.aliveAccountIds,
      categoryIds: data.scope.aliveCategoryIds,
    );
  }

  void nameChanged(String value) => emit(state.copyWith(name: value));

  void iconSelected(String? icon) => emit(
        icon == null
            ? state.copyWith(clearIcon: true)
            : state.copyWith(icon: icon),
      );

  void amountChanged(int? amountMinor) => emit(
        amountMinor == null
            ? state.copyWith(clearAmount: true)
            : state.copyWith(amountMinor: amountMinor),
      );

  void currencyChanged(String currency) =>
      emit(state.copyWith(currency: currency));

  /// HU-03: switching between "Periódico" and "Una única vez". A one-off must
  /// carry an end date; a periodic budget keeps whatever end (or none) it had.
  void recurringChanged({required bool recurring}) => emit(
        state.copyWith(recurring: recurring),
      );

  void periodSelected(BudgetPeriod period) =>
      emit(state.copyWith(period: period));

  void startDateSelected(DateTime date) => emit(
        state.copyWith(startDate: DateTime(date.year, date.month, date.day)),
      );

  void endDateSelected(DateTime? date) => emit(
        date == null
            ? state.copyWith(clearEndDate: true)
            : state.copyWith(
                endDate: DateTime(date.year, date.month, date.day),
              ),
      );

  void thresholdSelected(int? pct) => emit(
        pct == null
            ? state.copyWith(clearThreshold: true)
            : state.copyWith(alertThresholdPct: pct),
      );

  void accountsSelected(Set<String> accountIds) =>
      emit(state.copyWith(accountIds: accountIds));

  void categoriesSelected(Set<String> categoryIds) =>
      emit(state.copyWith(categoryIds: categoryIds));

  /// Validates and persists. On success sets `savedId`; on a validation error
  /// surfaces the [Failure] so the form can point at the offending field.
  Future<void> submit() async {
    if (state.submitting) {
      return;
    }
    emit(state.copyWith(submitting: true));

    final draft = state.toDraft();
    final result = state.isEditing
        ? await _updateBudget(draft)
        : await _createBudget(draft);
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(submitting: false, failure: failure),
        (budget) => state.copyWith(submitting: false, savedId: budget.id),
      ),
    );
  }
}
