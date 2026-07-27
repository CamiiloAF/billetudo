import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';

enum PendingOccurrencesStatus { loading, ready, failure }

/// What the last resolved occurrence was, so the page can offer "Deshacer"
/// (criterion 9/10). `null` once dismissed or undone.
class PendingOccurrenceUndo extends Equatable {
  const PendingOccurrenceUndo({
    required this.occurrenceId,
    required this.isSnooze,
    this.previousSnoozedToDate,
  });

  final String occurrenceId;

  /// True for a snooze, false for a skip — the two share the affordance but
  /// call different undo use cases.
  final bool isSnooze;

  /// For a snooze of an already-materialized (vencida) occurrence: the snoozed
  /// date the row held before this snooze (null when it was still `pending`),
  /// so undo steps back exactly one date instead of jumping to the original.
  final DateTime? previousSnoozedToDate;

  @override
  List<Object?> get props => [occurrenceId, isSnooze, previousSnoozedToDate];
}

/// State of "Por confirmar" (HU-03/HU-04 overflow subpantalla): every pending
/// occurrence across every manual-mode template, ordered by effective due
/// date ascending.
class PendingOccurrencesState extends Equatable {
  const PendingOccurrencesState({
    this.status = PendingOccurrencesStatus.loading,
    this.items = const <PendingScheduledOccurrence>[],
    this.pendingUndo,
    this.failure,
  });

  final PendingOccurrencesStatus status;
  final List<PendingScheduledOccurrence> items;
  final PendingOccurrenceUndo? pendingUndo;
  final Failure? failure;

  bool get isLoading => status == PendingOccurrencesStatus.loading;

  bool get isEmpty => status == PendingOccurrencesStatus.ready && items.isEmpty;

  PendingOccurrencesState copyWith({
    PendingOccurrencesStatus? status,
    List<PendingScheduledOccurrence>? items,
    PendingOccurrenceUndo? pendingUndo,
    bool clearPendingUndo = false,
    Failure? failure,
  }) =>
      PendingOccurrencesState(
        status: status ?? this.status,
        items: items ?? this.items,
        pendingUndo:
            clearPendingUndo ? null : (pendingUndo ?? this.pendingUndo),
        failure: failure,
      );

  @override
  List<Object?> get props => [status, items, pendingUndo, failure];
}
