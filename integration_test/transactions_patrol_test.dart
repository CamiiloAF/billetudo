// Patrol e2e for Transacciones (HU-01 to HU-08). Runs the real app — real DI
// graph, real on-device Drift database, real go_router navigation — against a
// real emulator/simulator. No datasource or repository is mocked.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so scenarios do not leak state
// into each other even though they share one app process.
//
// The app now has the real navigation shell (`StatefulShellRoute` + tab bar):
// Movimientos is a top-level tab and Cuentas/Categorías live under the "Más"
// hub. These scenarios still reach routes through `GoRouter` directly, exactly
// like a deep link would, so navigation is deterministic regardless of which
// tab or nested stack a previous scenario left active.
//
// HU-07's "crear una etiqueta nueva al vuelo... desde el formulario de
// transacción" *is* reachable today, unlike an earlier pass over this file
// assumed: `TransactionFormPage` renders `TransactionTagsField` (see its
// "Etiquetas" section, right after Nota), whose "+ Nueva" chip
// (`transactionFormTagNew`) opens the very same `TagFilterSheet` HU-06's
// filter reuses, just with its create action enabled (`title`/`confirmLabel`
// passed) — this is exactly the "product moved on, the test didn't" pattern
// documented in `home_patrol_test.dart`'s Presupuestos fix. The HU-07
// scenario below now exercises the real in-form flow instead of the filter
// workaround.
import 'dart:async';

import 'package:billetudo/core/database/app_database.dart' hide CategoryKind;
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/core/widgets/toggle_field.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_select_row.dart';
import 'package:billetudo/features/accounts/presentation/widgets/info_row.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:billetudo/features/transactions/presentation/widgets/filter_chip_pill.dart';
import 'package:billetudo/features/transactions/presentation/widgets/sheets/new_tag_sheet.dart';
import 'package:billetudo/features/transactions/presentation/widgets/transaction_row.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Deterministic navigation via `GoRouter.go`, not a UI tap: `go` replaces
/// the whole navigation stack and always lands on the requested route
/// regardless of where the tester currently is, unlike tapping through the
/// "Más" hub to reach Cuentas, which breaks as soon as this helper is chained
/// after another one that already navigated away from that hub.
Future<void> _goToAccountsList(PatrolIntegrationTester $) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.accounts);
  await $.tester.pumpAndSettle();
}

/// Assumes the accounts list is already on screen (see `_goToAccountsList`) —
/// safe to call more than once per test, unlike re-navigating through the
/// "Más" hub each time.
Future<void> _addCashAccount(PatrolIntegrationTester $, String name) async {
  await $.tester.tap(find.byTooltip('Agregar cuenta'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Efectivo'));
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField).first, name);
  await $.tester.pumpAndSettle();
  // `find.byIcon(LucideIcons.check)` alone is ambiguous on `AccountFormPage`:
  // it now has two save affordances doing the same thing (`PageHeader`'s
  // trailing circle button, and a full-width "Guardar cuenta" `Button/Primary`
  // added at the bottom of the content — see that page's own doc comment,
  // "in addition to the check icon in the Page Header, not instead of it").
  // Only the header one carries a `Tooltip` (`PageHeaderCircleButton`); the
  // bottom one is labelled by its own text ("Guardar cuenta"), never a bare
  // icon lookup.
  await $.tester.tap(find.byTooltip('Guardar'));
  await $.tester.pumpAndSettle();
}

/// Single-account convenience: navigates to the accounts list and creates
/// one cash account, for scenarios that only need one.
Future<void> _createCashAccount(PatrolIntegrationTester $, String name) async {
  await _goToAccountsList($);
  await _addCashAccount($, name);
}

/// Creates a root category of [kind] from `/categorias` (default Tipo:
/// Gasto, switched to Ingreso first when [kind] is income), same flow as
/// `categories_patrol_test.dart`'s HU-01 scenario. Navigates via
/// `GoRouter.go`, same reasoning as `_goToAccountsList` — safe to call after
/// another helper has already navigated the tester away from home.
///
/// Required before creating any expense/income transaction in this suite:
/// `TransactionDraft.validated()` rejects a `null` `categoryId` for both
/// types (`fieldCategoryId`, "a category is required") — a transfer is the
/// only type that carries none, so only `HU-03`/`HU-07` (which never taps
/// Guardar) skip this.
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

/// Picks [name] directly from the `Category Quick Picker`'s chip row.
///
/// Not "Ver más" (`CategorySelectSheet`): `GetMostUsedCategories`'s own doc
/// comment says a user with no usage history "falls back to the earliest
/// categories by `sortOrder`" — so with only one category created (every
/// scenario in this suite creates exactly one before reaching this point),
/// it shows up as a quick chip immediately, before ever being picked once,
/// not only after. Going through "Ver más" anyway does not fail outright,
/// but it does make the sheet's own `CategorySelectRow` and the still-
/// mounted quick chip underneath both read [name] at once, so tapping
/// `find.text(name)` there is ambiguous (verified against a real emulator
/// run) — tapping the chip directly, before any sheet opens, has no such
/// duplicate.
Future<void> _pickCategory(PatrolIntegrationTester $, String name) async {
  await $.tester.tap(find.text(name));
  await $.tester.pumpAndSettle();
}

