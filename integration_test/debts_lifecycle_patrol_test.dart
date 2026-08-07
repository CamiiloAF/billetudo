// Patrol e2e for the "cerrar/completar deuda" extension of Deudas (HU-07):
// the detail's ⋮ menu (Editar/Cerrar deuda/Eliminar), the manual close
// confirm sheet, the automatic felicitación sheet fired when a debt settles
// (with copy that differs by direction, iOwe vs owedToMe), the "Activas"/
// "Cerradas" tabs with their own "Pagué"/"Me pagaron" summary, and the
// write-blocking a closed debt enforces in the UI (no "Registrar abono", a
// disabled "Actualizar saldo").
//
// Same conventions as `debts_patrol_test.dart` (see its header comment for
// the full rationale): `startApp` wipes the on-device sqlite file first, so
// scenarios never leak state into each other even though they share one app
// process; money goes through `DebtAmountHeroField`'s `TextField` +
// `MoneyInputFormatter` via `enterText` (COP, no decimals, so `enterText
// ('600')` reads `$600` / stores `60000` minor); helpers below are
// deliberately duplicated from `debts_patrol_test.dart` rather than shared
// (the existing two Deudas suites do the same, see
// `debts_installment_patrol_test.dart`'s own "shared shape" comment) — there
// is no shared support module for Deudas helpers in this project yet.
import 'dart:async';

import 'package:billetudo/core/database/app_database.dart' hide CategoryKind;
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_amount_hero_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_cash_switch.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_closed_summary_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_form_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

// ---------------------------------------------------------------------------
// Navigation + setup helpers (same shape as `debts_patrol_test.dart`).
// ---------------------------------------------------------------------------

void _goToDebts(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.debts));
}

Future<void> _openNewDebtForm(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Agregar deuda'));
  await $.tester.pumpAndSettle();
}

Future<void> _enterHeroAmount(PatrolIntegrationTester $, String value) async {
  final field = find.descendant(
    of: find.byType(DebtAmountHeroField),
    matching: find.byType(TextField),
  );
  await $.tester.enterText(field, '');
  await $.tester.pumpAndSettle();
  await $.tester.enterText(field, value);
  await $.tester.pumpAndSettle();
}

Future<void> _enterDebtName(PatrolIntegrationTester $, String name) async {
  final field = find.descendant(
    of: find
        .ancestor(
          of: find.text('Nombre de la deuda'),
          matching: find.byType(DebtFormField),
        )
        .first,
    matching: find.byType(TextFormField),
  );
  await $.tester.enterText(field, name);
  await $.tester.pumpAndSettle();
}

Future<void> _selectDirection(PatrolIntegrationTester $, String label) async {
  await $.tester.tap(find.text(label));
  await $.tester.pumpAndSettle();
}

/// Creates a debt with [name]/[openingWhole]/[direction] and leaves the
/// tester back on the list. No cash account exists in these scenarios, so
/// "Crear deuda" saves straight away — the registro-inicial sheet (item 2)
/// only appears when at least one account exists, which none of this file's
/// scenarios need (they exercise the close/celebrate lifecycle, not cash
/// movements).
Future<void> _createDebt(
  PatrolIntegrationTester $, {
  required String name,
  required String openingWhole,
  String direction = 'Yo debo',
}) async {
  await _openNewDebtForm($);
  if (direction != 'Yo debo') {
    await _selectDirection($, direction);
  }
  await _enterHeroAmount($, openingWhole);
  await _enterDebtName($, name);
  await $.tester.tap(find.text('Crear deuda'));
  await $.tester.pumpAndSettle();
}

/// Opens the only `DebtCard` on the current tab. Only safe when exactly one
/// card is on screen.
Future<void> _openOnlyDebt(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byType(DebtCard));
  await $.tester.pumpAndSettle();
}

/// Opens the `DebtCard` named [name] specifically — for scenarios with
/// several debts on the same tab.
Future<void> _openDebtByName(PatrolIntegrationTester $, String name) async {
  await $.tester.tap(
    find.ancestor(of: find.text(name), matching: find.byType(DebtCard)),
  );
  await $.tester.pumpAndSettle();
}

Future<void> _openAbonoSheet(PatrolIntegrationTester $) async {
  await $.tester.tap(find.text('Registrar abono'));
  await $.tester.pumpAndSettle();
}

