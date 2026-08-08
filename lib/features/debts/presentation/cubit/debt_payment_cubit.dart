import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/preferences/debt_payment_toggle_preference_datasource.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../categories/domain/usecases/get_category.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_cash_event.dart';
import '../../domain/entities/debt_cash_event_draft.dart';
import '../../domain/services/debt_category_seed.dart';
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
///
/// Fix 7: when adding to an account, the category defaults to the same
/// `DebtCategorySeed` bucket the opening movement uses for this debt's
/// direction, and [DebtPaymentState.canSubmit] requires one — a category-less
/// abono used to be possible and left the movement under "Sin categoría".
@injectable
class DebtPaymentCubit extends Cubit<DebtPaymentState> {
  DebtPaymentCubit(
    this._registerCashEvent,
    this._registerLedgerEvent,
    this._watchAccounts,
    this._togglePreference,
    this._getCategory,
  ) : super(DebtPaymentState(debt: _placeholder, date: clock.now()));

  final RegisterDebtCashEvent _registerCashEvent;
  final RegisterDebtLedgerEvent _registerLedgerEvent;
  final WatchAccounts _watchAccounts;
  final DebtPaymentTogglePreferenceDatasource _togglePreference;
  final GetCategory _getCategory;

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

  /// Loads the active accounts, the remembered toggle default, and the
  /// direction-appropriate seed category (fix 7) for [debt].
  Future<void> start(Debt debt) async {
    emit(DebtPaymentState(debt: debt, date: clock.now()));

    final accountsResult = await _watchAccounts().first;
    final addToAccount = await _togglePreference.readAddToAccount(debt.id);
    final seedCategory = await _getCategory(
      DebtCategorySeed.categoryIdFor(debt.direction),
    );
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
    // The seed category is expected to always exist (HU-06 onboarding seeds
    // it for every user); if it somehow doesn't (or fails to load), the field
    // just starts empty and the user must pick one — `canSubmit` still
    // enforces that instead of silently saving uncategorized.
    final category = seedCategory.fold((_) => null, (c) => c);

    emit(
      state.copyWith(
        status: DebtPaymentStatus.ready,
        accounts: accounts,
        addToAccount: effectiveAddToAccount,
        selectedAccountId: () =>
            accounts.isEmpty ? null : accounts.first.account.id,
        categoryId: () => category?.id,
        categoryName: () => category?.name,
        categoryIcon: () => category?.icon,
        categoryColor: () => category?.color,
      ),
    );
  }

  Future<List<AccountWithBalance>> _loadAccounts() async {
    final result = await _watchAccounts().first;
    return result.fold((_) => <AccountWithBalance>[], (list) => list);
  }

  /// `15-gate-cuenta.md`: the "¿Agregar a una cuenta?" gate is informative,
  /// not blocking — the caller only reaches this after the user created an
  /// account from the bridge sheet while `state.accounts` was empty. Reloads
  /// the list so the switch (and the account row it reveals) reflect the new
  /// account without needing to close and reopen the sheet, mirroring
  /// `GoalFormCubit.refreshAccounts()`.
  Future<void> refreshAccounts() async {
    final accounts = await _loadAccounts();
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        accounts: accounts,
        selectedAccountId: () =>
            state.selectedAccountId ??
            (accounts.isEmpty ? null : accounts.first.account.id),
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

  void categorySelected({
    required String? id,
    required String? name,
    String? icon,
    String? color,
  }) =>
      emit(
        state.copyWith(
          categoryId: () => id,
          categoryName: () => name,
          categoryIcon: () => icon,
          categoryColor: () => color,
        ),
      );

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