/// Taps "Guardar" (`commonSave`) to submit a **new** transaction whose
/// category was just picked via [_pickCategory] with [categoryName],
/// retrying that pick (bounded, up to 3 attempts total) if the form is still
/// showing afterward. Works for any type that actually shows a category
/// picker at save time — expense/income always, and a `transfer` too once
/// its "¿Incluir en tu presupuesto?" toggle is on (Fase B1+B2).
///
/// Not chasing a real validation bug: every attempt uses the exact same
/// steps that do work reliably elsewhere in this suite (`_pickCategory`'s
/// direct chip tap, confirmed correct against `CategoryQuickPicker`'s own
/// selection wiring) — this is the same class of intermittent real-tap-miss
/// flakiness already documented for `accounts_patrol_test.dart`'s day-picker
/// (`docs/dev-runs/bug-fixes-pixel-audit.md`), here surfacing as an
/// occasionally-missed tap on the category chip: when it misses,
/// `categoryId` stays `null` and `TransactionDraft.validated()` rejects the
/// save (`fieldCategoryId`), leaving the form open with the `Guardar`
/// `AppBar` button (unique to the form, never the list) still present.
///
/// Checks the finder's own `evaluate()` before every `tap()` (never taps
/// blind): `WidgetTester.tap()` throws immediately if its target vanished
/// between the check and the call, which a bare bounded loop cannot recover
/// from — this treats "Guardar not there this round" the same as "still on
/// the form", just another reason to re-pick the category and retry.
Future<void> _saveNewTransaction(
  PatrolIntegrationTester $, {
  required String categoryName,
}) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    final guardar = find.byTooltip('Guardar');
    if (guardar.evaluate().isNotEmpty) {
      await $.tester.tap(guardar);
      await $.tester.pumpAndSettle();
    }
    if (find.byTooltip('Guardar').evaluate().isEmpty) {
      return; // Saved: back on the list, no more form `AppBar`.
    }
    await _pickCategory($, categoryName);
  }
  fail('still on the transaction form after 3 Guardar attempts.');
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

/// Re-enters `/movimientos` for a **second** time in the same scenario, via
/// `go()` — not another call to [_goToTransactions]. Fase B1+B2's transfer
/// scenario is the first (and, as of this writing, only) one that needs to
/// leave Transacciones (to check a `Presupuesto`) and come back within a
/// single `patrolTest`: [_goToTransactions]'s own `push` never gets popped
/// on the way to Presupuestos (`_goToBudgets` uses `go`, which does not
/// collapse a page an earlier `push` put on the stack — see
/// [_goToTransactions]'s own doc comment), so a *second* `push` of the exact
/// same `/movimientos` location collides with the still-live first one:
/// `NavigatorState._debugCheckDuplicatedPageKeys`'s
/// `'!keyReservation.contains(key)'` assertion, verified against a real
/// emulator run. `go()` recomputes the whole page stack from the target
/// URI instead of appending to it, discarding that stale entry — the exact
/// mechanism [_goToBudgets]'s own doc comment already relies on for
/// `/presupuestos`.
Future<void> _returnToTransactions(PatrolIntegrationTester $) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.transactions);
  await $.tester.pumpAndSettle();
}

/// Taps the `AccountPickerField` whose *label* (the text above the tappable
/// box, e.g. "Cuenta"/"Cuenta origen"/"Cuenta destino") matches [label].
///
/// Not `find.text(label)`: that label is a plain `Text`, a sibling of the
/// actual tappable box inside `TransactionFormFieldButton` — never itself
/// wrapped in the field's `InkWell` (see that widget's `build`) — so tapping
/// it is a no-op. And the box's own text is no better a target: before a
/// selection it just reads the shared placeholder ("Elegir cuenta") for
/// every account field on screen, ambiguous the moment a transfer form shows
/// two of them at once. Matching on the field's `label` instead sidesteps
/// both problems and still resolves to the one real widget, verified
/// against a real emulator run.
Future<void> _tapAccountField(PatrolIntegrationTester $, String label) async {
  final finder = find.byWidgetPredicate(
    (widget) => widget is AccountPickerField && widget.label == label,
  );
  await $.tester.tap(finder);
  await $.tester.pumpAndSettle();
}

/// Picks [name] from an open `AccountPickerSheetBody`/`AccountFilterSheet`
/// (both list `AccountSelectRow`s). Not `find.text(name)`, nor even
/// `find.widgetWithText(AccountSelectRow, name)`: plenty of other mounted
/// text can read the same account name at this point — the account field's
/// *own* current value bleeds through from underneath the sheet (`Bottom
/// Sheet Base` never unmounts the page below, and `TransactionFormCubit`
/// preselects the first account by `sortOrder` for a brand-new transaction,
/// so the very account being picked can already be showing as the field's
/// current value while its own sheet is open), the accounts list page one
/// route down (`AccountCard`, kept mounted by the `Navigator` under this
/// push) repeats the name again, and an `AccountSelectRow` itself shows the
/// name **and** the account type's own label as two separate `Text`s, which
/// collide whenever an account is named after its type (e.g. a cash account
/// named "Efectivo", same word as `AccountType.cash.label`). All of the
/// above still found `text-ancestor`-composed finders ambiguous in practice
/// (verified against a real emulator run), so this matches the
/// `AccountSelectRow` widget itself by its actual `account.name` data
/// instead of any rendered `Text` — the same robust approach
/// `_tapAccountField` already uses for `AccountPickerField`.
Future<void> _pickAccount(PatrolIntegrationTester $, String name) async {
  final finder = find.byWidgetPredicate(
    (widget) => widget is AccountSelectRow && widget.account.name == name,
  );
  await $.tester.tap(finder);
  await $.tester.pumpAndSettle();
}

/// Taps the only `TransactionRow` on screen, to open its detail page.
///
/// Not a match against the row's rendered title: `TransactionRow._title`'s
/// own fallback chain (note, else category name, else the account(s)
/// involved) is one more layer of indirection to get exactly right than the
/// thing every scenario that calls this actually needs — each of them seeds
/// or creates exactly one transaction before reaching this point, so the
/// single row on screen unambiguously *is* the one to open.
Future<void> _openOnlyTransaction(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byType(TransactionRow));
  await $.tester.pumpAndSettle();
}

