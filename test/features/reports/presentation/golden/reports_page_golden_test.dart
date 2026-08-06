import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/reports/domain/entities/chart_view.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/presentation/cubit/cashflow_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/cashflow_state.dart';
import 'package:billetudo/features/reports/presentation/cubit/category_breakdown_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/category_breakdown_state.dart';
import 'package:billetudo/features/reports/presentation/cubit/net_worth_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/net_worth_state.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_dashboard_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_dashboard_state.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_shell_cubit.dart';
import 'package:billetudo/features/reports/presentation/cubit/reports_shell_state.dart';
import 'package:billetudo/features/reports/presentation/pages/reports_page.dart';
import 'package:billetudo/features/reports/presentation/widgets/categories/category_view_subcategories_link.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import 'reports_golden_fixtures.dart';

/// Every `load`/`start` override below is a no-op: `*TabView`s call their
/// cubit's loader from `initState` (see e.g. `CashflowTabView`), and a bare
/// `MockCubit` throws `MissingStubError` on any unstubbed method — these
/// overrides let a golden stub only `.state` (like every other cubit golden
/// in this repo, see `account_detail_page_golden_test.dart`) without also
/// having to stub the loader per test case.
class MockReportsShellCubit extends MockCubit<ReportsShellState>
    implements ReportsShellCubit {
  @override
  Future<void> start() async {}
}

class MockCashflowCubit extends MockCubit<CashflowState>
    implements CashflowCubit {
  @override
  Future<void> load({
    required DateRange range,
    required bool includeDebtMovements,
  }) async {}
}

class MockNetWorthCubit extends MockCubit<NetWorthState>
    implements NetWorthCubit {
  @override
  Future<void> load({
    required DateRange range,
    required bool includeArchivedAccounts,
  }) async {}
}

class MockCategoryBreakdownCubit extends MockCubit<CategoryBreakdownState>
    implements CategoryBreakdownCubit {
  @override
  Future<void> load({required DateRange range}) async {}
}

class MockReportsDashboardCubit extends MockCubit<ReportsDashboardState>
    implements ReportsDashboardCubit {
  @override
  Future<void> start() async {}
}

