// Patrol e2e for Cuentas (HU-01 to HU-09). Runs the real app — real DI graph,
// real on-device Drift database, real go_router navigation — against a real
// emulator/simulator. No datasource or repository is mocked: these tests
// exercise the exact code path a user's phone runs, which is the whole point
// of an e2e suite over the unit/widget ones already in test/.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so scenarios do not leak state
// into each other even though they share one app process.
import 'package:billetudo/features/accounts/presentation/widgets/account_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// The "add account" app bar action's tooltip (`accountsAdd` in the arb).
/// Tapping by icon alone is ambiguous: the empty accounts list renders its own
/// "Agregar cuenta" CTA with the very same [LucideIcons.plus] glyph, so
/// `find.byIcon(LucideIcons.plus)` matches two widgets whenever the list is empty —
/// verified against a real emulator run. The CTA button has no tooltip, so
/// this finder is unambiguous in every state the list can be in.
const _addAccountTooltip = 'Agregar cuenta';

/// The form's full-width "Guardar cuenta" submit button.
///
/// Not `find.byIcon(LucideIcons.check)`: the same check glyph renders on the
/// `PageHeader`'s circular save button (a secondary, redundant action kept
/// alongside this one by design — see the comment above the `FilledButton` in
/// `account_form_page.dart`) and, on the credit-card flow, a third time next
/// to the selected currency row — so the icon finder matches 2 or 3 widgets
/// and every `tap()` on it throws — verified against a real emulator run.
/// This full-width button, found by its own label, is unambiguous in every
/// form state.
///
/// Not `find.widgetWithText(FilledButton, ...)` either: `FilledButton.icon`
/// (used here, since this button has both an icon and a label) returns a
/// private `_FilledButtonWithIcon` subclass, and `byType`/`widgetWithText`
/// match the exact runtime type, not `is FilledButton` — so that finder
/// matches 0 widgets even though the button is a real `FilledButton` —
/// verified against a real emulator run. `byWidgetPredicate` with an `is`
/// check matches the subclass too.
Finder get _saveAccountButton => find.ancestor(
      of: find.text('Guardar cuenta'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );

/// Drags the nearest `Scrollable` until [finder] is on screen. The account
/// form is a plain `ListView`, so fields below the fold (credit limit,
/// statement/payment day) need this before they can be tapped or typed into.
Future<void> _scrollUntilVisible(
  PatrolIntegrationTester $,
  Finder finder,
) async {
  await $.tester.dragUntilVisible(
    finder,
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await $.tester.pumpAndSettle();
}

/// Scrolls to and taps [_saveAccountButton].
///
/// The button sits at the very end of the form's `ListView`, so on every
/// scenario — even the short bank/cash forms that don't touch
/// `_scrollUntilVisible` for any other field — it can be outside the list's
/// cache extent and simply absent from the widget tree, not just off screen:
/// tapping it directly fails with "Found 0 widgets", not a hit-test miss —
/// verified against a real emulator run.
Future<void> _submitAccountForm(PatrolIntegrationTester $) async {
  await _scrollUntilVisible($, _saveAccountButton);
  await $.tester.tap(_saveAccountButton);
  await $.tester.pumpAndSettle();
}

/// Types [text] into the `TextFormField` labeled [fieldLabel].
///
/// Not `find.byType(TextFormField).at(n)`: the form is a plain `ListView`
/// (not `.builder`), but its underlying sliver still discards elements that
/// scroll far enough outside the cache extent — so once the credit card
/// fields further down are scrolled into view, an earlier field (e.g. the
/// name field) can be missing from the tree entirely and every subsequent
/// index shifts — verified against a real emulator run. Finding the field by
/// its own label, the same way [_pickDay] finds a selector, survives that.
Future<void> _enterTextByLabel(
  PatrolIntegrationTester $,
  String fieldLabel,
  String text,
) async {
  final label = find.text(fieldLabel);
  await _scrollUntilVisible($, label);
  final field =
      find.ancestor(of: label, matching: find.byType(AccountFormField)).first;
  final textField =
      find.descendant(of: field, matching: find.byType(TextFormField));
  await $.tester.enterText(textField, text);
  await $.tester.pumpAndSettle();
}

/// Opens the day picker sheet at [selectorLabel], taps [day] and confirms it.
///
/// Taps the selector's own tappable box, not its label: the label is a plain
/// `Text` sibling above the `InkWell`, not inside it, so tapping the label
/// itself hits nothing interactive and the sheet never opens — verified
/// against a real emulator run.
///
/// Tapping the day cell only *stages* it (`DayPickerSheet`'s own doc comment:
/// "Tapping a day only stages it ... an explicit confirmation step, instead of
/// closing the sheet on the first tap") — the sheet stays open showing its own
/// "Guardar" button until that button is tapped too. Skipping this step
/// doesn't fail loudly: the next `_pickDay` call for a *different* selector
/// still finds a day cell to tap (the still-open sheet's own grid), silently
/// re-staging a day on the wrong field while the intended one is left as
/// "Seleccionar" — verified against a real emulator run.
Future<void> _pickDay(
  PatrolIntegrationTester $,
  String selectorLabel,
  int day,
) async {
  final label = find.text(selectorLabel);
  await _scrollUntilVisible($, label);
  final field =
      find.ancestor(of: label, matching: find.byType(AccountFormField)).first;
  final selectorBox =
      find.descendant(of: field, matching: find.byType(InkWell));

  // The tap that opens the sheet is intermittently swallowed on a real
  // device (a real touch-injection miss, not a slow animation: when the
  // sheet does open, its day cell is hit-testable immediately, with no extra
  // settling needed) — verified against a real emulator run. Retrying the
  // tap itself, not just waiting longer, is what recovers from that.
  final dayCell = find.text('$day');
  for (var retry = 0; retry < 3 && dayCell.evaluate().isEmpty; retry++) {
    await $.tester.tap(selectorBox);
    await $.tester.pumpAndSettle();
  }
  await $.tester.tap(dayCell);
  await $.tester.pumpAndSettle();

  // Confirms the staged day (`commonSave`'s "Guardar" — not this form's own
  // "Guardar cuenta" button, which uses a different label). Not
  // `find.widgetWithText(FilledButton, ...)`: same `_FilledButtonWithIcon`
  // exact-type mismatch as `_saveAccountButton` above.
  await $.tester.tap(
    find.ancestor(
      of: find.text('Guardar'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    ),
  );
  await $.tester.pumpAndSettle();
}

void main() {
  patrolTest(
    'HU-01: crear una cuenta bancaria simple la deja visible con su saldo',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Cuentas'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip(_addAccountTooltip));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('Banco'));
      await $.tester.pumpAndSettle();

      await $.tester.enterText(find.byType(TextFormField).first, 'Bancolombia');
      await $.tester.enterText(
        find.byType(TextFormField).at(2), // name(0), institution(1), balance(2)
        '500000',
      );
      await $.tester.pumpAndSettle();

      await _submitAccountForm($);

      // Back on the list: the new account and its initial balance, formatted
      // in cents-derived pesos — never a double slipping through the pipe.
      // Every account balance in this feature renders through
      // `MoneyFormatter.formatSymbol` (`$`-prefixed, COP has no visible
      // decimals), not `MoneyFormatter.format` (which would place a trailing
      // `COP` currency code instead) — verified against a real device render.
      expect(find.text('Bancolombia'), findsOneWidget);
      // Renders twice by design: once in the account row and once in the
      // "Patrimonio total" hero card, which — with only one account — equals
      // that very same balance.
      expect(find.text(r'$500.000'), findsNWidgets(2));
    },
  );

  patrolTest(
    'HU-02: crear una tarjeta de crédito con cupo, corte y pago',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Cuentas'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip(_addAccountTooltip));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('Tarjeta de crédito'));
      await $.tester.pumpAndSettle();

      await $.tester
          .enterText(find.byType(TextFormField).first, 'Visa Platino');
      await $.tester.pumpAndSettle();
      // Hides the on-screen keyboard before scrolling: on a real device its
      // show/hide animation is not driven by the test's fake clock, so it can
      // still be resizing the viewport after `pumpAndSettle` returns, shifting
      // the list enough to make the credit-limit field drop out of the
      // scroll's cache extent right after `_scrollUntilVisible` confirms it
      // on screen — verified against a real emulator run (intermittent
      // `Bad state: No element` from the field lookup below).
      FocusManager.instance.primaryFocus?.unfocus();
      await $.tester.pumpAndSettle();

      await _enterTextByLabel($, 'Cupo máximo', '3000000');

      await _pickDay($, 'Día de corte', 15);
      await _pickDay($, 'Día de pago', 5);

      await _submitAccountForm($);

      // HU-02/HU-04: the list's credit row shows the card, its debt (the
      // opening balance is 0, so it opens at no debt) and its full available
      // credit — 3,000,000 minor units is $30,000.00 COP, the whole limit.
      expect(find.text('Visa Platino'), findsOneWidget);
      expect(find.textContaining('Tarjeta de crédito'), findsOneWidget);

      await $.tester.tap(find.text('Visa Platino'));
      await $.tester.pumpAndSettle();
      expect(find.text('Día de corte'), findsOneWidget);
      expect(find.text('15 de cada mes'), findsOneWidget);
      expect(find.text('Día de pago'), findsOneWidget);
      expect(find.text('5 de cada mes'), findsOneWidget);
    },
  );

  patrolTest(
    // No slash in the scenario name: AndroidTestOrchestrator turns each Dart
    // test name into an output filename, and a literal "/" is treated as a
    // path separator, crashing the whole native test run (not just this
    // scenario) with "File ... contains a path separator" right after this
    // test would have started — verified against a real emulator run.
    'HU-05 y HU-06: editar el nombre de una cuenta lo actualiza en el detalle',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Cuentas'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip(_addAccountTooltip));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();
      await $.tester.enterText(find.byType(TextFormField).first, 'Bolsillo');
      await $.tester.pumpAndSettle();
      await _submitAccountForm($);

      await $.tester.tap(find.text('Bolsillo'));
      await $.tester.pumpAndSettle();

      // Not find.byIcon(LucideIcons.pencil): account detail also shows a
      // second pencil next to the balance figure ("Ajustar saldo",
      // Mejora #1) that edits only the balance, not the whole account. The
      // header pencil that opens the full edit form is the one tagged with
      // the "Editar" tooltip (l10n `commonEdit`).
      await $.tester.tap(find.byTooltip('Editar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Editar cuenta'), findsOneWidget);

      await $.tester.enterText(
        find.byType(TextFormField).first,
        'Efectivo diario',
      );
      await $.tester.pumpAndSettle();
      await _submitAccountForm($);

      // Editing pops back to the detail, not the list: the rename must show
      // up right there, in the app bar title.
      expect(find.text('Efectivo diario'), findsOneWidget);
      expect(find.text('Bolsillo'), findsNothing);
    },
  );

  patrolTest(
    'HU-07: archivar una cuenta la saca de la lista activa y desarchivarla '
    'la devuelve',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Cuentas'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip(_addAccountTooltip));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Banco'));
      await $.tester.pumpAndSettle();
      await $.tester
          .enterText(find.byType(TextFormField).first, 'Cuenta vieja');
      await $.tester.pumpAndSettle();
      await _submitAccountForm($);

      await $.tester.tap(find.text('Cuenta vieja'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Archivar'));
      await $.tester.pumpAndSettle();
      // Confirmation sheet (HU-07): reversible, so the confirm button is also
      // "Archivar", not styled as destructive.
      await $.tester.tap(find.text('Archivar').last);
      await $.tester.pumpAndSettle();

      // Closing the sheet pops the detail: back on the (now empty) list.
      expect(find.text('Cuenta vieja'), findsNothing);

      await $.tester.tap(find.byIcon(LucideIcons.archive));
      await $.tester.pumpAndSettle();
      expect(find.text('Cuentas archivadas'), findsOneWidget);
      expect(find.text('Cuenta vieja'), findsOneWidget);

      await $.tester.tap(find.text('Desarchivar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Cuenta vieja'), findsNothing);

      // Not `$.tester.pageBack()`: it only recognizes the back button by its
      // English "Back" tooltip or by `CupertinoNavigationBarBackButton`, and
      // this page uses the custom `PageHeader` component (a Lucide
      // `arrowLeft` circular button, not a Material `AppBar` back arrow) —
      // verified against a real emulator run.
      await $.tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await $.tester.pumpAndSettle();
      expect(find.text('Cuenta vieja'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-08: no se puede eliminar la última cuenta activa',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Cuentas'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip(_addAccountTooltip));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Efectivo'));
      await $.tester.pumpAndSettle();
      await $.tester.enterText(find.byType(TextFormField).first, 'Única');
      await $.tester.pumpAndSettle();
      await _submitAccountForm($);

      await $.tester.tap(find.text('Única'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar cuenta'));
      await $.tester.pumpAndSettle();

      // The system-constraint sheet, not the destructive one: neutral icon,
      // "Entendido" as the primary action.
      expect(find.text('No se puede eliminar'), findsOneWidget);
      expect(
        find.text(
          'Esta cuenta no tiene movimientos asociados. '
          'Esta acción no se puede deshacer.',
        ),
        findsNothing,
      );

      await $.tester.tap(find.text('Entendido'));
      await $.tester.pumpAndSettle();

      // Dismissing it leaves the account untouched.
      expect(find.text('Única'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-08: eliminar una cuenta que no es la última la quita de la lista',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Cuentas'));
      await $.tester.pumpAndSettle();

      for (final name in ['Cuenta A', 'Cuenta B']) {
        await $.tester.tap(find.byTooltip(_addAccountTooltip));
        await $.tester.pumpAndSettle();
        await $.tester.tap(find.text('Efectivo'));
        await $.tester.pumpAndSettle();
        await $.tester.enterText(find.byType(TextFormField).first, name);
        await $.tester.pumpAndSettle();
        await _submitAccountForm($);
      }

      expect(find.text('Cuenta A'), findsOneWidget);
      expect(find.text('Cuenta B'), findsOneWidget);

      await $.tester.tap(find.text('Cuenta A'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar cuenta'));
      await $.tester.pumpAndSettle();

      // With a second account still active, this is the destructive sheet,
      // not the blocking one. Not a "¿Eliminar esta cuenta?" title:
      // `ConfirmDeleteAccountSheet`'s own doc comment says its `Sheet Icon
      // Header` title is deliberately `enabled:false` — one narrative message
      // instead of a generic title plus a separate body — verified against a
      // real emulator run.
      expect(
        find.text(
          'Esta cuenta no tiene movimientos asociados. '
          'Esta acción no se puede deshacer.',
        ),
        findsOneWidget,
      );
      await $.tester.tap(find.text('Eliminar'));
      await $.tester.pumpAndSettle();
      // The delete itself, the pop back to the list, and the Drift stream
      // that removes the row are three separate async hops; `pumpAndSettle`
      // only waits out Flutter's own frame schedule, not the DB round trip,
      // so the row can still be on screen right after it — verified against
      // a real emulator run.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('Cuenta A'), findsNothing);
      expect(find.text('Cuenta B'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-09: arrastrar una cuenta reordena la lista y el nuevo orden persiste',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Cuentas'));
      await $.tester.pumpAndSettle();

      for (final name in ['Primera', 'Segunda']) {
        await $.tester.tap(find.byTooltip(_addAccountTooltip));
        await $.tester.pumpAndSettle();
        await $.tester.tap(find.text('Efectivo'));
        await $.tester.pumpAndSettle();
        await $.tester.enterText(find.byType(TextFormField).first, name);
        await $.tester.pumpAndSettle();
        await _submitAccountForm($);
      }

      // Created in this order, "Primera" sorts first (lowest sortOrder).
      final firstTop = $.tester.getCenter(find.text('Primera')).dy;
      final secondTop = $.tester.getCenter(find.text('Segunda')).dy;
      expect(firstTop, lessThan(secondTop));

      // Long-press-drag "Primera" below "Segunda" (HU-09's
      // `ReorderableDelayedDragStartListener`: the drag only starts after the
      // long-press delay, hence the pump before moving).
      //
      // The move happens in small incremental steps, each followed by its own
      // pump: a single big `moveTo` jump does not give the drag recognizer
      // (and the list's own reordering animation) per-frame pointer updates to
      // react to, so the item never actually picks up — verified against a
      // real emulator run.
      final start = $.tester.getCenter(find.text('Primera'));
      final end =
          $.tester.getCenter(find.text('Segunda')) + const Offset(0, 40);
      final gesture = await $.tester.startGesture(start);
      await $.tester.pump(const Duration(milliseconds: 600));
      const steps = 10;
      for (var i = 1; i <= steps; i++) {
        await gesture.moveTo(
          Offset.lerp(start, end, i / steps)!,
        );
        await $.tester.pump(const Duration(milliseconds: 50));
      }
      await $.tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await $.tester.pumpAndSettle();

      final newFirstTop = $.tester.getCenter(find.text('Segunda')).dy;
      final newSecondTop = $.tester.getCenter(find.text('Primera')).dy;
      expect(
        newFirstTop,
        lessThan(newSecondTop),
        reason: 'after the drag, Segunda should render above Primera',
      );
    },
  );
}
