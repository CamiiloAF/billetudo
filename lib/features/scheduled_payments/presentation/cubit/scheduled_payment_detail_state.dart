import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../../domain/entities/scheduled_history_entry.dart';
import '../../domain/entities/scheduled_payment_detail.dart';

enum ScheduledPaymentDetailStatus {
  loading,
  ready,
  failure,

  /// The template was deleted: the screen has nothing left to show and pops.
  closed,
}

/// State of the hybrid "próximo pago + configuración" detail screen (HU-05).
class ScheduledPaymentDetailState extends Equatable {
  const ScheduledPaymentDetailState({
    this.status = ScheduledPaymentDetailStatus.loading,
    this.detail,
    this.history = const <ScheduledHistoryEntry>[],
    this.historyExpanded = false,
    this.loadingMoreHistory = false,
    this.deletePrompt = false,
    this.snoozePrompt = false,
    this.pendingUndoSnoozeOccurrenceId,
    this.pendingUndoSnoozeWasCreated = false,
    this.pendingUndoSnoozePreviousDate,
    this.pendingUndoRecoverOccurrenceId,
    this.failure,
    this.pendingUndoDeleteTransactionId,
    this.confirmingNow = false,
    this.confirmNowOccurrence,
  });

  final ScheduledPaymentDetailStatus status;
  final ScheduledPaymentDetail? detail;

  /// The rows currently shown: starts as [ScheduledPaymentDetail.history]
  /// (up to 3, criterion 13) and grows in place as "Ver historial completo"
  /// loads more — never a navigation to another screen. Confirmed and skipped
  /// occurrences interleaved (page spec "Historial con omitidos").
  final List<ScheduledHistoryEntry> history;

  final bool historyExpanded;
  final bool loadingMoreHistory;

  final bool deletePrompt;

  /// Whether the Posponer sheet should be showing for the template's next
  /// (not-yet-due) occurrence (HU-07, criterion 10).
  final bool snoozePrompt;

  /// Set right after a successful snooze from this screen, so the page can
  /// offer "Deshacer".
  final String? pendingUndoSnoozeOccurrenceId;

  /// The pre-snooze state carried into [pendingUndoSnoozeOccurrenceId]'s undo,
  /// so "Deshacer" reverses exactly one snooze step (criterion 10): whether
  /// the snooze materialized the row, and the immediately previous snoozed
  /// date when it was a re-snooze. Only meaningful while
  /// [pendingUndoSnoozeOccurrenceId] is non-null.
  final bool pendingUndoSnoozeWasCreated;
  final DateTime? pendingUndoSnoozePreviousDate;

  /// Set right after a skipped occurrence is recovered from the Historial
  /// (page spec "Recuperar", Fase 2), so the page can offer the "Pago
  /// recuperado · Deshacer" snackbar. `null` once dismissed or undone.
  final String? pendingUndoRecoverOccurrenceId;

  final Failure? failure;

  /// The id of a transaction a "Deshacer" snackbar is currently offered for,
  /// after a delete triggered from the transaction detail page opened from
  /// this template's history. `null` once dismissed or undone.
  final String? pendingUndoDeleteTransactionId;

  /// Whether "Confirmar ahora" (HU-05, `docs/bugfixes.md` point 1) is
  /// currently materializing the occurrence — disables the CTA against a
  /// double tap while it runs.
  final bool confirmingNow;

  /// Set right after "Confirmar ahora" successfully materializes a pending
  /// occurrence, so the page can open the mandatory `ConfirmationSheet` for
  /// it. Cleared once the page has consumed it.
  final PendingScheduledOccurrence? confirmNowOccurrence;

  int get historyTotalCount => detail?.historyTotalCount ?? 0;

  bool get hasMoreHistory => history.length < historyTotalCount;

  ScheduledPaymentDetailState copyWith({
    ScheduledPaymentDetailStatus? status,
    ScheduledPaymentDetail? detail,
    List<ScheduledHistoryEntry>? history,
    bool? historyExpanded,
    bool? loadingMoreHistory,
    bool? deletePrompt,
    bool? snoozePrompt,
    String? pendingUndoSnoozeOccurrenceId,
    bool? pendingUndoSnoozeWasCreated,
    DateTime? pendingUndoSnoozePreviousDate,
    bool clearPendingUndoSnooze = false,
    String? pendingUndoRecoverOccurrenceId,
    bool clearPendingUndoRecover = false,
    Failure? failure,
    String? pendingUndoDeleteTransactionId,
    bool clearPendingUndoDeleteTransaction = false,
    bool? confirmingNow,
    PendingScheduledOccurrence? confirmNowOccurrence,
    bool clearConfirmNowOccurrence = false,
  }) =>
      ScheduledPaymentDetailState(
        status: status ?? this.status,
        detail: detail ?? this.detail,
        history: history ?? this.history,
        historyExpanded: historyExpanded ?? this.historyExpanded,
        loadingMoreHistory: loadingMoreHistory ?? this.loadingMoreHistory,
        deletePrompt: deletePrompt ?? this.deletePrompt,
        snoozePrompt: snoozePrompt ?? this.snoozePrompt,
        pendingUndoSnoozeOccurrenceId: clearPendingUndoSnooze
            ? null
            : (pendingUndoSnoozeOccurrenceId ??
                this.pendingUndoSnoozeOccurrenceId),
        pendingUndoSnoozeWasCreated: !clearPendingUndoSnooze &&
            (pendingUndoSnoozeWasCreated ?? this.pendingUndoSnoozeWasCreated),
        pendingUndoSnoozePreviousDate: clearPendingUndoSnooze
            ? null
            : (pendingUndoSnoozePreviousDate ??
                this.pendingUndoSnoozePreviousDate),
        pendingUndoRecoverOccurrenceId: clearPendingUndoRecover
            ? null
            : (pendingUndoRecoverOccurrenceId ??
                this.pendingUndoRecoverOccurrenceId),
        failure: failure,
        pendingUndoDeleteTransactionId: clearPendingUndoDeleteTransaction
            ? null
            : (pendingUndoDeleteTransactionId ??
                this.pendingUndoDeleteTransactionId),
        confirmingNow: confirmingNow ?? this.confirmingNow,
        confirmNowOccurrence: clearConfirmNowOccurrence
            ? null
            : (confirmNowOccurrence ?? this.confirmNowOccurrence),
      );

  @override
  List<Object?> get props => [
        status,
        detail,
        history,
        historyExpanded,
        loadingMoreHistory,
        deletePrompt,
        snoozePrompt,
        pendingUndoSnoozeOccurrenceId,
        pendingUndoSnoozeWasCreated,
        pendingUndoSnoozePreviousDate,
        pendingUndoRecoverOccurrenceId,
        failure,
        pendingUndoDeleteTransactionId,
        confirmingNow,
        confirmNowOccurrence,
      ];
}
