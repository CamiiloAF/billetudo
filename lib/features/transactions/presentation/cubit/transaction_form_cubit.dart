import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_draft.dart';
import '../../domain/entities/transaction_with_details.dart';
import '../../domain/usecases/create_transaction.dart';
import '../../domain/usecases/get_transaction_edit_impact.dart';
import '../../domain/usecases/set_transaction_tags.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/watch_transaction_detail.dart';
import 'transaction_form_state.dart';

/// Drives the single add/edit form for the 3 transaction types
/// (HU-01/02/03/04), including the anchored numeric keypad's focus rule and
/// the edit-impact confirmation flow.
///
/// It parses what the user typed and hands a draft to a use case; the
/// business rules (category kind, distinct transfer accounts, positive
/// amount) live in `TransactionDraft.validated`, never re-implemented here.
@injectable
class TransactionFormCubit extends Cubit<TransactionFormState> {
  TransactionFormCubit(
    this._createTransaction,
    this._updateTransaction,
    this._watchTransactionDetail,
    this._getTransactionEditImpact,
    this._setTransactionTags,
    this._watchAccounts,
  ) : super(TransactionFormState());

  final CreateTransaction _createTransaction;
  final UpdateTransaction _updateTransaction;
  final WatchTransactionDetail _watchTransactionDetail;
  final GetTransactionEditImpact _getTransactionEditImpact;
  final SetTransactionTags _setTransactionTags;
  final WatchAccounts _watchAccounts;

  /// Kept for HU-04's edit-impact check; not part of the (Equatable) state,
  /// since it is never rendered — only diffed against the pending draft.
  Transaction? _original;

