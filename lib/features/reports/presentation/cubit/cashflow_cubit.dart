import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/date_range.dart';
import '../../domain/usecases/watch_cashflow_report.dart';
import 'cashflow_state.dart';

/// Drives the Flujo de caja tab (HU-01). Talks only to
/// [WatchCashflowReport] — the shared period/toggle it queries with comes
/// from `ReportsShellCubit`, one level up.
@injectable
class CashflowCubit extends Cubit<CashflowState> {
  CashflowCubit(this._watchCashflowReport) : super(const CashflowState());

  final WatchCashflowReport _watchCashflowReport;

  StreamSubscription<dynamic>? _subscription;

  Future<void> load({
    required DateRange range,
    required bool includeDebtMovements,
  }) async {
    await _subscription?.cancel();
    emit(const CashflowState());
    _subscription = _watchCashflowReport(
      WatchCashflowReportParams(
        range: range,
        includeDebtMovements: includeDebtMovements,
      ),
    ).listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) =>
              state.copyWith(status: CashflowStatus.failure, failure: failure),
          (series) =>
              state.copyWith(status: CashflowStatus.ready, series: series),
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
