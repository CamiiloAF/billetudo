import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
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
  ) : super(TransactionFormState());

  final CreateTransaction _createTransaction;
  final UpdateTransaction _updateTransaction;
  final WatchTransactionDetail _watchTransactionDetail;
  final GetTransactionEditImpact _getTransactionEditImpact;
  final SetTransactionTags _setTransactionTags;

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
      emit(
        TransactionFormState(
          status: TransactionFormStatus.ready,
          type: type,
          accountId: accountId,
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
      categoryName: entry.categoryName,
      amountMinor: transaction.amountMinor,
      currency: transaction.currency,
      date: transaction.date,
      note: transaction.note ?? '',
      tagIds: {for (final tag in entry.tags) tag.id},
      source: transaction.source,
    );
  }

  void typeSelected(TransactionType type) => emit(
        state.copyWith(
          type: type,
          // HU-03: a transfer carries no category; switching away from one
          // must drop a destination account that no longer applies.
          clearCategory: type == TransactionType.transfer,
          clearTransferAccount: type != TransactionType.transfer,
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

  /// HU-01/02/03 criterion 11: digit-by-digit money entry from the anchored
  /// keypad, e.g. typing `1`,`2`,`3`,`4` builds `$12,34` — never through a
  /// parsed/edited text field.
  void amountDigitPressed(int digit) {
    if (digit < 0 || digit > 9) {
      return;
    }
    // Caps at a sane ceiling instead of overflowing silently.
    const maxAmountMinor = 999999999999;
    final next = state.amountMinor * 10 + digit;
    if (next > maxAmountMinor) {
      return;
    }
    emit(state.copyWith(amountMinor: next));
  }

  void amountBackspace() =>
      emit(state.copyWith(amountMinor: state.amountMinor ~/ 10));

  void amountCleared() => emit(state.copyWith(amountMinor: 0));

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
  /// recurring/goal/debt and this is `false`, the write is held and
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
      recurringId: _original?.recurringId,
      goalId: _original?.goalId,
      debtId: _original?.debtId,
    ).validated();
  }
}
