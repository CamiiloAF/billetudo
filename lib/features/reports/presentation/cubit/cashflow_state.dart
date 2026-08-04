import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/cashflow_series.dart';

enum CashflowStatus { loading, ready, failure }

/// State of the Flujo de caja tab (HU-01). `ready` covers empty/insufficient
/// history/normal — the widgets read those off [series] itself.
class CashflowState extends Equatable {
  const CashflowState({
    this.status = CashflowStatus.loading,
    this.series,
    this.failure,
  });

  final CashflowStatus status;
  final CashflowSeries? series;
  final Failure? failure;

  bool get isLoading => status == CashflowStatus.loading;

  CashflowState copyWith({
    CashflowStatus? status,
    CashflowSeries? series,
    Failure? failure,
  }) =>
      CashflowState(
        status: status ?? this.status,
        series: series ?? this.series,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, series, failure];
}
