import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/reports_dashboard.dart';

enum ReportsDashboardStatus { loading, ready, failure }

/// State of the Resumen tab (HU-04).
class ReportsDashboardState extends Equatable {
  const ReportsDashboardState({
    this.status = ReportsDashboardStatus.loading,
    this.dashboard,
    this.failure,
  });

  final ReportsDashboardStatus status;
  final ReportsDashboard? dashboard;
  final Failure? failure;

  bool get isLoading => status == ReportsDashboardStatus.loading;

  ReportsDashboardState copyWith({
    ReportsDashboardStatus? status,
    ReportsDashboard? dashboard,
    Failure? failure,
  }) =>
      ReportsDashboardState(
        status: status ?? this.status,
        dashboard: dashboard ?? this.dashboard,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, dashboard, failure];
}
