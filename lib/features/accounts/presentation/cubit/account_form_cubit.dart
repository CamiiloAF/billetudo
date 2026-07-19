import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_draft.dart';
import '../../domain/entities/account_number_edit.dart';
import '../../domain/usecases/create_account.dart';
import '../../domain/usecases/get_account_number.dart';
import '../../domain/usecases/update_account.dart';
import '../../domain/usecases/watch_account_detail.dart';
import 'account_form_state.dart';

/// Drives adding and editing an account (HU-01/HU-02/HU-03/HU-06).
///
/// It parses what the user typed and hands a draft to a use case; it does not
/// re-implement a single validation rule — those live in
/// [AccountDraft.validated] so the form and any other caller cannot drift
/// apart.
@injectable
class AccountFormCubit extends Cubit<AccountFormState> {
  AccountFormCubit(
    this._createAccount,
    this._updateAccount,
    this._watchAccountDetail,
    this._getAccountNumber,
    this._money,
  ) : super(const AccountFormState());

  final CreateAccount _createAccount;
  final UpdateAccount _updateAccount;
  final WatchAccountDetail _watchAccountDetail;
  final GetAccountNumber _getAccountNumber;
  final MoneyFormatter _money;

  /// Loads the account to edit, or prepares an empty form when [id] is null.
  Future<void> load(String? id) async {
    if (id == null) {
      emit(const AccountFormState(status: AccountFormStatus.ready));
      return;
    }

    emit(const AccountFormState());
    final result = await _watchAccountDetail(id).first;
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: AccountFormStatus.failure,
            failure: failure,
          ),
        );
      case Right(value: final entry):
        emit(await _formFor(entry.account));
    }
  }

  Future<AccountFormState> _formFor(Account account) async {
    // HU-03: the stored number has to come back into the form so the user can
    // see and edit it. When the read fails we say so instead of rendering an
    // empty field that looks like "no number": the number only exists on this
    // device, so a silent empty field would be its last stop before deletion.
    final number = await _getAccountNumber(account.id);

    // A card's balance is stored negative (it is debt, see
    // `AccountBalance.fromBalance`), but the field the user sees is relabeled
    // "Deuda actual" and always takes a positive number — so it is shown here
    // as one, and `_buildDraft` negates it back on save.
    final displayedBalanceMinor = account.type == AccountType.card
        ? account.initialBalanceMinor.abs()
        : account.initialBalanceMinor;

    return AccountFormState(
      status: AccountFormStatus.ready,
      id: account.id,
      type: account.type,
      name: account.name,
      institution: account.institution ?? '',
      currency: account.currency,
      // Rendered with the same formatter that will parse it back, so an
      // untouched field round-trips to the exact same cents. `formatAmount`
      // would bake in a thousands separator the user then has to fight while
      // editing, so the editable field uses `formatAmountForEditing` instead.
      initialBalanceText: _money.formatAmountForEditing(
        displayedBalanceMinor,
        decimalDigits: MoneyFormatter.currencyDecimals(account.currency),
      ),
      interestRateText: account.interestRateBps == null
          ? ''
          : _money.formatAmountForEditing(account.interestRateBps!),
      creditLimitText: account.creditLimitMinor == null
          ? ''
          : _money.formatAmountForEditing(
              account.creditLimitMinor!,
              decimalDigits: MoneyFormatter.currencyDecimals(account.currency),
            ),
      statementDay: account.statementDay,
      paymentDueDay: account.paymentDueDay,
      // HU-04: the form does not edit this preference, but the update writes it
      // explicitly (HU-06), so it has to round-trip or an unrelated edit would
      // reset the card back to showing its debt.
      cardBalancePrimary: account.cardBalancePrimary,
      fullAccountNumber: number.getOrElse((_) => null),
      numberReadFailed: number.isLeft(),
      last4: account.last4 ?? '',
    );
  }

  void nameChanged(String value) => emit(state.copyWith(name: value));

  void institutionChanged(String value) =>
      emit(state.copyWith(institution: value));

  void currencySelected(String value) => emit(state.copyWith(currency: value));

  void initialBalanceChanged(String value) =>
      emit(state.copyWith(initialBalanceText: value));

  void interestRateChanged(String value) =>
      emit(state.copyWith(interestRateText: value));

  void creditLimitChanged(String value) =>
      emit(state.copyWith(creditLimitText: value));

  void statementDaySelected(int day) => emit(state.copyWith(statementDay: day));

  void paymentDueDaySelected(int day) =>
      emit(state.copyWith(paymentDueDay: day));

  void fullAccountNumberChanged(String value) => emit(
        state.copyWith(
          fullAccountNumber: value,
          clearFullAccountNumber: value.trim().isEmpty,
        ),
      );

  void last4Changed(String value) => emit(state.copyWith(last4: value));

  void toggleNumberVisibility() =>
      emit(state.copyWith(numberVisible: !state.numberVisible));

  void toggleTypePicker() =>
      emit(state.copyWith(typePickerExpanded: !state.typePickerExpanded));

  /// HU-02/HU-03: a type that cannot hold a full number must not keep one
  /// around — a card would be rejected for carrying a PAN it never showed.
  void typeSelected(AccountType type) => emit(
        state.copyWith(
          type: type,
          typePickerExpanded: false,
          clearFullAccountNumber: !type.allowsFullAccountNumber,
        ),
      );

  /// Validates through the use case and persists. [confirmed] answers HU-06's
  /// type/currency confirmation.
  Future<void> submit({bool confirmed = false}) async {
    final AccountDraft draft;
    switch (_buildDraft()) {
      case Left(value: final failure):
        emit(state.copyWith(failure: failure));
        return;
      case Right(value: final built):
        draft = built;
    }

    emit(state.copyWith(status: AccountFormStatus.saving));
    final result = state.isEditing
        ? await _updateAccount(draft, confirmed: confirmed)
        : await _createAccount(draft);
    if (isClosed) {
      return;
    }

    switch (result) {
      case Left(value: final failure):
        final needsConfirmation = failure is ValidationFailure &&
            failure.field == UpdateAccount.confirmationField;
        emit(
          state.copyWith(
            status: AccountFormStatus.ready,
            needsConfirmation: needsConfirmation,
            failure: needsConfirmation ? null : failure,
          ),
        );
      case Right():
        emit(state.copyWith(status: AccountFormStatus.saved));
    }
  }

  /// Turns the typed text into a draft. Only parsing lives here; the business
  /// rules are the draft's.
  Result<AccountDraft> _buildDraft() {
    final type = state.type;
    if (type == null) {
      return const Left(
        ValidationFailure(
          'an account type must be picked',
          field: AccountFormState.fieldType,
        ),
      );
    }

    final initialBalanceMinor = _parseOptional(
      state.initialBalanceText,
      MoneyFormatter.parseMinor,
    );
    if (initialBalanceMinor == null) {
      return const Left(
        ValidationFailure(
          'the opening balance is not a valid amount',
          field: AccountFormState.fieldInitialBalance,
        ),
      );
    }

    final interestRateBps = state.interestRateText.trim().isEmpty
        ? null
        : MoneyFormatter.parseRateBps(state.interestRateText);
    if (state.interestRateText.trim().isNotEmpty && interestRateBps == null) {
      return const Left(
        ValidationFailure(
          'the interest rate is not a valid number',
          field: AccountDraft.fieldInterestRateBps,
        ),
      );
    }

    final int? creditLimitMinor;
    if (type.isCard && state.creditLimitText.trim().isNotEmpty) {
      creditLimitMinor = MoneyFormatter.parseMinor(state.creditLimitText);
      if (creditLimitMinor == null) {
        return const Left(
          ValidationFailure(
            'the credit limit is not a valid amount',
            field: AccountDraft.fieldCreditLimitMinor,
          ),
        );
      }
    } else {
      // Left null on purpose when the card has no limit typed: HU-02 says the
      // draft must reject that, and it is not the form's rule to duplicate.
      creditLimitMinor = null;
    }

    return Right(
      AccountDraft(
        id: state.id,
        name: state.name,
        type: type,
        currency: state.currency,
        // A card's field is labeled "Deuda actual" (Bug 3) and always takes a
        // positive number from the user, but `AccountBalance.fromBalance`
        // treats a card's balance as debt, i.e. negative — so it is negated
        // here, on the way into the draft, mirroring `_formFor`'s `.abs()` on
        // the way back out.
        initialBalanceMinor:
            type.isCard ? -initialBalanceMinor.abs() : initialBalanceMinor,
        institution: state.institution,
        numberEdit: _numberEdit(type),
        last4: state.last4,
        interestRateBps: interestRateBps,
        creditLimitMinor: creditLimitMinor,
        statementDay: state.statementDay,
        paymentDueDay: state.paymentDueDay,
        cardBalancePrimary: state.cardBalancePrimary,
      ),
    );
  }

  /// What the number field means for secure storage (HU-03).
  ///
  /// An empty field is only a delete when we know there is something to delete:
  /// if the stored number could not be read, the same empty field means
  /// "unknown", and the number stays where it is.
  AccountNumberEdit _numberEdit(AccountType type) {
    // HU-02/HU-03: a type that cannot hold a number never keeps one, so a PAN
    // never reaches the domain.
    if (!type.allowsFullAccountNumber) {
      return const ClearAccountNumber();
    }
    if (state.isNumberUnknown) {
      return const KeepAccountNumber();
    }
    final typed = state.fullAccountNumber ?? '';
    return typed.trim().isEmpty
        ? const ClearAccountNumber()
        : SetAccountNumber(typed);
  }

  /// An empty amount is 0, not an error: the opening balance is optional.
  int? _parseOptional(String text, int? Function(String) parse) =>
      text.trim().isEmpty ? 0 : parse(text);
}
