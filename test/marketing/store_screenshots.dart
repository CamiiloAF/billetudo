import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_state.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budgets_list_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budgets_list_state.dart';
import 'package:billetudo/features/budgets/presentation/cubit/zero_based_summary_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/zero_based_summary_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budgets_page.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_cubit.dart';
import 'package:billetudo/features/categories/presentation/cubit/categories_list_state.dart';
import 'package:billetudo/features/debts/presentation/cubit/debts_list_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debts_list_state.dart';
import 'package:billetudo/features/debts/presentation/pages/debts_list_page.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/presentation/cubit/goals_list_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goals_list_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goals_list_page.dart';
import 'package:billetudo/features/home/domain/entities/home_snapshot.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_export_hub_cubit.dart';
import 'package:billetudo/features/import_export/presentation/cubit/import_export_hub_state.dart';
import 'package:billetudo/features/import_export/presentation/pages/import_export_hub_page.dart';
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
import 'package:billetudo/features/reports/presentation/models/reports_period_selection.dart';
import 'package:billetudo/features/reports/presentation/pages/reports_page.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/pending_occurrences_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payments_list_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payments_list_state.dart';
import 'package:billetudo/features/scheduled_payments/presentation/pages/scheduled_payments_page.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:billetudo/features/transactions/presentation/cubit/tag_filter_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fake_note_suggestions.dart';
import 'marketing_capture.dart';
import 'showcase_dataset.dart';

/// **Store-listing screenshot generator** — F1 of
/// `docs/marketing/plan-fichas-de-tienda.md`.
///
/// Run it with:
///
/// ```bash
/// flutter test test/marketing/store_screenshots.dart
/// ```
///
/// Pass **the file**, not the directory: `flutter test test/marketing` finds no
/// `*_test.dart` inside it and silently falls back to running the entire suite
/// (~4000 tests, ~5 min) without generating a single screenshot.
///
/// It writes nine PNGs of exactly 1170 x 2532 px to
/// `docs/marketing/store-listing/raw/`, numbered after the guion of §4/§4.1:
///
/// | # | Archivo | Pantalla | Tab bar |
/// |---|---|---|---|
/// | 1 | `01-inicio.png` | Inicio con datos (claro) | Sí — Inicio |
/// | 2 | `02-registrar-gasto.png` | Formulario con teclado numérico abierto | No |
/// | 3 | `03-graficas.png` | Gráficas → Categorías (dona + desglose) | No |
/// | 4 | `04-presupuestos.png` | Presupuestos en modo sobres | Sí — Presupuestos |
/// | 5 | `05-metas.png` | Metas con racha activa | Sí — Metas |
/// | 6 | `06-deudas.png` | Deudas (yo debo / me deben) | No |
/// | 7 | `07-pagos-programados.png` | Pagos programados con pendientes | No |
/// | 8 | `08-inicio-oscuro.png` | Inicio con datos (**oscuro**) | Sí — Inicio |
/// | 9 | `09-importar-exportar.png` | Importar y exportar | No |
///
/// The "Tab bar" column is not a stylistic choice: it mirrors, screen by
/// screen, what `lib/core/router/app_router.dart` actually renders. A route
/// that is a `StatefulShellBranch`'s first-level route (no
/// `parentNavigatorKey`) is drawn inside `HomeShellPage` and keeps the bar;
/// anything declared with `parentNavigatorKey: _rootNavigatorKey` — every
/// `nuevo`/`:id` subroute plus the top-level siblings of the shell (Gráficas,
/// Deudas, Pagos Programados, Import/Export) — is stacked over the shell and
/// shows a `Page Header` with a back button instead. See
/// [MarketingTabBranch].
///
/// Every screen renders the real page widget with a mocked cubit — the same
/// technique the golden suite uses — fed by the single showcase dataset in
/// `showcase_dataset.dart`, so the nine images stay coherent with each other.
///
/// This file is intentionally **not** named `*_test.dart`: `flutter test` on
/// the whole suite must never rewrite marketing assets as a side effect, and
/// nothing here is an assertion about the app's behaviour. Fidelity of these
/// screens against Pencil is the golden suite's and
/// `pencil-fidelity-reviewer`'s job, not this file's.

class _MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class _MockTransactionFormCubit extends MockCubit<TransactionFormState>
    implements TransactionFormCubit {}