/// Waits (bounded, up to 10 extra pumps) for [finder] to satisfy [matcher]
/// before asserting it, instead of relying solely on the `pumpAndSettle()`
/// already done by the caller.
///
/// `pumpAndSettle()` only waits for *scheduled frames*, not for an arbitrary
/// Future/Stream to resolve — the reactive Drift query behind
/// `TransactionsListCubit`/`GetTransactionEditImpact` occasionally finishes
/// its requery a beat after the write that triggered it (a direct DB insert
/// in `HU-04 caso 2`'s seed, or the Guardar submit in `HU-01`/`HU-03`/etc.),
/// which does not always line up with a frame `pumpAndSettle()` is already
/// waiting on. Verified against a real emulator run, in both directions:
/// sometimes the finder is briefly empty (the row has not landed yet) and
/// sometimes briefly ambiguous (the popping form's own big amount display
/// and the list row underneath both still read the same value mid-
/// transition) — checking the actual [matcher] on every attempt, not just
/// non-emptiness, catches both.
///
/// Bound raised from 5 to 10 attempts (1.5s → 3s of bounded extra wait)
/// after `HU-04 caso 2`'s seed-then-list-read still missed the 1.5s window
/// on a real emulator run (2026-07-24): the direct DB insert this scenario
/// uses to seed a scheduled-payment-linked transaction races the same
/// reactive-requery lag documented above, just closer to its edge than the
/// UI-driven writes other scenarios trigger. Costs nothing on the passing
/// path — the loop only pumps extra frames when the first check misses.
Future<void> _expectEventually(
  PatrolIntegrationTester $,
  Finder finder,
  Matcher matcher,
) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    if (matcher.matches(finder, <dynamic, dynamic>{}) || attempt == 9) {
      break;
    }
    await $.tester.pump(const Duration(milliseconds: 300));
  }
  expect(finder, matcher);
}

/// Types [digits] on the anchored keypad. Each digit is a **whole** peso
/// place, not a cents-shifted calculator entry: `TransactionFormCubit
/// .amountDigitPressed`'s "whole-number mode" always advances `amountMinor`
/// as if it carried the storage-wide 2 implied decimals (`MoneyFormatter`'s
/// own `_minorPerMajor`/`_storedDecimals`, the same convention every currency
/// shares) — so `[2, 5, 0]` reaches an internal `amountMinor` of `25000`,
/// which COP (0 *display* decimals, `MoneyFormatter.currencyDecimals`) then
/// renders as `$250`, never `$2,50`.
///
/// Verifies the displayed amount actually advanced after every single digit
/// (bounded retry per digit, up to 3 attempts) instead of firing all the taps
/// blind and only checking the final total: a digit tap occasionally not
/// registering — the same class of intermittent real-tap flakiness already
/// documented for `accounts_patrol_test.dart`'s day-picker — otherwise only
/// surfaces much later, as a wrong final amount with no indication of which
/// digit was actually dropped (verified against a real emulator run).
///
/// The expected text after each digit is built through `MoneyFormatter`
/// itself, not a bare `'\$$whole'` interpolation: once the running total
/// reaches 1.000, `TransactionAmountExpandedZone` renders it with Spanish
/// thousands grouping (`$1.000`, not `$1000`) — a plain `'\$$whole'` finder
/// never matches from that point on, so every retry loop exhausts its 3
/// attempts and *triple*-taps that digit, snowballing the amount
/// exponentially (verified against a real emulator run, 2026-07-24: entering
/// `[5, 0, 0, 0, 0]` for an intended $50.000 landed on $50.000.000.000 once
/// the running total crossed 1.000 mid-entry). Every scenario before Fase
/// B1+B2 only ever typed amounts under 1.000, so this never tripped before.
Future<void> _enterAmount(PatrolIntegrationTester $, List<int> digits) async {
  const money = MoneyFormatter();
  // `$0` (`MoneyFormatter.formatSymbol`), not `0,00`: COP shows no decimals
  // (`MoneyFormatter.currencyDecimals`), and the amount is always prefixed
  // with `$`, never suffixed with the currency code, in the form's Zona
  // Fija (`TransactionAmountExpandedZone`) — the code suffix is a Cuentas/
  // list-row-only convention (`MoneyFormatter.format`), not this widget's.
  await $.tester.tap(find.text('\$0'));
  await $.tester.pumpAndSettle();
  var whole = 0;
  for (final digit in digits) {
    whole = whole * 10 + digit;
    // `whole * 100`: the entry-phase `amountMinor` the cubit actually holds
    // (see this helper's own doc comment), so `formatSymbol` renders exactly
    // what `TransactionAmountExpandedZone` shows on screen, grouping dots
    // included.
    final expectedText =
        money.formatSymbol(whole * 100, currencyCode: 'COP');
    final expected = find.text(expectedText);
    for (var attempt = 0; attempt < 3 && expected.evaluate().isEmpty;
        attempt++) {
      await $.tester.tap(find.text('$digit').first);
      await $.tester.pump();
      await $.tester.pump(const Duration(milliseconds: 100));
    }
  }
  await $.tester.pumpAndSettle();
}

/// Backspaces [count] digits off the amount field. Used when editing: the
/// anchored keypad has no single "clear" key, only a backspace glyph
/// rendered as `LucideIcons.delete` (see `NumericKeypad`'s `KeypadKey.icon`),
/// never the `'⌫'` text glyph — undoing a whole existing amount is one tap
/// per digit, [count] matching however many digits `_enterAmount` typed for
/// it (see that helper's own doc comment on whole-number-mode entry).
Future<void> _clearAmount(PatrolIntegrationTester $, int count) async {
  for (var i = 0; i < count; i++) {
    await $.tester.tap(find.byIcon(LucideIcons.delete));
    await $.tester.pump();
  }
  await $.tester.pumpAndSettle();
}

/// Asserts a `TransactionDetailInfoCard` row exists with exactly this
/// [label]/[value] pair. Not `find.text('$label: $value')`: `InfoRow`
/// renders the label and the value as two separate `Text` widgets (label
/// above, value below), never joined into one string — so that combined
/// literal never appears anywhere in the tree.
void _expectInfoRow(String label, String value) {
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget is InfoRow && widget.label == label && widget.value == value,
    ),
    findsOneWidget,
  );
}