void main() {
  late MockReportsShellCubit shellCubit;
  late MockCashflowCubit cashflowCubit;
  late MockNetWorthCubit netWorthCubit;
  late MockCategoryBreakdownCubit categoryCubit;
  late MockReportsDashboardCubit dashboardCubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    shellCubit = MockReportsShellCubit();
    cashflowCubit = MockCashflowCubit();
    netWorthCubit = MockNetWorthCubit();
    categoryCubit = MockCategoryBreakdownCubit();
    dashboardCubit = MockReportsDashboardCubit();
  });

  /// Fabricates the tap `fl_chart` would report for tapping the donut
  /// section at [index] and invokes the chart's own `touchCallback`
  /// directly — same technique as `category_donut_chart_test.dart`, since
  /// tapping the real rendered geometry of a `PieChart` from a widget test
  /// is brittle.
  void tapDonutSection(WidgetTester tester, int index) {
    final pieChart = tester.widget<PieChart>(find.byType(PieChart));
    final touchCallback = pieChart.data.pieTouchData.touchCallback!;
    touchCallback(
      FlTapUpEvent(TapUpDetails(kind: PointerDeviceKind.touch)),
      PieTouchResponse(
        PieTouchedSection(
          PieChartSectionData(),
          index,
          0,
          0,
        ),
      ),
    );
  }

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    ReportsShellState? shellState,
    CashflowState? cashflowState,
    NetWorthState? netWorthState,
    CategoryBreakdownState? categoryState,
    ReportsDashboardState? dashboardState,
    Future<void> Function(WidgetTester tester)? interact,
  }) async {
    when(
      () => shellCubit.state,
    ).thenReturn(shellState ?? ReportsShellState());
    when(
      () => cashflowCubit.state,
    ).thenReturn(cashflowState ?? const CashflowState());
    when(
      () => netWorthCubit.state,
    ).thenReturn(netWorthState ?? const NetWorthState());
    when(
      () => categoryCubit.state,
    ).thenReturn(categoryState ?? const CategoryBreakdownState());
    when(
      () => dashboardCubit.state,
    ).thenReturn(dashboardState ?? const ReportsDashboardState());

    await pumpGolden(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ReportsShellCubit>.value(value: shellCubit),
          BlocProvider<CashflowCubit>.value(value: cashflowCubit),
          BlocProvider<NetWorthCubit>.value(value: netWorthCubit),
          BlocProvider<CategoryBreakdownCubit>.value(value: categoryCubit),
          BlocProvider<ReportsDashboardCubit>.value(value: dashboardCubit),
        ],
        child: ReportsPage(
          onAddMovement: () {},
          onOpenSyncStatus: () {},
          onOpenBudget: (BudgetWithProgress _) {},
          onCreateBudget: () {},
          onOpenGoal: (GoalWithProgress _) {},
          onCreateGoal: () {},
          onOpenDebts: () {},
        ),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: 1400),
    );
    if (interact != null) {
      await interact(tester);
      await tester.pumpAndSettle();
    }
    await expectLater(
      find.byType(ReportsPage),
      matchesGoldenFile('goldens/reports_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    // --- Resumen (HU-04) ---------------------------------------------

    testWidgets('dashboard: carga ($suffix)', (tester) async {
      await golden(tester, 'dashboard_loading_$suffix', brightness: brightness);
    });

    testWidgets('dashboard: vacío ($suffix)', (tester) async {
      await golden(
        tester,
        'dashboard_empty_$suffix',
        brightness: brightness,
        dashboardState: ReportsDashboardState(
          status: ReportsDashboardStatus.ready,
          dashboard: emptyDashboard(),
        ),
      );
    });

    testWidgets('dashboard: con datos ($suffix)', (tester) async {
      await golden(
        tester,
        'dashboard_with_data_$suffix',
        brightness: brightness,
        dashboardState: ReportsDashboardState(
          status: ReportsDashboardStatus.ready,
          dashboard: dashboardWithData(),
        ),
      );
    });

    // --- Flujo de caja (HU-01) ----------------------------------------

    testWidgets('cashflow: carga ($suffix)', (tester) async {
      await golden(
        tester,
        'cashflow_loading_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(activeTab: ChartViewId.cashflow),
      );
    });

    testWidgets('cashflow: vacío ($suffix)', (tester) async {
      await golden(
        tester,
        'cashflow_empty_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(activeTab: ChartViewId.cashflow),
        cashflowState: CashflowState(
          status: CashflowStatus.ready,
          series: emptyCashflowSeries(),
        ),
      );
    });

    testWidgets('cashflow: con datos, balance positivo ($suffix)', (
      tester,
    ) async {
      await golden(
        tester,
        'cashflow_positive_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(activeTab: ChartViewId.cashflow),
        cashflowState: CashflowState(
          status: CashflowStatus.ready,
          series: positiveCashflowSeries(),
        ),
      );
    });

    testWidgets('cashflow: balance negativo ($suffix)', (tester) async {
      // Criterion 26: neutral (`$text-primary`) figure color, never
      // `$expense`, plus the two-frase explainer + "Ver en qué se fue" link.
      await golden(
        tester,
        'cashflow_negative_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(activeTab: ChartViewId.cashflow),
        cashflowState: CashflowState(
          status: CashflowStatus.ready,
          series: negativeCashflowSeries(),
        ),
      );
    });

    testWidgets('cashflow: historial insuficiente ($suffix)', (tester) async {
      await golden(
        tester,
        'cashflow_short_history_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(activeTab: ChartViewId.cashflow),
        cashflowState: CashflowState(
          status: CashflowStatus.ready,
          series: shortHistoryCashflowSeries(),
        ),
      );
    });

    testWidgets('cashflow: fallo de sync ($suffix)', (tester) async {
      // HU-06 "fallo de sync": discreet, non-blocking strip — the chart
      // underneath still renders every real data point.
      await golden(
        tester,
        'cashflow_sync_notice_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(
          activeTab: ChartViewId.cashflow,
          syncState: SyncState.stalled,
        ),
        cashflowState: CashflowState(
          status: CashflowStatus.ready,
          series: positiveCashflowSeries(),
        ),
      );
    });

    // --- Patrimonio (HU-02) --------------------------------------------

    testWidgets('net worth: carga ($suffix)', (tester) async {
      await golden(
        tester,
        'net_worth_loading_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(activeTab: ChartViewId.netWorth),
      );
    });

    testWidgets('net worth: vacío ($suffix)', (tester) async {
      await golden(
        tester,
        'net_worth_empty_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(activeTab: ChartViewId.netWorth),
        netWorthState: NetWorthState(
          status: NetWorthStatus.ready,
          series: emptyNetWorthSeries(),
        ),
      );
    });

    testWidgets('net worth: con datos ($suffix)', (tester) async {
      await golden(
        tester,
        'net_worth_with_data_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(activeTab: ChartViewId.netWorth),
        netWorthState: NetWorthState(
          status: NetWorthStatus.ready,
          series: netWorthSeriesWithData(),
        ),
      );
    });

    testWidgets('net worth: historial insuficiente ($suffix)', (
      tester,
    ) async {
      await golden(
        tester,
        'net_worth_short_history_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(activeTab: ChartViewId.netWorth),
        netWorthState: NetWorthState(
          status: NetWorthStatus.ready,
          series: shortHistoryNetWorthSeries(),
        ),
      );
    });

    // --- Categorías (HU-03) ---------------------------------------------

    testWidgets('categories: carga ($suffix)', (tester) async {
      await golden(
        tester,
        'categories_loading_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(
          activeTab: ChartViewId.categoryBreakdown,
        ),
      );
    });

    testWidgets('categories: vacío ($suffix)', (tester) async {
      await golden(
        tester,
        'categories_empty_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(
          activeTab: ChartViewId.categoryBreakdown,
        ),
        categoryState: CategoryBreakdownState(
          status: CategoryBreakdownStatus.ready,
          breakdown: emptyCategoryBreakdown(),
        ),
      );
    });

    testWidgets('categories: con datos ($suffix)', (tester) async {
      // Flat desglose (`A3zxf`): top-level rows only, no accordion — see
      // `CategoryBreakdownRow`/`CategoryViewSubcategoriesLink`.
      await golden(
        tester,
        'categories_with_data_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(
          activeTab: ChartViewId.categoryBreakdown,
        ),
        categoryState: CategoryBreakdownState(
          status: CategoryBreakdownStatus.ready,
          breakdown: categoryBreakdownWithData(),
        ),
      );
    });

    testWidgets('categories: sección seleccionada ($suffix)', (tester) async {
      // A root arc (Mercado, the top spender, has subcategories) tapped and
      // held selected: the donut's centre shows its name + amount, and the
      // drill-down pill becomes enabled ("Ver subcategorías").
      await golden(
        tester,
        'categories_selected_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(
          activeTab: ChartViewId.categoryBreakdown,
        ),
        categoryState: CategoryBreakdownState(
          status: CategoryBreakdownStatus.ready,
          breakdown: categoryBreakdownWithData(),
        ),
        interact: (tester) async {
          tapDonutSection(tester, 0);
        },
      );
    });

    testWidgets('categories: nivel de subcategorías ($suffix)', (
      tester,
    ) async {
      // After drilling into Mercado: the donut now shows its subcategories
      // and the pill reads "Atrás" instead of "Ver subcategorías".
      await golden(
        tester,
        'categories_subcategories_$suffix',
        brightness: brightness,
        shellState: ReportsShellState(
          activeTab: ChartViewId.categoryBreakdown,
        ),
        categoryState: CategoryBreakdownState(
          status: CategoryBreakdownStatus.ready,
          breakdown: categoryBreakdownWithData(),
        ),
        interact: (tester) async {
          tapDonutSection(tester, 0);
          await tester.pump();
          await tester
              .tap(find.byType(CategoryViewSubcategoriesLink));
        },
      );
    });
  }
}