class _MockAccountsListCubit extends MockCubit<AccountsListState>
    implements AccountsListCubit {}

class _MockCategoriesListCubit extends MockCubit<CategoriesListState>
    implements CategoriesListCubit {}

class _MockCategoryQuickPickerCubit extends MockCubit<CategoryQuickPickerState>
    implements CategoryQuickPickerCubit {}

class _MockTagFilterCubit extends MockCubit<TagFilterState>
    implements TagFilterCubit {}

// The reports tab views call their cubit's loader from `initState`, and a bare
// `MockCubit` throws on any unstubbed method — same no-op overrides the
// reports golden suite uses.
class _MockReportsShellCubit extends MockCubit<ReportsShellState>
    implements ReportsShellCubit {
  @override
  Future<void> start() async {}
}

class _MockCashflowCubit extends MockCubit<CashflowState>
    implements CashflowCubit {
  @override
  Future<void> load({
    required DateRange range,
    required bool includeDebtMovements,
    Set<String> accountIds = const <String>{},
  }) async {}
}

class _MockNetWorthCubit extends MockCubit<NetWorthState>
    implements NetWorthCubit {
  @override
  Future<void> load({
    required DateRange range,
    required bool includeArchivedAccounts,
    Set<String> accountIds = const <String>{},
  }) async {}
}

class _MockCategoryBreakdownCubit extends MockCubit<CategoryBreakdownState>
    implements CategoryBreakdownCubit {
  @override
  Future<void> load({
    required DateRange range,
    Set<String> accountIds = const <String>{},
  }) async {}
}

class _MockReportsDashboardCubit extends MockCubit<ReportsDashboardState>
    implements ReportsDashboardCubit {
  @override
  Future<void> start() async {}
}

class _MockBudgetsListCubit extends MockCubit<BudgetsListState>
    implements BudgetsListCubit {}

class _MockZeroBasedSummaryCubit extends MockCubit<ZeroBasedSummaryState>
    implements ZeroBasedSummaryCubit {}

class _MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

class _MockGoalsListCubit extends MockCubit<GoalsListState>
    implements GoalsListCubit {}

class _MockDebtsListCubit extends MockCubit<DebtsListState>
    implements DebtsListCubit {}

class _MockScheduledPaymentsListCubit
    extends MockCubit<ScheduledPaymentsListState>
    implements ScheduledPaymentsListCubit {}

class _MockPendingOccurrencesCubit extends MockCubit<PendingOccurrencesState>
    implements PendingOccurrencesCubit {}

