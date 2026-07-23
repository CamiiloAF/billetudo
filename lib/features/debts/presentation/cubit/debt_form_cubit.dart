import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/debt_detail.dart';
import '../../domain/entities/debt_draft.dart';
import '../../domain/usecases/create_debt.dart';
import '../../domain/usecases/create_debt_with_opening_movement.dart';
import '../../domain/usecases/delete_debt.dart';
import '../../domain/usecases/update_debt.dart';
import '../../domain/usecases/update_initial_movement.dart';
import '../../domain/usecases/watch_debt_detail.dart';
import 'debt_form_state.dart';

/// Drives crear/editar deuda (HU-01/HU-05 + item 2/2b).
///
/// It parses what the user typed and hands a [DebtDraft] to `CreateDebt`/
/// `UpdateDebt`; every validation rule lives in `DebtDraft.validated()`, so the
/// form never re-implements one. On create, the "Crear deuda" CTA no longer
/// saves directly: it offers a **registro inicial** (item 2) — either the debt
/// alone, or the debt plus an opening movement against a chosen account. On
/// edit, changing the opening figure of a debt that already has a registro
/// offers to sync that movement (item 2b).
@injectable
class DebtFormCubit extends Cubit<DebtFormState> {
  DebtFormCubit(
    this._createDebt,
    this._createDebtWithOpeningMovement,
    this._updateDebt,
    this._updateInitialMovement,
    this._deleteDebt,
    this._watchDebtDetail,
    this._watchAccounts,
  ) : super(const DebtFormState());

  final CreateDebt _createDebt;
  final CreateDebtWithOpeningMovement _createDebtWithOpeningMovement;
  final UpdateDebt _updateDebt;
  final UpdateInitialMovement _updateInitialMovement;
  final DeleteDebt _deleteDebt;
  final WatchDebtDetail _watchDebtDetail;
  final WatchAccounts _watchAccounts;

