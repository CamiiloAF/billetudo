import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/scheduled_payment_summary.dart';

enum FinishedScheduledPaymentsStatus { loading, ready, failure }

/// State of the "Terminados" history (HU-04 overflow).
class FinishedScheduledPaymentsState extends Equatable {
  const FinishedScheduledPaymentsState({
    this.status = FinishedScheduledPaymentsStatus.loading,
    this.items = const <ScheduledPaymentSummary>[],
    this.failure,
  });

  final FinishedScheduledPaymentsStatus status;
  final List<ScheduledPaymentSummary> items;
  final Failure? failure;

  bool get isLoading => status == FinishedScheduledPaymentsStatus.loading;

  bool get isEmpty =>
      status == FinishedScheduledPaymentsStatus.ready && items.isEmpty;

  FinishedScheduledPaymentsState copyWith({
    FinishedScheduledPaymentsStatus? status,
    List<ScheduledPaymentSummary>? items,
    Failure? failure,
  }) =>
      FinishedScheduledPaymentsState(
        status: status ?? this.status,
        items: items ?? this.items,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, items, failure];
}
