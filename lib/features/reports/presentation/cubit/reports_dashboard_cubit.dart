import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/watch_reports_dashboard.dart';
import 'reports_dashboard_state.dart';

/// Drives the Resumen tab (HU-04). No period parameter — it has none (D2).
@injectable
class ReportsDashboardCubit extends Cubit<ReportsDashboardState> {
  ReportsDashboardCubit(this._watchReportsDashboard)
      : super(const ReportsDashboardState());

  final WatchReportsDashboard _watchReportsDashboard;

  StreamSubscription<dynamic>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    emit(const ReportsDashboardState());
    _subscription = _watchReportsDashboard().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: ReportsDashboardStatus.failure,
            failure: failure,
          ),
          (dashboard) => state.copyWith(
            status: ReportsDashboardStatus.ready,
            dashboard: dashboard,
          ),
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
