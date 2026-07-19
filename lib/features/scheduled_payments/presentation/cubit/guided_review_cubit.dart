import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/usecases/confirm_scheduled_occurrence.dart';
import '../../domain/usecases/skip_scheduled_occurrence.dart';
import '../../domain/usecases/snooze_scheduled_occurrence.dart';
import 'guided_review_state.dart';

/// Drives "Revisar todas" (HU-03): steps through every pending occurrence one
/// at a time, each one requiring the same explicit Confirmar/Posponer/Omitir
/// decision as the standalone confirmation sheet — there is no "apply-all"
/// shortcut anywhere in this flow (criterion 7).
@injectable
class GuidedReviewCubit extends Cubit<GuidedReviewState> {
  GuidedReviewCubit(
    this._confirmOccurrence,
    this._skipOccurrence,
    this._snoozeOccurrence,
  ) : super(const GuidedReviewState());

  final ConfirmScheduledOccurrence _confirmOccurrence;
  final SkipScheduledOccurrence _skipOccurrence;
  final SnoozeScheduledOccurrence _snoozeOccurrence;

  void start(List<PendingScheduledOccurrence> pending) {
    if (pending.isEmpty) {
      emit(const GuidedReviewState(status: GuidedReviewStatus.finished));
      return;
    }
    emit(GuidedReviewState(status: GuidedReviewStatus.ready, queue: pending));
    _loadCurrent();
  }

  void _loadCurrent() {
    final current = state.current;
    if (current == null) {
      emit(state.copyWith(status: GuidedReviewStatus.finished));
      return;
    }
    final sameTemplate = state.queue
        .where(
          (item) => item.scheduledPayment.id == current.scheduledPayment.id,
        )
        .length;
    emit(
      state.copyWith(
        status: GuidedReviewStatus.ready,
        date: current.occurrence.effectiveDate,
        accountId: current.scheduledPayment.accountId,
        accountName: current.accountName,
        amountMinor: current.scheduledPayment.amountMinor,
        pendingCountForTemplate: sameTemplate == 0 ? 1 : sameTemplate,
      ),
    );
  }

  void dateChanged(DateTime date) => emit(state.copyWith(date: date));

  void accountSelected(String id, String name) =>
      emit(state.copyWith(accountId: id, accountName: name));

  void amountChanged(int amountMinor) =>
      emit(state.copyWith(amountMinor: amountMinor));

  Future<void> confirmCurrent() async {
    final current = state.current;
    final amountMinor = state.amountMinor ?? 0;
    if (current == null) {
      return;
    }
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
    emit(state.copyWith(status: GuidedReviewStatus.saving));
    final result = await _confirmOccurrence(
      occurrenceId: current.occurrence.id,
      date: state.date!,
      accountId: state.accountId!,
      amountMinor: amountMinor,
    );
    _afterResolved(result);
  }

  Future<void> skipCurrent() async {
    final current = state.current;
    if (current == null) {
      return;
    }
    emit(state.copyWith(status: GuidedReviewStatus.saving));
    final result = await _skipOccurrence(current.occurrence.id);
    _afterResolved(result);
  }

  Future<void> snoozeCurrent(DateTime newDate) async {
    final current = state.current;
    if (current == null) {
      return;
    }
    emit(state.copyWith(status: GuidedReviewStatus.saving));
    final result = await _snoozeOccurrence(
      scheduledPaymentId: current.scheduledPayment.id,
      occurrenceDate: current.occurrence.occurrenceDate,
      newDate: newDate,
    );
    _afterResolved(result);
  }

  void _afterResolved(Result<Object?> result) {
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(status: GuidedReviewStatus.ready, failure: failure));
      case Right():
        emit(
          state.copyWith(
            index: state.index + 1,
            resolvedCount: state.resolvedCount + 1,
          ),
        );
        _loadCurrent();
    }
  }
}
