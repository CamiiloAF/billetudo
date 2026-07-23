import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/debt.dart';
import '../../domain/usecases/update_debt_balance.dart';
import 'debt_update_balance_state.dart';

/// Drives actualizar-saldo (`DEWMf`, HU-06): reconciles the debt to a figure
/// the user names, recording a `manualAdjustment` that absorbs the difference.
/// It never moves an account.
@injectable
class DebtUpdateBalanceCubit extends Cubit<DebtUpdateBalanceState> {
  DebtUpdateBalanceCubit(this._updateDebtBalance)
      : super(
          DebtUpdateBalanceState(
            debt: _placeholder,
            currentOutstandingMinor: 0,
            targetMinor: 0,
            date: DateTime.now(),
          ),
        );

  final UpdateDebtBalance _updateDebtBalance;

  static final Debt _placeholder = Debt(
    id: '',
    name: '',
    direction: DebtDirection.iOwe,
    principalMinor: 0,
    currency: 'COP',
    accrualMode: DebtAccrualMode.manual,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: 0,
  );

  /// Seeds the sheet from the debt and its current derived outstanding, with
  /// the new-saldo field defaulting to the current figure (a zero adjustment).
  void start({required Debt debt, required int currentOutstandingMinor}) {
    emit(
      DebtUpdateBalanceState(
        debt: debt,
        currentOutstandingMinor: currentOutstandingMinor,
        targetMinor: currentOutstandingMinor,
        date: DateTime.now(),
      ),
    );
  }

  void targetChanged(int targetMinor) =>
      emit(state.copyWith(targetMinor: targetMinor));

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void noteChanged(String note) => emit(state.copyWith(note: note));

  Future<void> submit() async {
    if (!state.canSubmit) {
      return;
    }
    emit(
      state.copyWith(
        status: DebtUpdateBalanceStatus.saving,
        failure: () => null,
      ),
    );
    final note = state.note.trim().isEmpty ? null : state.note.trim();
    final result = await _updateDebtBalance(
      debtId: state.debt.id,
      targetOutstandingMinor: state.targetMinor,
      date: state.date,
      note: note,
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtUpdateBalanceStatus.ready,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: DebtUpdateBalanceStatus.saved)),
    );
  }
}
