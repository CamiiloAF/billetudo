// Patrol e2e for Presupuestos (HU-01 to HU-11, `06-presupuestos.md`). Runs the
// real app — real DI graph, real on-device Drift database, real go_router
// navigation — against a real emulator/simulator. No datasource or repository
// is mocked: these tests exercise the exact code path a user's phone runs,
// which is the whole point of an e2e suite over the unit/widget/golden ones
// already in test/ (`budget_period_calculator_test.dart`,
// `budget_detail_cubit_test.dart`, the adjustment usecase tests, and the
// golden suites already cover the math and the render pixel-by-pixel).
//
// Every budget created here uses the "Todo" (global) scope on purpose: a
// custom scope needs at least one category, and this app's only category
// source is a remote `category_seeds` catalog fetched from Supabase
// (`CategoryRepositoryImpl.seedDefaultCategories`) — not deterministic
// offline/on a throwaway test project. The global scope is itself a first
// -class scenario (HU-02), not a workaround, and it keeps every scenario here
// free of that network dependency.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so scenarios do not leak state
// into each other even though they share one app process.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Opens the budget form from the list's `+` circular button.
Future<void> _openNewBudgetForm(PatrolIntegrationTester $) async {
  await $.tester.tap(find.text('Presupuestos'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byTooltip('Nuevo presupuesto'));
  await $.tester.pumpAndSettle();
}

/// Types [name] into the budget form's name field and [amount] (a bare digit
/// string, e.g. `'1000000'`) into its amount field, leaving every other field
/// at its default (scope "Todo", monthly, recurring, anchored today) — the
/// same minimal-valid-form shape `AccountFormField` scenarios use in
/// `accounts_patrol_test.dart`.
Future<void> _fillMinimalBudgetForm(
  PatrolIntegrationTester $, {
  required String name,
  required String amount,
}) async {
  await $.tester.enterText(find.byType(TextFormField).first, name);
  await $.tester.pumpAndSettle();
  // amount(0): the name field above is a bare `TextFormField`, the amount
  // field is the only other one in the minimal (scope "Todo") form.
  await $.tester.enterText(find.byType(TextFormField).at(1), amount);
  await $.tester.pumpAndSettle();
}

/// Scrolls to and taps the form's full-width submit button, found by its own
/// label rather than by icon: `FilledButton.icon` renders as a private
/// `_FilledButtonWithIcon` subclass, so `byType`/`widgetWithText` misses it —
/// same reasoning as `_saveAccountButton` in `accounts_patrol_test.dart`. Not
/// used here since the label itself ("Crear presupuesto" / "Guardar
/// cambios") is unambiguous without needing the widget-predicate dance: no
/// other `FilledButton` with that exact text exists elsewhere in this form.
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

/// Opens the detail's `⋮` actions sheet.
Future<void> _openDetailActions(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
  await $.tester.pumpAndSettle();
}

/// Replaces an already-prefilled `BudgetAmountField`'s value with [amount].
///
/// Not a single `enterText(finder, amount)`: `WidgetTester.enterText` delivers
/// the whole new string as one `TextEditingValue` with a collapsed selection,
/// which — whenever the prefilled text and the new raw digits happen to differ
/// in length by exactly one character (as `'500.000'` → `'750000'` does: 7
/// formatted characters vs. 6 raw ones) — satisfies
/// `MoneyInputFormatter`'s "backspacing onto a separator" guard by accident and
/// drops a digit (`$750.000` saved as `$75.000`) — verified against a real
/// emulator run. Clearing the field first makes the follow-up `enterText` an
/// insert-into-empty, which cannot collide with that guard.
Future<void> _replaceAmount(
  PatrolIntegrationTester $,
  Finder field,
  String amount,
) async {
  await $.tester.enterText(field, '');
  await $.tester.pumpAndSettle();
  await $.tester.enterText(field, amount);
  await $.tester.pumpAndSettle();
}

void main() {
  patrolTest(
    'HU-01 y HU-02: crear un presupuesto global lo deja visible con su '
    'progreso',
    ($) async {
      await startApp($);

      await _openNewBudgetForm($);
      await _fillMinimalBudgetForm(
        $,
        name: 'Mercado del mes',
        amount: '1000000',
      );
      await _submitBudgetForm($, 'Crear presupuesto');

      // Back on the list: the budget line (HU-04) shows its name, the
      // positive-tone "Te quedan" headline (nothing spent yet, so the full
      // amount) and the global scope label — never the punitive framing.
      expect(find.text('Mercado del mes'), findsOneWidget);
      expect(find.text('Te quedan'), findsOneWidget);
      expect(find.text(r'$1.000.000'), findsOneWidget);
      expect(find.textContaining('Todo el gasto'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-09: editar un presupuesto existente actualiza su nombre y monto en '
    'el detalle',
    ($) async {
      await startApp($);

      await _openNewBudgetForm($);
      await _fillMinimalBudgetForm($, name: 'Gastos fijos', amount: '500000');
      await _submitBudgetForm($, 'Crear presupuesto');

      await $.tester.tap(find.text('Gastos fijos'));
      await $.tester.pumpAndSettle();

      await _openDetailActions($);
      await $.tester.tap(find.text('Editar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Editar presupuesto'), findsOneWidget);

      await $.tester.enterText(
        find.byType(TextFormField).first,
        'Gastos fijos del hogar',
      );
      await $.tester.pumpAndSettle();
      await _replaceAmount($, find.byType(TextFormField).at(1), '750000');
      await _submitBudgetForm($, 'Guardar cambios');

      // Editing pops back to the detail, not the list: the new name shows up
      // right there (in the page header and the hero card, hence 2), and the
      // hero's headline reflects the new amount (nothing spent yet).
      expect(find.text('Gastos fijos del hogar'), findsNWidgets(2));
      expect(find.text('Gastos fijos'), findsNothing);
      // Renders twice: the hero's own "Te quedan" headline (a standalone
      // string, nothing spent yet so it equals the full amount) and its
      // breakdown caption ("0% · $0 de $750.000").
      expect(find.textContaining(r'$750.000'), findsNWidgets(2));
    },
  );

  patrolTest(
    'HU-13: ajustar el monto de un presupuesto para el período actual no '
    'afecta el período siguiente',
    ($) async {
      await startApp($);

      await _openNewBudgetForm($);
      await _fillMinimalBudgetForm(
        $,
        name: 'Tarjeta de crédito',
        amount: '1000000',
      );
      await _submitBudgetForm($, 'Crear presupuesto');

      await $.tester.tap(find.text('Tarjeta de crédito'));
      await $.tester.pumpAndSettle();

      // The running period's caption ("0% · $0 de $1.000.000") before any
      // adjustment.
      expect(find.textContaining(r'$0 de $1.000.000'), findsOneWidget);

      await _openDetailActions($);
      await $.tester.tap(find.text('Ajustar monto — este período'));
      await $.tester.pumpAndSettle();
      expect(find.text('Ajustar monto'), findsOneWidget);
      // "Actual $1.000.000" — the base amount the sheet prefills from and the
      // one every other period keeps.
      expect(find.textContaining(r'Actual $1.000.000'), findsOneWidget);

      // Overwrite the prefilled amount with the extra-income figure from the
      // motivating scenario (`presupuestos-ajuste-un-periodo.md`).
      await $.tester.enterText(find.byType(TextFormField).first, '3000000');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Aplicar cambios'));
      await $.tester.pumpAndSettle();

      // Back on the detail, still showing the (now adjusted) running period:
      // the banner names the new amount, and the hero's own breakdown already
      // reflects it — this is the crux of the fix (0c55978): the CURRENT
      // period changes, not the next one.
      expect(find.text('Ajuste de monto'), findsOneWidget);
      expect(find.textContaining(r'$0 de $3.000.000'), findsOneWidget);
      expect(find.textContaining(r'$0 de $1.000.000'), findsNothing);

      // Step to the next period (HU-05): the banner disappears and the
      // breakdown returns to the budget's original, un-adjusted amount — the
      // regression this fix closed would have shown $3.000.000 here too.
      await $.tester.tap(find.byTooltip('Periodo siguiente'));
      await $.tester.pumpAndSettle();
      expect(find.text('Ajuste de monto'), findsNothing);
      expect(find.textContaining(r'$0 de $1.000.000'), findsOneWidget);
      expect(find.textContaining(r'$0 de $3.000.000'), findsNothing);

      // Stepping back confirms the override is still scoped to that one
      // period, not lost.
      await $.tester.tap(find.byTooltip('Periodo anterior'));
      await $.tester.pumpAndSettle();
      expect(find.text('Ajuste de monto'), findsOneWidget);
      expect(find.textContaining(r'$0 de $3.000.000'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-10 y HU-11: cerrar un presupuesto lo saca de la lista activa y lo '
    'deja en el histórico, reactivarlo lo devuelve',
    ($) async {
      await startApp($);

      await _openNewBudgetForm($);
      await _fillMinimalBudgetForm(
        $,
        name: 'Presupuesto viejo',
        amount: '200000',
      );
      await _submitBudgetForm($, 'Crear presupuesto');

      await $.tester.tap(find.text('Presupuesto viejo'));
      await $.tester.pumpAndSettle();

      await _openDetailActions($);
      await $.tester.tap(find.text('Cerrar (guardar en histórico)'));
      await $.tester.pumpAndSettle();

      // Closing pops the detail straight back to the (now empty) list — no
      // confirmation sheet, this action is reversible (HU-10).
      expect(find.text('Presupuesto viejo'), findsNothing);

      await $.tester.tap(find.byTooltip('Más opciones'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Ver histórico'));
      await $.tester.pumpAndSettle();

      expect(find.text('Histórico'), findsOneWidget);
      expect(find.text('Presupuesto viejo'), findsOneWidget);

      await $.tester.tap(find.text('Reactivar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Presupuesto viejo'), findsNothing);

      await $.tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await $.tester.pumpAndSettle();
      expect(find.text('Presupuesto viejo'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-11: eliminar un presupuesto pide confirmación y lo quita de la lista',
    ($) async {
      await startApp($);

      await _openNewBudgetForm($);
      await _fillMinimalBudgetForm(
        $,
        name: 'Presupuesto a borrar',
        amount: '150000',
      );
      await _submitBudgetForm($, 'Crear presupuesto');

      await $.tester.tap(find.text('Presupuesto a borrar'));
      await $.tester.pumpAndSettle();

      await _openDetailActions($);
      await $.tester.tap(find.text('Eliminar presupuesto'));
      await $.tester.pumpAndSettle();

      // Reversible, logical delete (`deletedAt`, HU-11): neutral violet icon,
      // "Eliminar" as the only destructive-looking action, with an explicit
      // "Cancelar" escape — verify the cancel path first.
      expect(
        find.text(
          'Este presupuesto se eliminará. Podrás deshacerlo justo después '
          'de eliminar.',
        ),
        findsOneWidget,
      );
      await $.tester.tap(find.text('Cancelar'));
      await $.tester.pumpAndSettle();
      // Renders twice by design: once in the `PageHeader` title and once in
      // the hero card, same as HU-09's rename assertion above.
      expect(find.text('Presupuesto a borrar'), findsNWidgets(2));

      await _openDetailActions($);
      await $.tester.tap(find.text('Eliminar presupuesto'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar'));
      // The delete, the pop back to the list and the Drift stream removing
      // the row are separate async hops; `pumpAndSettle` alone can race the
      // DB round trip — same reasoning as HU-08 in `accounts_patrol_test.dart`.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('Presupuesto a borrar'), findsNothing);
    },
  );
}
