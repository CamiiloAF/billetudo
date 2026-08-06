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
///
/// `@lazySingleton` (not `@injectable`/factory) so the period/cuentas
/// filter survives Movimientos' categories drill-down and back — the same
/// reasoning as `TransactionsListCubit`'s own singleton. `AppRoutes.reports`
/// is a stacked `GoRoute`, so its `builder` re-runs on every visit and would
/// otherwise hand out a brand-new `ReportsShellState()` (default period,
/// "todas las cuentas") each time, discarding whatever the user had
/// selected before navigating away. The "Más" hub and Inicio's chip —
/// the entry points that *should* reset to the default period/cuentas — call
/// [resetToDefault] explicitly before navigating instead of relying on a
/// fresh instance.
@lazySingleton
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

  /// Gráficas' cuentas filter (criteria 4-8): [accountIds] is
  /// inclusive-empty — an empty set restores "todas las cuentas".
  void updateAccountFilter(Set<String> accountIds) {
    emit(state.copyWith(accountIds: accountIds));
  }

  /// Restores the default tab/period/toggles/cuentas — called explicitly by
  /// the "Más" hub and Inicio's chip right before pushing `/graficas`, the
  /// two entry points where landing on a stale selection from a previous
  /// visit would be surprising. Movimientos' "volver a Gráficas" flow (and
  /// any other re-entry) never calls this, so the shared filter persists
  /// there by design — see the class doc. `syncState` is left untouched:
  /// it is not a user selection, and [start] will refresh it right after
  /// this call anyway.
  void resetToDefault() {
    emit(ReportsShellState(syncState: state.syncState));
  }

  @override
  Future<void> close() async {
    await _syncSubscription?.cancel();
    return super.close();
  }
}
