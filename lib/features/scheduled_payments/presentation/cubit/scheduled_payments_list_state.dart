import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/scheduled_payment_summary.dart';

/// The three states the "próximos vencimientos" list renders (HU-04). `ready`
/// splits into "with data" and "empty" through [ScheduledPaymentsListState.isEmpty].
enum ScheduledPaymentsListStatus { loading, ready, failure }

class ScheduledPaymentsListState extends Equatable {
  const ScheduledPaymentsListState({
    this.status = ScheduledPaymentsListStatus.loading,
    this.items = const <ScheduledPaymentSummary>[],
    this.finishedCount = 0,
    this.failure,
  });

  final ScheduledPaymentsListStatus status;

  /// Active templates ordered by `nextDate` ascending, already carrying each
  /// template's `pendingOccurrenceCount` (criterion 11) — no separate entry
  /// per pending occurrence.
  final List<ScheduledPaymentSummary> items;

  /// "Terminados · N": templates that no longer generate occurrences, feeds
  /// the neutral pill next to "Activos · N".
  final int finishedCount;

  final Failure? failure;

  bool get isLoading => status == ScheduledPaymentsListStatus.loading;

  bool get isEmpty => status == ScheduledPaymentsListStatus.ready && items.isEmpty;

  /// "Activos · N": every active template counts once, pending or not
  /// (criterion 11).
  int get activeCount => items.length;

  ScheduledPaymentsListState copyWith({
    ScheduledPaymentsListStatus? status,
    List<ScheduledPaymentSummary>? items,
    int? finishedCount,
    Failure? failure,
  }) =>
      ScheduledPaymentsListState(
        status: status ?? this.status,
        items: items ?? this.items,
        finishedCount: finishedCount ?? this.finishedCount,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, items, finishedCount, failure];
}
