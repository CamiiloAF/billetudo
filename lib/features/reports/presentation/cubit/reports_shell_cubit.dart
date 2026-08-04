import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/sync/domain/usecases/watch_sync_status_details.dart';
import '../../domain/entities/chart_view.dart';
import '../models/reports_period_selection.dart';
import 'reports_shell_state.dart';

/// Drives the chrome shared by the 4 tabs (HU-01 to HU-04): which tab is
/// active, the shared date range/toggles, and the sync-notice signal
/// (HU-06). One instance lives for the whole "Gráficas e informes" page —
/// switching tabs never resets it (`design-system/billetudo/pages/
/// graficas.md`, "Rango compartido entre los 4 tabs").
@injectable
class ReportsShellCubit extends Cubit<ReportsShellState> {
  ReportsShellCubit(this._watchSyncStatusDetails)
      : super(ReportsShellState());

  final WatchSyncStatusDetails _watchSyncStatusDetails;

  StreamSubscription<dynamic>? _syncSubscription;

  Future<void> start() async {
    await _syncSubscription?.cancel();
    _syncSubscription = _watchSyncStatusDetails().listen((snapshot) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(syncState: snapshot.state));
    });
  }

  void selectTab(ChartViewId tab) {
    emit(state.copyWith(activeTab: tab));
  }

  void updatePeriod(ReportsPeriodSelection period) {
    emit(state.copyWith(period: period));
  }

  void toggleDebtMovements({required bool value}) {
    emit(state.copyWith(includeDebtMovements: value));
  }

  void toggleArchivedAccounts({required bool value}) {
    emit(state.copyWith(includeArchivedAccounts: value));
  }

  @override
  Future<void> close() async {
    await _syncSubscription?.cancel();
    return super.close();
  }
}
