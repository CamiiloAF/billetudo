import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_draft.dart';
import '../../domain/usecases/create_debt.dart';
import '../../domain/usecases/delete_debt.dart';
import '../../domain/usecases/update_debt.dart';
import '../../domain/usecases/watch_debt_detail.dart';
import 'debt_form_state.dart';

/// Drives crear/editar deuda (HU-01/HU-05).
///
/// It parses what the user typed and hands a [DebtDraft] to `CreateDebt`/
/// `UpdateDebt`; every validation rule (name required, non-negative opening
/// balance, ISO currency, non-negative rate) lives in `DebtDraft.validated()`,
/// so the form never re-implements one. Editing loads through `WatchDebtDetail`
/// (its first emission), the same reactive read the detail uses.
@injectable
class DebtFormCubit extends Cubit<DebtFormState> {
  DebtFormCubit(
    this._createDebt,
    this._updateDebt,
    this._deleteDebt,
    this._watchDebtDetail,
  ) : super(const DebtFormState());

  final CreateDebt _createDebt;
  final UpdateDebt _updateDebt;
  final DeleteDebt _deleteDebt;
  final WatchDebtDetail _watchDebtDetail;

  /// Loads the debt to edit, or prepares an empty form when [id] is null.
  Future<void> load(String? id) async {
    if (id == null) {
      emit(const DebtFormState(status: DebtFormStatus.ready));
      return;
    }

    emit(const DebtFormState());
    final result = await _watchDebtDetail(id).first;
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (detail) => emit(_formFor(detail.debt)),
    );
  }

  DebtFormState _formFor(Debt debt) => DebtFormState(
        status: DebtFormStatus.ready,
        id: debt.id,
        direction: debt.direction,
        amountMinor: debt.principalMinor,
        name: debt.name,
        counterparty: debt.counterparty ?? '',
        currency: debt.currency,
        dueDate: debt.dueDate,
        rateText: debt.interestRateBps == null
            ? ''
            : _rateText(debt.interestRateBps!),
        accrualMode: debt.accrualMode,
      );

  /// Basis points back to the editable "18,5" the field types in (2450 → 24,5).
  static String _rateText(int rateBps) {
    final rate = rateBps / 100;
    final text = rate == rate.roundToDouble()
        ? rate.toStringAsFixed(0)
        : rate.toString();
    return text.replaceAll('.', ',');
  }

  void directionChanged(DebtDirection direction) =>
      emit(state.copyWith(direction: direction));

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  void nameChanged(String name) => emit(
        state.copyWith(
          name: name,
          failedField:
              state.failedField == DebtDraft.fieldName ? () => null : null,
        ),
      );

  void counterpartyChanged(String counterparty) =>
      emit(state.copyWith(counterparty: counterparty));

  void currencyChanged(String currency) =>
      emit(state.copyWith(currency: currency));

  void dueDateChanged(DateTime? dueDate) =>
      emit(state.copyWith(dueDate: () => dueDate));

  void rateChanged(String rateText) => emit(
        state.copyWith(
          rateText: rateText,
          failedField: state.failedField == DebtDraft.fieldInterestRateBps
              ? () => null
              : null,
        ),
      );

  void accrualModeChanged(DebtAccrualMode accrualMode) =>
      emit(state.copyWith(accrualMode: accrualMode));

  /// Builds a draft from the form and creates or updates the debt (HU-01/05).
  Future<void> submit() async {
    if (state.isSaving) {
      return;
    }
    emit(state.copyWith(status: DebtFormStatus.saving, failedField: () => null));

    final rateText = state.rateText.trim();
    final draft = DebtDraft(
      id: state.id,
      name: state.name,
      direction: state.direction,
      principalMinor: state.amountMinor,
      currency: state.currency,
      counterparty: state.counterparty,
      dueDate: state.dueDate,
      interestRateBps:
          rateText.isEmpty ? null : MoneyFormatter.parseRateBps(rateText),
      accrualMode: state.accrualMode,
    );

    final result =
        state.isEditing ? await _updateDebt(draft) : await _createDebt(draft);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          failedField: () =>
              failure is ValidationFailure ? failure.field : null,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: DebtFormStatus.saved)),
    );
  }

  /// HU-05: logical delete (papelera/undo). On success the page pops back to
  /// the list with the `deleted` outcome.
  Future<void> delete() async {
    final id = state.id;
    if (id == null || state.isSaving) {
      return;
    }
    emit(state.copyWith(status: DebtFormStatus.saving));
    final result = await _deleteDebt(id);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: DebtFormStatus.deleted)),
    );
  }
}
