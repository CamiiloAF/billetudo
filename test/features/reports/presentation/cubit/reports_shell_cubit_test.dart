import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_sync_status_details.dart';
import 'package:billetudo/features/reports/domain/entities/chart_view.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_shell_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_shell_state.dart';
import 'package:billetudo/features/reports/presentation/models/reports_period_selection.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    'updateAccountFilter replaces the shared cuentas filter',
    build: () => ReportsShellCubit(watchSyncStatusDetails),
    act: (cubit) => cubit.updateAccountFilter({'acc-1', 'acc-2'}),
    verify: (cubit) {
      expect(cubit.state.accountIds, {'acc-1', 'acc-2'});
    },
  );

  blocTest<ReportsShellCubit, ReportsShellState>(
    'updateAccountFilter back to empty restores "todas las cuentas"',
    build: () => ReportsShellCubit(watchSyncStatusDetails),
    act: (cubit) {
      cubit.updateAccountFilter({'acc-1'});
      cubit.updateAccountFilter(const <String>{});
    },
    verify: (cubit) {
      expect(cubit.state.accountIds, isEmpty);
    },
  );

  blocTest<ReportsShellCubit, ReportsShellState>(
    // Bug 3: "Más" hub / Inicio's chip call this explicitly right before
    // pushing `/graficas` so a stale selection from a previous visit never
    // shows up on that fresh entry — see the class doc for why the cubit
    // itself no longer resets on every navigation now that it is a
    // `@lazySingleton`.
    'resetToDefault restores tab/period/toggles/cuentas but keeps syncState',
    build: () => ReportsShellCubit(watchSyncStatusDetails),
    act: (cubit) {
      cubit.selectTab(ChartViewId.cashflow);
      cubit.updatePeriod(ReportsPeriodSelection.year(2025));
      cubit.toggleDebtMovements(value: false);
      cubit.toggleArchivedAccounts(value: true);
      cubit.updateAccountFilter({'acc-1'});
      cubit.resetToDefault();
    },
    verify: (cubit) {
      expect(cubit.state.activeTab, ChartViewId.dashboard);
      expect(cubit.state.period.kind, ReportsPeriodKind.lastSixMonths);
      expect(cubit.state.includeDebtMovements, isTrue);
      expect(cubit.state.includeArchivedAccounts, isFalse);
      expect(cubit.state.accountIds, isEmpty);
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

  group('lifecycle vs. the widget that provides it', () {
    // Regression for Sentry BILLETUDO-B: `ReportsShellCubit` is
    // `@lazySingleton` so it survives navigating away from and back to
    // Gráficas (the shared period/cuentas selection). It must be provided
    // with `BlocProvider.value` in `app_router.dart`, never plain
    // `BlocProvider(create: ...)` — the latter calls `.close()` on the
    // cubit automatically when its widget is disposed, which would leave
    // `GetIt` handing out an already-closed instance on the next visit and
    // crash the following `emit` (`selectTab`, restoring the active tab)
    // with `StateError: Cannot emit new states after calling close`.
    testWidgets(
      'survives its providing widget being disposed, like leaving and '
      'returning to Gráficas',
      (tester) async {
        final cubit = ReportsShellCubit(watchSyncStatusDetails);

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<ReportsShellCubit>.value(
              value: cubit,
              child: const SizedBox.shrink(),
            ),
          ),
        );

        // Simulates leaving Gráficas: the subtree that provided the cubit
        // is torn down, as it would be when go_router pops/replaces the
        // route.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

        expect(cubit.isClosed, isFalse);

        // The next visit to Gráficas restores the active tab through
        // `selectTab` — this must not throw.
        expect(() => cubit.selectTab(ChartViewId.cashflow), returnsNormally);
        expect(cubit.state.activeTab, ChartViewId.cashflow);

        await cubit.close();
      },
    );
  });
}
