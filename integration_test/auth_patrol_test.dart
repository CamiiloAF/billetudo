// Patrol e2e for Auth + Sync (feature 05, HU-01 to HU-07). Runs the real
// app: real DI graph, real on-device Drift database, real go_router
// navigation. No datasource or repository is mocked.
//
// Supabase/PowerSync are not wired into this project yet (see CLAUDE.md →
// "Estado del repo" and `docs/requirements/05-auth-sync.md`): every real
// Google/Apple sign-in call throws `UnimplementedError` from
// `AuthRepositoryImpl`. That rules out automating an actual sign-in, a real
// merge, a real cloud delete, or a real "Cerrar sesión" (which only shows in
// "Más" once a session exists — unreachable without a real sign-in). Those
// flows already have full coverage without a real backend at the cubit level
// (`test/features/auth/presentation/cubit/`) and, for the no-dark-pattern
// requirement on paso 2 of "Eliminar cuenta", at the widget level
// (`test/features/auth/presentation/widgets/sheets/local_data_choice_sheet_test.dart`)
// — that one specifically because paso 2 is only reachable once paso 1's
// (currently unimplemented) cloud call succeeds.
//
// What *is* verifiable end-to-end without a network call: HU-01's "never a
// gate" guarantee (Login opens and closes without ever blocking navigation)
// and paso 1 of "Eliminar cuenta" up to and including its real failure path
// (the confirm button really calls the repository, which really throws,
// which really surfaces the neutral error sheet instead of crashing).
import 'package:billetudo/features/auth/presentation/pages/login_page.dart';
import 'package:billetudo/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

Future<void> _openSettings(PatrolIntegrationTester $) async {
  await $.tester.tap(find.text('Más'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Ajustes'));
  await $.tester.pumpAndSettle();
}

void main() {
  patrolTest(
    'HU-01: Ajustes -> Login -> "Continuar sin cuenta" nunca bloquea la app',
    ($) async {
      await startApp($);

      await _openSettings($);
      expect(find.byType(SettingsPage), findsOneWidget);
      // Fresh install, no session: the invitation shows, not a session card.
      expect(find.text('Respaldar en la nube'), findsOneWidget);

      await $.tester.tap(find.text('Respaldar en la nube'));
      await $.tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);

      await $.tester.tap(find.text('Continuar sin cuenta'));
      await $.tester.pumpAndSettle();

      // Back on Ajustes, still without a session — skipping is a full,
      // frictionless exit, never a partial/blocked state.
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Respaldar en la nube'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-01: el botón de cerrar (x) de Login también permite posponer',
    ($) async {
      await startApp($);

      await _openSettings($);
      await $.tester.tap(find.text('Respaldar en la nube'));
      await $.tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);

      await $.tester.tap(find.byIcon(LucideIcons.x));
      await $.tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    },
  );

  patrolTest(
    'HU-01: sin sesión, "Más" nunca ofrece "Cerrar sesión"',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Más'));
      await $.tester.pumpAndSettle();

      expect(find.text('Cerrar sesión'), findsNothing);
    },
  );

  patrolTest(
    'HU-07 paso 1: "Eliminar cuenta" abre la hoja destructiva; "Cancelar" '
    'la cierra sin tocar nada',
    ($) async {
      await startApp($);

      await _openSettings($);
      await $.tester.tap(find.text('Eliminar cuenta'));
      await $.tester.pumpAndSettle();

      expect(find.text('Eliminar tu cuenta'), findsOneWidget);
      expect(find.textContaining('no se puede deshacer'), findsOneWidget);

      await $.tester.tap(find.text('Cancelar'));
      await $.tester.pumpAndSettle();

      // Sheet closed, Ajustes untouched, no session created.
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Respaldar en la nube'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-07 paso 1: confirmar sin backend cableado cae al estado de error, '
    'nunca crashea la app',
    ($) async {
      await startApp($);

      await _openSettings($);
      await $.tester.tap(find.text('Eliminar cuenta'));
      await $.tester.pumpAndSettle();

      // "Eliminar cuenta" appears twice on screen at this point: once as
      // Ajustes' destructive row (now behind the sheet) and once as the
      // sheet's own CTA — the CTA is the one actually on top/hit-testable.
      await $.tester.tap(find.text('Eliminar cuenta').last);
      await $.tester.pumpAndSettle();

      expect(find.text('No pudimos eliminar tu cuenta'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      await $.tester.tap(find.text('Cancelar'));
      await $.tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    },
  );
}
