import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_sync_status_details.dart';
import 'package:billetudo/features/reports/domain/entities/chart_view.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_shell_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_shell_state.dart';
import 'package:billetudo/features/reports/presentation/models/reports_period_selection.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchSyncStatusDetails extends Mock implements WatchSyncStatusDetails {}

void main() {
  late MockWatchSyncStatusDetails watchSyncStatusDetails;

  setUp(() {
    watchSyncStatusDetails = MockWatchSyncStatusDetails();
  });

  test('defaults to the dashboard tab and the last-6-months period', () {
    final cubit = ReportsShellCubit(watchSyncStatusDetails);
    expect(cubit.state.activeTab, ChartViewId.dashboard);
    expect(cubit.state.period.kind, ReportsPeriodKind.lastSixMonths);
    expect(cubit.state.includeDebtMovements, isTrue);
    expect(cubit.state.includeArchivedAccounts, isFalse);
  });

  blocTest<ReportsShellCubit, ReportsShellState>(
    'selectTab updates only the active tab, the period survives',
    build: () => ReportsShellCubit(watchSyncStatusDetails),
    act: (cubit) => cubit.selectTab(ChartViewId.cashflow),
    verify: (cubit) {
      expect(cubit.state.activeTab, ChartViewId.cashflow);
      expect(cubit.state.period.kind, ReportsPeriodKind.lastSixMonths);
    },
  );

  blocTest<ReportsShellCubit, ReportsShellState>(
    'updatePeriod replaces the shared period',
    build: () => ReportsShellCubit(watchSyncStatusDetails),
    act: (cubit) => cubit.updatePeriod(ReportsPeriodSelection.year(2025)),
    verify: (cubit) {
      expect(cubit.state.period.kind, ReportsPeriodKind.year);
    },
  );

  blocTest<ReportsShellCubit, ReportsShellState>(
    'start reflects a stalled sync snapshot as a sync notice',
    build: () {
      when(() => watchSyncStatusDetails()).thenAnswer(
        (_) => Stream.value(
          const SyncStatusSnapshot(state: SyncState.stalled, quarantinedCount: 2),
        ),
      );
      return ReportsShellCubit(watchSyncStatusDetails);
    },
    act: (cubit) => cubit.start(),
    verify: (cubit) {
      expect(cubit.state.hasSyncNotice, isTrue);
    },
  );
}
