// Patrol e2e for Gráficas e informes esenciales (Nivel 0,
// `docs/requirements/10-graficas-informes.md`, design spec
// `design-system/billetudo/pages/graficas.md`). Runs the real app — real DI
// graph, real on-device Drift database, real go_router navigation — against
// a real emulator/simulator. No datasource or repository is mocked: this is
// the exact code path a user's phone runs, on top of the unit/widget/golden
// suites already covering the domain math and the render pixel-by-pixel
// (`test/features/reports/...`).
//
// The scenario seeds one account, one expense category and one expense
// transaction directly through the real `AppDatabase` (same convention as
// `categories_patrol_test.dart`'s `ConTx` scenario) — Cuentas/Categorías/
// Movimientos already own their own Patrol suites covering that capture UI;
// here the seed is a fixture, not the thing under test. This keeps every
// report tab out of its "vacío" (HU-06) state so the multi-tab navigation
// actually exercises each card's real chart, not an `EmptyState` placeholder.
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/features/home/presentation/pages/more_page.dart';
import 'package:billetudo/features/reports/presentation/pages/reports_page.dart';
import 'package:billetudo/features/reports/presentation/widgets/period_selector.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Seeds a real account, an expense category and an expense transaction in
/// the current month, so every report tab has data to render instead of its
/// empty state (HU-06). Returns nothing: the seed's ids are not user-visible
/// and this scenario never asserts against them directly.
Future<void> _seedOneMonthOfData() async {
  final db = getIt<AppDatabase>();
  final account = await db.into(db.accounts).insertReturning(
        AccountsCompanion.insert(
          name: 'Cuenta seed',
          type: AccountType.cash,
          currency: 'COP',
        ),
      );
  final category = await db.into(db.categories).insertReturning(
        CategoriesCompanion.insert(
          name: 'Mercado seed',
          kind: CategoryKind.expense,
        ),
      );
  final now = DateTime.now();
  await db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          accountId: account.id,
          categoryId: Value(category.id),
          amountMinor: 85000,
          currency: 'COP',
          type: EntryType.expense,
          date: DateTime(now.year, now.month),
        ),
      );
}

/// Reaches Gráficas e informes from the "Más" hub row (criterion 27): the
/// row can sit below the fold on a small device, so it is scrolled into view
/// first, same convention as the widget test's `scrollUntilVisible` +
/// `ensureVisible` fix for this exact row
/// (`test/features/home/presentation/pages/more_page_test.dart`).
/// Drags the nearest `Scrollable` until [finder] is on screen — same
/// convention as `accounts_patrol_test.dart`'s `_scrollUntilVisible`: each
/// tab body is a plain `SingleChildScrollView` (`cashflow_tab_view.dart`),
/// so a control placed below a full chart card (e.g. the debt toggle, which
/// renders after `CashflowCardContent`'s hero + legend + bars) can sit
/// outside the visible viewport. `WidgetTester.tap()` does not fail on an
/// off-screen target — it hit-tests the widget's global position regardless
/// of whether a scroll view clips it — so a tap that silently lands nowhere
/// looks identical to a successful one until the very next assertion.
Future<void> _scrollUntilVisible(
  PatrolIntegrationTester $,
  Finder finder,
) async {
  await $.tester.dragUntilVisible(
    finder,
    find.byType(Scrollable).first,
    const Offset(0, -220),
  );
  await $.tester.pumpAndSettle();
}

Future<void> _goToReportsFromMoreHub(PatrolIntegrationTester $) async {
  await $.tester.tap(find.text('Más'));
  await $.tester.pumpAndSettle();
  expect(find.byType(MorePage), findsOneWidget);

  await $.tester.scrollUntilVisible(
    find.text('Gráficas e informes'),
    100,
    scrollable: find.byType(Scrollable),
  );
  await $.tester.ensureVisible(find.text('Gráficas e informes'));
  await $.tester.pump();
  await $.tester.tap(find.text('Gráficas e informes'));
  await $.tester.pumpAndSettle();
  expect(find.byType(ReportsPage), findsOneWidget);
}

