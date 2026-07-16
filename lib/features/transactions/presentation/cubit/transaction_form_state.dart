import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_edit_impact.dart';

enum TransactionFormStatus { loading, ready, saving, saved, failure }

/// Which control has focus. Drives the anchored numeric keypad (HU-01/02/03
/// criterion 11): it shows only while [amount] has focus, and hides the
/// instant [note] gets it — the two never show at once.
enum TransactionFormFocusedField { none, amount, note }

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

  /// Set once `submit()` finds the edit would desync a linked
  /// recurring/goal/debt (HU-04) and is awaiting confirmation.
  final TransactionEditImpact? editImpact;

  final Failure? failure;

  bool get isEditing => id != null;

  bool get isTransfer => type == TransactionType.transfer;

  bool get isKeypadVisible =>
      focusedField == TransactionFormFocusedField.amount;

  bool get isAwaitingEditImpactConfirmation =>
      editImpact != null && editImpact!.hasImpact;

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
    TransactionEditImpact? editImpact,
    Failure? failure,
    bool clearCategory = false,
    bool clearTransferAccount = false,
    bool clearEditImpact = false,
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
        editImpact,
        failure,
      ];
}