  /// Loads the debt to edit, or prepares an empty form when [id] is null. Also
  /// loads the active accounts for the registro-inicial picker.
  Future<void> load(String? id) async {
    // The cubit starts in `loading`, so no explicit loading emit is needed here
    // (it would only add a redundant duplicate emission).
    final accounts = await _loadAccounts();
    if (isClosed) {
      return;
    }

    if (id == null) {
      emit(DebtFormState(status: DebtFormStatus.ready, accounts: accounts));
      return;
    }

    final result = await _watchDebtDetail(id).first;
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtFormStatus.failure,
          failure: () => failure,
        ),
      ),
      (detail) => emit(_formForDetail(detail, accounts)),
    );
  }

  Future<List<AccountWithBalance>> _loadAccounts() async {
    final result = await _watchAccounts().first;
    return result.fold((_) => const <AccountWithBalance>[], (list) => list);
  }

  DebtFormState _formForDetail(
    DebtDetail detail,
    List<AccountWithBalance> accounts,
  ) {
    final debt = detail.debt;
    final initialTxId = debt.initialTransactionId;
    // With a registro inicial the principal is 0; the opening figure the héroe
    // must show is the linked movement's amount, read from the ledger.
    final openingMinor = initialTxId == null
        ? debt.principalMinor
        : _openingFromLedger(detail, initialTxId);
    return DebtFormState(
      status: DebtFormStatus.ready,
      id: debt.id,
      direction: debt.direction,
      amountMinor: openingMinor,
      name: debt.name,
      counterparty: debt.counterparty ?? '',
      currency: debt.currency,
      dueDate: debt.dueDate,
      rateText: debt.interestRateBps == null
          ? ''
          : _rateText(debt.interestRateBps!),
      accrualMode: debt.accrualMode,
      accounts: accounts,
      initialTransactionId: initialTxId,
      openingBaselineMinor: openingMinor,
    );
  }

  static int _openingFromLedger(DebtDetail detail, String transactionId) {
    for (final entry in detail.ledger) {
      if (entry.transactionId == transactionId) {
        return entry.effectMinor.abs();
      }
    }
    return 0;
  }

  /// Basis points back to the editable "18,5" the field types in (2450 → 24,5).
  static String _rateText(int rateBps) {
    final rate = rateBps / 100;
    final text = rate == rate.roundToDouble()
        ? rate.toStringAsFixed(0)
        : rate.toString();
    return text.replaceAll('.', ',');
  }

  void directionChanged(DebtDirection direction) =>
      emit(state.copyWith(direction: direction));

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  void nameChanged(String name) => emit(
        state.copyWith(
          name: name,
          failedField:
              state.failedField == DebtDraft.fieldName ? () => null : null,
        ),
      );

  void counterpartyChanged(String counterparty) =>
      emit(state.copyWith(counterparty: counterparty));

  void currencyChanged(String currency) =>
      emit(state.copyWith(currency: currency));

  void dueDateChanged(DateTime? dueDate) =>
      emit(state.copyWith(dueDate: () => dueDate));

  void rateChanged(String rateText) => emit(
        state.copyWith(
          rateText: rateText,
          failedField: state.failedField == DebtDraft.fieldInterestRateBps
              ? () => null
              : null,
        ),
      );

  void accrualModeChanged(DebtAccrualMode accrualMode) =>
      emit(state.copyWith(accrualMode: accrualMode));

  /// The "Crear deuda" / "Guardar cambios" CTA. On create it offers a registro
  /// inicial (item 2) instead of saving directly; on edit it saves and, when
  /// the opening figure of a registro debt changed, offers to sync the movement
  /// (item 2b).
  Future<void> submit() async {
    if (state.isSaving) {
      return;
    }

    // A registro debt keeps its stored principal at 0 (the opening figure lives
    // in the linked movement); a classic debt stores the héroe as principal.
    final principalMinor =
        state.isEditing && state.hasInitialMovement ? 0 : state.amountMinor;
    final draft = _buildDraft(principalMinor);

    final validation = draft.validated();
    final invalidField = validation.fold(
      (failure) => failure is ValidationFailure ? failure.field : 'invalid',
      (_) => null,
    );
    if (invalidField != null) {
      emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          failedField: () => invalidField,
          failure: () => validation.fold((f) => f, (_) => null),
        ),
      );
      return;
    }

    if (state.isEditing) {
      await _submitEdit(draft);
      return;
    }

    // Create: offer the registro inicial when there is a positive opening
    // figure and at least one account to move; otherwise create the debt alone.
    if (state.amountMinor > 0 && state.accounts.isNotEmpty) {
      emit(
        state.copyWith(
          failedField: () => null,
          prompt: () => const DebtChooseRegistroPrompt(),
        ),
      );
    } else {
      await _createSoloDeuda();
    }
  }

  Future<void> _submitEdit(DebtDraft draft) async {
    emit(state.copyWith(status: DebtFormStatus.saving, failedField: () => null));
    final result = await _updateDebt(draft);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          failedField: () =>
              failure is ValidationFailure ? failure.field : null,
          failure: () => failure,
        ),
      ),
      (_) {
        // The debt row is saved. If it carries a registro and its opening
        // figure moved, offer to sync the linked movement (item 2b); otherwise
        // we are done.
        if (state.hasInitialMovement &&
            state.amountMinor > 0 &&
            state.amountMinor != state.openingBaselineMinor) {
          emit(
            state.copyWith(
              status: DebtFormStatus.ready,
              prompt: () => DebtConfirmUpdateRegistroPrompt(
                fromMinor: state.openingBaselineMinor,
                toMinor: state.amountMinor,
              ),
            ),
          );
        } else {
          emit(state.copyWith(status: DebtFormStatus.saved));
        }
      },
    );
  }

  Future<void> _createSoloDeuda() async {
    emit(state.copyWith(status: DebtFormStatus.saving, failedField: () => null));
    final result = await _createDebt(_buildDraft(state.amountMinor));
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          failedField: () =>
              failure is ValidationFailure ? failure.field : null,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: DebtFormStatus.saved)),
    );
  }

  /// Item 2 "No, solo la deuda": create the debt without a movement.
  Future<void> chooseSoloDeuda() async {
    emit(state.copyWith(prompt: () => null));
    await _createSoloDeuda();
  }

  /// Item 2 "Sí, elegir cuenta" (after the account picker resolved): create the
  /// debt with an opening movement against [accountId].
  Future<void> createWithOpeningMovement(String accountId) async {
    emit(
      state.copyWith(
        status: DebtFormStatus.saving,
        prompt: () => null,
        failedField: () => null,
      ),
    );
    final result = await _createDebtWithOpeningMovement(
      draft: _buildDraft(state.amountMinor),
      accountId: accountId,
      date: DateTime.now(),
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: DebtFormStatus.saved)),
    );
  }

  /// Item 2b confirm: sync the linked opening movement to the new figure.
  Future<void> confirmUpdateRegistro() async {
    final transactionId = state.initialTransactionId;
    if (transactionId == null) {
      emit(state.copyWith(status: DebtFormStatus.saved, prompt: () => null));
      return;
    }
    emit(
      state.copyWith(
        status: DebtFormStatus.saving,
        prompt: () => null,
        failure: () => null,
      ),
    );
    final result = await _updateInitialMovement(
      transactionId: transactionId,
      amountMinor: state.amountMinor,
      direction: state.direction,
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: DebtFormStatus.saved)),
    );
  }

  /// Item 2b cancel: the debt was already saved, so just leave (the movement
  /// keeps its previous amount).
  void dismissUpdateRegistro() =>
      emit(state.copyWith(status: DebtFormStatus.saved, prompt: () => null));

  /// The registro-inicial sheet (or its account picker) was dismissed: nothing
  /// is created; drop the prompt and stay on the form.
  void cancelPrompt() => emit(
        state.copyWith(status: DebtFormStatus.ready, prompt: () => null),
      );

  DebtDraft _buildDraft(int principalMinor) {
    final rateText = state.rateText.trim();
    return DebtDraft(
      id: state.id,
      name: state.name,
      direction: state.direction,
      principalMinor: principalMinor,
      currency: state.currency,
      counterparty: state.counterparty,
      dueDate: state.dueDate,
      interestRateBps:
          rateText.isEmpty ? null : MoneyFormatter.parseRateBps(rateText),
      accrualMode: state.accrualMode,
    );
  }

  /// HU-05: logical delete (papelera/undo). On success the page pops back to
  /// the list with the `deleted` outcome.
  Future<void> delete() async {
    final id = state.id;
    if (id == null || state.isSaving) {
      return;
    }
    emit(state.copyWith(status: DebtFormStatus.saving));
    final result = await _deleteDebt(id);
    if (isClosed) {
      return;
    }
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DebtFormStatus.ready,
          failure: () => failure,
        ),
      ),
      (_) => emit(state.copyWith(status: DebtFormStatus.deleted)),
    );
  }
}