/// Deterministic navigation to the Presupuestos tab via `GoRouter.go`, same
/// reasoning as `_goToAccountsList` — Presupuestos is a `StatefulShellBranch`
/// (`AppRoutes.budgets`, see `app_router.dart`), so `go()` here just switches
/// the active branch, it does not collapse a page stack the way it would for
/// `/movimientos` (see `_goToTransactions`'s own doc comment).
Future<void> _goToBudgets(PatrolIntegrationTester $) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.budgets);
  await $.tester.pumpAndSettle();
}

/// Creates a budget scoped to a single account: `Personalizado` → `Cuentas`
/// → pick [accountName] → `Aplicar`, then fills name/amount and submits.
///
/// Unlike every budget in the sibling `budgets_patrol_test.dart` (which
/// stays on the default "Todo" scope specifically to avoid the remote
/// `category_seeds` catalog — see that file's own doc comment), a
/// single-*account* scope needs no category at all: `BudgetDraft.categoryIds`
/// stays empty ("all categories"), so this carries no such network
/// dependency. Assumes [accountName] already exists (`_addCashAccount`) and
/// the Presupuestos tab is not yet open.
Future<void> _createAccountScopedBudget(
  PatrolIntegrationTester $, {
  required String name,
  required String amount,
  required String accountName,
}) async {
  await _goToBudgets($);
  await $.tester.tap(find.byTooltip('Nuevo presupuesto'));
  await $.tester.pumpAndSettle();

  await $.tester.enterText(find.byType(TextFormField).first, name);
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField).at(1), amount);
  await $.tester.pumpAndSettle();

  // `SegmentedControl<bool>` "Todo"/"Personalizado" (`budgetFormScopeAll`/
  // `budgetFormScopeCustom`); "Personalizado" reveals the `Cuentas`/
  // `Categorías` `BudgetNavField`s (see `budget_form_page.dart`).
  await $.tester.tap(find.text('Personalizado'));
  await $.tester.pumpAndSettle();
  // Not `find.text('Cuentas')`: unlike `InfoRow` (label and value as two
  // separate `Text` widgets, see `_expectInfoRow`'s own doc comment),
  // `BudgetNavField` renders its label and value as a *single* interpolated
  // `Text` ("Cuentas: Todas las cuentas", `budgetFormRowValue`) — so the bare
  // label string never appears alone anywhere in the tree (verified against
  // a real emulator run: `find.text('Cuentas')` finds 0 widgets even though
  // the field is on screen).
  await $.tester.tap(find.textContaining('Cuentas'));
  await $.tester.pumpAndSettle();
  await _pickAccount($, accountName);
  await $.tester.tap(find.text('Aplicar'));
  await $.tester.pumpAndSettle();

  final button = find.text('Crear presupuesto');
  await $.tester.dragUntilVisible(
    button,
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await $.tester.pumpAndSettle();
  await $.tester.tap(button);
  await $.tester.pumpAndSettle();
}

