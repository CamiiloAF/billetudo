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
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/features/accounts/presentation/pages/accounts_page.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/budgets/presentation/pages/budgets_page.dart';
import 'package:billetudo/features/goals/presentation/pages/goals_list_page.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/home/presentation/pages/more_page.dart';
import 'package:billetudo/features/home/presentation/widgets/home_tab_bar.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
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
      // Regression: "Metas" also joined `QuickAccessRow`'s chips on Home
      // itself (`design-system/billetudo/pages/inicio.md`), so a plain
      // `find.text('Metas')` is ambiguous on this very screen — one match in
      // the tab bar, one in the quick-access strip. Scope every label lookup
      // to `HomeTabBar` so this asserts the tab bar specifically, exactly as
      // the file header promises ("checks do not depend on ... a label
      // appearing more than once").
      final tabBar = find.byType(HomeTabBar);
      for (final label in const [
        'Inicio',
        'Movimientos',
        'Presupuestos',
        'Metas',
        'Más',
      ]) {
        expect(
          find.descendant(of: tabBar, matching: find.text(label)),
          findsOneWidget,
        );
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
    'HU-01: Presupuestos y Metas abren sus features reales',
    ($) async {
      await startApp($);

      // This scenario is about branch switching in `HomeTabBar`, not about
      // the minitutorial (`16-minitutoriales.md` criterion 1). Both
      // `BudgetsPage` and `GoalsListPage` wrap themselves in
      // `TutorialAutoShow`, which auto-shows a full-screen modal sheet on a
      // fresh install's first visit — `TutorialGateCubit.evaluate` awaits a
      // real Drift query first, so the sheet can appear a few frames *after*
      // the page itself is found, right as the next tab tap lands, and
      // silently swallow it (`WidgetTester.tap`'s hit-test misses without
      // throwing unless `warnIfMissed` is inspected).
      //
      // A prior fix tried closing the sheet right after each first-time
      // landing (`dismissAutoTutorialIfShown`) — confirmed unreliable even
      // with 3-5x longer poll windows (`docs/dev-runs/
      // patrol-e2e-findings-2026-09-10.md` § "Corrección posterior"): it
      // still lost the tap to Metas intermittently. Disabling the auto-show
      // outright for this scenario removes the race instead of trying to
      // win it — confirmed stable in 2 clean back-to-back runs (8s each, vs.
      // the previous ~23s + failure). This does not test the minitutorial
      // itself; that is `16-minitutoriales.md`'s own concern, not this
      // navigation scenario's.
      await getIt<AppSettingsCubit>().setShowHelpOnSectionEntry(enabled: false);

      // Both Budgets and Goals shipped as real features (BudgetsPage,
      // GoalsListPage): neither tab renders the ComingSoonPage placeholder
      // anymore. Goals recovered its own bottom-nav tab (see
      // `QuickAccessRow`'s doc comment: "Metas is not here anymore: it
      // recovered its own bottom-nav tab").
      //
      // Taps go through `HomeTabBar` specifically: "Metas" also names a
      // `QuickAccessRow` chip on Home itself, so a plain `find.text('Metas')`
      // is ambiguous while Home is the visible branch. Every switch also
      // waits with `_pumpUntilFound` instead of trusting `pumpAndSettle`
      // alone: a `StatefulShellRoute` branch built for the first time this
      // run (Budgets, Goals) still has its own async Drift stream to
      // hydrate, same reason HU-01's empty state needs it above — a bare
      // `pumpAndSettle` can return before that first emission lands, an
      // intermittent false negative on a real device/emulator.
      final tabBar = find.byType(HomeTabBar);
      await $.tester.tap(
        find.descendant(of: tabBar, matching: find.text('Presupuestos')),
      );
      await $.tester.pumpAndSettle();
      await _pumpUntilFound($, find.byType(BudgetsPage));
      expect(find.byType(BudgetsPage), findsOneWidget);

      await $.tester.tap(
        find.descendant(of: tabBar, matching: find.text('Metas')),
      );
      await $.tester.pumpAndSettle();
      await _pumpUntilFound($, find.byType(GoalsListPage));
      expect(find.byType(GoalsListPage), findsOneWidget);

      // The tab bar stays visible and lets us return to Inicio.
      await $.tester.tap(
        find.descendant(of: tabBar, matching: find.text('Inicio')),
      );
      await $.tester.pumpAndSettle();
      await _pumpUntilFound($, find.byType(HomePage));
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
    'HU-02 gateada (15-gate-cuenta.md): en un install fresco sin cuentas, '
    'el FAB abre el puente de cuenta en vez del formulario',
    ($) async {
      await startApp($);
      await _pumpUntilFound($, find.text('Aún no registras movimientos'));

      // The FAB is the primary capture entry point (HU-02), but a fresh
      // install has zero active accounts: `15-gate-cuenta.md` HU-02/HU-04
      // intercepts before the new-transaction form ever mounts.
      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();

      expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
      expect(find.byType(TransactionFormPage), findsNothing);
    },
  );
}
