// Patrol e2e for the account gate (`docs/requirements/15-gate-cuenta.md`).
// Runs the real app: real DI graph, real on-device Drift database, real
// go_router navigation. No datasource or repository is mocked.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so each one begins on a clean
// install: no accounts — the scenarios this feature exists for.
import 'package:billetudo/features/accounts/presentation/pages/account_form_page.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Pumps frames until [finder] matches at least one widget, or a frame
/// budget runs out — needed for content that appears after an async Drift
/// stream emits.
Future<void> _pumpUntilFound(
  PatrolIntegrationTester $,
  Finder finder, {
  int maxFrames = 30,
}) async {
  for (var i = 0; i < maxFrames && finder.evaluate().isEmpty; i++) {
    await $.tester.pump(const Duration(milliseconds: 100));
  }
}

/// The account form's full-width "Guardar cuenta" submit button — see the
/// identical helper in `accounts_patrol_test.dart` for why this finder
/// (rather than an icon or `widgetWithText`) is the unambiguous one.
Finder get _saveAccountButton => find.ancestor(
      of: find.text('Guardar cuenta'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );

void main() {
  patrolTest(
    'HU-01, HU-02, HU-04: crear la cuenta desde el puente cierra la hoja y '
    'continúa directo al formulario de movimiento con la cuenta disponible',
    ($) async {
      await startApp($);
      await _pumpUntilFound($, find.text('Aún no registras movimientos'));

      // Fresh install, no accounts: the FAB opens the bridge, not the form.
      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
      expect(find.byType(TransactionFormPage), findsNothing);

      // Accept: the real account form (HU-01 of `01-cuentas.md`), not a
      // bespoke embedded one.
      await $.tester.tap(find.text('Crear cuenta'));
      await $.tester.pumpAndSettle();
      expect(find.byType(AccountFormPage), findsOneWidget);

      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();
      await $.tester.enterText(find.byType(TextFormField).first, 'Bolsillo');
      await $.tester.pumpAndSettle();
      await $.tester.tap(_saveAccountButton);
      await $.tester.pumpAndSettle();

      // HU-01: no transition screen, no bounce back to Home — the original
      // action (the new-transaction form) opens directly, with the
      // freshly-created account already available to pick.
      expect(find.byType(AccountGateBridgeSheet), findsNothing);
      expect(find.byType(AccountFormPage), findsNothing);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(TransactionFormPage), findsOneWidget);
    },
  );

  patrolTest(
    'HU-01: cancelar el puente ("Ahora no") deja al usuario en Home, sin '
    'crear cuenta ni abrir el formulario',
    ($) async {
      await startApp($);
      await _pumpUntilFound($, find.text('Aún no registras movimientos'));

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      expect(find.byType(AccountGateBridgeSheet), findsOneWidget);

      await $.tester.tap(find.text('Ahora no'));
      await $.tester.pumpAndSettle();

      expect(find.byType(AccountGateBridgeSheet), findsNothing);
      expect(find.byType(TransactionFormPage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      // Still the empty state: cancelling never creates an account.
      expect(find.text('Aún no registras movimientos'), findsOneWidget);
    },
  );
}
