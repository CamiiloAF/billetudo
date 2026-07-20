import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateUtils;

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_edit_impact.dart';

enum TransactionFormStatus { loading, ready, saving, saved, failure }

/// Which control has focus. Drives the anchored numeric keypad (HU-01/02/03
/// criterion 11): it shows only while [amount] has focus, and hides the
/// instant [note] gets it — the two never show at once.
enum TransactionFormFocusedField { none, amount, note }

/// The four binary operators of the anchored calculator keypad (`transacciones.md`,
/// Pencil `Keypad` node). Kept as a domain-free enum so the math stays in the
/// cubit and never leaks a `double` into the money path.
enum CalcOperator { add, subtract, multiply, divide }

/// State of the single add/edit form, parametrized by [type] (HU-01/02/03/04).
class TransactionFormState extends Equatable {
  TransactionFormState({
    this.status = TransactionFormStatus.loading,
    this.id,
    this.type = TransactionType.expense,
    this.accountId,
    this.accountName,
    this.transferAccountId,
    this.transferAccountName,
    this.categoryId,
    this.categoryName,
    this.categoryKind,
    this.amountMinor = 0,
    this.currency = 'COP',
    DateTime? date,
    this.note = '',
    this.tagIds = const <String>{},
    this.source = TransactionSource.manual,
    this.focusedField = TransactionFormFocusedField.none,
    this.calcOperator,
    this.calcOperand,
    this.entryFractionDigits = -1,
    this.startNewOperand = false,
    this.justEvaluated = false,
    this.editImpact,
    this.failure,
  }) : date = date ?? DateTime.now();

  /// `null` when creating; the transaction id when editing.
  final String? id;

  final TransactionFormStatus status;
  final TransactionType type;
  final String? accountId;

  /// Resolved display name of [accountId]. The picker field renders this
  /// instead of its static label once a selection exists — without it, the
  /// button never shows which account the user picked (regression: HU-01
  /// found this dark, id-only, in the real form).
  final String? accountName;

  final String? transferAccountId;
  final String? transferAccountName;
  final String? categoryId;
  final String? categoryName;

  /// The `kind` of the category [categoryId] points to, required whenever
  /// [categoryId] is set (see `TransactionDraft`).
  final CategoryKind? categoryKind;

  /// Built digit by digit from the anchored keypad: always a positive integer
  /// of cents, never a parsed string (HU-01/02/03 money rule).
  final int amountMinor;

  final String currency;
  final DateTime date;
  final String note;

  /// Tags currently assigned in the form (HU-07), applied via
  /// `SetTransactionTags` on save.
  final Set<String> tagIds;

  /// Capture origin. Read-only in the form: HU-04 never lets an edit rewrite
  /// it.
  final TransactionSource source;

  final TransactionFormFocusedField focusedField;

  // --- Anchored calculator keypad state (all integer, never a `double`) ---

  /// The pending left operand in minor units, captured when an operator was
  /// pressed. `null` when no operation is in progress.
  final CalcOperator? calcOperator;

  /// The operator awaiting its right operand. `null` when none is pending.
  final int? calcOperand;

  /// How many fraction digits the *current* operand has typed after a decimal
  /// point: `-1` = whole-number entry (no point yet), `0..2` = that many
  /// fraction digits. Drives digit placement without ever parsing a `double`.
  final int entryFractionDigits;

  /// True right after an operator: the next digit starts a fresh right operand
  /// instead of appending to the value still shown on screen.
  final bool startNewOperand;

  /// True right after `=`: the next digit starts a brand-new calculation
  /// (standard calculator behaviour).
  final bool justEvaluated;

  /// Set once `submit()` finds the edit would desync a linked
  /// scheduled-payment/goal/debt (HU-04) and is awaiting confirmation.
  final TransactionEditImpact? editImpact;

  final Failure? failure;

  bool get isEditing => id != null;

  bool get isTransfer => type == TransactionType.transfer;

  /// HU-06/criterion 14: the puente to Pagos Programados only offers to turn
  /// a **new** movement into a template — editing an existing transaction
  /// never re-triggers it, even if its date is moved into the future.
  bool get isFutureDate {
    if (isEditing) {
      return false;
    }
    final today = DateUtils.dateOnly(DateTime.now());
    return DateUtils.dateOnly(date).isAfter(today);
  }

  bool get isKeypadVisible =>
      focusedField == TransactionFormFocusedField.amount;

  bool get isAwaitingEditImpactConfirmation =>
      editImpact != null && editImpact!.hasImpact;

  /// The failing field, when [failure] points at one — mirrors
  /// `AccountFormState.failedField` so the form can highlight the offending
  /// selector.
  String? get failedField => failure is ValidationFailure
      ? (failure! as ValidationFailure).field
      : null;

  TransactionFormState copyWith({
    TransactionFormStatus? status,
    String? id,
    TransactionType? type,
    String? accountId,
    String? accountName,
    String? transferAccountId,
    String? transferAccountName,
    String? categoryId,
    String? categoryName,
    CategoryKind? categoryKind,
    int? amountMinor,
    String? currency,
    DateTime? date,
    String? note,
    Set<String>? tagIds,
    TransactionSource? source,
    TransactionFormFocusedField? focusedField,
    CalcOperator? calcOperator,
    int? calcOperand,
    int? entryFractionDigits,
    bool? startNewOperand,
    bool? justEvaluated,
    TransactionEditImpact? editImpact,
    Failure? failure,
    bool clearCategory = false,
    bool clearTransferAccount = false,
    bool clearEditImpact = false,
    bool clearCalc = false,
  }) =>
      TransactionFormState(
        status: status ?? this.status,
        id: id ?? this.id,
        type: type ?? this.type,
        accountId: accountId ?? this.accountId,
        accountName: accountName ?? this.accountName,
        transferAccountId: clearTransferAccount
            ? null
            : (transferAccountId ?? this.transferAccountId),
        transferAccountName: clearTransferAccount
            ? null
            : (transferAccountName ?? this.transferAccountName),
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        categoryName:
            clearCategory ? null : (categoryName ?? this.categoryName),
        categoryKind:
            clearCategory ? null : (categoryKind ?? this.categoryKind),
        amountMinor: amountMinor ?? this.amountMinor,
        currency: currency ?? this.currency,
        date: date ?? this.date,
        note: note ?? this.note,
        tagIds: tagIds ?? this.tagIds,
        source: source ?? this.source,
        focusedField: focusedField ?? this.focusedField,
        calcOperator: clearCalc ? null : (calcOperator ?? this.calcOperator),
        calcOperand: clearCalc ? null : (calcOperand ?? this.calcOperand),
        entryFractionDigits: entryFractionDigits ?? this.entryFractionDigits,
        startNewOperand: startNewOperand ?? this.startNewOperand,
        justEvaluated: justEvaluated ?? this.justEvaluated,
        editImpact: clearEditImpact ? null : (editImpact ?? this.editImpact),
        // A new state carrying data is a state without an error: the caller
        // clears the failure by simply not passing one.
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        id,
        type,
        accountId,
        accountName,
        transferAccountId,
        transferAccountName,
        categoryId,
        categoryName,
        categoryKind,
        amountMinor,
        currency,
        date,
        note,
        tagIds,
        source,
        focusedField,
        calcOperator,
        calcOperand,
        entryFractionDigits,
        startNewOperand,
        justEvaluated,
        editImpact,
        failure,
      ];
}
