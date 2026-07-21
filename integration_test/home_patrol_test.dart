// Patrol e2e for Inicio — the navigation shell (feature 04, HU-01/HU-02).
// Runs the real app: real DI graph, real on-device Drift database, real
// go_router `StatefulShellRoute`. No datasource or repository is mocked.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite file
// first (see `support/patrol_app.dart`), so each one begins on a clean install:
// no accounts, no transactions — the Home therefore renders its empty state.
//
// Navigation is asserted by page type (`find.byType`), not by text, so the
// checks do not depend on localized copy or on a label appearing more than once
// (every tab label also shows inside its own page). Taps still go through the
// visible affordances — the tab labels and the FAB tooltip — exactly as a user
// would drive the shell.
import 'package:billetudo/core/widgets/coming_soon_page.dart';
import 'package:billetudo/features/accounts/presentation/pages/accounts_page.dart';
import 'package:billetudo/features/budgets/presentation/pages/budgets_page.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/home/presentation/pages/more_page.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Pumps frames until [finder] matches at least one widget, or a frame budget
/// runs out. Needed for content that appears after an async Drift stream emits:
/// `pumpWidgetAndSettle` cannot see I/O that completes after it returns, so on a
/// fresh install the Home is still on its loading skeletons for the first frame.
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
    'HU-01: la app abre en Inicio con la tab bar de cinco destinos',
    ($) async {
      await startApp($);

      // Default tab is Inicio, and the persistent tab bar exposes the five
      // destinations in order.
      expect(find.byType(HomePage), findsOneWidget);
      for (final label in const [
        'Inicio',
        'Movimientos',
        'Presupuestos',
        'Metas',
        'Más',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      // Fresh install: no movements yet, so the welcome/empty state shows
      // (HU-08) — never a full-screen error (HU-10). The Home opens on its
      // loading skeletons and swaps to the empty state once the async Drift
      // stream emits the empty first month, so wait for it instead of asserting
      // on the very first frame.
      await _pumpUntilFound($, find.text('Aún no registras movimientos'));
      expect(find.text('Aún no registras movimientos'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-01: Presupuestos abre su feature real y Metas muestra "Próximamente"',
    ($) async {
      await startApp($);

      // Budgets shipped as a real feature (BudgetsPage), so its tab no longer
      // renders the ComingSoonPage placeholder. Goals is still unimplemented.
      await $.tester.tap(find.text('Presupuestos'));
      await $.tester.pumpAndSettle();
      expect(find.byType(BudgetsPage), findsOneWidget);

      await $.tester.tap(find.text('Metas'));
      await $.tester.pumpAndSettle();
      expect(find.byType(ComingSoonPage), findsOneWidget);

      // The tab bar stays visible and lets us return to Inicio.
      await $.tester.tap(find.text('Inicio'));
      await $.tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    },
  );

  patrolTest(
    'HU-01: el hub "Más" llega a Cuentas (feature de Nivel 0 alcanzable)',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Más'));
      await $.tester.pumpAndSettle();

      // The hub lists the live Nivel 0 destinations.
      expect(find.byType(MorePage), findsOneWidget);
      expect(find.text('Cuentas'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);

      // Tapping a live one navigates into it (stacked over the tab bar).
      await $.tester.tap(find.text('Cuentas'));
      await $.tester.pumpAndSettle();
      expect(find.byType(AccountsPage), findsOneWidget);
      expect(find.byTooltip('Agregar cuenta'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-02: el FAB abre el formulario de nueva transacción',
    ($) async {
      await startApp($);

      // The FAB is the primary capture entry point (HU-02): it opens the
      // new-transaction form on the root navigator, above the tab bar.
      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();

      expect(find.byType(TransactionFormPage), findsOneWidget);
    },
  );
}
