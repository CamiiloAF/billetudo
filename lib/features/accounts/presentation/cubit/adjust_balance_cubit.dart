import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_balance_adjustment.dart';
import '../../domain/usecases/adjust_account_balance.dart';
import 'adjust_balance_state.dart';

/// Drives the "Ajustar saldo" sheet (Mejora #1).
///
/// It parses the typed figure and hands the account, its current balance and
/// the chosen mode to [AdjustAccountBalance]; the diff and every sign rule live
/// in the domain, not here.
@injectable
class AdjustBalanceCubit extends Cubit<AdjustBalanceState> {
  AdjustBalanceCubit(this._adjustAccountBalance)
      : super(const AdjustBalanceState());

  final AdjustAccountBalance _adjustAccountBalance;

  void start({required Account account, required int currentBalanceMinor}) =>
      emit(
        AdjustBalanceState(
          account: account,
          currentBalanceMinor: currentBalanceMinor,
        ),
      );

  void newBalanceChanged(String value) =>
      emit(state.copyWith(newBalanceText: value, clearFailure: true));

  void modeSelected(BalanceAdjustmentMode mode) =>
      emit(state.copyWith(mode: mode, clearFailure: true));

  /// [note] is the user-facing description the registered movement is stamped
  /// with ("Ajuste de saldo"). It is localized, so it comes from presentation,
  /// not the domain.
  Future<void> apply({required String note}) async {
    final account = state.account;
    final newDisplayed = state.newDisplayedBalanceMinor;
    if (account == null || newDisplayed == null) {
      return;
    }

    emit(
        state.copyWith(status: AdjustBalanceStatus.saving, clearFailure: true));
    final result = await _adjustAccountBalance(
      account: account,
      currentBalanceMinor: state.currentBalanceMinor,
      newDisplayedBalanceMinor: newDisplayed,
      mode: state.mode,
      note: note,
    );
    if (isClosed) {
      return;
    }

    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: AdjustBalanceStatus.failure,
            failure: failure,
          ),
        );
      case Right():
        emit(state.copyWith(status: AdjustBalanceStatus.saved));
    }
  }
}
