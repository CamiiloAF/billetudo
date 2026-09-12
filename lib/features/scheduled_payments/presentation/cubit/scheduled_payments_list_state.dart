import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/scheduled_payment_summary.dart';

/// The three states the "próximos vencimientos" list renders (HU-04). `ready`
/// splits into "with data" and "empty" through [ScheduledPaymentsListState.isEmpty].
enum ScheduledPaymentsListStatus { loading, ready, failure }

/// Which slice of the list the content area shows. Presentation-only: "what
/// counts as finished" is a domain rule (`ScheduledPayment.isActive`); this
/// only says which of the two already-resolved lists is on screen.
enum ScheduledPaymentsFilter { active, finished }

class ScheduledPaymentsListState extends Equatable {
  const ScheduledPaymentsListState({
    this.status = ScheduledPaymentsListStatus.loading,
    this.items = const <ScheduledPaymentSummary>[],
    this.finishedStatus = ScheduledPaymentsListStatus.loading,
    this.finishedItems = const <ScheduledPaymentSummary>[],
    this.filter = ScheduledPaymentsFilter.active,
    this.failure,
  });

  final ScheduledPaymentsListStatus status;

  /// Active templates' upcoming occurrences ordered by date ascending
  /// (2026-09 fix, `GetScheduledPayments`): a template with a DUE occurrence
  /// still carries its `pendingOccurrenceCount` as a single entry (criterion
  /// 11, no separate entry per pending occurrence), but one without a due
  /// occurrence can now appear as *more than one* entry — one per real
  /// projected date inside the forward window — so [items] no longer maps
  /// 1:1 to templates. Use [activeCount] for "how many templates", not
  /// `items.length`.
  final List<ScheduledPaymentSummary> items;

  final ScheduledPaymentsListStatus finishedStatus;

  /// Templates that no longer generate occurrences. Loaded alongside the
  /// active ones instead of on demand, because their count feeds the
  /// "Terminados · N" chip — which is the only way into this filter.
  final List<ScheduledPaymentSummary> finishedItems;

  final ScheduledPaymentsFilter filter;

  final Failure? failure;

  bool get isLoading => status == ScheduledPaymentsListStatus.loading;

  bool get isEmpty =>
      status == ScheduledPaymentsListStatus.ready && items.isEmpty;

  /// "Activos · N": every active template counts once, pending or not
  /// (criterion 11) — counted by distinct `scheduledPayment.id` rather than
  /// `items.length` since a template without a due occurrence can now
  /// contribute more than one row (2026-09 fix, `GetScheduledPayments`).
  int get activeCount =>
      items.map((item) => item.scheduledPayment.id).toSet().length;

  /// "Terminados · N". The chip is not rendered at all when this is 0.
  int get finishedCount => finishedItems.length;

  bool get showsFinished => filter == ScheduledPaymentsFilter.finished;

  ScheduledPaymentsListState copyWith({
    ScheduledPaymentsListStatus? status,
    List<ScheduledPaymentSummary>? items,
    ScheduledPaymentsListStatus? finishedStatus,
    List<ScheduledPaymentSummary>? finishedItems,
    ScheduledPaymentsFilter? filter,
    Failure? failure,
  }) =>
      ScheduledPaymentsListState(
        status: status ?? this.status,
        items: items ?? this.items,
        finishedStatus: finishedStatus ?? this.finishedStatus,
        finishedItems: finishedItems ?? this.finishedItems,
        filter: filter ?? this.filter,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        items,
        finishedStatus,
        finishedItems,
        filter,
        failure,
      ];
}