/// Sets the abono sheet's "¿Agregar a una cuenta?" toggle to [addToAccount].
/// None of this file's scenarios create a cash account, so the toggle
/// defaults off (`DebtPaymentCubit.start` forces it off when there are no
/// accounts even if a prior session remembered "on") — this only taps when
/// the current state genuinely differs from what is asked.
Future<void> _setCashToggle(
  PatrolIntegrationTester $, {
  required bool addToAccount,
}) async {
  final isOn = find.byType(DebtSelectedAccountRow).evaluate().isNotEmpty;
  if (isOn != addToAccount) {
    await $.tester.tap(find.byType(DebtCashSwitch));
    await $.tester.pumpAndSettle();
  }
}

/// Submits the abono sheet's own CTA (the only `LucideIcons.check` inside
/// `DebtPaymentSheetBody` while it is open — see `debts_patrol_test.dart`'s
/// `_submitAbono` for why a bare text match is ambiguous here), then bounds
/// the pump so the write, the sheet pop and the detail's Drift stream
/// re-emitting all land before the next assertion.
Future<void> _submitAbono(PatrolIntegrationTester $) async {
  await $.tester.tap(
    find.descendant(
      of: find.byType(DebtPaymentSheetBody),
      matching: find.byIcon(LucideIcons.check),
    ),
  );
  await $.tester.pumpAndSettle();
  await $.tester.pump(const Duration(milliseconds: 500));
  await $.tester.pumpAndSettle();
}

/// Registers a cash-less abono of [wholeAmount] on the currently open debt's
/// detail. Bundles open-sheet + amount + submit since every multi-debt
/// scenario in this file needs the same three steps repeated.
Future<void> _registerCashlessAbono(
  PatrolIntegrationTester $,
  String wholeAmount,
) async {
  await _openAbonoSheet($);
  await _enterHeroAmount($, wholeAmount);
  await _setCashToggle($, addToAccount: false);
  await _submitAbono($);
}

/// Opens the detail's ⋮ overflow menu (`debtMenuTooltip`, "Más opciones").
Future<void> _openActionsMenu(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Más opciones'));
  await $.tester.pumpAndSettle();
}

/// Closes the debt currently on screen through the manual flow: ⋮ → "Cerrar
/// deuda" → the confirm sheet's own "Cerrar deuda" CTA. Both the menu row and
/// the confirm sheet's CTA share the exact same label
/// (`debtActionClose`/`debtCloseCta` are both "Cerrar deuda" in `app_es.arb`)
/// but never coexist on screen at once (the menu sheet pops before the
/// confirm sheet opens), so two sequential `find.text` taps are unambiguous.
Future<void> _closeDebtManually(PatrolIntegrationTester $) async {
  await _openActionsMenu($);
  await $.tester.tap(find.text('Cerrar deuda'));
  await $.tester.pumpAndSettle();
  expect(find.text('¿Cerrar esta deuda?'), findsOneWidget);
  await $.tester.tap(find.text('Cerrar deuda'));
  // The status write (`closedAt`), the sheet pop and the detail's stream
  // re-emitting are separate async hops — same bounded pump the abono flow
  // uses before asserting a stream-driven change.
  await $.tester.pump(const Duration(milliseconds: 500));
  await $.tester.pumpAndSettle();
}

Future<void> _goBack(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Atrás'));
  await $.tester.pumpAndSettle();
}

Future<void> _switchTab(PatrolIntegrationTester $, String label) async {
  await $.tester.tap(find.text(label));
  await $.tester.pumpAndSettle();
}

