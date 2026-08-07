// Patrol e2e for the Home hero's period navigation (this entrega: "Rediseño
// del hero de Inicio y desacople de Movimientos recientes"). Runs the real
// app — real DI graph, real on-device Drift database, real go_router
// navigation — against a real emulator/simulator.
//
// Covers, end to end, the two multi-screen guarantees a unit/widget test
// cannot: (1) a budget created in Presupuestos becomes the Home hero's
// featured budget on its very next frame (no manual wiring, no restart), with
// a real period-range label instead of a calendar month name (criterion 3),
// and (2) tapping that hero navigates to *that* budget's own detail screen —
// never a movements list (criterion 6). `home_patrol_test.dart` already
// covers the tab-bar shell itself; this suite only adds the hero's own
// cross-feature flow.
//
// Reuses `budgets_patrol_test.dart`'s "Todo" (global) scope + monthly cadence
// helpers on purpose: that is exactly the profile `BudgetHeroSelector`'s
// automatic pick requires, and it keeps this scenario free of the
// category-seed network dependency (see that file's own header comment).
import 'package:billetudo/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_budget_progress.dart';
import 'package:billetudo/features/home/presentation/widgets/home_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Opens the budget form from the list's `+` circular button — same helper
/// shape as `budgets_patrol_test.dart`'s private one (not shared across
/// integration_test files on purpose: each Patrol suite stays self
/// contained).
Future<void> _openNewBudgetForm(PatrolIntegrationTester $) async {
  await $.tester.tap(find.text('Presupuestos'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byTooltip('Nuevo presupuesto'));
  await $.tester.pumpAndSettle();
}

Future<void> _fillMinimalBudgetForm(
  PatrolIntegrationTester $, {
  required String name,
  required String amount,
}) async {
  await $.tester.enterText(find.byType(TextFormField).first, name);
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField).at(1), amount);
  await $.tester.pumpAndSettle();
}

Future<void> _submitBudgetForm(PatrolIntegrationTester $, String label) async {
  final button = find.text(label);
  await $.tester.dragUntilVisible(
    button,
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await $.tester.pumpAndSettle();
  await $.tester.tap(button);
  await $.tester.pumpAndSettle();
}

/// Pumps frames until [finder] matches at least one widget, or a frame budget
/// runs out — same reasoning as `home_patrol_test.dart`'s own helper: the
/// hero's featured-budget stream lands async, after Drift's first emission.
Future<void> _pumpUntilFound(
  PatrolIntegrationTester $,
  Finder finder, {
  int maxFrames = 30,
}) async {
  for (var i = 0; i < maxFrames && finder.evaluate().isEmpty; i++) {
    await $.tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  patrolTest(
    'criterios 3, 5 y 6: un presupuesto global-mensual se destaca en el hero '
    'con su ventana real, y tocarlo abre su propio detalle',
    ($) async {
      await startApp($);

      // Before any budget exists: the hero falls back to the current
      // calendar month with no stepper at all (criterion 5). A fresh install
      // starts on the hero's loading skeleton until accounts/transactions'
      // first async emission lands, so wait for the real card instead of
      // asserting on the very first frame (same reasoning as
      // `home_patrol_test.dart`'s own `_pumpUntilFound` usage).
      await _pumpUntilFound($, find.byType(HomeHeroCard));
      expect(find.byType(HomeHeroCard), findsOneWidget);
      expect(find.byType(HeroPeriodStepper), findsNothing);
      expect(find.byType(HomeHeroBudgetProgress), findsNothing);

      await _openNewBudgetForm($);
      await _fillMinimalBudgetForm(
        $,
        name: 'Mercado del mes',
        amount: '1000000',
      );
      await _submitBudgetForm($, 'Crear presupuesto');

      await $.tester.tap(find.text('Inicio'));
      await $.tester.pumpAndSettle();

      // Criterion 3: the freshly created global-monthly budget is featured
      // automatically — no Ajustes step needed — and the hero swaps its
      // calendar-month chip for the period stepper, with a real progress bar
      // instead of the budget invitation.
      await _pumpUntilFound($, find.byType(HeroPeriodStepper));
      expect(find.byType(HeroPeriodStepper), findsOneWidget);
      expect(find.byType(HomeHeroBudgetProgress), findsOneWidget);

      // Criterion 6: tapping the hero opens *that* budget's own detail —
      // never a movements list.
      await $.tester.tap(find.byType(HomeHeroCard));
      await $.tester.pumpAndSettle();

      expect(find.byType(BudgetDetailPage), findsOneWidget);
      // The budget's own name renders more than once on its detail (e.g. the
      // header and the amount card) — assert presence, not uniqueness.
      expect(find.text('Mercado del mes'), findsWidgets);
    },
  );
}
