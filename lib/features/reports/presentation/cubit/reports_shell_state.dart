import 'package:equatable/equatable.dart';

import '../../../../core/sync/domain/entities/sync_state.dart';
import '../../domain/entities/chart_view.dart';
import '../models/reports_period_selection.dart';

/// Shell state of Gráficas e informes (HU-01 to HU-06): the active tab and
/// the period/toggles shared by the three tabs that use them. `Resumen`
/// (HU-04) reads only [activeTab] — it has no Period Row (D2,
/// `design-system/billetudo/pages/graficas.md`).
class ReportsShellState extends Equatable {
  ReportsShellState({
    this.activeTab = ChartViewId.dashboard,
    ReportsPeriodSelection? period,
    this.includeDebtMovements = true,
    this.includeArchivedAccounts = false,
    this.syncState = SyncState.offline,
  }) : period = period ?? ReportsPeriodSelection.lastSixMonths();

  final ChartViewId activeTab;
  final ReportsPeriodSelection period;

  /// HU-01 "Separar movimientos de deuda" toggle. Default `true` = integrated.
  final bool includeDebtMovements;

  /// HU-02 "Incluir cuentas archivadas" toggle. Default `false` = excluded.
  final bool includeArchivedAccounts;

  /// Drives the "fallo de sync" tira (HU-06): shown when this is
  /// [SyncState.stalled] — same domain signal as Home's `Sync Indicator`
  /// (`saRZW`), presented differently on purpose (see `graficas.md`).
  final SyncState syncState;

  bool get hasSyncNotice => syncState == SyncState.stalled;

  ReportsShellState copyWith({
    ChartViewId? activeTab,
    ReportsPeriodSelection? period,
    bool? includeDebtMovements,
    bool? includeArchivedAccounts,
    SyncState? syncState,
  }) =>
      ReportsShellState(
        activeTab: activeTab ?? this.activeTab,
        period: period ?? this.period,
        includeDebtMovements: includeDebtMovements ?? this.includeDebtMovements,
        includeArchivedAccounts:
            includeArchivedAccounts ?? this.includeArchivedAccounts,
        syncState: syncState ?? this.syncState,
      );

  @override
  List<Object?> get props => [
        activeTab,
        period,
        includeDebtMovements,
        includeArchivedAccounts,
        syncState,
      ];
}
