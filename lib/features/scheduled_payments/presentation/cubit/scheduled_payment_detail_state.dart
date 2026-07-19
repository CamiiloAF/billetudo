import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../transactions/domain/entities/transaction.dart' as tx;
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
    this.history = const <tx.Transaction>[],
    this.historyExpanded = false,
    this.loadingMoreHistory = false,
    this.deletePrompt = false,
    this.snoozePrompt = false,
    this.pendingUndoSnoozeOccurrenceId,
    this.failure,
  });

  final ScheduledPaymentDetailStatus status;
  final ScheduledPaymentDetail? detail;

  /// The rows currently shown: starts as [ScheduledPaymentDetail.history]
  /// (up to 3, criterion 13) and grows in place as "Ver historial completo"
  /// loads more — never a navigation to another screen.
  final List<tx.Transaction> history;

  final bool historyExpanded;
  final bool loadingMoreHistory;

  final bool deletePrompt;

  /// Whether the Posponer sheet should be showing for the template's next
  /// (not-yet-due) occurrence (HU-07, criterion 10).
  final bool snoozePrompt;

  /// Set right after a successful snooze from this screen, so the page can
  /// offer "Deshacer".
  final String? pendingUndoSnoozeOccurrenceId;

  final Failure? failure;

  int get historyTotalCount => detail?.historyTotalCount ?? 0;

  bool get hasMoreHistory => history.length < historyTotalCount;

  ScheduledPaymentDetailState copyWith({
    ScheduledPaymentDetailStatus? status,
    ScheduledPaymentDetail? detail,
    List<tx.Transaction>? history,
    bool? historyExpanded,
    bool? loadingMoreHistory,
    bool? deletePrompt,
    bool? snoozePrompt,
    String? pendingUndoSnoozeOccurrenceId,
    bool clearPendingUndoSnooze = false,
    Failure? failure,
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
        failure: failure,
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
        failure,
      ];
}
