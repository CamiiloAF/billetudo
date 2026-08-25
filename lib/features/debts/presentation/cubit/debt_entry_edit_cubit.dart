import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/debt_entry.dart';
import '../../domain/usecases/delete_debt_entry.dart';
import '../../domain/usecases/update_debt_entry.dart';
import 'debt_entry_edit_state.dart';

/// Drives `DebtEntryEditSheet`: viewing, editing, and deleting a single
/// solo-deuda [DebtEntry]. Editing (amount/date/note) is only offered when
/// [DebtEntryEditState.editable]; `UpdateDebtEntry` re-derives the correct
/// sign for the edited magnitude on its own and rejects an `interestAccrual`
/// outright — the cubit never lets `kind` change either way. Deleting is
/// offered for every kind (`DeleteDebtEntry` has no such restriction).
@injectable
class DebtEntryEditCubit extends Cubit<DebtEntryEditState> {
  DebtEntryEditCubit(this._updateDebtEntry, this._deleteDebtEntry)
      : super(_initial);

  final UpdateDebtEntry _updateDebtEntry;
  final DeleteDebtEntry _deleteDebtEntry;

  static final DebtEntry _placeholder = DebtEntry(
    id: '',
    debtId: '',
    kind: DebtEntryKind.manualAdjustment,
    amountMinor: 0,
    entryDate: DateTime.fromMillisecondsSinceEpoch(0),
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: 0,
  );

  static final DebtEntryEditState _initial = DebtEntryEditState(
    entry: _placeholder,
    amountMinor: 0,
    date: DateTime.fromMillisecondsSinceEpoch(0),
    runningMinor: 0,
  );

  /// Seeds the sheet from the entry being viewed/edited:
  /// [DebtEntry.amountMinor] is signed, but the héroe field always shows a
  /// positive magnitude. [runningMinor] is the debt's balance right after
  /// this entry, resolved by the caller (`DebtDetailCubit`) and never
  /// re-derived here.
  void start(DebtEntry entry, {required int runningMinor}) => emit(
        DebtEntryEditState(
          entry: entry,
          amountMinor: entry.amountMinor.abs(),
          date: entry.entryDate,
          note: entry.note ?? '',
          runningMinor: runningMinor,
        ),
      );

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void noteChanged(String note) => emit(state.copyWith(note: note));

  Future<void> submit() async {
    if (!state.canSubmit) {
      return;
    }
    emit(
      state.copyWith(status: DebtEntryEditStatus.saving, failure: () => null),
    );

    final note = state.note.trim().isEmpty ? null : state.note.trim();
    final result = await _updateDebtEntry(
      id: state.entry.id,
      magnitudeMinor: state.amountMinor,
      entryDate: state.date,
      note: note,
    );
    if (isClosed) {
      return;
    }

    result.fold(
      (failure) => emit(
        state.copyWith(
            status: DebtEntryEditStatus.ready, failure: () => failure),
      ),
      (_) => emit(state.copyWith(status: DebtEntryEditStatus.saved)),
    );
  }

  /// Deletes the entry being viewed (the reversible papelera, `deletedAt`) —
  /// offered for every kind, including an `interestAccrual`. The caller
  /// confirms with `ConfirmDeleteDebtEntrySheet` before calling this.
  Future<void> delete() async {
    if (!state.canDelete) {
      return;
    }
    emit(
      state.copyWith(status: DebtEntryEditStatus.deleting, failure: () => null),
    );

    final result = await _deleteDebtEntry(state.entry.id);
    if (isClosed) {
      return;
    }

    result.fold(
      (failure) => emit(
        state.copyWith(
            status: DebtEntryEditStatus.ready, failure: () => failure),
      ),
      (_) => emit(state.copyWith(status: DebtEntryEditStatus.saved)),
    );
  }
}
