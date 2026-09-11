import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../capture/domain/usecases/confirm_pending_capture.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../categories/domain/usecases/get_category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_draft.dart';
import '../../domain/entities/transaction_with_details.dart';
import '../../domain/usecases/create_transaction.dart';
import '../../domain/usecases/get_transaction_edit_impact.dart';
import '../../domain/usecases/set_transaction_tags.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/watch_transaction_detail.dart';
import 'capture_prefill.dart';
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
    this._confirmPendingCapture,
    this._getCategory,
  ) : super(TransactionFormState());

  final CreateTransaction _createTransaction;
  final UpdateTransaction _updateTransaction;
  final WatchTransactionDetail _watchTransactionDetail;
  final GetTransactionEditImpact _getTransactionEditImpact;
  final SetTransactionTags _setTransactionTags;
  final WatchAccounts _watchAccounts;

  /// HU-05: used instead of [_createTransaction] when the form was opened
  /// from a pending capture, so the movement is created, the capture is
  /// closed and the merchant learning is fed in one business action.
  final ConfirmPendingCapture _confirmPendingCapture;

  /// Resolves the capture's suggested category so the picker opens showing
  /// its name and kind, not a bare id.
  final GetCategory _getCategory;

  /// The capture being dispatched (HU-05), or `null` for an ordinary
  /// new/edit. Not part of the (Equatable) state: it is never rendered, it
  /// only decides which use case [submit] calls.
  CapturePrefill? _capture;

  /// Kept for HU-04's edit-impact check; not part of the (Equatable) state,
  /// since it is never rendered — only diffed against the pending draft.
  Transaction? _original;

  /// The state the form was born with, used by [completeFromVoice] to tell
  /// "still the default the form opened with" from "the user chose this".
  /// Not in the state either: it describes the editing session, not the
  /// movement.
  TransactionFormState? _initialState;

  /// Loads the transaction to edit, or prepares an empty form of [type] when
  /// [id] is null.
  Future<void> load(
    String? id, {
    TransactionType type = TransactionType.expense,
    String? accountId,
    CapturePrefill? capture,
  }) async {
    _capture = capture;
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
      if (capture != null) {
        emit(await _prefilledFromCapture(
            capture, initialAccountId, initialAccountName));
        return;
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
      _initialState = state;
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
        _initialState = state;
    }
  }

  /// The form as a capture hands it over: amount, type, date, note and the
  /// suggested account/category already filled in.
  ///
  /// The focus deliberately does **not** go to the amount as it does for a
  /// blank form: the amount arrived from the issuer and is the field least
  /// likely to need editing, so opening the keypad over the form would hide
  /// the category — the one field the user actually has to check.
  Future<TransactionFormState> _prefilledFromCapture(
    CapturePrefill capture,
    String? fallbackAccountId,
    String? fallbackAccountName,
  ) async {
    String? categoryId;
    String? categoryName;
    CategoryKind? categoryKind;
    final suggestedCategoryId = capture.categoryId;
    if (suggestedCategoryId != null) {
      final result = await _getCategory(suggestedCategoryId);
      if (result case Right(value: final category)) {
        categoryId = category.id;
        categoryName = category.name;
        categoryKind = category.kind;
      }
    }
    return TransactionFormState(
      status: TransactionFormStatus.ready,
      type: capture.type,
      accountId: capture.accountId ?? fallbackAccountId,
      accountName: capture.accountId == null ? fallbackAccountName : null,
      amountMinor: capture.amountMinor,
      currency: capture.currency,
      date: capture.postedAt,
      note: capture.note ?? '',
      categoryId: categoryId,
      categoryName: categoryName,
      categoryKind: categoryKind,
      source: TransactionSource.notification,
    );
  }

  /// Opens an empty form prefilled with whatever the voice capture managed to
  /// understand (`17-captura-voz.md`, HU-01/HU-05).
  ///
  /// Same shape as `ScheduledPaymentFormCubit.loadFromBridge`: the bridge only
  /// ever hands this cubit plain values, so Transacciones never depends on
  /// Captura's domain. It builds on [load] so the account default, the
  /// currency and every other form rule stay exactly the ones the manual path
  /// uses — voice adds no invisible rules of its own.
  ///
  /// Everything is optional: **partial parsing is the normal case**. A capture
  /// that only understood the amount still opens the form with the amount, and
  /// one that understood nothing still opens the form with the transcription
  /// as the note. Nothing is written until the user presses Guardar.
  ///
  /// `source` stays `voice` no matter what the user edits afterwards: the
  /// capture origin is a historical fact, not a description of the final
  /// field values (HU-01, paridad con HU-04 de `03-transacciones.md`).
  Future<void> loadFromVoice({
    int? amountMinor,
    bool amountIsUncertain = false,
    String? amountSpokenText,
    TransactionType? type,
    String? accountId,
    String? categoryId,
    String? categoryName,
    CategoryKind? categoryKind,
    DateTime? date,
    String? note,
  }) async {
    await load(
      null,
      type: type ?? TransactionType.expense,
      accountId: accountId,
    );
    if (isClosed || state.status != TransactionFormStatus.ready) {
      return;
    }
    emit(
      state.copyWith(
        source: TransactionSource.voice,
        amountMinor: amountMinor,
        amountIsUncertain: amountMinor != null && amountIsUncertain,
        amountSpokenText: amountSpokenText,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryKind: categoryKind,
        date: date,
        note: note,
        // The focus lands on the first thing that still needs the user: the
        // amount when it is missing or only inferred. Category and account are
        // pickers, not text fields, so they take no keyboard focus — the form
        // blocks Guardar on them exactly as it does in the manual flow.
        focusedField: amountMinor == null || amountIsUncertain
            ? TransactionFormFocusedField.amount
            : TransactionFormFocusedField.none,
      ),
    );
  }

  /// Fills in from a voice capture started **from an already open form**
  /// (`E1vEe7`'s "Dictar" pill), as opposed to [loadFromVoice], which builds
  /// the form from scratch.
  ///
  /// It **completes, it does not overwrite**: only fields the user has not
  /// touched since the form opened take a dictated value (HU-05). "Touched"
  /// is measured against the state the form was born with, so the account and
  /// the date — which always open with a default rather than empty — still
  /// count as dictatable until the user picks something themselves.
  ///
  /// The `source` is *not* flipped to voice: a movement the user started
  /// typing by hand and then completed by dictating is not a voice capture,
  /// and the source measures where the record came from, not which controls
  /// were used along the way.
  void completeFromVoice({
    int? amountMinor,
    bool amountIsUncertain = false,
    String? amountSpokenText,
    TransactionType? type,
    String? accountId,
    String? categoryId,
    String? categoryName,
    CategoryKind? categoryKind,
    DateTime? date,
    String? note,
  }) {
    if (state.status != TransactionFormStatus.ready) {
      return;
    }
    final baseline = _initialState;
    final canFillAmount = state.amountMinor == 0;
    final canFillCategory = state.categoryId == null;
    final canFillNote = state.note.isEmpty;
    final canFillAccount =
        baseline == null || state.accountId == baseline.accountId;
    final canFillDate = baseline == null || state.date == baseline.date;
    final fillsAmount = amountMinor != null && canFillAmount;

    emit(
      state.copyWith(
        type: type != null && state.amountMinor == 0 ? type : state.type,
        amountMinor: fillsAmount ? amountMinor : state.amountMinor,
        amountIsUncertain: fillsAmount && amountIsUncertain,
        amountSpokenText: fillsAmount ? amountSpokenText : null,
        entryFractionDigits: fillsAmount ? -1 : state.entryFractionDigits,
        accountId:
            canFillAccount && accountId != null ? accountId : state.accountId,
        categoryId: canFillCategory ? categoryId : state.categoryId,
        categoryName: canFillCategory ? categoryName : state.categoryName,
        categoryKind: canFillCategory ? categoryKind : state.categoryKind,
        date: canFillDate && date != null ? date : state.date,
        note: canFillNote && note != null ? note : state.note,
        // Same landing as the voice-opened form: whatever still needs the user
        // takes the focus, and an inferred amount always does.
        focusedField: fillsAmount && !amountIsUncertain
            ? TransactionFormFocusedField.none
            : TransactionFormFocusedField.amount,
      ),
    );
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
      // `TransactionDraft` class doc). A budgetable transfer's category is
      // always `expense` kind (B-3), same as the form only ever offering it.
      categoryKind: transaction.categoryId == null
          ? null
          : switch (transaction.type) {
              TransactionType.expense => CategoryKind.expense,
              TransactionType.income => CategoryKind.income,
              TransactionType.transfer => CategoryKind.expense,
            },
      categoryName: entry.categoryName,
      amountMinor: transaction.amountMinor,
      currency: transaction.currency,
      date: transaction.date,
      note: transaction.note ?? '',
      tagIds: {for (final tag in entry.tags) tag.id},
      source: transaction.source,
      // Same as creation: the edit form opens with the keypad expanded.
      focusedField: TransactionFormFocusedField.amount,
      countsInBudget: transaction.countsInBudget,
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
        // a transfer carries none by default — so any real type change must
        // drop the previously picked category, or an expense category would
        // linger on an income (item 17). Switching away from a transfer also
        // drops a destination account that no longer applies.
        clearCategory: true,
        clearTransferAccount: type != TransactionType.transfer,
        // The "¿Incluir en tu presupuesto?" toggle (B-3 for transfer,
        // budget-income-counts-in-budget for income) survives across the two
        // types it applies to — alternating Transferencia <-> Ingreso keeps
        // whatever the user had chosen, since both types share the same
        // "counts toward presupuestos" meaning. It only resets to `false`
        // when the new type is `expense`, which never offers the toggle.
        countsInBudget: (type == TransactionType.transfer ||
                type == TransactionType.income) &&
            state.countsInBudget,
      ),
    );
  }

  /// The "¿Incluir en tu presupuesto?" toggle: transfer-only for B-3, and
  /// also income-only for budget-income-counts-in-budget (an ingreso
  /// presupuestable raises a matching budget's disponible instead of leaving
  /// it untouched). Turning it off drops any category picked while it was on
  /// **only for a transfer** — a transfer's category is conditional on the
  /// toggle (`TransactionDraft._validatedByType`). An income always requires
  /// a category regardless of this flag, so its category must survive the
  /// toggle being turned off.
  // ignore: avoid_positional_boolean_parameters
  void countsInBudgetChanged(bool value) => emit(
        state.copyWith(
          countsInBudget: value,
          clearCategory: state.isTransfer && !value,
        ),
      );

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
    // Touching the amount confirms it: a voice-inferred amount stops being
    // flagged as unverified the moment the user types over it.
    emit(
      base.copyWith(
        amountMinor: next,
        entryFractionDigits: nextFraction,
        amountIsUncertain: false,
      ),
    );
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
      // needs to land — as does dropping the "Supusimos…" hint, since
      // pressing the decimal key is already the user editing the amount.
      if (!identical(base, state) || state.amountIsUncertain) {
        emit(base.copyWith(amountIsUncertain: false));
      }
      return;
    }
    emit(base.copyWith(entryFractionDigits: 0, amountIsUncertain: false));
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
    if (s.amountIsUncertain) {
      // Same rule as [amountDigitPressed]: any key that edits the amount is
      // the user taking it over, so the "Supusimos…" hint goes away. Cleared
      // here, on the base state, because every branch below copies from it.
      s = s.copyWith(amountIsUncertain: false);
    }
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
          amountIsUncertain: false,
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
    final capture = _capture;
    final result = switch ((state.isEditing, capture)) {
      // Dispatching a capture always CREATES; it can never edit, and the
      // origin is a historical fact the user cannot rewrite afterwards.
      (_, final CapturePrefill capture) => await _confirmPendingCapture(
          captureId: capture.captureId,
          draft: draft,
        ),
      (true, _) => await _updateTransaction(draft),
      (false, _) => await _createTransaction(draft),
    };
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
      countsInBudget: state.countsInBudget,
    ).validated();
  }
}
