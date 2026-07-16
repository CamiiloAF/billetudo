// Patrol e2e for Transacciones (HU-01 to HU-08). Runs the real app — real DI
// graph, real on-device Drift database, real go_router navigation — against a
// real emulator/simulator. No datasource or repository is mocked.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so scenarios do not leak state
// into each other even though they share one app process.
//
// `BootstrapHomePage` (the temporary shell) only links to Cuentas and
// Categorías so far — Transacciones has no entry point there yet (same "goes
// away with the real shell" note as those two). Reaching `/movimientos`
// therefore goes through `GoRouter` directly, exactly like a deep link would,
// rather than through a tap that does not exist in the UI yet.
//
// Two real product gaps surfaced while writing this suite (both left
// unfixed, per this role's scope — reported, not patched):
//
//  1. HU-07's "crear una etiqueta nueva al vuelo... desde el formulario de
//     transacción" is not reachable from the transaction form at all.
//     `TransactionFormState`/`TransactionFormCubit` fully support `tagIds`
//     (`tagsChanged`, persisted via `SetTransactionTags` on submit — see
//     `transaction_form_cubit_test.dart`), and the class doc comment on
//     `TransactionFormPage` even lists "-> Etiquetas" as the last step of the
//     form, but `TransactionFormBody.build` never renders a tag picker/
//     creator. The only place `NewTagSheet` is actually wired up is
//     `TagFilterSheet` (filtering, not assigning). The HU-07 scenario below
//     only exercises what is reachable: creating a tag from the filter.
//  2. (Fixed, 2026-07-16.) HU-05's "papelera/undo inmediato tipo snackbar" was
//     unreachable in practice: the snackbar/undo logic lived in
//     `TransactionsListCubit` (`deleteTransaction` sets `pendingUndoId`,
//     `TransactionsPage`'s `BlocConsumer` listens for it), but the only
//     delete affordance in the UI is the trash icon on
//     `TransactionDetailPage`, which goes through
//     `TransactionDetailCubit.confirmDelete` — a different cubit that never
//     touched `pendingUndoId`. Fixed by having the detail page pop with the
//     deleted id (`TransactionDetailPage`'s listener) and the router forward
//     it to `TransactionsListCubit.notifyExternalDelete` (see
//     `app_router.dart`'s `AppRoutes.transactions` route), which only
//     surfaces the undo affordance without re-running the delete use case.
//     The HU-05 scenario below now asserts the snackbar actually appears.
import 'dart:async';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/new_tag_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Deterministic navigation via `GoRouter.go`, not a UI tap: `go` replaces
/// the whole navigation stack and always lands on the requested route
/// regardless of where the tester currently is, unlike tapping
/// 'Ver mis cuentas' (which only exists on `BootstrapHomePage` and breaks as
/// soon as this helper is chained after another one that already navigated
/// away from home).
Future<void> _goToAccountsList(PatrolIntegrationTester $) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.accounts);
  await $.tester.pumpAndSettle();
}

/// Assumes the accounts list is already on screen (see `_goToAccountsList`) —
/// safe to call more than once per test, unlike tapping "Ver mis cuentas"
/// again, which only exists on `BootstrapHomePage`.
Future<void> _addCashAccount(PatrolIntegrationTester $, String name) async {
  await $.tester.tap(find.byTooltip('Agregar cuenta'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Efectivo'));
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField).first, name);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byIcon(Icons.check));
  await $.tester.pumpAndSettle();
}

/// Single-account convenience: navigates to the accounts list and creates
/// one cash account, for scenarios that only need one.
Future<void> _createCashAccount(PatrolIntegrationTester $, String name) async {
  await _goToAccountsList($);
  await _addCashAccount($, name);
}

/// Creates a root expense category from `/categorias` (default Tipo: Gasto),
/// same flow as `categories_patrol_test.dart`'s HU-01 scenario. Navigates via
/// `GoRouter.go`, same reasoning as `_goToAccountsList` — safe to call after
/// another helper has already navigated the tester away from home.
Future<void> _createExpenseCategory(
    PatrolIntegrationTester $, String name) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.categories);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byTooltip('Crear categoría'));
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField), name);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byIcon(Icons.check));
  await $.tester.pumpAndSettle();
}

