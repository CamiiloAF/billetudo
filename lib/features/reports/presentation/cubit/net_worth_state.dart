import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/net_worth_series.dart';

enum NetWorthStatus { loading, ready, failure }

/// State of the Patrimonio tab (HU-02).
class NetWorthState extends Equatable {
  const NetWorthState({
    this.status = NetWorthStatus.loading,
    this.series,
    this.failure,
  });

  final NetWorthStatus status;
  final NetWorthSeries? series;
  final Failure? failure;

  bool get isLoading => status == NetWorthStatus.loading;

  NetWorthState copyWith({
    NetWorthStatus? status,
    NetWorthSeries? series,
    Failure? failure,
  }) =>
      NetWorthState(
        status: status ?? this.status,
        series: series ?? this.series,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, series, failure];
}
