import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/usecases/confirm_scheduled_occurrence.dart';
import '../../domain/usecases/skip_scheduled_occurrence.dart';
import '../../domain/usecases/snooze_scheduled_occurrence.dart';
import 'confirmation_sheet_state.dart';

/// Drives the mandatory confirmation sheet of a single pending occurrence
/// (HU-03, criterion 7): edit date/account/amount, then Confirmar, Posponer
/// or Omitir. There is no one-tap path around it — every caller (the "Por
/// confirmar" list and the guided review) goes through this cubit.
@injectable
class ConfirmationSheetCubit extends Cubit<ConfirmationSheetState> {
  ConfirmationSheetCubit(
    this._confirmOccurrence,
    this._skipOccurrence,
    this._snoozeOccurrence,
  ) : super(const ConfirmationSheetState());

  final ConfirmScheduledOccurrence _confirmOccurrence;
  final SkipScheduledOccurrence _skipOccurrence;
  final SnoozeScheduledOccurrence _snoozeOccurrence;

  /// [allPending] is the full "por confirmar" list, when the caller has it
  /// (the pending list/card do; the detail screen's lone pending badge does
  /// not) — used only to count how many other occurrences of the same
  /// template are still unconfirmed, for the "Acumuladas" strip.
  void load(
    PendingScheduledOccurrence source, {
    List<PendingScheduledOccurrence> allPending = const [],
  }) {
    final sameTemplate = allPending
        .where((item) => item.scheduledPayment.id == source.scheduledPayment.id)
        .length;
    emit(
      ConfirmationSheetState.loaded(
        source,
        pendingCountForTemplate: sameTemplate == 0 ? 1 : sameTemplate,
      ),
    );
  }

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void accountSelected(String id, String name) =>
      emit(state.copyWith(accountId: id, accountName: name));

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  /// Criterion 8: applies only these three edited (or untouched) values,
  /// never rewriting the template — the next occurrence proposes the
  /// template's original values again.
  Future<void> confirm() async {
    final amountMinor = state.amountMinor ?? 0;
    if (amountMinor <= 0) {
      emit(
        state.copyWith(
          failure: const ValidationFailure(
            'the amount must be a positive integer of cents',
            field: 'amountMinor',
          ),
        ),
      );
      return;
    }
    emit(state.copyWith(status: ConfirmationSheetStatus.saving));
    final result = await _confirmOccurrence(
      occurrenceId: state.occurrenceId,
      date: state.date!,
      accountId: state.accountId!,
      amountMinor: amountMinor,
    );
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: ConfirmationSheetStatus.failure,
            failure: failure,
          ),
        );
      case Right():
        emit(state.copyWith(status: ConfirmationSheetStatus.confirmed));
    }
  }

  /// Criterion 9: discards without generating a transaction. Reversible via
  /// `PendingOccurrencesCubit.undo`/`UndoSkipScheduledOccurrence`.
  Future<void> skip() async {
    emit(state.copyWith(status: ConfirmationSheetStatus.saving));
    final result = await _skipOccurrence(state.occurrenceId);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: ConfirmationSheetStatus.failure,
            failure: failure,
          ),
        );
      case Right():
        emit(state.copyWith(status: ConfirmationSheetStatus.skipped));
    }
  }

  /// Criterion 10: moves only this occurrence to [newDate]. Reversible via
  /// `UndoSnoozeScheduledOccurrence`.
  Future<void> snooze(DateTime newDate) async {
    emit(state.copyWith(status: ConfirmationSheetStatus.saving));
    final result = await _snoozeOccurrence(
      scheduledPaymentId: state.scheduledPaymentId,
      occurrenceDate: state.source!.occurrence.occurrenceDate,
      newDate: newDate,
    );
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: ConfirmationSheetStatus.failure,
            failure: failure,
          ),
        );
      case Right():
        emit(state.copyWith(status: ConfirmationSheetStatus.snoozed));
    }
  }
}