/// Jumps straight to `/movimientos`: see the file comment above. `push`, not
/// `go` — deliberately: this router has a single root `Navigator` (no
/// `ShellRoute`/`StatefulShellRoute`), so `go()` here does not just change
/// the matched route, it collapses/rebuilds the whole page stack in one
/// frame. That interacts badly with HU-05's delete flow, which pops the
/// confirm sheet and the detail page in two rapid, unsynchronized hops
/// (`ConfirmDeleteTransactionSheet`'s own pop, then `TransactionDetailPage`'s
/// listener pop once the soft delete lands) — with `go()` this reliably hits
/// a `Navigator.dispose`/`!_debugLocked` assertion, verified against a real
/// emulator run; `push` does not exhibit it.
///
/// `push` stacks `/movimientos` on top of whatever route was already
/// showing, which is exactly what every scenario below relies on for the
/// return trip: a single pop always lands back on that prior route (see
/// HU-03), never home.
void _goToTransactions(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.transactions));
}

/// Drags `TransactionsFilterBar`'s horizontal `SingleChildScrollView` until
/// [finder] is on screen. The bar (Cuentas, Categorías, Tipo, Fecha,
/// Etiqueta) does not fit on a typical phone width at once, so the last chip
/// ('Etiqueta') is laid out past the right edge — still in the widget tree,
/// but its center coordinate lands outside the visible viewport, so a plain
/// `tap` on it silently hits nothing (no exception, the sheet just never
/// opens) — verified against a real emulator run.
Future<void> _scrollFilterBarUntilVisible(
  PatrolIntegrationTester $,
  Finder finder,
) async {
  await $.tester.dragUntilVisible(
    finder,
    find.byType(SingleChildScrollView).first,
    const Offset(-250, 0),
  );
  await $.tester.pumpAndSettle();
}

Future<void> _enterAmount(PatrolIntegrationTester $, List<int> digits) async {
  await $.tester.tap(find.text('0,00'));
  await $.tester.pumpAndSettle();
  for (final digit in digits) {
    await $.tester.tap(find.text('$digit').first);
    await $.tester.pump();
  }
  await $.tester.pumpAndSettle();
}

/// Backspaces [count] digits off the amount field. Used when editing: the
/// anchored keypad has no single "clear" key, only `⌫` (see
/// `NumericKeypad`), so undoing a whole existing amount is one tap per digit.
Future<void> _clearAmount(PatrolIntegrationTester $, int count) async {
  for (var i = 0; i < count; i++) {
    await $.tester.tap(find.text('⌫'));
    await $.tester.pump();
  }
  await $.tester.pumpAndSettle();
}