void main() {
  patrolTest(
    'cerrar una deuda manualmente con saldo pendiente la saca de "Activas" y '
    'la deja en "Cerradas" con el saldo congelado',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createDebt($, name: 'Deuda pendiente', openingWhole: '600');

      // Still $600 pending, 0% paid: closing here must freeze exactly that.
      await _openOnlyDebt($);
      expect(find.text(r'$600'), findsWidgets);
      await _closeDebtManually($);

      // Still on the detail (closing is not a delete: no auto-pop), but the
      // fixed CTA disappears now that the debt is closed.
      expect(find.text('Registrar abono'), findsNothing);

      await _goBack($);

      // "Activas" is the list's default tab: the closed debt is gone from it.
      expect(find.text('Deuda pendiente'), findsNothing);

      await _switchTab($, 'Cerradas');
      expect(find.text('Deuda pendiente'), findsOneWidget);
      // Closed with a balance still pending => the "flag" "Cerrada · <fecha>"
      // badge, not the "check" "Pagada · <fecha>" one (`DebtClosedStatusBadge`
      // .settled` is false here — it never reached $0).
      expect(find.textContaining('Cerrada ·'), findsOneWidget);
      expect(find.textContaining('Pagada ·'), findsNothing);
      // The outstanding figure is frozen at the closing balance, not reset.
      expect(find.text(r'$600'), findsWidgets);

      final db = getIt<AppDatabase>();
      final row = await db.select(db.debts).getSingle();
      expect(row.closedAt, isNotNull);
      // Trash/undo is a different mechanism (`deletedAt`) — closing a debt is
      // a business-state change, not the papelera.
      expect(row.deletedAt, isNull);
      expect(row.tombstonedAt, isNull);
    },
  );

  patrolTest(
    'felicitación automática al saldar por completo: aparece con el copy de '
    'iOwe, "Completar" cierra la deuda',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createDebt($, name: 'Deuda chica', openingWhole: '500');

      await _openOnlyDebt($);
      // A full payoff crosses the balance to settled inside `_submitAbono`'s
      // own write, which fires the felicitación sheet automatically (see
      // `DebtDetailPage._handleSideEffects`) — no separate trigger step.
      await _registerCashlessAbono($, '500');

      // iOwe direction's copy (`debtCelebrationTitleIOwe`/dismiss/complete).
      expect(find.text('¡Felicidades! Ya no debes nada'), findsOneWidget);
      expect(find.textContaining('Terminaste de pagar Deuda chica'),
          findsOneWidget);
      expect(find.text('Total pagado'), findsOneWidget);
      expect(find.text('Duración'), findsOneWidget);
      expect(find.text('Ahora no'), findsOneWidget);
      expect(find.text('Completar'), findsOneWidget);

      await $.tester.tap(find.text('Completar'));
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // "Completar" runs the same `closeDebt()` the manual flow uses.
      expect(find.text('Registrar abono'), findsNothing);

      await _goBack($);
      expect(find.text('Deuda chica'), findsNothing);
      await _switchTab($, 'Cerradas');
      expect(find.text('Deuda chica'), findsOneWidget);
      // Fully settled before closing => "Pagada · <fecha>", not "Cerrada".
      expect(find.textContaining('Pagada ·'), findsOneWidget);

      final db = getIt<AppDatabase>();
      final row = await db.select(db.debts).getSingle();
      expect(row.closedAt, isNotNull);
    },
  );

  patrolTest(
    'felicitación al saldar en dirección "Me deben" usa el copy de cobro, no '
    'el de pago',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createDebt(
        $,
        name: 'Préstamo a Andrés',
        openingWhole: '300',
        direction: 'Me deben',
      );

      await _openOnlyDebt($);
      await _registerCashlessAbono($, '300');

      // owedToMe direction's distinct copy — cobro, not pago.
      expect(find.text('¡Felicidades! Ya no te deben nada'), findsOneWidget);
      expect(
        find.textContaining('Terminaste de cobrar Préstamo a Andrés'),
        findsOneWidget,
      );
      expect(find.text('Total cobrado'), findsOneWidget);
      // The iOwe-only stat label must not leak into this direction.
      expect(find.text('Total pagado'), findsNothing);
    },
  );

  patrolTest(
    '"Ahora no" en la felicitación deja la deuda saldada (100%) pero SIGUE '
    'en "Activas" hasta que se cierre explícitamente',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createDebt($, name: 'Deuda chica', openingWhole: '500');

      await _openOnlyDebt($);
      await _registerCashlessAbono($, '500');

      expect(find.text('¡Felicidades! Ya no debes nada'), findsOneWidget);
      await $.tester.tap(find.text('Ahora no'));
      await $.tester.pumpAndSettle();

      // Dismissed, not closed: the balance is settled (100%, $0) but the
      // fixed "Registrar abono" CTA is still there — an open debt's CTA,
      // never a closed one's.
      expect(find.text('100%'), findsOneWidget);
      expect(find.text(r'$0'), findsWidgets);
      expect(find.text('Registrar abono'), findsOneWidget);

      await _goBack($);
      // Still in "Activas" (the default tab).
      expect(find.text('Deuda chica'), findsOneWidget);
      await _switchTab($, 'Cerradas');
      expect(find.text('Deuda chica'), findsNothing);

      final db = getIt<AppDatabase>();
      final row = await db.select(db.debts).getSingle();
      expect(row.closedAt, isNull);
    },
  );

  patrolTest(
    'una deuda cerrada bloquea "Registrar abono" y "Actualizar saldo" en su '
    'detalle',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createDebt($, name: 'Deuda cerrada', openingWhole: '400');

      await _openOnlyDebt($);
      await _closeDebtManually($);

      // The fixed bottom CTA is gone entirely (not just disabled) —
      // `DebtDetailPage`'s `bottomNavigationBar` builder returns
      // `SizedBox.shrink()` once `debt.isClosed`.
      expect(find.text('Registrar abono'), findsNothing);

      // "Actualizar saldo" still renders (same row, same label) but wired to
      // a null `onTap` (`DebtMetaCard.onUpdateBalance`); tapping it must not
      // open the reconciliation sheet.
      expect(find.text('Actualizar saldo'), findsOneWidget);
      await $.tester.tap(find.text('Actualizar saldo'));
      await $.tester.pumpAndSettle();
      expect(find.text('Nuevo saldo'), findsNothing);

      // The ⋮ menu itself must still work on a closed debt — closing is not
      // the same as deleting, "Editar"/"Eliminar" both stay reachable.
      // `DebtActionsSheet` has no dedicated "Cancelar" of its own (dismissed
      // by tapping the scrim), so the scenario simply ends with it open.
      await _openActionsMenu($);
      expect(find.text('Editar deuda'), findsOneWidget);
      expect(find.text('Eliminar deuda'), findsOneWidget);
    },
  );

  patrolTest(
    'el tab "Cerradas" con varias deudas suma "Pagué" y "Me pagaron" solo '
    'sobre las cerradas, nunca sobre la que sigue activa',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);

      // Debt A (iOwe): abono $200 of $600, then closed manually with $400
      // still pending. Its contribution to "Pagué" is the $200 actually
      // paid, never the $600 opening or the $400 left owing.
      await _createDebt($, name: 'Deuda A', openingWhole: '600');
      await _openDebtByName($, 'Deuda A');
      await _registerCashlessAbono($, '200');
      await _closeDebtManually($);
      await _goBack($);

      // Debt B (iOwe): abonada por completo ($300 of $300) — settles, and
      // the felicitación's "Completar" closes it. Contributes $300 to
      // "Pagué", bringing the closed iOwe total to $200 + $300 = $500.
      await _createDebt($, name: 'Deuda B', openingWhole: '300');
      await _openDebtByName($, 'Deuda B');
      await _registerCashlessAbono($, '300');
      expect(find.text('¡Felicidades! Ya no debes nada'), findsOneWidget);
      await $.tester.tap(find.text('Completar'));
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();
      await _goBack($);

      // Debt C (owedToMe): abonada por completo ($250 of $250) — the ONLY
      // contributor to "Me pagaron", so its total must read exactly $250,
      // never mixed with the iOwe figures above.
      await _createDebt(
        $,
        name: 'Deuda C',
        openingWhole: '250',
        direction: 'Me deben',
      );
      await _openDebtByName($, 'Deuda C');
      await _registerCashlessAbono($, '250');
      expect(find.text('¡Felicidades! Ya no te deben nada'), findsOneWidget);
      await $.tester.tap(find.text('Completar'));
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();
      await _goBack($);

      // Debt D (iOwe): left untouched and active, $1.000 outstanding — this
      // must NOT leak into the "Cerradas" tab's summary at all.
      await _createDebt($, name: 'Deuda D', openingWhole: '1000');

      // "Activas" (default tab) only has Debt D now.
      expect(find.text('Deuda A'), findsNothing);
      expect(find.text('Deuda B'), findsNothing);
      expect(find.text('Deuda C'), findsNothing);
      expect(find.text('Deuda D'), findsOneWidget);

      await _switchTab($, 'Cerradas');
      expect(find.text('Deuda A'), findsOneWidget);
      expect(find.text('Deuda B'), findsOneWidget);
      expect(find.text('Deuda C'), findsOneWidget);
      expect(find.text('Deuda D'), findsNothing);

      // The closed-tab summary card: "Pagué" $500 (200+300, iOwe only),
      // "Me pagaron" $250 (owedToMe only) — scoped to
      // `DebtClosedSummaryCard` so this can never accidentally match the
      // still-open Debt D's $1.000 shown elsewhere on the same screen.
      final closedCard = find.byType(DebtClosedSummaryCard);
      expect(closedCard, findsOneWidget);
      expect(
        find.descendant(of: closedCard, matching: find.text(r'$500')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: closedCard, matching: find.text(r'$250')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: closedCard, matching: find.text(r'$1.000')),
        findsNothing,
      );

      final db = getIt<AppDatabase>();
      final closedDebts = await (db.select(db.debts)
            ..where((d) => d.closedAt.isNotNull()))
          .get();
      expect(closedDebts.length, 3);
      final activeDebts =
          await (db.select(db.debts)..where((d) => d.closedAt.isNull())).get();
      expect(activeDebts.length, 1);
      expect(activeDebts.single.name, 'Deuda D');
    },
  );
}