class _MockImportExportHubCubit extends MockCubit<ImportExportHubState>
    implements ImportExportHubCubit {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await setUpMarketingCapture();
    registerFallbackValue(CategoryKind.expense);
  });

  // --- 1 y 8: Inicio (claro y oscuro) --------------------------------------

  // Each capture is produced once per store: the two listings must not
  // show each other's system chrome.
  for (final platform in MarketingPlatform.values) {
    group(platform.name, () {
      Future<void> captureHome(
        WidgetTester tester, {
        required Brightness brightness,
        required String fileName,
      }) async {
        final cubit = _MockHomeCubit();
        final state = HomeState(
          status: HomeStatus.ready,
          snapshot: HomeSnapshot.from(
            month: showcaseMonth,
            accounts: showcaseAccounts,
            transactions: showcaseMonthMovements,
            budgetProgress: monthlyBudget,
          ),
        );
        when(() => cubit.state).thenReturn(state);
        whenListen(cubit, const Stream<HomeState>.empty(), initialState: state);

        // `HomePage` reads `AppSettingsCubit` for the Acceso rapido order.
        final settingsCubit = _MockAppSettingsCubit();
        const settingsState = AppSettingsState(
          settings: AppSettings(
            zeroBasedEnabled: false,
            categoriesSeeded: true,
            onboardingCompleted: true,
          ),
        );
        when(() => settingsCubit.state).thenReturn(settingsState);
        whenListen(
          settingsCubit,
          const Stream<AppSettingsState>.empty(),
          initialState: settingsState,
        );

        await pumpMarketing(
          tester,
          MultiBlocProvider(
            providers: [
              BlocProvider<HomeCubit>.value(value: cubit),
              BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
            ],
            child: HomePage(
              onAddTransaction: () {},
              onSeeAllTransactions: () {},
              onOpenTransaction: (_) async => null,
              onCreateBudget: () {},
              onOpenBudget: (_) {},
              onOpenAccounts: () {},
              onOpenAccountMovements: (_) {},
              onOpenScheduledPayments: () {},
              onOpenDebts: () {},
              onOpenReports: () {},
              onOpenLogin: () {},
              onOpenSyncStatus: () {},
            ),
          ),
          brightness: brightness,
          platform: platform,
          // `AppRoutes.home` is `_inicioBranch`'s first-level route with no
          // `parentNavigatorKey`, so the real app renders it inside the shell
          // with the tab bar and Inicio active.
          tabBranch: MarketingTabBranch.inicio,
        );
        await captureMarketing(tester, fileName);
      }

      testWidgets('01 · Inicio con datos (claro)', (tester) async {
        await captureHome(
          tester,
          brightness: Brightness.light,
          fileName: '01-inicio-v2.png',
        );
      });

      testWidgets('08 · Inicio con datos (oscuro)', (tester) async {
        await captureHome(
          tester,
          brightness: Brightness.dark,
          fileName: '08-inicio-oscuro-v2.png',
        );
      });

      // --- 2: Registrar un gasto, teclado abierto ------------------------------

      testWidgets('02 · Registrar un gasto, teclado numérico abierto',
          (tester) async {
        final cubit = _MockTransactionFormCubit();
        when(() => cubit.state).thenReturn(
          TransactionFormState(
            status: TransactionFormStatus.ready,
            accountId: cashAccountId,
            accountName: cashAccountName,
            categoryId: groceriesCategory.id,
            categoryName: groceriesCategory.name,
            categoryKind: CategoryKind.expense,
            amountMinor: 4590000, // $45.900
            date: showcaseToday,
            focusedField: TransactionFormFocusedField.amount,
          ),
        );

        // The account/category pickers and the Etiquetas field resolve their own
        // cubits through `getIt`, so the form only builds with these registered —
        // same DI setup as `transaction_form_page_golden_test.dart`.
        final accountsListCubit = _MockAccountsListCubit();
        when(accountsListCubit.start).thenAnswer((_) async {});
        when(() => accountsListCubit.state).thenReturn(
          AccountsListState(
            status: AccountsListStatus.ready,
            accounts: showcaseAccounts,
          ),
        );

        final categoriesListCubit = _MockCategoriesListCubit();
        when(() => categoriesListCubit.start(kind: any(named: 'kind')))
            .thenAnswer((_) async {});
        when(() => categoriesListCubit.state).thenReturn(
          CategoriesListState(
            status: CategoriesListStatus.ready,
            nodes: [
              for (final category in showcaseExpenseCategories)
                CategoryNode(root: showcaseCategoryEntity(category)),
            ],
          ),
        );

        final quickPickerCubit = _MockCategoryQuickPickerCubit();
        when(
          () => quickPickerCubit.start(
            kind: any(named: 'kind'),
            selectedId: any(named: 'selectedId'),
            accountId: any(named: 'accountId'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => quickPickerCubit.setKind(any(),
              selectedId: any(named: 'selectedId')),
        ).thenAnswer((_) async {});
        when(() => quickPickerCubit.syncSelection(any()))
            .thenAnswer((_) async {});
        when(() => quickPickerCubit.setAccount(any())).thenAnswer((_) async {});
        // Without a populated quick picker the Categoría row renders as a lone
        // "Ver más" chip — correct for a golden of the empty state, but it reads
        // as a broken screen in a store listing.
        when(() => quickPickerCubit.state).thenReturn(
          CategoryQuickPickerState(
            status: CategoryQuickPickerStatus.ready,
            mostUsed: [
              for (final category in showcaseExpenseCategories.take(3))
                showcaseCategoryEntity(category),
            ],
            selected: showcaseCategoryEntity(groceriesCategory),
          ),
        );

        final tagFilterCubit = _MockTagFilterCubit();
        when(() => tagFilterCubit.start(any())).thenAnswer((_) async {});
        when(() => tagFilterCubit.state).thenReturn(TagFilterState());

        getIt
          ..registerFactory<AccountsListCubit>(() => accountsListCubit)
          ..registerFactory<CategoriesListCubit>(() => categoriesListCubit)
          ..registerFactory<CategoryQuickPickerCubit>(() => quickPickerCubit)
          ..registerFactory<TagFilterCubit>(() => tagFilterCubit);
        registerFakeNoteSuggestions();
        addTearDown(getIt.reset);

        await pumpMarketing(
          tester,
          BlocProvider<TransactionFormCubit>.value(
            value: cubit,
            child: const TransactionFormPage(),
          ),
          brightness: Brightness.light,
          platform: platform,
          // No `tabBranch`: `movimientos/nuevo` declares
          // `parentNavigatorKey: _rootNavigatorKey`, so it is pushed on the root
          // navigator and covers the shell — no tab bar in the real app.
        );
        await captureMarketing(
          tester,
          '02-registrar-gasto-v2.png',
        );
      });

      // --- 3: Gráficas → Categorías -------------------------------------------

      testWidgets('03 · Gráficas, desglose por categoría', (tester) async {
        final shellCubit = _MockReportsShellCubit();
        when(() => shellCubit.state).thenReturn(
          ReportsShellState(
            activeTab: ChartViewId.categoryBreakdown,
            period: ReportsPeriodSelection.month(showcaseMonth),
          ),
        );

        final cashflowCubit = _MockCashflowCubit();
        when(() => cashflowCubit.state).thenReturn(const CashflowState());

        final netWorthCubit = _MockNetWorthCubit();
        when(() => netWorthCubit.state).thenReturn(const NetWorthState());

        final categoryCubit = _MockCategoryBreakdownCubit();
        when(() => categoryCubit.state).thenReturn(
          CategoryBreakdownState(
            status: CategoryBreakdownStatus.ready,
            breakdown: showcaseCategoryBreakdown,
          ),
        );

        final dashboardCubit = _MockReportsDashboardCubit();
        when(() => dashboardCubit.state)
            .thenReturn(const ReportsDashboardState());

        await pumpMarketing(
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
          brightness: Brightness.light,
          platform: platform,
          // No `tabBranch`: `_reportsRoute()` is a top-level sibling of the shell
          // route with `parentNavigatorKey: _rootNavigatorKey` — a stacked screen
          // with its own `Page Header` and its own 4-tab shell, no bottom bar.
        );
        await captureMarketing(
          tester,
          '03-graficas-v2.png',
        );
      });

      // --- 4: Presupuestos, modo sobres ---------------------------------------

      testWidgets('04 · Presupuestos en modo sobres', (tester) async {
        final listCubit = _MockBudgetsListCubit();
        when(() => listCubit.state).thenReturn(
          BudgetsListState(
            status: BudgetsListStatus.ready,
            budgets: showcaseBudgets,
          ),
        );

        final envelopeCubit = _MockZeroBasedSummaryCubit();
        when(() => envelopeCubit.state).thenReturn(
          const ZeroBasedSummaryState(summary: showcaseEnvelopeSummary),
        );

        final settingsCubit = _MockAppSettingsCubit();
        when(() => settingsCubit.state).thenReturn(
          const AppSettingsState(
            settings: AppSettings(
              zeroBasedEnabled: true,
              categoriesSeeded: true,
              onboardingCompleted: true,
            ),
          ),
        );

        await pumpMarketing(
          tester,
          MultiBlocProvider(
            providers: [
              BlocProvider<BudgetsListCubit>.value(value: listCubit),
              BlocProvider<ZeroBasedSummaryCubit>.value(value: envelopeCubit),
              BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
            ],
            child: BudgetsPage(
              onAddBudget: () {},
              onOpenBudget: (_) {},
              onOpenHistory: () {},
            ),
          ),
          brightness: Brightness.light,
          platform: platform,
          // `AppRoutes.budgets` is `_presupuestosBranch`'s first-level route (no
          // `parentNavigatorKey`) → shell + tab bar, Presupuestos active.
          tabBranch: MarketingTabBranch.presupuestos,
        );
        await captureMarketing(
          tester,
          '04-presupuestos-v2.png',
        );
      });

      // --- 5: Metas ------------------------------------------------------------

      testWidgets('05 · Metas con racha activa', (tester) async {
        final cubit = _MockGoalsListCubit();
        when(() => cubit.state).thenReturn(
          GoalsListState(status: GoalsListStatus.ready, goals: showcaseGoals),
        );

        await pumpMarketing(
          tester,
          BlocProvider<GoalsListCubit>.value(
            value: cubit,
            child: GoalsListPage(
              onAddGoal: ([_]) {},
              onOpenGoal: (_) {},
              onOpenArchived: () {},
            ),
          ),
          brightness: Brightness.light,
          platform: platform,
          // `AppRoutes.goals` is `_metasBranch`'s first-level route (no
          // `parentNavigatorKey`) → shell + tab bar, Metas active. Only
          // `archivadas`/`nueva`/`:id` under it go to the root navigator.
          tabBranch: MarketingTabBranch.metas,
        );
        await captureMarketing(tester, '05-metas-v2.png');
      });

      // --- 6: Deudas -----------------------------------------------------------

      testWidgets('06 · Deudas', (tester) async {
        final cubit = _MockDebtsListCubit();
        when(() => cubit.state).thenReturn(
          DebtsListState(
            status: DebtsListStatus.ready,
            summary: showcaseDebtsSummary,
          ),
        );

        await pumpMarketing(
          tester,
          BlocProvider<DebtsListCubit>.value(
            value: cubit,
            child: DebtsListPage(onAddDebt: () {}, onOpenDebt: (_) {}),
          ),
          brightness: Brightness.light,
          platform: platform,
          // No `tabBranch`: `_debtsRoute()` is a root-navigator sibling of the
          // shell (`parentNavigatorKey: _rootNavigatorKey`) — reached from
          // Inicio's quick-access chip as a stacked screen with a back button.
        );
        await captureMarketing(tester, '06-deudas-v2.png');
      });

      // --- 7: Pagos programados ------------------------------------------------

      testWidgets('07 · Pagos programados con pendientes', (tester) async {
        final listCubit = _MockScheduledPaymentsListCubit();
        when(() => listCubit.state).thenReturn(
          ScheduledPaymentsListState(
            status: ScheduledPaymentsListStatus.ready,
            items: showcaseScheduledPayments,
          ),
        );

        final pendingCubit = _MockPendingOccurrencesCubit();
        when(() => pendingCubit.state).thenReturn(
          PendingOccurrencesState(
            status: PendingOccurrencesStatus.ready,
            items: showcasePendingOccurrences,
          ),
        );

        await pumpMarketing(
          tester,
          MultiBlocProvider(
            providers: [
              BlocProvider<ScheduledPaymentsListCubit>.value(value: listCubit),
              BlocProvider<PendingOccurrencesCubit>.value(value: pendingCubit),
            ],
            child: ScheduledPaymentsPage(
              onAddScheduledPayment: () {},
              onOpenScheduledPayment: (_) {},
              onOpenPending: () {},
            ),
          ),
          brightness: Brightness.light,
          platform: platform,
          // No `tabBranch`: `_pagosProgramadosRoute()` stopped being a tab when
          // Metas recovered slot 4 — it is now a root-navigator sibling of the
          // shell, "hence its own `Page Header` with a back button, unlike when
          // it was a tab root" (`app_router.dart`).
        );
        await captureMarketing(
          tester,
          '07-pagos-programados-v2.png',
        );
      });

      // --- 9: Importar y exportar ---------------------------------------------

      testWidgets('09 · Importar y exportar', (tester) async {
        final cubit = _MockImportExportHubCubit();
        when(() => cubit.state).thenReturn(
          ImportExportHubState(
            status: ImportExportHubStatus.ready,
            lastBackupSavedAt: showcaseLastBackupAt,
            latestBatch: showcaseImportBatch,
          ),
        );

        await pumpMarketing(
          tester,
          BlocProvider<ImportExportHubCubit>.value(
            value: cubit,
            child: ImportExportHubPage(
              onSaveCopy: () {},
              onExportCsv: () {},
              onImportCsv: () {},
              onRestore: () {},
              onSeeImportHistory: () {},
              onOpenBatch: (_) {},
            ),
          ),
          brightness: Brightness.light,
          platform: platform,
          // No `tabBranch`: `_importExportRoute()` lives "as a root-navigator
          // sibling like Cuentas/Categorías — never inside a
          // `StatefulShellBranch`" (`app_router.dart`).
        );
        await captureMarketing(
          tester,
          '09-importar-exportar-v2.png',
        );
      });
    });
  }
}
