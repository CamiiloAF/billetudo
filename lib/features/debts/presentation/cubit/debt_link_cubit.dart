import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/debt.dart';
import '../../domain/usecases/link_transaction_to_debt.dart';
import 'debt_link_state.dart';

/// Drives Movimientos link mode (`g0x859`, HU-02 Fase 0): attributes an
/// already-registered `Transaction` to the debt being linked, without creating
/// a new movement.
@injectable
class DebtLinkCubit extends Cubit<DebtLinkState> {
  DebtLinkCubit(this._linkTransactionToDebt)
      : super(DebtLinkState(debt: _placeholder));

  final LinkTransactionToDebt _linkTransactionToDebt;

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

  /// Seeds the mode with the [debt] the banner names.
  void start(Debt debt) => emit(DebtLinkState(debt: debt));

  /// Links [transactionId] to the active debt. Returns `true` on success so the
  /// caller can pop back to the debt; emits a failure otherwise.
  Future<bool> link(String transactionId) async {
    if (state.status == DebtLinkStatus.linking) {
      return false;
    }
    emit(state.copyWith(status: DebtLinkStatus.linking, failure: () => null));
    final result = await _linkTransactionToDebt(
      transactionId: transactionId,
      debtId: state.debt.id,
    );
    if (isClosed) {
      return false;
    }
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: DebtLinkStatus.failure,
            failure: () => failure,
          ),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(status: DebtLinkStatus.idle));
        return true;
      },
    );
  }
}