void main() {
  patrolTest(
    'HU-01: crear un gasto con el teclado numérico anclado lo deja en la '
    'lista',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Comida');

      // Home has no button into Transacciones yet — go straight to the list,
      // right from the accounts list `Scaffold` we are already on.
      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();

      // HU-01/criterion 11: Monto has focus and the anchored keypad is up as
      // soon as the form loads (no explicit tap needed to reveal it) — typing
      // digits straight away is exactly what a user would do.
      await _enterAmount($, [2, 5, 0]); // $250 COP

      await _tapAccountField($, 'Cuenta');
      await _pickAccount($, 'Efectivo');
      await _pickCategory($, 'Comida');
      await _saveNewTransaction($, categoryName: 'Comida');

      // Back on the list: the new expense, formatted from cents — never a
      // double slipping through the pipe (see `MoneyFormatter`). No note was
      // entered, so the row's title falls back to the category name
      // (`Comida`), not the account (`_title` prefers category over
      // account). The amount itself goes through `transactionAmountLabel`
      // (shared with Inicio's `RecentActivityRow`): an expense gets an
      // explicit `-` prefix here, in the list row — a different, neutral-
      // colored-text convention from the detail page's own
      // `DetailAmountHero`, which stays unsigned (see HU-04's own comments
      // below).
      await _expectEventually($, find.byType(TransactionRow), findsOneWidget);
      expect(find.text('-\$250'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-02: registrar un ingreso lo deja en la lista con signo positivo',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Salario', kind: CategoryKind.income);

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('Ingreso'));
      await $.tester.pumpAndSettle();
      expect(find.text('Nuevo ingreso'), findsOneWidget);

      await _enterAmount($, [1, 5, 0]); // $150 COP

      await _tapAccountField($, 'Cuenta');
      await _pickAccount($, 'Efectivo');
      await _pickCategory($, 'Salario');
      await _saveNewTransaction($, categoryName: 'Salario');

      await _expectEventually($, find.text('+\$150'), findsOneWidget);
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

      await _enterAmount($, [1, 0, 0]); // $100 COP

      // HU-03: origin (`Cuenta origen`) and destination (`Cuenta destino`)
      // are two separate `AccountPickerField`s.
      await _tapAccountField($, 'Cuenta origen');
      await _pickAccount($, 'Cuenta A');

      await _tapAccountField($, 'Cuenta destino');
      // Excludes the already-picked origin (HU-03 "distinct accounts"),
      // asserted implicitly: only 'Cuenta B' is offered as a tile to tap.
      await _pickAccount($, 'Cuenta B');

      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      // The list row for a transfer shows no +/- sign and both account
      // names (`TransactionRow._amountLabel`/`_subtitle`... title).
      await _expectEventually(
        $,
        find.text('Cuenta A → Cuenta B'),
        findsOneWidget,
      );
      // Not a bare find.text('\$100'): the Movimientos balance carousel
      // (Mejora #2, `MovementsBalanceCard`) now shows "Cuenta B"'s own
      // balance figure right above the list, so the same string also renders
      // there. Scope the finder to the transfer's `TransactionRow` — the
      // widget this assertion actually cares about.
      await _expectEventually(
        $,
        find.descendant(
          of: find.byType(TransactionRow),
          matching: find.text('\$100'),
        ),
        findsOneWidget,
      );

      // The actual balance effect (HU-03 criterion 3: "resta en origen, suma
      // en destino") is only visible on Cuentas, not on the transaction row
      // itself. `_goToAccountsList` navigates deterministically via
      // `GoRouter.go`, regardless of the current stack (`/movimientos` was
      // itself reached via `push` — see `_goToTransactions` — so a single
      // `arrow_back` tap would also land on `/cuentas` here, but `go` is used
      // for consistency with every other cross-feature jump in this file).
      await _goToAccountsList($);

      // `AccountCard` renders balances via `MoneyFormatter.formatSymbol`
      // (leading `$`, sign baked into the number itself, no currency-code
      // suffix) — the same convention `TransactionRow`/the detail hero use
      // above, not `MoneyFormatter.format`'s "<number> COP" (verified
      // against a real emulator run).
      expect(find.text('\$-100'), findsOneWidget);
      expect(find.text('\$100'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-04 caso 1: editar el monto de un gasto sin vínculos lo actualiza '
    'sin advertencia',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Comida');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [1, 0, 0]); // $100 COP
      await _tapAccountField($, 'Cuenta');
      await _pickAccount($, 'Efectivo');
      await _pickCategory($, 'Comida');
      await _saveNewTransaction($, categoryName: 'Comida');

      // The list row's amount is signed (`-$100`, see HU-01's own comment on
      // `transactionAmountLabel`) — only the detail page below stays
      // unsigned.
      await _expectEventually($, find.text('-\$100'), findsOneWidget);

      // Note is never set here, so `TransactionRow._title` falls back to the
      // category name (`Comida`), not the account — a category is now
      // mandatory for every expense/income transaction.
      await _openOnlyTransaction($);
      expect(find.text('Detalle del gasto'), findsOneWidget);

      // `DetailActionsRow`'s Editar is a plain label inside its own tappable
      // row, never an `IconButton`/`Tooltip` — `commonEdit` ("Editar").
      await $.tester.tap(find.text('Editar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Editar movimiento'), findsOneWidget);

      await $.tester.tap(find.text('\$100'));
      await $.tester.pumpAndSettle();
      await _clearAmount($, 3); // '1','0','0'
      await _enterAmount($, [2, 0, 0]); // $200 COP

      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      // No linked scheduled-payment/goal/debt on this transaction: straight back to
      // the detail (`TransactionFormPage`'s single `Navigator.pop` on save
      // returns to whatever pushed it — the detail page here, since the edit
      // flow is List -> tap row -> Detail -> tap Editar -> Form, not List ->
      // Form directly), no `EditImpactWarningSheet` in the way. Both the
      // list row and the detail hero render the amount through
      // `formatSymbol` (unsigned, `$`-prefixed, no code suffix), so the
      // string itself does not change across the two screens.
      expect(find.textContaining('vinculada a'), findsNothing);
      expect(find.text('\$200'), findsOneWidget);
      expect(find.text('\$100'), findsNothing);
    },
  );

  patrolTest(
    'HU-04 caso 2: editar el monto de un movimiento ligado a un pago programado '
    'advierte el impacto antes de guardar',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      // A category is required (see `_createCategory`'s doc comment): the
      // seeded transaction below needs a real `categoryId` too, or the edit
      // this scenario drives (which re-submits the *whole* draft, category
      // included) would fail `TransactionDraft.validated()` on save just
      // like a fresh create would.
      await _createCategory($, 'Comida');

      // There is no Pagos programados UI yet to create the link from (that feature
      // is still a blank canvas per CLAUDE.md), so the linked transaction is
      // seeded directly against the same real on-device Drift database the
      // app itself reads from — same pattern as
      // `categories_patrol_test.dart`'s "HU-04 caso 2". `scheduledPaymentId` only
      // needs to be non-null for `GetTransactionEditImpact` to flag the
      // impact; the row it points to does not need to exist (this schema
      // does not enforce the FK at the SQLite level).
      final db = getIt<AppDatabase>();
      final account = await (db.select(db.accounts)
            ..where((a) => a.name.equals('Efectivo')))
          .getSingle();
      final category = await (db.select(db.categories)
            ..where((c) => c.name.equals('Comida')))
          .getSingle();
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: account.id,
              categoryId: Value(category.id),
              amountMinor: 10000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime.now(),
              note: const Value('Suscripción test'),
              scheduledPaymentId: const Value('scheduled-seed-1'),
              // Explicit, not relying on `TransactionsCompanion`'s Dart-side
              // `withDefault(false)`: Drift opens on top of the
              // PowerSync-managed connection (see `AppDatabase`'s own doc
              // comment), whose local `Table` schema
              // (`powersync_schema.dart`) declares every column as a bare
              // nullable `Column.integer`/`.text`, with no SQL-level
              // `DEFAULT`/`NOT NULL` of its own — that only exists in
              // Drift's Dart-side generated DDL. Omitting a column Drift
              // considers "has a default" here does not fall back to that
              // default; it inserts a real `NULL`, and the generated
              // `$TransactionsTable.map`'s non-null read on
              // `counts_in_budget` then throws `Null check operator used on
              // a null value` the moment the reactive list query re-maps
              // this row — which surfaced as this scenario's seeded
              // transaction silently never appearing on screen (verified
              // against a real emulator run, 2026-07-24: the crash is in
              // the stream's `map()`, not in anything this test asserts on
              // directly). Every real write path in `lib/`
              // (`transaction_mapper.dart`) already sets this explicitly on
              // every insert — only this kind of raw test seed skips it.
              countsInBudget: const Value(false),
            ),
          );

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      // The seeded transaction has a note, so `TransactionRow._title` shows
      // it instead of falling back to the account name — the whole row
      // (note text included) is the tappable target, same as every other
      // row in this suite.
      await _expectEventually(
        $,
        find.textContaining('Suscripción test'),
        findsOneWidget,
      );
      await $.tester.tap(find.textContaining('Suscripción test'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('Editar'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('\$100'));
      await $.tester.pumpAndSettle();
      await _clearAmount($, 3);
      await _enterAmount($, [3, 0, 0]); // $300 COP

      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      // HU-04 criterion 3: changing the amount of a scheduled-payment-linked
      // transaction must warn before it saves. `EditImpactWarningSheet` has
      // no separate title (`Sheet Icon Header`'s title is left disabled per
      // its own doc comment) — only the interpolated message
      // (`transactionEditImpactMessage`), and the confirm button reads
      // `commonContinue` ("Continuar"), never a bespoke "Guardar de todas
      // formas".
      expect(find.textContaining('vinculada a tu pago programado'),
          findsOneWidget);

      await $.tester.tap(find.text('Continuar'));
      await $.tester.pumpAndSettle();

      // Same landing spot and unsigned-amount caveat as HU-04 caso 1: the
      // form's `Navigator.pop` returns to the detail page it was pushed
      // from.
      expect(find.text('\$300'), findsOneWidget);
      expect(find.text('\$100'), findsNothing);
    },
  );

  patrolTest(
    'HU-05: eliminar un movimiento lo saca de la lista vía borrado lógico '
    '(deletedAt)',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Comida');

      _goToTransactions($);
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [5, 0]); // $50 COP
      await _tapAccountField($, 'Cuenta');
      await _pickAccount($, 'Efectivo');
      await _pickCategory($, 'Comida');
      await _saveNewTransaction($, categoryName: 'Comida');

      // The list row's amount is signed (`-$50`, see HU-01's own comment).
      await _expectEventually($, find.text('-\$50'), findsOneWidget);

      // No note, so the row's title falls back to the category name
      // (`Comida`), not the account — a category is now mandatory.
      await _openOnlyTransaction($);
      // `DetailActionsRow`'s delete affordance is a text link
      // (`transactionDetailDeleteLink`, "Eliminar movimiento"), not a
      // tooltip'd icon button.
      await $.tester.tap(find.text('Eliminar movimiento'));
      await $.tester.pumpAndSettle();

      // `ConfirmDeleteTransactionSheet` has no title either (same
      // icon-header-disabled pattern as `EditImpactWarningSheet` above),
      // only `transactionDeleteMessage`.
      expect(
        find.text('Podrás deshacerlo justo después de eliminar.'),
        findsOneWidget,
      );
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

      expect(find.text('-\$50'), findsNothing);

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
      await _createCategory($, 'Comida');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      for (final (account, digits) in [
        ('Cuenta A', [1, 0]),
        ('Cuenta B', [2, 0])
      ]) {
        await $.tester.tap(find.byTooltip('Agregar movimiento'));
        await $.tester.pumpAndSettle();
        await _enterAmount($, digits);
        await _tapAccountField($, 'Cuenta');
        await _pickAccount($, account);
        await _pickCategory($, 'Comida');
        await _saveNewTransaction($, categoryName: 'Comida');
      }

      // Both list rows are signed (`-$10`/`-$20`, see HU-01's own comment).
      await _expectEventually($, find.text('-\$10'), findsOneWidget);
      expect(find.text('-\$20'), findsOneWidget);

      // HU-06a: the account filter chip. Its label defaults to "Todas"
      // (`accountFilterSelectAll`) whenever no account filter is active yet
      // — `TransactionsFilterBar._accountChipLabel` deliberately never reads
      // "Cuentas" (see that method's own doc comment).
      await $.tester.tap(find.text('Todas'));
      await $.tester.pumpAndSettle();
      expect(find.text('Filtrar por cuenta'), findsOneWidget);

      // `find.text('Cuenta A')` alone is ambiguous here (the sheet is a
      // modal overlaying the transaction list, which still has a row whose
      // title is also 'Cuenta A'), and this sheet's rows are `AccountSelectRow`
      // (not a `CheckboxListTile` — this is a single-select-styled row
      // toggled for multi-select) — see `_pickAccount`, used here directly
      // since this is `AccountFilterSheet`, not the single-select
      // `AccountPickerSheetBody` every other scenario opens through
      // `_tapAccountField`.
      await _pickAccount($, 'Cuenta A');
      await $.tester.tap(find.text('Aplicar'));
      await $.tester.pumpAndSettle();

      // HU-06: filtered to Cuenta A only — Cuenta B's movement disappears.
      expect(find.text('-\$10'), findsOneWidget);
      expect(find.text('-\$20'), findsNothing);
    },
  );

  patrolTest(
    'HU-07: crear una etiqueta nueva al vuelo desde el formulario de '
    'transacción',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();

      // The Etiquetas section's "+ Nueva" chip (`TransactionFormTagChip`,
      // `transactionFormTagNew`) opens the same `TagFilterSheet` HU-06's
      // filter reuses, but with its create action enabled (a `title` is
      // passed here — see `TransactionTagsField`/`TagFilterSheetBody`'s
      // `showCreateAction`). It sits near the bottom of the form's
      // `ListView`, past Nota — not merely off the visible viewport but
      // genuinely not yet *built* (`ListView(children: ...)` still lazily
      // creates elements only within the estimated viewport/cache extent,
      // the same virtualization a `.builder` list has), so `ensureVisible`
      // alone cannot find it (verified against a real emulator run: the
      // dumped widget tree stopped right after Nota's hint text). Drag the
      // scroll view down step by step instead, same technique
      // `_scrollFilterBarUntilVisible` used for the (removed) horizontal
      // filter bar case.
      final newTagChip = find.text('Nueva');
      await $.tester.dragUntilVisible(
        newTagChip,
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await $.tester.pumpAndSettle();
      await $.tester.tap(newTagChip);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar etiqueta'));
      await $.tester.pumpAndSettle();
      expect(find.text('Nueva etiqueta'), findsOneWidget);

      // `find.byType(TextField)` alone is ambiguous: `NewTagSheet`'s own
      // field is not the only `TextField` mounted underneath every sheet
      // stacked on top of the page below (`showModalBottomSheet` never
      // unmounts it) — verified against a real emulator run.
      await $.tester.enterText(
        find.descendant(
          of: find.byType(NewTagSheet),
          matching: find.byType(TextField),
        ),
        'viaje-test',
      );
      await $.tester.pumpAndSettle();
      // `NewTagSheet`'s confirm button reads `commonCreate` ("Crear"), not
      // "Guardar" — it creates the tag directly, it does not save a form.
      await $.tester.tap(find.text('Crear'));
      await $.tester.pumpAndSettle();

      // Back on the (still open) tag sheet: the new tag is now in the live
      // list, selectable like any other.
      await _expectEventually($, find.text('viaje-test'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-08: el detalle de un movimiento muestra cuenta, categoría, nota y '
    'origen',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Comida test');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [7, 5]); // $75 COP
      await _tapAccountField($, 'Cuenta');
      await _pickAccount($, 'Efectivo');
      // No "Sin categoría" affordance exists at all (see `_pickCategory`'s
      // doc comment) — a category is mandatory for expense/income.
      await _pickCategory($, 'Comida test');
      await $.tester.enterText(find.byType(TextField), 'Almuerzo');
      await $.tester.pumpAndSettle();
      await _saveNewTransaction($, categoryName: 'Comida test');

      // The saved transaction has a note ("Almuerzo"), so `TransactionRow`
      // shows that as its title instead of the category name (`_title`
      // prefers the note whenever there is one) — tap that to open the
      // detail.
      await _openOnlyTransaction($);

      // `TransactionDetailPage._titleFor`: "Detalle del gasto" for an
      // expense, never a type-agnostic "Detalle del movimiento".
      expect(find.text('Detalle del gasto'), findsOneWidget);
      // `TransactionDetailInfoCard` renders each field as an `InfoRow`
      // (label above, value below, two separate `Text`s) — never a single
      // "Label: value" string.
      _expectInfoRow('Cuenta', 'Efectivo');
      _expectInfoRow('Categoría', 'Comida test');
      _expectInfoRow('Nota', 'Almuerzo');
      // HU-08 criterion 10: legible source label, `manual` being the only
      // one any Fase 0 capture flow can actually produce.
      _expectInfoRow('Origen', 'Manual');
    },
  );

  patrolTest(
    'Fase B1+B2: una transferencia con "¿Incluir en tu presupuesto?" activo '
    'cuenta como gasto del presupuesto de su cuenta origen; sin el toggle, '
    'no lo afecta',
    ($) async {
      await startApp($);
      await _goToAccountsList($);
      await _addCashAccount($, 'Cuenta origen');
      await _addCashAccount($, 'Cuenta destino');
      await _createCategory($, 'Ahorro');

      // A budget scoped ONLY to "Cuenta origen" (`docs/plan-cuentas-tipos-y-
      // transferencias-presupuestables.md` §3): the datasource folds a
      // budgetable transfer in as an origin-side expense row, so this is the
      // one budget whose scope should ever see it.
      await _createAccountScopedBudget(
        $,
        name: 'Presupuesto origen',
        amount: '500000', // $500.000
        accountName: 'Cuenta origen',
      );
      expect(find.text('Presupuesto origen'), findsOneWidget);

      // First transfer, toggle left OFF (the default): the plan's "sin
      // marcar: comportamiento actual, neutral" case — must never move a
      // presupuesto, exactly like every transfer before Fase B1 existed.
      _goToTransactions($);
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Transferencia'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [5, 0, 0, 0, 0]); // $50.000 COP
      await _tapAccountField($, 'Cuenta origen');
      await _pickAccount($, 'Cuenta origen');
      await _tapAccountField($, 'Cuenta destino');
      await _pickAccount($, 'Cuenta destino');
      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      await _expectEventually(
        $,
        find.text('Cuenta origen → Cuenta destino'),
        findsOneWidget,
      );

      await _goToBudgets($);
      await $.tester.tap(find.text('Presupuesto origen'));
      await $.tester.pumpAndSettle();
      // Nothing counted yet: the un-toggled $50.000 transfer above stays
      // excluded, same as the pre-Fase-B1 behaviour.
      await _expectEventually(
        $,
        find.textContaining(r'$0 de $500.000'),
        findsOneWidget,
      );

      // Second transfer, this time WITH the toggle ON and a category — Fase
      // B1's motor: the origin side ("Cuenta origen", in this budget's
      // scope) must now count as spend.
      await _returnToTransactions($);
      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Transferencia'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [1, 0, 0, 0, 0, 0]); // $100.000 COP
      await _tapAccountField($, 'Cuenta origen');
      await _pickAccount($, 'Cuenta origen');
      await _tapAccountField($, 'Cuenta destino');
      await _pickAccount($, 'Cuenta destino');

      // `ToggleField` sits past Nota, off-screen until scrolled into view —
      // same virtualized-`ListView` situation as HU-07's "+ Nueva" tag chip.
      final toggle = find.byType(ToggleField);
      await $.tester.dragUntilVisible(
        toggle,
        find.byType(Scrollable).first,
        const Offset(0, -250),
      );
      await $.tester.pumpAndSettle();
      await $.tester.tap(toggle);
      await $.tester.pumpAndSettle();
      // Toggling ON reveals the `Category Quick Picker` right below it
      // (`transaction_form_page.dart`), mandatory for a budgetable transfer.
      // `_saveNewTransaction`, not a bare `_pickCategory` + `Guardar` tap:
      // its own doc comment's "occasionally-missed category chip tap"
      // flakiness applies here exactly as it does to a plain expense/income
      // save — same `CategoryQuickPicker`, same `fieldCategoryId` validation
      // gate on a budgetable transfer — verified against a real emulator
      // run, 2026-07-24: a missed `Ahorro` tap left `Elige una categoría.`
      // on screen and the whole scenario never got past `Guardar`.
      await _saveNewTransaction($, categoryName: 'Ahorro');

      await _goToBudgets($);
      await $.tester.tap(find.text('Presupuesto origen'));
      await $.tester.pumpAndSettle();
      // The budgetable transfer's $100.000 origin side now counts — the
      // earlier, un-toggled $50.000 transfer still does not: the total stays
      // at $100.000, never $150.000.
      await _expectEventually(
        $,
        find.textContaining(r'$100.000 de $500.000'),
        findsOneWidget,
      );
      expect(find.textContaining(r'$150.000 de $500.000'), findsNothing);
    },
  );

  patrolTest(
    'HU-06 Presupuesto: elegir un presupuesto en el nuevo chip activa el '
    'chip con su nombre, independiente del chip Fecha',
    ($) async {
      await startApp($);
      await _goToAccountsList($);
      await _addCashAccount($, 'Efectivo');
      await _createCategory($, 'Comida');

      // Account-scoped budget: exercises the real `GetActiveBudgets` ->
      // `WatchBudgetPeriodOptions` -> `BudgetPeriodFilterSheet` chain end to
      // end, same helper `Fase B1+B2` above already relies on.
      await _createAccountScopedBudget(
        $,
        name: 'Comida del mes',
        amount: '500000',
        accountName: 'Efectivo',
      );
      expect(find.text('Comida del mes'), findsOneWidget);

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      // Criterio 3: neutral state before any selection — the chip's own
      // generic label (`transactionsFilterBudget`), not the budget's name.
      expect(find.text('Presupuesto'), findsOneWidget);
      // Criterio 1: the Fecha chip (default "this month", rendered as
      // `datePeriodLabel` — e.g. "Agosto 2026", never the literal string
      // "Este mes") coexists, unaffected.
      final dateChipLabelBefore = _dateChipText($);

      // The Presupuesto chip is the 6th in `TransactionsFilterBar`'s
      // horizontal `SingleChildScrollView` — off-screen until scrolled into
      // view, same reasoning as HU-07's "+ Nueva" tag chip: `find.text` still
      // resolves the (off-screen) widget, but `tap()` at its actual painted
      // position outside the viewport hits nothing.
      final budgetChip = find.text('Presupuesto');
      await $.tester.dragUntilVisible(
        budgetChip,
        find.byType(Scrollable).first,
        const Offset(-200, 0),
      );
      await $.tester.pumpAndSettle();
      await $.tester.tap(budgetChip);
      await $.tester.pumpAndSettle();
      expect(find.text('Filtrar por presupuesto'), findsOneWidget);

      // Criterio 2: the sheet lists the active budget with its name — pick
      // it and apply.
      await $.tester.tap(find.text('Comida del mes'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Aplicar'));
      await $.tester.pumpAndSettle();

      // Criterio 3: the chip now shows the chosen budget's own name instead
      // of the generic label — and Fecha stayed exactly as it was
      // (independent chips, neither replaces the other).
      await _expectEventually($, find.text('Comida del mes'), findsOneWidget);
      expect(find.text('Presupuesto'), findsNothing);
      expect(find.text(dateChipLabelBefore), findsOneWidget);
    },
  );

  patrolTest(
    'Note autocomplete: a note typed on one transaction suggests itself on '
    'the next, and picking it fills the field',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Comida');

      _goToTransactions($);
      await $.tester.pumpAndSettle();

      // First movement: types a brand-new note by hand. Nothing in history
      // yet, so `GetNoteSuggestions` has nothing to offer — this only
      // establishes the history entry the second movement will match
      // against, on the real on-device Drift database (no mocked
      // repository).
      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [1, 0, 0]); // $100 COP
      await _tapAccountField($, 'Cuenta');
      await _pickAccount($, 'Efectivo');
      await _pickCategory($, 'Comida');
      await $.tester.enterText(find.byType(TextField), 'Almuerzo oficina');
      await $.tester.pumpAndSettle();
      await _saveNewTransaction($, categoryName: 'Comida');
      await _expectEventually($, find.byType(TransactionRow), findsOneWidget);

      // Second movement: typing a short prefix of that same note now shows
      // the shared `NoteAutocompleteField` overlay with it as a suggestion.
      await $.tester.tap(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await _enterAmount($, [2, 0, 0]); // $200 COP
      await _tapAccountField($, 'Cuenta');
      await _pickAccount($, 'Efectivo');
      await _pickCategory($, 'Comida');
      await $.tester.enterText(find.byType(TextField), 'Almu');
      await $.tester.pumpAndSettle();

      await _expectEventually(
        $,
        find.byKey(const ValueKey('note-suggestions-dropdown')),
        findsOneWidget,
      );
      final suggestion = find.text('Almuerzo oficina');
      expect(suggestion, findsOneWidget);

      // Selecting it fills the field with the full note (not just the typed
      // prefix) and closes the overlay, exactly like `onChanged` typing it
      // out by hand would have.
      await $.tester.tap(suggestion);
      await $.tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('note-suggestions-dropdown')),
        findsNothing,
      );
      expect(
        $.tester
            .widget<TextField>(find.byType(TextField))
            .controller
            ?.text,
        'Almuerzo oficina',
      );

      await _saveNewTransaction($, categoryName: 'Comida');

      // Both movements persisted with the same note text — `TransactionRow`
      // prefers the note over the category name as its title, so both rows
      // now read "Almuerzo oficina".
      await _expectEventually(
        $,
        find.text('Almuerzo oficina'),
        findsNWidgets(2),
      );
    },
  );
}

/// The Fecha chip's current label (`datePeriodLabel`, e.g. "Agosto 2026"):
/// the calendar-icon `FilterChipPill` immediately to the right of the
/// account chip, on `TransactionsFilterBar`. Not a hardcoded string — the
/// label depends on the device's current month, unlike the fixed "Este mes"
/// placeholder text that only appears in `DateFilterSheet`'s own field, never
/// on the chip itself (see `datePeriodLabel`'s own doc comment).
String _dateChipText(PatrolIntegrationTester $) {
  final chip = $.tester.widget<FilterChipPill>(
    find.byWidgetPredicate(
      (widget) => widget is FilterChipPill && widget.leadingIcon == LucideIcons.calendar,
    ),
  );
  return chip.label;
}