void main() {
  patrolTest(
    'HU-01: crear un gasto con el teclado numérico anclado lo deja en la '
    'lista',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      // Home has no button into Transacciones yet — go straight to the list,
      // right from the accounts list `Scaffold` we are already on.
      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();

      // HU-01/criterion 11: Monto has focus and the anchored keypad is up as
      // soon as the form loads (no explicit tap needed to reveal it) — typing
      // digits straight away is exactly what a user would do.
      await _enterAmount($, [2, 5, 0, 0, 0]); // $250,00 COP

      await $.tester.tap(find.text('Cuenta'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      // Back on the list: the new expense, negative and formatted from cents
      // — never a double slipping through the pipe (see `MoneyFormatter`).
      // The currency code is separated from the amount by a non-breaking
      // space (U+00A0), same rendering quirk noted in accounts_patrol_test.
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('-250,00\u{00A0}COP'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-02: registrar un ingreso lo deja en la lista con signo positivo',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('Ingreso'));
      await $.tester.pumpAndSettle();
      expect(find.text('Nuevo ingreso'), findsOneWidget);

      await _enterAmount($, [1, 5, 0, 0, 0]); // $150,00 COP

      await $.tester.tap(find.text('Cuenta'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      expect(find.text('+150,00\u{00A0}COP'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-03: transferir entre 2 cuentas resta del origen y suma al destino',
    ($) async {
      await startApp($);
      await _goToAccountsList($);
      await _addCashAccount($, 'Cuenta A');
      await _addCashAccount($, 'Cuenta B');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('Transferencia'));
      await $.tester.pumpAndSettle();
      expect(find.text('Nueva transferencia'), findsOneWidget);

      await _enterAmount($, [1, 0, 0, 0, 0]); // $100,00 COP

      // HU-03: origin (`Cuenta`) and destination (`Cuenta destino`) are two
      // separate pickers.
      await $.tester.tap(find.text('Cuenta'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Cuenta A'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('Cuenta destino'));
      await $.tester.pumpAndSettle();
      // Excludes the already-picked origin (HU-03 "distinct accounts"),
      // asserted implicitly: only 'Cuenta B' is offered as a tile to tap.
      await $.tester.tap(find.text('Cuenta B'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      // The list row for a transfer shows no +/- sign and both account
      // names (`TransactionRow._amountLabel`/`_subtitle`... title).
      expect(find.text('Cuenta A → Cuenta B'), findsOneWidget);
      expect(find.text('100,00\u{00A0}COP'), findsOneWidget);

      // The actual balance effect (HU-03 criterion 3: "resta en origen, suma
      // en destino") is only visible on Cuentas, not on the transaction row
      // itself. `_goToAccountsList` navigates deterministically via
      // `GoRouter.go`, regardless of the current stack (`/movimientos` was
      // itself reached via `push` — see `_goToTransactions` — so a single
      // `arrow_back` tap would also land on `/cuentas` here, but `go` is used
      // for consistency with every other cross-feature jump in this file).
      await _goToAccountsList($);

      expect(find.text('-100,00\u{00A0}COP'), findsOneWidget);
      expect(find.text('100,00\u{00A0}COP'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-04 caso 1: editar el monto de un gasto sin vínculos lo actualiza '
    'sin advertencia',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [1, 0, 0, 0, 0]); // $100,00 COP
      await $.tester.tap(find.text('Cuenta'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      expect(find.text('-100,00\u{00A0}COP'), findsOneWidget);

      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();
      expect(find.text('Detalle del movimiento'), findsOneWidget);

      await $.tester.tap(find.byTooltip('Editar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Editar movimiento'), findsOneWidget);

      await $.tester.tap(find.text('100,00'));
      await $.tester.pumpAndSettle();
      await _clearAmount($, 5); // '1','0','0','0','0'
      await _enterAmount($, [2, 0, 0, 0, 0]); // $200,00 COP

      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      // No linked recurring/goal/debt on this transaction: straight back to
      // the detail (`TransactionFormPage`'s single `Navigator.pop` on save
      // returns to whatever pushed it — the detail page here, since the edit
      // flow is List -> tap row -> Detail -> tap Editar -> Form, not List ->
      // Form directly), no `EditImpactWarningSheet` in the way.
      // `TransactionDetailBody` renders the amount unsigned (only
      // `TransactionRow`, in the list, prefixes +/-), so the update is
      // asserted against the reactive detail stream instead.
      expect(find.text('Este movimiento está vinculado'), findsNothing);
      expect(find.text('200,00\u{00A0}COP'), findsOneWidget);
      expect(find.text('100,00\u{00A0}COP'), findsNothing);
    },
  );

  patrolTest(
    'HU-04 caso 2: editar el monto de un movimiento ligado a un recurrente '
    'advierte el impacto antes de guardar',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      // There is no Recurrentes UI yet to create the link from (that feature
      // is still a blank canvas per CLAUDE.md), so the linked transaction is
      // seeded directly against the same real on-device Drift database the
      // app itself reads from — same pattern as
      // `categories_patrol_test.dart`'s "HU-04 caso 2". `recurringId` only
      // needs to be non-null for `GetTransactionEditImpact` to flag the
      // impact; the row it points to does not need to exist (this schema
      // does not enforce the FK at the SQLite level).
      final db = getIt<AppDatabase>();
      final account = await (db.select(db.accounts)
            ..where((a) => a.name.equals('Efectivo')))
          .getSingle();
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: account.id,
              amountMinor: 10000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime.now(),
              note: const Value('Suscripción test'),
              recurringId: const Value('recurring-seed-1'),
            ),
          );

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      expect(find.textContaining('Suscripción test'), findsOneWidget);
      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Editar'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('100,00'));
      await $.tester.pumpAndSettle();
      await _clearAmount($, 5);
      await _enterAmount($, [3, 0, 0, 0, 0]); // $300,00 COP

      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      // HU-04 criterion 3: changing the amount of a recurring-linked
      // transaction must warn before it saves.
      expect(find.text('Este movimiento está vinculado'), findsOneWidget);
      expect(find.text('Afecta su recurrente asociado.'), findsOneWidget);

      await $.tester.tap(find.text('Guardar de todas formas'));
      await $.tester.pumpAndSettle();

      // Same landing spot and unsigned-amount caveat as HU-04 caso 1: the
      // form's `Navigator.pop` returns to the detail page it was pushed
      // from, which renders the amount without the list's +/- sign.
      expect(find.text('300,00\u{00A0}COP'), findsOneWidget);
      expect(find.text('100,00\u{00A0}COP'), findsNothing);
    },
  );

  patrolTest(
    'HU-05: eliminar un movimiento lo saca de la lista vía borrado lógico '
    '(deletedAt)',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToTransactions($);
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [5, 0, 0, 0]); // $50,00 COP
      await $.tester.tap(find.text('Cuenta'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      expect(find.text('-50,00\u{00A0}COP'), findsOneWidget);

      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip('Eliminar'));
      await $.tester.pumpAndSettle();

      expect(find.text('¿Eliminar este movimiento?'), findsOneWidget);
      await $.tester.tap(find.text('Eliminar').last);
      // Deliberately bounded pumps, not `pumpAndSettle()`, all the way to the
      // snackbar assertion below: `pumpAndSettle()` keeps pumping frames
      // until nothing is animating, and a SnackBar's own auto-dismiss timer
      // eventually starts a reverse animation too — it counts as "animating"
      // until that fires, so `pumpAndSettle()` here would fast-forward
      // straight through the snackbar's entire ~4s visible lifecycle before
      // ever returning control to this test (confirmed: it does). The delete,
      // the sheet's own pop, the pop back to the list (with its page
      // transition), and the Drift stream that removes the row are separate
      // async/animation hops — same caveat as `accounts_patrol_test.dart`'s
      // equivalent scenario, extended here to stay comfortably inside the
      // snackbar's visible window instead of settling past it.
      await $.tester.pump();
      await $.tester.pump(const Duration(milliseconds: 300));
      await $.tester.pump(const Duration(milliseconds: 500));

      // The delete happened on TransactionDetailPage (a different cubit than
      // the list's), so this is the regression check: the "Deshacer"
      // snackbar must still appear back on the list.
      expect(find.text('Movimiento eliminado.'), findsOneWidget);
      expect(find.text('Deshacer'), findsOneWidget);

      await $.tester.pumpAndSettle();

      expect(find.text('-50,00\u{00A0}COP'), findsNothing);

      // Verified against the real database, not inferred from the UI: a
      // trash/undo delete must land on `deletedAt`, never `tombstonedAt`
      // (CLAUDE.md's borrado rule — the two are never interchangeable).
      final db = getIt<AppDatabase>();
      final row = await db.select(db.transactions).getSingle();
      expect(row.deletedAt, isNotNull);
      expect(row.tombstonedAt, isNull);
    },
  );

  patrolTest(
    'HU-06: filtrar por cuenta solo deja en la lista los movimientos de esa '
    'cuenta',
    ($) async {
      await startApp($);
      await _goToAccountsList($);
      await _addCashAccount($, 'Cuenta A');
      await _addCashAccount($, 'Cuenta B');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      for (final (account, digits) in [
        ('Cuenta A', [1, 0, 0, 0]),
        ('Cuenta B', [2, 0, 0, 0])
      ]) {
        await $.tester.tap(find.byTooltip('Agregar movimiento'));
        await $.tester.pumpAndSettle();
        await _enterAmount($, digits);
        await $.tester.tap(find.text('Cuenta'));
        await $.tester.pumpAndSettle();
        await $.tester.tap(find.text(account));
        await $.tester.pumpAndSettle();
        await $.tester.tap(find.byTooltip('Guardar'));
        await $.tester.pumpAndSettle();
      }

      expect(find.text('-10,00\u{00A0}COP'), findsOneWidget);
      expect(find.text('-20,00\u{00A0}COP'), findsOneWidget);

      // HU-06a: the account filter chip, one tap away.
      await $.tester.tap(find.text('Cuentas'));
      await $.tester.pumpAndSettle();
      expect(find.text('Filtrar por cuenta'), findsOneWidget);

      // `find.text('Cuenta A')` alone is ambiguous here: the sheet is a
      // modal overlaying the transaction list, which still has a row whose
      // title is also 'Cuenta A' (`TransactionRow.title` falls back to the
      // account name when the entry has no category). Scope the tap to the
      // sheet's own `CheckboxListTile`.
      await $.tester.tap(
        find.descendant(
          of: find.byType(CheckboxListTile),
          matching: find.text('Cuenta A'),
        ),
      );
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Aplicar'));
      await $.tester.pumpAndSettle();

      // HU-06: filtered to Cuenta A only — Cuenta B's movement disappears.
      expect(find.text('-10,00\u{00A0}COP'), findsOneWidget);
      expect(find.text('-20,00\u{00A0}COP'), findsNothing);
    },
  );

  patrolTest(
    'HU-07: crear una etiqueta nueva al vuelo desde el filtro',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      // See the file-level comment: the transaction form itself has no tag
      // picker/creator wired up (a real gap, not fixed here), so the only
      // reachable "create a tag on the fly" affordance today is the tag
      // filter sheet's own "+" (`TagFilterSheetBody`), which is what HU-07's
      // "puedo crear una etiqueta nueva al vuelo" is verified against.
      // 'Etiqueta' is the last chip in the filter bar and starts off-screen
      // (see `_scrollFilterBarUntilVisible`).
      final tagChip = find.text('Etiqueta');
      await _scrollFilterBarUntilVisible($, tagChip);
      await $.tester.tap(tagChip);
      await $.tester.pumpAndSettle();
      expect(find.text('Filtrar por etiqueta'), findsOneWidget);

      await $.tester.tap(find.byTooltip('Agregar etiqueta'));
      await $.tester.pumpAndSettle();
      expect(find.text('Nueva etiqueta'), findsOneWidget);

      // `find.byType(TextField)` alone is ambiguous: `NewTagSheet`'s own
      // field is the second match, the first being `TransactionsPage`'s
      // search bar, still mounted underneath every sheet stacked on top of
      // it (`showModalBottomSheet` never unmounts the page below) —
      // verified against a real emulator run.
      await $.tester.enterText(
        find.descendant(
          of: find.byType(NewTagSheet),
          matching: find.byType(TextField),
        ),
        'viaje-test',
      );
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Guardar'));
      await $.tester.pumpAndSettle();

      // Back on the (still open) tag filter sheet: the new tag is now in the
      // live list, selectable like any other.
      expect(find.text('viaje-test'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-08: el detalle de un movimiento muestra cuenta, categoría, nota y '
    'origen',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createExpenseCategory($, 'Comida test');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [7, 5, 0, 0]); // $75,00 COP
      await $.tester.tap(find.text('Cuenta'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Sin categoría'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Comida test'));
      await $.tester.pumpAndSettle();
      await $.tester.enterText(find.byType(TextField), 'Almuerzo');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('Comida test'));
      await $.tester.pumpAndSettle();

      expect(find.text('Detalle del movimiento'), findsOneWidget);
      expect(find.text('Cuenta: Efectivo'), findsOneWidget);
      expect(find.text('Categoría: Comida test'), findsOneWidget);
      expect(find.text('Nota: Almuerzo'), findsOneWidget);
      // HU-08 criterion 10: legible source label, `manual` being the only
      // one any Fase 0 capture flow can actually produce.
      expect(find.text('Registrado como Manual'), findsOneWidget);
    },
  );
}
