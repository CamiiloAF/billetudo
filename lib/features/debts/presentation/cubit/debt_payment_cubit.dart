import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/preferences/debt_payment_toggle_preference_datasource.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_cash_event.dart';
import '../../domain/entities/debt_cash_event_draft.dart';
import '../../domain/usecases/register_debt_cash_event.dart';
import '../../domain/usecases/register_debt_ledger_event.dart';
import 'debt_payment_state.dart';

/// Drives registrar-abono (`xbsY3`/`V6Z9ln`, HU-02).
///
/// The abono is always a `payment` (it reduces the debt); the sheet never asks
/// the user to pick income vs. expense — that follows from the debt's
/// direction inside `RegisterDebtCashEvent`. The "¿Agregar a una cuenta?"
/// default is remembered per debt (with a global fallback) via
/// [DebtPaymentTogglePreferenceDatasource].
@injectable
class DebtPaymentCubit extends Cubit<DebtPaymentState> {
  DebtPaymentCubit(
    this._registerCashEvent,
    this._registerLedgerEvent,
    this._watchAccounts,
    this._togglePreference,
  ) : super(DebtPaymentState(debt: _placeholder, date: DateTime.now()));

  final RegisterDebtCashEvent _registerCashEvent;
  final RegisterDebtLedgerEvent _registerLedgerEvent;
  final WatchAccounts _watchAccounts;
  final DebtPaymentTogglePreferenceDatasource _togglePreference;

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

  /// Loads the active accounts and the remembered toggle default for [debt].
  Future<void> start(Debt debt) async {
    emit(DebtPaymentState(debt: debt, date: DateTime.now()));

    final accountsResult = await _watchAccounts().first;
    final addToAccount = await _togglePreference.readAddToAccount(debt.id);
    if (isClosed) {
      return;
    }

    final accounts = accountsResult.fold(
      (_) => <AccountWithBalance>[],
      (list) => list,
    );
    // No accounts means "add to account" is impossible; fall back to the
    // cash-less ledger abono so the sheet still works.
    final effectiveAddToAccount = accounts.isNotEmpty && addToAccount;

    emit(
      state.copyWith(
        status: DebtPaymentStatus.ready,
        accounts: accounts,
        addToAccount: effectiveAddToAccount,
        selectedAccountId: () =>
            accounts.isEmpty ? null : accounts.first.account.id,
      ),
    );
  }

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  // ignore: avoid_positional_boolean_parameters
  void addToAccountChanged(bool addToAccount) {
    // Toggling to "Sí" with no accounts is a no-op; there is nothing to move.
    if (addToAccount && state.accounts.isEmpty) {
      return;
    }
    emit(state.copyWith(addToAccount: addToAccount));
  }

  void accountSelected(String accountId) =>
      emit(state.copyWith(selectedAccountId: () => accountId));

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void noteChanged(String note) => emit(state.copyWith(note: note));

  void categorySelected({required String? id, required String? name}) =>
      emit(state.copyWith(categoryId: () => id, categoryName: () => name));

  /// Registers the abono and remembers the toggle choice for next time.
  Future<void> submit() async {
    if (!state.canSubmit) {
      return;
    }
    emit(state.copyWith(status: DebtPaymentStatus.saving, failure: () => null));

    final note = state.note.trim().isEmpty ? null : state.note.trim();
    final result = state.addToAccount
        ? await _registerCashEvent(
            DebtCashEventDraft(
              debtId: state.debt.id,
              accountId: state.selectedAccountId ?? '',
              amountMinor: state.amountMinor,
              kind: DebtCashEventKind.payment,
              date: state.date,
              note: note,
              categoryId: state.categoryId,
            ),
          )
        : await _registerLedgerEvent(
            debtId: state.debt.id,
            kind: DebtCashEventKind.payment,
            amountMinor: state.amountMinor,
            date: state.date,
            note: note,
          );
    if (isClosed) {
      return;
    }

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: DebtPaymentStatus.ready,
          failure: () => failure,
        ),
      ),
      (_) async {
        await _togglePreference.writeAddToAccount(
          debtId: state.debt.id,
          addToAccount: state.addToAccount,
        );
        if (!isClosed) {
          emit(state.copyWith(status: DebtPaymentStatus.saved));
        }
      },
    );
  }
}
