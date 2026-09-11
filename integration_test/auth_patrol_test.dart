// Patrol e2e for Auth + Sync (feature 05, HU-01 to HU-07). Runs the real
// app: real DI graph, real on-device Drift database, real go_router
// navigation. No datasource or repository is mocked.
//
// Supabase/PowerSync are wired into this project (see CLAUDE.md → "Estado
// del repo": `lib/core/bootstrap.dart`, `lib/core/database/database_connection.dart`,
// `lib/core/database/powersync_schema.dart`, `lib/core/di/register_module.dart`).
// Automating a real Google/Apple sign-in end to end still is not viable
// here — it needs a real OAuth round trip through a system browser/account
// chooser outside Flutter's widget tree, not something Patrol drives — so a
// real sign-in, a real merge, a real cloud delete, or a real "Cerrar sesión"
// (which only shows in "Más" once a session exists — unreachable without a
// real sign-in) stay out of scope for this suite. Those flows already have
// full coverage without a real backend at the cubit level
// (`test/features/auth/presentation/cubit/`) and, for the no-dark-pattern
// requirement on paso 2 of "Eliminar cuenta", at the widget level
// (`test/features/auth/presentation/widgets/sheets/local_data_choice_sheet_test.dart`).
//
// What *is* verifiable end-to-end without a network call: HU-01's "never a
// gate" guarantee (Login opens and closes without ever blocking navigation)
// and "Eliminar cuenta" for a device that never signed in — paso 1's real
// `AuthRepositoryImpl.deleteAccount` skips the Edge Function outright when
// there is no session to attach a JWT to (there is nothing in the cloud to
// delete), so it genuinely succeeds and advances straight to paso 2, rather
// than genuinely failing (found 2026-09-11, see
// `docs/dev-runs/patrol-e2e-findings-2026-09-10.md` § "Resuelto de verdad
// esta vez": the suite's own last scenario used to assert the *error* sheet
// here, which is dead code for this path since that short-circuit was
// added — the real failure path is already covered without a real backend
// by `test/features/auth/presentation/cubit/delete_account_cubit_test.dart`
// and its sheet/golden counterparts, `test/features/auth/presentation/
// widgets/sheets/confirm_delete_account_sheet*.dart`).
import 'package:billetudo/features/auth/presentation/pages/login_page.dart';
import 'package:billetudo/features/settings/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// "Ajustes" is `MorePage`'s last row before "Cerrar sesión" (8th of 8, each
/// with an icon, a bold label and a description line — tall enough that a
/// phone screen shows only the first 5-6 without scrolling). `MorePage`'s
/// `ListView` is a plain one (`ListView(children: [...])`, not `.builder`),
/// but — same caveat as `_scrollUntilVisible` documents in
/// `accounts_patrol_test.dart` — its underlying sliver still discards
/// elements that scroll far enough outside the cache extent, so tapping
/// "Ajustes" without scrolling to it first fails with "Found 0 widgets", not
/// a hit-test miss — verified against the real emulator run this suite
/// failed on.
Future<void> _openSettings(PatrolIntegrationTester $) async {
  await $.tester.tap(find.text('Más'));
  await $.tester.pumpAndSettle();
  await $.tester.dragUntilVisible(
    find.text('Ajustes'),
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Ajustes'));
  await $.tester.pumpAndSettle();
}

/// `SettingsPage`'s "Eliminar cuenta" row is the last item in its own
/// `ListView` (below "Cuenta y respaldo", "Presupuesto", "Preferencias" and
/// "Asistente de IA") — same cache-extent caveat as `_openSettings` above:
/// off screen, it is absent from the tree, not just unreachable by hit-test.
Future<void> _tapDeleteAccountRow(PatrolIntegrationTester $) async {
  await $.tester.dragUntilVisible(
    find.text('Eliminar cuenta'),
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Eliminar cuenta'));
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
      await _tapDeleteAccountRow($);

      expect(find.text('Eliminar tu cuenta'), findsOneWidget);
      expect(find.textContaining('irreversible'), findsOneWidget);

      await $.tester.tap(find.text('Cancelar'));
      await $.tester.pumpAndSettle();

      // Sheet closed, Ajustes untouched, no session created. The underlying
      // `ListView` is still scrolled to the bottom from `_tapDeleteAccountRow`
      // above — scroll back up before looking for a row near the top,
      // otherwise it is off screen and absent from the tree.
      expect(find.byType(SettingsPage), findsOneWidget);
      await $.tester.dragUntilVisible(
        find.text('Respaldar en la nube'),
        find.byType(Scrollable).first,
        const Offset(0, 250),
      );
      await $.tester.pumpAndSettle();
      expect(find.text('Respaldar en la nube'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-07: confirmar "Eliminar cuenta" sin sesión avanza directo a paso 2 '
    '(sin llamar al backend), nunca crashea la app',
    ($) async {
      await startApp($);

      await _openSettings($);
      await _tapDeleteAccountRow($);

      // "Eliminar cuenta" appears twice on screen at this point: once as
      // Ajustes' destructive row (now behind the sheet) and once as the
      // sheet's own CTA — the CTA is the one actually on top/hit-testable.
      await $.tester.tap(find.text('Eliminar cuenta').last);
      await $.tester.pumpAndSettle();

      // No session on this device (never signed in this run) — paso 1
      // genuinely skips the Edge Function call and succeeds immediately
      // (`AuthRepositoryImpl.deleteAccount`'s `!isSignedIn` short-circuit:
      // nothing in the cloud to delete), advancing straight to paso 2
      // instead of ever showing the error sheet. Asserting the
      // never-signed-in copy specifically (not just any paso-2 text) also
      // confirms `GetDeleteAccountScope` told paso 2 this device never had a
      // cloud account, rather than mistaking it for one that signed out.
      expect(
        find.text('¿Qué hacemos con tus datos en este teléfono?'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Nunca iniciaste sesión en este dispositivo, así que no hay una '
          'cuenta en la nube. Elige qué pasa con la información guardada '
          'aquí.',
        ),
        findsOneWidget,
      );
      // Never falls back to the error sheet.
      expect(find.text('No pudimos eliminar tu cuenta'), findsNothing);

      // Paso 2 itself (the choice + its no-dark-pattern CTA gating, and the
      // actual local wipe) is this suite's own scope boundary — already
      // covered without a real backend at the widget level, see this file's
      // header comment. This scenario stops here: it only needs to prove
      // paso 1 → paso 2 really happens end-to-end for this device, which it
      // just did. Last scenario in the file, so no cleanup is needed for a
      // scenario after it.
    },
  );
}
