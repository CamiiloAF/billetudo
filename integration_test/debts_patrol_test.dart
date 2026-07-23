// Patrol e2e for Deudas (HU-01 to HU-07, Fase 0). Runs the real app — real DI
// graph, real on-device Drift database, real go_router navigation — against a
// real emulator/simulator. No datasource or repository is mocked.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite file
// first (see `support/patrol_app.dart`), so scenarios do not leak state into
// each other even though they share one app process.
//
// Money entry here uses the debt/abono/actualizar-saldo *héroe* field
// (`DebtAmountHeroField`), a plain `TextField` + `MoneyInputFormatter` the app
// types into with the system keyboard — NOT the anchored calculator keypad the
// transaction / scheduled-payment forms use. So amounts are entered with
// `enterText`, exactly like `accounts_patrol_test.dart` seeds an account
// balance (`enterText('500000')` renders `$500.000`). Storage is always 1/100
// (cents) whatever the currency (`MoneyFormatter._minorPerMajor`), and COP is
// shown with no decimals (`MoneyFormatter.currencyDecimals('COP') == 0`), so
// `enterText('600')` reads as `$600` and stores `60000` minor. Every figure
// here stays a plain, separator-free number under 1.000 so the rendered string
// is unambiguous (`$600`, `$200`, …), except where a grouped total is the point
// (the ledger scenario's `$1.000`).
//
// The debt detail's read screens are plain `ListView`s (hero, meta card, cuota
// card, ledger), so a row below the fold can be discarded by the sliver's cache
// extent — `_scrollUntilVisible` drags it back into view before asserting,
// same reasoning as `scheduled_payments_patrol_test.dart`.
import 'dart:async';

import 'package:billetudo/core/database/app_database.dart' hide CategoryKind;
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/debts/presentation/widgets/debt_amount_hero_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_cash_switch.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_form_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_ledger_row.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_payment_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Opens Deudas via `GoRouter.push`: like Pagos programados, this feature has
/// no bottom-tab entry of its own (`HomeTabBar`'s 5 tabs are Inicio/Movimientos
/// /Presupuestos/Metas/Más) — its entry points are Inicio's quick-access chip
/// and the "Más" hub tile. Pushing the route directly is deterministic
/// regardless of which tab a prior helper navigated to, same reasoning as
/// `scheduled_payments_patrol_test.dart`'s `_goToScheduledPayments` (a single
/// root `Navigator`, one pop lands back here).
void _goToDebts(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.debts));
}

/// Navigates to `/cuentas` and creates one cash account named [name]. `go`,
/// not a UI tap through a hub — same reasoning as
/// `scheduled_payments_patrol_test.dart`'s `_createCashAccount`.
Future<void> _createCashAccount(PatrolIntegrationTester $, String name) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.accounts);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byTooltip('Agregar cuenta'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Efectivo'));
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField).first, name);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byTooltip('Guardar'));
  await $.tester.pumpAndSettle();
}

/// Creates a root category of [kind] from `/categorias`, same flow as
/// `transactions_patrol_test.dart`'s `_createCategory`. A cash abono attributes
/// to a category of the direction-derived kind (expense for "Yo debo", income
/// for "Me deben"), but the category is optional there — this is only needed
/// when a scenario picks one.
Future<void> _createCategory(
  PatrolIntegrationTester $,
  String name, {
  CategoryKind kind = CategoryKind.expense,
}) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.categories);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byTooltip('Crear categoría'));
  await $.tester.pumpAndSettle();
  if (kind == CategoryKind.income) {
    await $.tester.tap(find.text('Ingreso'));
    await $.tester.pumpAndSettle();
  }
  await $.tester.enterText(find.byType(TextFormField), name);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byIcon(LucideIcons.check));
  await $.tester.pumpAndSettle();
}

/// Opens the crear-deuda form from the list. `find.byTooltip('Agregar deuda')`
/// resolves to the `PageHeader`'s circle button only — the empty-state CTA
/// carries the same label as plain button text, never a `Tooltip`, so this is
/// unambiguous whether the list is empty or already has debts.
Future<void> _openNewDebtForm(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Agregar deuda'));
  await $.tester.pumpAndSettle();
}