  /// Loads the transaction to edit, or prepares an empty form of [type] when
  /// [id] is null.
  Future<void> load(
    String? id, {
    TransactionType type = TransactionType.expense,
    String? accountId,
  }) async {
    if (id == null) {
      _original = null;
      // Resolve against the live account list so the preselected account
      // carries its name for the account chip and a stale id degrades
      // gracefully. [accountId] is the caller's preference — the account the
      // movements list was filtered by (HU-06a). When it is null or no longer
      // exists, fall back to the first account by `sortOrder` (the account
      // picker sheet's own order), so the form never opens with no account.
      final result = await _watchAccounts().first;
      if (isClosed) {
        return;
      }
      String? initialAccountId;
      String? initialAccountName;
      if (result case Right(value: final accounts) when accounts.isNotEmpty) {
        final preferred =
            accountId == null ? null : _accountById(accounts, accountId);
        final chosen = preferred ?? accounts.first;
        initialAccountId = chosen.account.id;
        initialAccountName = chosen.account.name;
      }
      emit(
        TransactionFormState(
          status: TransactionFormStatus.ready,
          type: type,
          accountId: initialAccountId,
          accountName: initialAccountName,
          // Open with the amount focused so the Zona Fija starts expanded with
          // the keypad visible — the design's default "Monto activo" state.
          focusedField: TransactionFormFocusedField.amount,
        ),
      );
      return;
    }

    emit(TransactionFormState());
    final result = await _watchTransactionDetail(id).first;
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          TransactionFormState(
            status: TransactionFormStatus.failure,
            failure: failure,
          ),
        );
      case Right(value: final entry):
        _original = entry.transaction;
        emit(_formFor(entry));
    }
  }

  AccountWithBalance? _accountById(
    List<AccountWithBalance> accounts,
    String id,
  ) {
    for (final entry in accounts) {
      if (entry.account.id == id) {
        return entry;
      }
    }
    return null;
  }

  TransactionFormState _formFor(TransactionWithDetails entry) {
    final transaction = entry.transaction;
    return TransactionFormState(
      status: TransactionFormStatus.ready,
      id: transaction.id,
      type: transaction.type,
      accountId: transaction.accountId,
      accountName: entry.accountName,
      transferAccountId: transaction.transferAccountId,
      transferAccountName: entry.transferAccountName,
      categoryId: transaction.categoryId,
      // `Transaction` never stores the category's `kind` (it is Categories'
      // data, not Transactions'); re-derive it from the transaction's own
      // type instead of leaving it null, or `validated()` would reject the
      // save on every edit of an already-categorized expense/income (the
      // category always matched the type when it was first picked — see
      // `TransactionDraft` class doc).
      categoryKind: transaction.categoryId == null
          ? null
          : (transaction.type == TransactionType.expense
              ? CategoryKind.expense
              : CategoryKind.income),
      categoryName: entry.categoryName,
      amountMinor: transaction.amountMinor,
      currency: transaction.currency,
      date: transaction.date,
      note: transaction.note ?? '',
      tagIds: {for (final tag in entry.tags) tag.id},
      source: transaction.source,
      // Same as creation: the edit form opens with the keypad expanded.
      focusedField: TransactionFormFocusedField.amount,
    );
  }

  void typeSelected(TransactionType type) {
    if (type == state.type) {
      return;
    }
    emit(
      state.copyWith(
        type: type,
        // Income and expense have distinct category sets (`CategoryKind`), and
        // a transfer carries none — so any real type change must drop the
        // previously picked category, or an expense category would linger on an
        // income (item 17). Switching away from a transfer also drops a
        // destination account that no longer applies.
        clearCategory: true,
        clearTransferAccount: type != TransactionType.transfer,
      ),
    );
  }

  void accountSelected(String id, String name) =>
      emit(state.copyWith(accountId: id, accountName: name));

  void transferAccountSelected(String id, String name) => emit(
        state.copyWith(transferAccountId: id, transferAccountName: name),
      );

  void categorySelected(String? id, CategoryKind? kind, String? name) => emit(
        id == null
            ? state.copyWith(clearCategory: true)
            : state.copyWith(
                categoryId: id,
                categoryKind: kind,
                categoryName: name,
              ),
      );

  void currencySelected(String value) => emit(state.copyWith(currency: value));

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void noteChanged(String value) => emit(state.copyWith(note: value));

  void tagsChanged(Set<String> tagIds) => emit(state.copyWith(tagIds: tagIds));

  /// Caps entry/results at a sane ceiling instead of overflowing silently.
  static const int _maxAmountMinor = 999999999999;

  /// HU-01/02/03 criterion 11: digit-by-digit money entry from the anchored
  /// calculator keypad. Whole-number digits build the integer part; a decimal
  /// point (see [amountDecimalPressed]) switches to the fraction. Money never
  /// becomes a `double`: `amountMinor` stays an integer of minor units, always
  /// scaled by 100 to match storage.
  void amountDigitPressed(int digit) {
    if (digit < 0 || digit > 9) {
      return;
    }
    final base = _startFreshOperandIfNeeded(state);
    final decimals = MoneyFormatter.inputDecimals(base.currency);

    final int next;
    final int nextFraction;
    if (base.entryFractionDigits < 0) {
      // Whole-number mode: each digit shifts the integer part by one place.
      final whole = base.amountMinor ~/ 100;
      next = (whole * 10 + digit) * 100;
      nextFraction = -1;
    } else if (base.entryFractionDigits < decimals) {
      // Fraction mode: place value shrinks from tenths (10) to cents (1).
      final place = _pow10(1 - base.entryFractionDigits);
      next = base.amountMinor + digit * place;
      nextFraction = base.entryFractionDigits + 1;
    } else {
      return; // Fraction already full for this currency; ignore.
    }
    if (next > _maxAmountMinor) {
      return;
    }
    emit(base.copyWith(amountMinor: next, entryFractionDigits: nextFraction));
  }

  /// The decimal-point key. Every currency the app handles accepts typed cents
  /// (item 4), so this is only a no-op for a hypothetical zero-decimal
  /// [MoneyFormatter.inputDecimals] currency.
  void amountDecimalPressed() {
    if (MoneyFormatter.inputDecimals(state.currency) == 0) {
      return;
    }
    final base = _startFreshOperandIfNeeded(state);
    if (base.entryFractionDigits >= 0) {
      // A second '.' does nothing, but a pending fresh-operand reset still
      // needs to land.
      if (!identical(base, state)) {
        emit(base);
      }
      return;
    }
    emit(base.copyWith(entryFractionDigits: 0));
  }

  /// An operator key (÷ × − +). Evaluates any pending operation first so that
  /// chaining (`2 + 3 ×`) folds the running result, then arms the new operator.
  void amountOperatorPressed(CalcOperator operator) {
    final s = state;
    // Operator right after another operator (no new operand typed) just swaps
    // the pending operator; nothing to evaluate yet.
    if (s.startNewOperand && s.calcOperator != null) {
      emit(s.copyWith(calcOperator: operator));
      return;
    }
    final left = s.calcOperator != null && s.calcOperand != null
        ? _evaluate(s.calcOperand!, s.calcOperator!, s.amountMinor)
        : s.amountMinor;
    emit(
      s.copyWith(
        amountMinor: left,
        calcOperand: left,
        calcOperator: operator,
        startNewOperand: true,
        justEvaluated: false,
        entryFractionDigits: -1,
      ),
    );
  }

  /// The `=` key: evaluates the pending operation and leaves the result as the
  /// amount. With nothing pending it is a no-op. Typing a digit afterwards
  /// starts a brand-new calculation (see [_startFreshOperandIfNeeded]).
  void amountEqualsPressed() {
    final s = state;
    final operator = s.calcOperator;
    final operand = s.calcOperand;
    if (operator == null || operand == null) {
      return;
    }
    final result = _evaluate(operand, operator, s.amountMinor);
    emit(
      s.copyWith(
        amountMinor: result,
        justEvaluated: true,
        startNewOperand: false,
        entryFractionDigits: -1,
        clearCalc: true,
      ),
    );
  }

  void amountBackspace() {
    var s = state;
    if (s.justEvaluated) {
      // Editing a result turns it back into a plain operand.
      s = s.copyWith(justEvaluated: false, clearCalc: true);
    }
    if (s.startNewOperand) {
      // No digit typed for this operand yet: drop back to a fresh 0.
      emit(
        s.copyWith(
          amountMinor: 0,
          startNewOperand: false,
          entryFractionDigits: -1,
        ),
      );
      return;
    }
    if (s.entryFractionDigits > 0) {
      final place = _pow10(2 - s.entryFractionDigits);
      final digit = (s.amountMinor ~/ place) % 10;
      emit(
        s.copyWith(
          amountMinor: s.amountMinor - digit * place,
          entryFractionDigits: s.entryFractionDigits - 1,
        ),
      );
      return;
    }
    if (s.entryFractionDigits == 0) {
      // Only the decimal point was there: remove it.
      emit(s.copyWith(entryFractionDigits: -1));
      return;
    }
    // Whole-number mode: drop the last integer digit.
    final whole = s.amountMinor ~/ 100;
    emit(s.copyWith(amountMinor: (whole ~/ 10) * 100));
  }

  void amountCleared() => emit(
        state.copyWith(
          amountMinor: 0,
          entryFractionDigits: -1,
          startNewOperand: false,
          justEvaluated: false,
          clearCalc: true,
        ),
      );

  /// Resets the current operand to a fresh `0` when the previous keystroke was
  /// `=` (start a new calculation) or an operator (start the right operand).
  /// Returns [s] untouched otherwise.
  TransactionFormState _startFreshOperandIfNeeded(TransactionFormState s) {
    if (s.justEvaluated) {
      return s.copyWith(
        amountMinor: 0,
        entryFractionDigits: -1,
        justEvaluated: false,
        clearCalc: true,
      );
    }
    if (s.startNewOperand) {
      return s.copyWith(
        amountMinor: 0,
        entryFractionDigits: -1,
        startNewOperand: false,
      );
    }
    return s;
  }

  /// Evaluates `left <op> right` on minor-unit integers, keeping the money path
  /// free of `double`. `+`/`−` are exact. `×`/`÷` use `BigInt` so the product
  /// cannot overflow and the single rounding to cents is explicit round-half-up.
  int _evaluate(int left, CalcOperator operator, int right) {
    final int raw;
    switch (operator) {
      case CalcOperator.add:
        raw = left + right;
      case CalcOperator.subtract:
        raw = left - right;
      case CalcOperator.multiply:
        // Both operands are scaled by 100, so their product is scaled by
        // 10000; divide by 100 once to return to minor units, rounding half-up.
        raw = ((BigInt.from(left) * BigInt.from(right) + BigInt.from(50)) ~/
                BigInt.from(100))
            .toInt();
      case CalcOperator.divide:
        if (right == 0) {
          return left; // Guard: '÷ 0' is a no-op, never a crash.
        }
        // (left/100) / (right/100) = left*100 / right, rounded half-up.
        raw = ((BigInt.from(left) * BigInt.from(100) +
                    BigInt.from(right) ~/ BigInt.two) ~/
                BigInt.from(right))
            .toInt();
    }
    if (raw < 0) {
      return 0; // Amounts stay non-negative.
    }
    return raw > _maxAmountMinor ? _maxAmountMinor : raw;
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }

  /// Focus rule of criterion 11: Monto and Nota never hold focus at once.
  void amountFocused() => emit(
        state.copyWith(focusedField: TransactionFormFocusedField.amount),
      );

  void noteFocused() =>
      emit(state.copyWith(focusedField: TransactionFormFocusedField.note));

  void fieldBlurred() =>
      emit(state.copyWith(focusedField: TransactionFormFocusedField.none));

  /// Dismisses the edit-impact warning without confirming the write.
  void editImpactDismissed() => emit(state.copyWith(clearEditImpact: true));

  /// Validates through the use case and persists. [confirmed] answers HU-04's
  /// edit-impact warning: when the pending edit affects a linked
  /// scheduled-payment/goal/debt and this is `false`, the write is held and
  /// `state.editImpact` is populated instead, so the caller can show the
  /// warning sheet and call `submit(confirmed: true)` to proceed.
  Future<void> submit({bool confirmed = false}) async {
    final TransactionDraft draft;
    switch (_buildDraft()) {
      case Left(value: final failure):
        emit(state.copyWith(failure: failure));
        return;
      case Right(value: final built):
        draft = built;
    }

    final original = _original;
    if (state.isEditing && original != null && !confirmed) {
      final impact =
          _getTransactionEditImpact(original: original, draft: draft);
      if (impact.hasImpact) {
        emit(state.copyWith(editImpact: impact));
        return;
      }
    }

    emit(state.copyWith(
        status: TransactionFormStatus.saving, clearEditImpact: true));
    final result = state.isEditing
        ? await _updateTransaction(draft)
        : await _createTransaction(draft);
    if (isClosed) {
      return;
    }

    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(
            status: TransactionFormStatus.ready, failure: failure));
      case Right(value: final saved):
        final tagsResult =
            await _setTransactionTags(saved.id, state.tagIds.toList());
        if (isClosed) {
          return;
        }
        if (tagsResult case Left(value: final failure)) {
          emit(
            state.copyWith(
                status: TransactionFormStatus.ready, failure: failure),
          );
          return;
        }
        emit(state.copyWith(status: TransactionFormStatus.saved));
    }
  }

  Result<TransactionDraft> _buildDraft() {
    final accountId = state.accountId;
    if (accountId == null) {
      return const Left(
        ValidationFailure(
          'an account is required',
          field: TransactionDraft.fieldAccountId,
        ),
      );
    }

    return TransactionDraft(
      id: state.id,
      accountId: accountId,
      categoryId: state.categoryId,
      categoryKind: state.categoryKind,
      amountMinor: state.amountMinor,
      currency: state.currency,
      type: state.type,
      date: state.date,
      note: state.note,
      source: state.source,
      transferAccountId: state.transferAccountId,
      scheduledPaymentId: _original?.scheduledPaymentId,
      goalId: _original?.goalId,
      debtId: _original?.debtId,
    ).validated();
  }
}