void main() {
  patrolTest(
    'HU-01 a HU-06: desde "Más", los 4 tabs de Gráficas e informes navegan, '
    'el toggle de deuda de Flujo, el selector de periodo y la exportación '
    'funcionan sin abandonar la pantalla',
    ($) async {
      await startApp($);
      await _seedOneMonthOfData();

      await _goToReportsFromMoreHub($);

      // Default tab is Resumen (HU-04, criterion 14): no Period Row (D2).
      expect(find.text('Resumen'), findsOneWidget);
      expect(find.text('Filtrar periodo'), findsNothing);

      // --- Flujo (HU-01) --------------------------------------------------
      await $.tester.tap(find.text('Flujo'));
      await $.tester.pumpAndSettle();
      expect(find.text('Flujo de caja'), findsOneWidget);
      // "Ingresos"/"Gastos" legitimately render twice on this tab: once in
      // the net hero's stat row (`CashflowNetHero`) and once in the bar
      // chart's own legend (`cashflow_card_content.dart`) — not a bug.
      expect(find.text('Ingresos'), findsNWidgets(2));
      expect(find.text('Gastos'), findsNWidgets(2));

      // Criterion 5: toggling "Separar movimientos de deuda" segregates
      // without hiding the card or changing tabs — the debt legend chip
      // (only shown once the toggle asks to separate) appears.
      expect(find.text('Separar movimientos de deuda'), findsOneWidget);
      expect(find.text('Movimientos de deuda'), findsNothing);
      await _scrollUntilVisible($, find.text('Separar movimientos de deuda'));
      await $.tester.tap(find.text('Separar movimientos de deuda'));
      await $.tester.pumpAndSettle();
      expect(find.text('Flujo de caja'), findsOneWidget);
      expect(find.text('Movimientos de deuda'), findsOneWidget);

      // Criterion 11: the period selector opens the sheet with no forced
      // range limit — apply the sheet's own default (unchanged) selection.
      // Tapping the `PeriodSelector` pill opens `PeriodSelectorSheet`, whose
      // title is "Filtrar periodo" (`reportsPeriodSheetTitle`) — the pill's
      // own label is dynamic (e.g. "Últimos 6 meses",
      // `ReportsPeriodFormat.selectorLabel`), never that literal string, so
      // it must be found by type, not by that text. The toggle tap above
      // may have left the tab's `SingleChildScrollView` scrolled down,
      // pushing the period row (top of the column, in
      // `cashflow_tab_view.dart`) out of the viewport — scroll back to it
      // before tapping, same reasoning as the toggle fix above.
      await _scrollUntilVisible($, find.byType(PeriodSelector));
      await $.tester.tap(find.byType(PeriodSelector).hitTestable());
      await $.tester.pumpAndSettle();
      expect(find.text('Filtrar periodo'), findsOneWidget);
      await $.tester.tap(find.text('Aplicar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Flujo de caja'), findsOneWidget);

      // Criterion 14: the shared period/toggle survive a tab switch — the
      // debt legend chip set above must still be visible after leaving and
      // coming back to Flujo.
      await $.tester.tap(find.text('Patrimonio'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Flujo'));
      await $.tester.pumpAndSettle();
      expect(find.text('Movimientos de deuda'), findsOneWidget);

      // Criterion 15: export captures the card via `RepaintBoundary` and
      // hands off to the native share sheet — this only asserts it neither
      // crashes nor shows the in-app export error snackbar.
      await $.tester.tap(find.byTooltip('Exportar como imagen'));
      await $.tester.pump(const Duration(milliseconds: 500));
      expect(find.text('No pudimos exportar la gráfica. Intenta de nuevo.'),
          findsNothing);

      // --- Patrimonio (HU-02) ---------------------------------------------
      await $.tester.tap(find.text('Patrimonio'));
      await $.tester.pumpAndSettle();
      expect(find.text('Patrimonio'), findsWidgets);
      expect(find.text('Incluir cuentas archivadas'), findsOneWidget);

      // --- Categorías (HU-03) ----------------------------------------------
      await $.tester.tap(find.text('Categorías'));
      await $.tester.pumpAndSettle();
      expect(find.text('Estructura de gasto'), findsOneWidget);
      expect(find.text('Mercado seed'), findsOneWidget);

      // Back to Resumen closes the loop across all 4 tabs.
      await $.tester.tap(find.text('Resumen'));
      await $.tester.pumpAndSettle();
      expect(find.text('Presupuestos'), findsOneWidget);
      expect(find.text('Metas'), findsWidgets);
      expect(find.text('Ver el avance de tus deudas'), findsOneWidget);
    },
  );
}