/// Types [value] into the one `DebtAmountHeroField` on screen (the form's boxed
/// opening-balance héroe, or the abono / actualizar-saldo sheet's héroe — never
/// more than one is mounted at a time, and the detail behind a sheet has none).
/// Clears the field first so an edit that shortens the figure never trips
/// `MoneyInputFormatter`'s single-char-backspace guard on a full-text replace
/// (documented in `docs/patrol-e2e-tracking.md`, Presupuestos note 6).
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

/// Types [name] into the crear/editar form's "Nombre" field. Matches by the
/// field's own label rather than a `ValueKey` (which embeds the debt id, unknown
/// when editing) or a bare `TextFormField` index (the form has several): find
/// the label `Text`, then its `DebtFormField` ancestor, then the input inside.
Future<void> _enterDebtName(PatrolIntegrationTester $, String name) async {
  final field = find.descendant(
    of: find
        .ancestor(
          of: find.text('Nombre'),
          matching: find.byType(DebtFormField),
        )
        .first,
    matching: find.byType(TextFormField),
  );
  await $.tester.enterText(field, name);
  await $.tester.pumpAndSettle();
}

/// Picks a direction on the form's toggle. "Yo debo" / "Me deben" are the two
/// segment labels; on the form only the toggle renders them, so a plain text
/// tap is unambiguous.
Future<void> _selectDirection(PatrolIntegrationTester $, String label) async {
  await $.tester.tap(find.text(label));
  await $.tester.pumpAndSettle();
}

/// Submits the crear/editar form via its fixed bottom CTA. "Crear deuda" when
/// creating, "Guardar cambios" when editing — each unique on its page.
Future<void> _submitDebtForm(
  PatrolIntegrationTester $, {
  required bool editing,
}) async {
  await $.tester.tap(find.text(editing ? 'Guardar cambios' : 'Crear deuda'));
  await $.tester.pumpAndSettle();
}

/// Opens the only `DebtCard` on the list to its detail. Every scenario creates
/// exactly one debt before calling this, so the single card unambiguously is
/// the one to open (same reasoning as `transactions_patrol_test.dart`'s
/// `_openOnlyTransaction`).
Future<void> _openOnlyDebt(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byType(DebtCard));
  await $.tester.pumpAndSettle();
}

/// Opens the abono sheet from the detail's fixed bottom bar. Before the sheet
/// is up, "Registrar abono" reads once (the bar's button); it also becomes the
/// sheet's own header + CTA once open, so this must run before those exist.
Future<void> _openAbonoSheet(PatrolIntegrationTester $) async {
  await $.tester.tap(find.text('Registrar abono'));
  await $.tester.pumpAndSettle();
}

/// Sets the abono sheet's "¿Agregar a una cuenta?" toggle to [addToAccount].
/// Reads the current state by whether the revealed `DebtSelectedAccountRow` is
/// mounted (it shows only when the toggle is on), and taps the `DebtCashSwitch`
/// only when it must change — never a blind tap that could flip the wrong way.
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

/// Submits the abono sheet. Both the sheet's CTA and the detail's bottom bar
/// read "Registrar abono", so text is ambiguous while the sheet is open — the
/// sheet's CTA is the only `LucideIcons.check` in the tree at that moment (the
/// bottom bar uses `plus`), scoped to `DebtPaymentSheetBody` for safety.
Future<void> _submitAbono(PatrolIntegrationTester $) async {
  await $.tester.tap(
    find.descendant(
      of: find.byType(DebtPaymentSheetBody),
      matching: find.byIcon(LucideIcons.check),
    ),
  );
  // The submit (the cash `Transaction`/`DebtEntry` write), the sheet pop, and
  // the detail's Drift stream re-emitting the new balance are separate async
  // hops; `pumpAndSettle` alone races the DB round trip (the abono lands but the
  // rebuilt detail lags a frame). Same bounded pump the delete flow and
  // `accounts_patrol_test.dart`'s HU-08 already use before asserting a
  // stream-driven change.
  await $.tester.pumpAndSettle();
  await $.tester.pump(const Duration(milliseconds: 500));
  await $.tester.pumpAndSettle();
}

/// Drags the nearest `Scrollable` until [finder] is on screen — the detail is a
/// plain `ListView`, so ledger rows below the fold may not be built yet.
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

void main() {
  patrolTest(
    'HU-01: crear una deuda "Yo debo" la deja en la lista con su saldo y avance',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      expect(find.text('Aún no tienes deudas registradas'), findsOneWidget);

      await _openNewDebtForm($);
      expect(find.text('Nueva deuda'), findsOneWidget);

      // Direction defaults to "Yo debo" (`DebtFormState.direction`); tap it
      // anyway to exercise the toggle explicitly.
      await _selectDirection($, 'Yo debo');
      await _enterHeroAmount($, '600'); // $600 COP
      await _enterDebtName($, 'Crédito carro');
      await _submitDebtForm($, editing: false);

      // Back on the list (the form pops on save; the list stream refreshes on
      // its own). The new card shows its name, outstanding balance and 0%
      // paid — nothing has been abonado yet.
      expect(find.text('Crédito carro'), findsOneWidget);
      expect(find.text(r'$600'), findsWidgets);
      expect(find.text('0% pagado'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-01: crear una deuda "Me deben" la deja con avance de cobro (dirección '
    'inversa)',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);

      await _selectDirection($, 'Me deben');
      await _enterHeroAmount($, '800'); // $800 COP
      await _enterDebtName($, 'Préstamo a Andrés');
      await _submitDebtForm($, editing: false);

      // An "owedToMe" debt reads its progress as *cobrado*, not *pagado*
      // (`DebtFormat.progressLabel`) — the direction changes the copy, never
      // just a color.
      expect(find.text('Préstamo a Andrés'), findsOneWidget);
      expect(find.text('0% cobrado'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-02: registrar un abono con caja (toggle Sí) baja el saldo y mueve una '
    'cuenta',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _enterHeroAmount($, '600'); // $600 COP
      await _enterDebtName($, 'Crédito carro');
      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);
      await _openAbonoSheet($);

      await _enterHeroAmount($, '200'); // $200 COP abono
      // With one account, `DebtPaymentCubit.start` preselects it and the toggle
      // defaults to "Sí"; assert it is on rather than assuming.
      await _setCashToggle($, addToAccount: true);
      expect(find.byType(DebtSelectedAccountRow), findsOneWidget);
      await _submitAbono($);

      // Detail updates on its stream: outstanding dropped $600 -> $400, and the
      // unified ledger now carries a cash "Abono a la deuda" row (iOwe
      // direction) on top of the opening row.
      expect(find.text(r'$400'), findsWidgets);
      await _scrollUntilVisible($, find.text('Abono a la deuda'));
      expect(find.text('Abono a la deuda'), findsOneWidget);
      expect(find.text('Saldo de apertura'), findsOneWidget);

      // Cash abono => exactly one `Transaction`, carrying the debt id and the
      // abono amount in cents ($200 -> 20000 minor). Asserted against the real
      // DB, never inferred from the UI.
      final db = getIt<AppDatabase>();
      final txns = await db.select(db.transactions).get();
      expect(txns.length, 1);
      expect(txns.single.debtId, isNotNull);
      expect(txns.single.amountMinor, 20000);
    },
  );

  patrolTest(
    'HU-02: registrar un abono sin caja (toggle No) baja el saldo pero no mueve '
    'ninguna cuenta',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _enterHeroAmount($, '600'); // $600 COP
      await _enterDebtName($, 'Deuda con Sara');
      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);
      await _openAbonoSheet($);

      await _enterHeroAmount($, '150'); // $150 COP abono
      await _setCashToggle($, addToAccount: false);
      // Toggle off hides the account row: the abono is a cash-less ledger entry.
      expect(find.byType(DebtSelectedAccountRow), findsNothing);
      await _submitAbono($);

      // Outstanding still drops $600 -> $450, and the cash-less abono row wears
      // the "No afecta cuentas" tag.
      expect(find.text(r'$450'), findsWidgets);
      // Scroll to the abono row by its (unique) title, NOT by the tag: the
      // opening row is also a solo-deuda entry (`isCashEvent == false`), so
      // `DebtFormat.ledgerTag` gives it the SAME "No afecta cuentas" tag — a
      // bare `find.text('No afecta cuentas')` matches BOTH rows, which is what
      // tripped `dragUntilVisible` with "Too many elements". "Abono a la deuda"
      // names only this one row.
      await _scrollUntilVisible($, find.text('Abono a la deuda'));
      expect(find.text('Abono a la deuda'), findsOneWidget);
      // Assert the tag scoped to the abono's own `DebtLedgerRow` so the check
      // stays a true, unique statement about the abono without pretending the
      // opening row does not also carry it (it legitimately does — an opening
      // balance moves no account either).
      final abonoRow = find.ancestor(
        of: find.text('Abono a la deuda'),
        matching: find.byType(DebtLedgerRow),
      );
      expect(
        find.descendant(of: abonoRow, matching: find.text('No afecta cuentas')),
        findsOneWidget,
      );

      // No `Transaction` was created — that is the whole point of "sin caja".
      final db = getIt<AppDatabase>();
      final txns = await db.select(db.transactions).get();
      expect(txns, isEmpty);
    },
  );

  patrolTest(
    'HU-02: un abono a una deuda "Me deben" también baja el saldo (registrado '
    'como pago recibido)',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _selectDirection($, 'Me deben');
      await _enterHeroAmount($, '900'); // $900 COP
      await _enterDebtName($, 'Préstamo a Andrés');
      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);
      await _openAbonoSheet($);
      await _enterHeroAmount($, '300'); // $300 COP recibido
      await _setCashToggle($, addToAccount: true);
      await _submitAbono($);

      // Reducing an owedToMe debt is a "Pago recibido", not an "Abono a la
      // deuda" (`DebtFormat.ledgerTitle` swaps on direction); the outstanding
      // still falls $900 -> $600.
      expect(find.text(r'$600'), findsWidgets);
      await _scrollUntilVisible($, find.text('Pago recibido'));
      expect(find.text('Pago recibido'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-02: enlazar un movimiento existente lo atribuye a la deuda y baja el '
    'saldo',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Cuotas');

      // Seed a real expense against the same on-device Drift DB the app reads
      // from (same technique as `transactions_patrol_test.dart`'s HU-04 caso
      // 2). $200 -> 20000 minor. It is a plain movement until it is linked.
      final db = getIt<AppDatabase>();
      final account = await (db.select(db.accounts)
            ..where((a) => a.name.equals('Efectivo')))
          .getSingle();
      final category = await (db.select(db.categories)
            ..where((c) => c.name.equals('Cuotas')))
          .getSingle();
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: account.id,
              categoryId: Value(category.id),
              amountMinor: 20000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime.now(),
              note: const Value('Pago cuota banco'),
            ),
          );

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _enterHeroAmount($, '600'); // $600 COP
      await _enterDebtName($, 'Crédito carro');
      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);
      await _openAbonoSheet($);
      // The "¿Ya lo registraste? Enlaza un movimiento" escape hatch closes the
      // sheet and jumps into Movimientos in link mode (`DebtLinkModePage`).
      await $.tester.tap(find.byType(DebtLinkExistingButton));
      await $.tester.pumpAndSettle();

      // Movimientos is now in link mode: the banner names the debt and every
      // row tap attributes that movement to it.
      expect(find.textContaining('Enlazar a'), findsOneWidget);
      await $.tester.tap(find.textContaining('Pago cuota banco'));
      await $.tester.pumpAndSettle();

      // Linking pops back to the debt detail (its stream picks up the movement
      // now carrying the debt id). Outstanding drops $600 -> $400.
      expect(find.text(r'$400'), findsWidgets);

      // Attribution is a `debtId` set on the existing row (never a new
      // movement): still one transaction, now linked.
      final txns = await db.select(db.transactions).get();
      expect(txns.length, 1);
      expect(txns.single.debtId, isNotNull);
    },
  );

  patrolTest(
    'HU-06: actualizar saldo registra el ajuste de reconciliación y refleja la '
    'cifra nueva',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _enterHeroAmount($, '600'); // $600 COP
      await _enterDebtName($, 'Tarjeta');
      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);
      // The meta card's "Actualizar saldo" row opens the reconciliation sheet.
      await $.tester.tap(find.text('Actualizar saldo'));
      await $.tester.pumpAndSettle();
      expect(find.text('Nuevo saldo'), findsOneWidget);

      await _enterHeroAmount($, '520'); // reconcile to $520 COP
      await $.tester.tap(find.text('Guardar saldo'));
      await $.tester.pumpAndSettle();

      // Outstanding now reads the reconciled figure, and the ledger has a
      // "Saldo actualizado" adjustment row.
      expect(find.text(r'$520'), findsWidgets);
      await _scrollUntilVisible($, find.text('Saldo actualizado'));
      expect(find.text('Saldo actualizado'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-07: abonar hasta 0 marca la deuda como saldada (100%, saldo \$0)',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _enterHeroAmount($, '500'); // $500 COP
      await _enterDebtName($, 'Deuda chica');
      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);
      await _openAbonoSheet($);
      await _enterHeroAmount($, '500'); // full payoff
      await _setCashToggle($, addToAccount: true);
      await _submitAbono($);

      // Settled: the raw balance hit 0 (`DebtBalance.settled`), so outstanding
      // reads $0 and the hero percentage reaches 100%.
      expect(find.text(r'$0'), findsWidgets);
      expect(find.text('100%'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-05: editar una deuda actualiza su nombre y saldo de apertura',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _enterHeroAmount($, '600'); // $600 COP
      await _enterDebtName($, 'Crédito viejo');
      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);
      // The detail header's pencil opens the editar form.
      await $.tester.tap(find.byTooltip('Editar deuda'));
      await $.tester.pumpAndSettle();
      expect(find.text('Editar deuda'), findsOneWidget);

      await _enterDebtName($, 'Crédito nuevo');
      await _enterHeroAmount($, '750'); // $750 COP
      await _submitDebtForm($, editing: true);

      // Editing pops back to the detail (the form's `Navigator.pop` on save):
      // the renamed debt and its new opening balance show there.
      expect(find.text('Crédito nuevo'), findsOneWidget);
      expect(find.text(r'$750'), findsWidgets);
    },
  );

  patrolTest(
    'HU-05: eliminar una deuda pide confirmación y la saca de la vista activa',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _enterHeroAmount($, '600'); // $600 COP
      await _enterDebtName($, 'Deuda a borrar');
      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);
      await $.tester.tap(find.byTooltip('Editar deuda'));
      await $.tester.pumpAndSettle();

      // The "Eliminar deuda" link lives at the bottom of the editar form; drag
      // it into view first (the form is a plain `ListView`).
      await _scrollUntilVisible($, find.text('Eliminar deuda'));
      await $.tester.tap(find.text('Eliminar deuda'));
      await $.tester.pumpAndSettle();

      // Reversible-reading copy (`deletedAt`, papelera/undo): the confirm sheet
      // says it can be recovered — no guilt, no finality.
      expect(find.text('¿Eliminar esta deuda?'), findsOneWidget);
      await $.tester.tap(find.text('Cancelar'));
      await $.tester.pumpAndSettle();
      // Still on the editar form after cancelling.
      expect(find.text('Editar deuda'), findsOneWidget);

      await _scrollUntilVisible($, find.text('Eliminar deuda'));
      await $.tester.tap(find.text('Eliminar deuda'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar'));
      // The delete (`deletedAt`), the form pop (with `true`), the detail pop
      // it triggers, and the list stream removing the row are separate async
      // hops; `pumpAndSettle` alone can race the DB round trip — same bounded
      // pump as `accounts_patrol_test.dart`'s HU-08.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // Back on the list, the trashed debt is gone from the active view; the
      // empty state is shown again since it was the only one.
      expect(find.text('Deuda a borrar'), findsNothing);
      expect(find.text('Aún no tienes deudas registradas'), findsOneWidget);

      // Trash/undo => `deletedAt`, never `tombstonedAt` (CLAUDE.md's borrado
      // rule — a debt is restorable by design).
      final db = getIt<AppDatabase>();
      final row = await db.select(db.debts).getSingle();
      expect(row.deletedAt, isNotNull);
      expect(row.tombstonedAt, isNull);
    },
  );

  patrolTest(
    'Ledger completo: apertura + abono con caja + abono sin caja + ajuste se '
    'listan y el saldo corrido refleja todo',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _enterHeroAmount($, '1000'); // $1.000 COP opening
      await _enterDebtName($, 'Historial');
      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);

      // Cash abono $200 -> $800.
      await _openAbonoSheet($);
      await _enterHeroAmount($, '200');
      await _setCashToggle($, addToAccount: true);
      await _submitAbono($);
      expect(find.text(r'$800'), findsWidgets);

      // Cash-less abono $100 -> $700.
      await _openAbonoSheet($);
      await _enterHeroAmount($, '100');
      await _setCashToggle($, addToAccount: false);
      await _submitAbono($);
      expect(find.text(r'$700'), findsWidgets);

      // Reconcile to $650 (an adjustment of -$50).
      await $.tester.tap(find.text('Actualizar saldo'));
      await $.tester.pumpAndSettle();
      await _enterHeroAmount($, '650');
      await $.tester.tap(find.text('Guardar saldo'));
      await $.tester.pumpAndSettle();
      expect(find.text(r'$650'), findsWidgets);

      // The unified ledger lists every kind of event: the opening, two abonos
      // (both "Abono a la deuda" for an iOwe debt) and the reconciliation.
      await _scrollUntilVisible($, find.text('Saldo actualizado'));
      expect(find.text('Saldo de apertura'), findsOneWidget);
      expect(find.text('Abono a la deuda'), findsNWidgets(2));
      expect(find.text('Saldo actualizado'), findsOneWidget);
      // Four ledger rows landed (opening + 2 abonos + adjustment).
      expect(find.byType(DebtLedgerRow), findsNWidgets(4));
    },
  );

  patrolTest(
    'Interés automático: una deuda con tasa en modo auto muestra el crecimiento '
    'diario estimado',
    ($) async {
      await startApp($);

      _goToDebts($);
      await $.tester.pumpAndSettle();
      await _openNewDebtForm($);
      await _enterHeroAmount($, '900'); // $900 COP principal
      await _enterDebtName($, 'Préstamo con interés');

      // Interés anual + modo Automático (the accrual estimates a daily growth
      // over a positive balance).
      //
      // Scroll by the field's `ValueKey` (`rate-new` while creating — see
      // `debt_form_page.dart`), never by a compound finder ending in `.first`:
      // the rate row is below the fold and outside the cache extent at first, so
      // `find.text('Interés anual (opcional)')` matches 0 elements, and
      // `find.ancestor(...).first` THROWS "No element" instead of returning
      // empty — which killed `dragUntilVisible` on its first iteration before it
      // could drag the row into existence. `find.byKey` returns empty (never
      // throws) when the row is not built yet, so the drag iterates until it is.
      final rateFieldRow = find.byKey(const ValueKey('rate-new'));
      await _scrollUntilVisible($, rateFieldRow);
      // Now that the row is built and on screen, resolve the inner input for
      // `enterText`.
      final rateField = find.descendant(
        of: rateFieldRow,
        matching: find.byType(TextFormField),
      );
      await $.tester.enterText(rateField, '24'); // 24% annual
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Automático'));
      await $.tester.pumpAndSettle();

      await _submitDebtForm($, editing: false);

      await _openOnlyDebt($);

      // The meta card's growth line only renders when the debt accrues
      // automatically over a positive balance (`DebtDetailState
      // .dailyGrowthMinor`): "Crece ~$X/día" with an "estimado" tag.
      //
      // No scroll here. The meta card is the SECOND item of the detail's
      // `ListView` (right under the hero) and, with no counterparty/due date,
      // the growth row is its first row — it sits near the top, well inside the
      // sliver's build area at offset 0, so both `Text`s are built at page
      // load. The old `_scrollUntilVisible($, find.text('estimado'))` dragged
      // the content UP (`Offset(0, -220)` reveals what is BELOW the fold),
      // pushing this top-of-page tag off the top edge and never bringing it
      // back, so `dragUntilVisible` exhausted its iterations and threw
      // "No element". A `findsOneWidget` needs the widget built, not
      // pixel-visible, so the direct assertion is both correct and robust.
      // (`debtDetailEstimated` is lowercase "estimado"; the ledger interest tag
      // `debtLedgerTagEstimated` is "Estimado", so there is no collision even if
      // an accrual row existed.)
      expect(find.textContaining('Crece'), findsOneWidget);
      expect(find.text('estimado'), findsOneWidget);
    },
  );
}
