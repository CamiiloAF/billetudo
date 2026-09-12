// Patrol e2e for Pagos programados (`design-system/billetudo/pages/pagos-
// programados.md`, `docs/dev-runs/pagos-programados.md`). Runs the real app —
// real DI graph, real on-device Drift database, real go_router navigation —
// against a real emulator/simulator. No datasource or repository is mocked.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so scenarios do not leak state
// into each other even though they share one app process.
//
// Every amount entered here stays under 1.000 (COP has 0 decimals): the
// per-digit typed-amount check in `_enterAmount` asserts the *exact* rendered
// string after each tap (`'$whole'`), and `MoneyFormatter.formatSymbol` only
// inserts a thousands separator (`.`) once the value reaches 1.000 — so a
// 4+-digit amount would break that per-digit assertion without a much more
// involved grouped-string formatter in this helper. Same reasoning
// `transactions_patrol_test.dart`'s own `_enterAmount` documents.
//
// Confirming an occurrence "ahead of schedule" (HU covered by fix `81cb943`)
// is exercised through the detail page's own "Confirmar ahora" CTA rather
// than by waiting for a real due date or seeding the occurrences table
// directly: it is the one deterministic, UI-only way to materialize a
// pending occurrence regardless of the template's actual `nextDate`, and it
// is also the exact path the scenario is meant to cover (`ScheduledPayment
// HeroCard`'s own doc comment: "visible for any live template ... whether its
// next date is future, due today, or overdue").
import 'dart:async';

import 'package:billetudo/core/database/app_database.dart' hide CategoryKind;
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/notifications/domain/entities/app_notification_channel.dart';
import 'package:billetudo/core/notifications/domain/entities/notification_id.dart';
import 'package:billetudo/core/notifications/domain/repositories/notification_scheduler.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_select_row.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_date_field.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_reminder_field.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/reminder_option_row.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart'
    show AccountPickerField;
import 'package:billetudo/features/transactions/presentation/widgets/numeric_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Navigates to `/cuentas` and creates one cash account named [name]. `go`,
/// not a UI tap through a hub, so it works no matter which screen a prior
/// helper left the tester on — same reasoning as
/// `transactions_patrol_test.dart`'s `_goToAccountsList`.
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

/// Creates a root category of [kind] from `/categorias` — required before a
/// scheduled expense/income template, whose `ScheduledPaymentDraft` rejects a
/// `null` `categoryId` the same way `TransactionDraft` does. Same flow as
/// `transactions_patrol_test.dart`'s `_createCategory`.
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

/// Opens Pagos programados via `GoRouter.push`, not a UI tap: unlike
/// Presupuestos/Movimientos, this feature has no bottom-tab entry of its own
/// (`HomeTabBar`'s 5 tabs are Inicio/Movimientos/Presupuestos/Metas/Más) — its
/// only two real entry points are Inicio's quick-access chip and the "Más"
/// hub tile, both nested a level below the initial screen. Pushing the route
/// directly is deterministic regardless of which tab a prior helper already
/// navigated to, same reasoning as `transactions_patrol_test.dart`'s
/// `_goToTransactions` (a `push`, since this router has a single root
/// `Navigator` and every scenario below relies on a single pop landing back
/// here).
void _goToScheduledPayments(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.scheduledPayments));
}

Future<void> _openNewScheduledPaymentForm(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Nuevo pago programado'));
  await $.tester.pumpAndSettle();
}

/// Drags the nearest `Scrollable` until [finder] is on screen. The template
/// form is a plain `ListView`, so fields below the fold (mode cards, note,
/// delete link) can be discarded from the tree by the sliver's cache extent
/// — same reasoning as `accounts_patrol_test.dart`'s `_scrollUntilVisible`.
///
/// Resets to the top of the list first: several scenarios below look up
/// fields out of top-to-bottom order (e.g. picking "Manual" mode or typing
/// Nota — both below "Primer pago" in the form — *before* going back up to
/// pick the date). Once HU-08's `ScheduledPaymentReminderField` made the
/// form tall enough, an earlier field scrolled past like that falls outside
/// the `ListView`'s cache extent and is dropped from the tree — and
/// `dragUntilVisible` only drags downward (its fixed `Offset(0, -250)`), so
/// once the target is *above* the current scroll offset it can never reach
/// it and exhausts its iterations instead (`Bad state: No element` — proven
/// against a real emulator run: before the reminder field this same
/// out-of-order lookup worked, because the earlier field's `Element` was
/// still mounted just outside the viewport and `Scrollable.ensureVisible`
/// alone — called unconditionally once `dragUntilVisible`'s own loop finds
/// it already present — fixed up the scroll offset regardless of
/// direction, since `dragUntilVisible`'s own drag always moves downward).
/// Starting every lookup from a known top position, then dragging
/// downward, keeps this helper direction-agnostic no matter which order
/// the caller needs fields in.
Future<void> _scrollUntilVisible(
  PatrolIntegrationTester $,
  Finder finder,
) async {
  final scrollable = find.byType(Scrollable).first;
  for (var i = 0; i < 20; i++) {
    await $.tester.drag(scrollable, const Offset(0, 250));
    await $.tester.pump(const Duration(milliseconds: 50));
  }
  await $.tester.dragUntilVisible(
    finder,
    scrollable,
    const Offset(0, -250),
  );
  await $.tester.pumpAndSettle();
}

/// Taps the `AccountPickerField` labeled [label] and picks [accountName] from
/// the sheet it opens — same robust-by-widget-data approach
/// `transactions_patrol_test.dart` already verified against a real emulator
/// run (`_tapAccountField`/`_pickAccount`): the field's own label `Text` is a
/// plain sibling of the tappable box (not itself tappable), and the box's
/// placeholder text is ambiguous whenever more than one account field is on
/// screen at once.
Future<void> _pickAccountField(
  PatrolIntegrationTester $,
  String label,
  String accountName,
) async {
  final field = find.byWidgetPredicate(
    (widget) => widget is AccountPickerField && widget.label == label,
  );
  await _scrollUntilVisible($, field);
  await $.tester.tap(field);
  await $.tester.pumpAndSettle();
  final row = find.byWidgetPredicate(
    (widget) =>
        widget is AccountSelectRow && widget.account.name == accountName,
  );
  await $.tester.tap(row);
  await $.tester.pumpAndSettle();
}

/// Picks [name] directly from the `Category Quick Picker`'s chip row — the
/// only category created in every scenario below is the earliest (and only)
/// one by `sortOrder`, so it always renders as a quick chip without ever
/// needing "Otra" — same reasoning as `transactions_patrol_test.dart`'s
/// `_pickCategory`.
Future<void> _pickCategory(PatrolIntegrationTester $, String name) async {
  final chip = find.text(name);
  await _scrollUntilVisible($, chip);
  await $.tester.tap(chip);
  await $.tester.pumpAndSettle();
}

/// Opens the "Recordatorio" field (`ScheduledPaymentReminderField`) and picks
/// [optionLabel] (e.g. "3 días antes") from the sheet it opens. The whole
/// field is one `TransactionFormFieldButton`, unambiguous by its own `label`
/// field the same way `_pickAccountField`/`_pickFutureDate` key off their
/// widgets' `label` — this form has no other field of that type carrying
/// "Recordatorio".
///
/// The field's `onTap` runs `dismissSystemKeyboard` first, which does a
/// bounded (up to 320ms) poll with no rebuild in between — on a real device
/// `pumpAndSettle()` can decide the tree already "settled" mid-poll (no
/// pending frames: no keyboard animation running yet, sheet not opened yet)
/// and return control before `ScheduledPaymentReminderSheet` exists. So,
/// same reasoning as `_expectSnackbar`, this waits for the option row with
/// small bounded pumps instead of trusting `pumpAndSettle()` right after the
/// tap that triggers that delay. The row is matched by `ReminderOptionRow`
/// itself, not bare text: `ScheduledPaymentReminderField` shows the same
/// "Sin recordatorio" string as its own placeholder when no reminder is set,
/// which `find.text('Sin recordatorio')` would otherwise also match.
Future<void> _pickReminder(
  PatrolIntegrationTester $,
  String optionLabel,
) async {
  final field = find.byWidgetPredicate(
    (widget) => widget is ScheduledPaymentReminderField,
  );
  await _scrollUntilVisible($, field);
  await $.tester.tap(field);

  final option = find.byWidgetPredicate(
    (widget) => widget is ReminderOptionRow && widget.label == optionLabel,
  );
  for (var attempt = 0; attempt < 15 && option.evaluate().isEmpty; attempt++) {
    await $.tester.pump(const Duration(milliseconds: 200));
  }
  expect(option, findsOneWidget);

  await $.tester.tap(option);
  await $.tester.pumpAndSettle();
}

/// Reads the persisted `ScheduledPayments` row named [note] straight off the
/// on-device Drift database — the same real `AppDatabase` the running app
/// writes to (`getIt`, no mock), not a UI-only proxy. Used to assert
/// `reminderLeadDays` and the notification scheduler's own pending-id set,
/// neither of which has a visible UI surface of its own.
Future<ScheduledPayment> _scheduledPaymentByNote(String note) async {
  final database = getIt<AppDatabase>();
  return (database.select(database.scheduledPayments)
        ..where((row) => row.note.equals(note)))
      .getSingle();
}

/// Whether a reminder notification is currently pending (scheduled with the
/// real `flutter_local_notifications` plugin on this device) for the
/// scheduled-payment template with [templateId] — computed the exact same
/// way `SyncScheduledPaymentReminders`/`CancelScheduledPaymentReminder` key
/// their own notifications, so this proves the *actual* OS-level pending set,
/// not just what the repository/UI believe.
Future<bool> _hasPendingReminder(String templateId) async {
  final pending = await getIt<NotificationScheduler>().pendingIds();
  final ids = pending.getOrElse((_) => const <int>[]);
  final expectedId = NotificationId.forKey(
    templateId,
    AppNotificationChannel.reminders,
  );
  return ids.contains(expectedId);
}

/// Types [digits] on the anchored calculator keypad, starting from whatever
/// [startingWhole] already shows (`0` for a brand-new template, the loaded
/// amount when editing one) — expanding the field first by tapping its
/// current collapsed value. Every digit typed here keeps the running total
/// under 1.000 (see file comment) so the expected string never needs a
/// thousands separator. Retries each digit tap (bounded) before moving to the
/// next: the same intermittent real-tap-miss flakiness already documented for
/// `accounts_patrol_test.dart`'s day picker and `transactions_patrol_test
/// .dart`'s own `_enterAmount`.
Future<void> _enterAmount(
  PatrolIntegrationTester $,
  List<int> digits, {
  int startingWhole = 0,
}) async {
  await $.tester.tap(find.text('\$$startingWhole'));
  await $.tester.pumpAndSettle();
  var whole = startingWhole;
  for (final digit in digits) {
    whole = whole * 10 + digit;
    final expected = find.text('\$$whole');
    for (var attempt = 0; attempt < 3; attempt++) {
      await $.tester.tap(find.text('$digit').first);
      await $.tester.pump();
      if (expected.evaluate().isNotEmpty) {
        break;
      }
    }
  }
  await $.tester.pumpAndSettle();
  // Collapses the keypad back via its own Confirm key rather than leaving it
  // expanded: `ScheduledPaymentAmountFixedZone`'s zone and the scrollable
  // `ListView` above it share one `Column` (`Expanded` list + fixed zone), so
  // an expanded keypad shrinks — but does not hide — the fields still to be
  // filled below it, and every subsequent `_scrollUntilVisible` call already
  // handles that; collapsing anyway keeps every scenario's screen state
  // predictable regardless of how tall the keypad ends up.
  final confirmKey = find.byType(KeypadConfirmKey);
  if (confirmKey.evaluate().isNotEmpty) {
    await $.tester.tap(confirmKey);
    await $.tester.pumpAndSettle();
  }
}

/// Backspaces [count] digits off the amount field before re-entering a new
/// value — mirrors `transactions_patrol_test.dart`'s `_clearAmount`. Assumes
/// the field is already expanded (call right after tapping the current value
/// to open it).
Future<void> _clearAmount(PatrolIntegrationTester $, int count) async {
  for (var i = 0; i < count; i++) {
    await $.tester.tap(find.byIcon(LucideIcons.delete));
    await $.tester.pump();
  }
  await $.tester.pumpAndSettle();
}

/// Taps the "Manual" mode radio card (`ScheduledPaymentModeRadioCard`): the
/// whole card is one `InkWell`, so its title text is a valid, unambiguous tap
/// target (unlike a field's outer label elsewhere in this form).
Future<void> _selectManualMode(PatrolIntegrationTester $) async {
  final card = find.text('Manual');
  await _scrollUntilVisible($, card);
  await $.tester.tap(card);
  await $.tester.pumpAndSettle();
}

/// Types [text] into the form's only Nota field. It is not a
/// `TextFormField`: `lib/features/scheduled_payments/presentation` renders
/// it via `NoteAutocompleteField`
/// (`lib/core/widgets/note_autocomplete_field.dart`), which internally
/// wraps a plain `TextField`, not a `TextFormField` — confirmed by reading
/// every widget under `lib/features/scheduled_payments/presentation`: the
/// amount, interval and account/category/date fields are all other custom
/// widgets, none of them a `TextField`/`TextFormField`, so `find.byType(
/// TextField)` is unambiguous on this form.
Future<void> _enterNote(PatrolIntegrationTester $, String text) async {
  final field = find.byType(TextField);
  await _scrollUntilVisible($, field);
  await $.tester.enterText(field, text);
  await $.tester.pumpAndSettle();
}

/// Opens [label]'s date field (`ScheduledPaymentDateField`, e.g. "Primer
/// pago") and picks a day in the *next* calendar month — a deterministic way
/// to land on a future date regardless of which day `DateTime.now()` is on
/// this run, without needing to know today's date up front. Every month has
/// at least 28 days, so [day] defaults to a day guaranteed to exist in any
/// month.
Future<void> _pickFutureDate(
  PatrolIntegrationTester $, {
  required String label,
  int day = 20,
}) async {
  final field = find.byWidgetPredicate(
    (widget) => widget is ScheduledPaymentDateField && widget.label == label,
  );
  await _scrollUntilVisible($, field);
  await $.tester.tap(field);
  await $.tester.pumpAndSettle();

  await $.tester.tap(find.byTooltip('Mes siguiente'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('$day'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Confirmar'));
  await $.tester.pumpAndSettle();
}

/// Opens [label]'s date field, jumps to [year] through the shared calendar's
/// new year-selection view (tapping the "mes año" header label instead of
/// paging month by month), picks [day] there, and confirms — end-to-end
/// coverage (multiple screens: form -> `DatePickerSheet` -> `CalendarYearGrid`
/// -> back to the form) for the "calendar-fix-height-and-year-nav" change
/// that a widget test alone cannot give: the real on-device sheet transition.
Future<void> _pickDateViaYearView(
  PatrolIntegrationTester $, {
  required String label,
  required int year,
  int day = 10,
}) async {
  final field = find.byWidgetPredicate(
    (widget) => widget is ScheduledPaymentDateField && widget.label == label,
  );
  await _scrollUntilVisible($, field);
  await $.tester.tap(field);
  await $.tester.pumpAndSettle();

  // The header label reads "<mes> <año>" (e.g. "Julio 2026") — whatever
  // month/year the sheet opened on; find it by its `Tooltip` instead of
  // hardcoding today's month name.
  final headerLabel = find.byTooltip('Elegir año');
  await $.tester.tap(headerLabel);
  await $.tester.pumpAndSettle();

  // The 12-year page the view opens on is centred on today's year, not
  // [year] — page forward (bounded) until [year]'s cell is on screen.
  final yearCell = find.text('$year');
  for (var attempt = 0;
      attempt < 10 && yearCell.evaluate().isEmpty;
      attempt++) {
    await $.tester.tap(find.byTooltip('Años siguientes'));
    await $.tester.pumpAndSettle();
  }
  await $.tester.tap(yearCell);
  await $.tester.pumpAndSettle();

  await $.tester.tap(find.text('$day'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Confirmar'));
  await $.tester.pumpAndSettle();
}

/// Scrolls to and taps the form's "Guardar" save button (the header's
/// circular check, `TransactionHeaderButton` with tooltip `commonSave`) —
/// unambiguous on this page, unlike Cuentas' form which carries a second,
/// untooltipped full-width save button too.
Future<void> _submitScheduledPaymentForm(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Guardar'));
  await $.tester.pumpAndSettle();
}

/// Opens the detail's ⋮ actions sheet.
Future<void> _openDetailActions(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Más opciones'));
  await $.tester.pumpAndSettle();
}

/// Waits (bounded, small increments) for [text] to appear, then asserts it
/// — never `pumpAndSettle()`: a `SnackBar`'s own auto-dismiss timer keeps it
/// "animating" until it fires, so `pumpAndSettle()` fast-forwards straight
/// through its entire visible window before returning control, same caveat
/// `transactions_patrol_test.dart`'s HU-05 delete scenario documents. Small
/// bounded pumps instead give the async round trip behind the action (a
/// cubit awaiting a repository call before emitting the state that shows the
/// snackbar) room to land without ever running the clock all the way to the
/// snackbar's own dismissal.
Future<void> _expectSnackbar(PatrolIntegrationTester $, String text) async {
  final finder = find.text(text);
  for (var attempt = 0; attempt < 15 && finder.evaluate().isEmpty; attempt++) {
    await $.tester.pump(const Duration(milliseconds: 200));
  }
  expect(finder, findsOneWidget);
}

void main() {
  patrolTest(
    'HU-01: crear un pago programado nuevo lo deja visible en el listado',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Suscripciones');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      expect(find.text('Nuevo pago programado'), findsOneWidget);

      await _enterAmount($, [5, 0, 0]); // $500 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Suscripciones');
      await _enterNote($, 'Netflix');
      await _submitScheduledPaymentForm($);

      // Back on the list: the new template's card, named after its note
      // (`ScheduledPaymentFormat.templateName` prefers a non-empty note over
      // the category/account fallback), its signed expense amount and the
      // "cada mes" cadence chip (frequency defaults to monthly, untouched).
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('-\$500'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-05: editar un pago programado existente actualiza su nombre y monto '
    'en el detalle',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Hogar');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      await _enterAmount($, [3, 0, 0]); // $300 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Hogar');
      await _enterNote($, 'Arriendo');
      await _submitScheduledPaymentForm($);

      expect(find.text('Arriendo'), findsOneWidget);
      await $.tester.tap(find.text('Arriendo'));
      await $.tester.pumpAndSettle();

      await _openDetailActions($);
      await $.tester.tap(find.text('Editar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Editar pago programado'), findsOneWidget);

      await _enterNote($, 'Arriendo apartamento');
      // The amount field loads prefilled with the template's own value
      // (`$300`, not `$0`): tap that current value to expand, clear its 3
      // digits, then type the new one.
      await $.tester.tap(find.text('\$300'));
      await $.tester.pumpAndSettle();
      await _clearAmount($, 3);
      await _enterAmount($, [4, 5, 0]); // $450 COP
      await _submitScheduledPaymentForm($);

      // Editing pops back to the detail, not the list (`ScheduledPaymentForm
      // Page`'s single `Navigator.pop` on `saved`): the rename and new amount
      // show up right there, in the Identity Strip and the Hero — each only
      // once, unlike Cuentas/Presupuestos, since this page's `AppBar` title is
      // the fixed "Detalle", not the template's own name.
      expect(find.text('Arriendo apartamento'), findsOneWidget);
      expect(find.text('Arriendo'), findsNothing);
      expect(find.text('\$450'), findsOneWidget);
      expect(find.text('\$300'), findsNothing);
    },
  );

  patrolTest(
    'HU confirmar un pago manualmente antes de su fecha (fix 81cb943): '
    '"Confirmar ahora" registra la ocurrencia sin esperar a que venza',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Servicios');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      await _enterAmount($, [8, 0, 0]); // $800 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Servicios');
      // Manual mode is the scenario this fix is about: before it, only an
      // automatic-mode template's due (or overdue) occurrence could be
      // registered ahead of schedule.
      await _selectManualMode($);
      await _enterNote($, 'Internet');
      // A next payment date a month out: confirming it now, while it is
      // nowhere near due, is exactly what the fix closes.
      await _pickFutureDate($, label: 'Primer pago');
      await _submitScheduledPaymentForm($);

      await $.tester.tap(find.text('Internet'));
      await $.tester.pumpAndSettle();

      // Nothing pending yet: the template is simply "Activa", not "Pendiente
      // de confirmar" — the CTA below is the only way to act on it early.
      expect(find.text('Activa'), findsOneWidget);
      expect(find.text('Pendiente de confirmar'), findsNothing);
      expect(find.text('Confirmar ahora'), findsOneWidget);

      await $.tester.tap(find.text('Confirmar ahora'));
      await $.tester.pumpAndSettle();

      // The mandatory `ConfirmationSheet` (criterion 7): never a one-tap
      // shortcut, even from "Confirmar ahora" — its head shows the same
      // template name and account the detail page already displayed.
      expect(find.text('Internet'), findsWidgets);
      expect(find.text('Efectivo'), findsWidgets);

      await $.tester.tap(find.text('Confirmar'));
      await $.tester.pumpAndSettle();

      // Back on the detail, still scrolled to the top: the hero's own copy
      // of the template's name is there.
      expect(find.text('Internet'), findsOneWidget);

      // The History section is no longer empty, and its new confirmed row
      // also carries the template's name — checked as a *separate* scroll
      // position rather than a single `findsNWidgets(2)` alongside the hero
      // above: the detail page is a plain `ListView`, so scrolling far
      // enough to reveal "Historial" pushes the hero's own name Text out of
      // the sliver's cache extent — both copies are never in the tree at
      // the same time on a real device (verified against a real emulator
      // run; same caveat `_scrollUntilVisible`'s own doc comment documents
      // for the form).
      await _scrollUntilVisible($, find.text('Historial'));
      expect(
        find.text('Todavía no se ha generado ningún movimiento de este pago '
            'programado.'),
        findsNothing,
      );
      expect(find.text('Internet'), findsOneWidget);
    },
  );

  patrolTest(
    'HU historial: un pago omitido se puede recuperar de vuelta a pendiente',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Ocio');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      await _enterAmount($, [6, 0, 0]); // $600 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Ocio');
      await _enterNote($, 'Gimnasio');
      await _submitScheduledPaymentForm($);

      await $.tester.tap(find.text('Gimnasio'));
      await $.tester.pumpAndSettle();

      // "Confirmar ahora" is the deterministic way to materialize a pending
      // occurrence regardless of the template's actual `nextDate` (see file
      // comment) — the point of this scenario is what happens after it is
      // skipped, not how it became due.
      await $.tester.tap(find.text('Confirmar ahora'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Omitir'));
      await $.tester.pumpAndSettle();

      // Back on the detail: the skipped occurrence shows up in the History
      // as "Omitido", not as a punitive red entry (tone rule) — with a
      // "Recuperar" link. The History section can sit below the fold:
      // `find.text` matching a widget is not the same as it being on screen
      // (the detail page is a plain `ListView`, same caveat as the form's
      // own fields) — scroll to its title first.
      await _scrollUntilVisible($, find.text('Historial'));
      expect(find.text('Omitido'), findsOneWidget);
      expect(find.text('Recuperar'), findsOneWidget);

      await $.tester.tap(find.text('Recuperar'));

      // Reversible (page spec "Recuperar", Fase 2): the snackbar offers its
      // own "Deshacer", and the occurrence itself is already back to
      // `pending` — it leaves the "omitido" History entirely and the
      // template's own Estado now reads "Pendiente de confirmar".
      await _expectSnackbar($, 'Pago recuperado');
      expect(find.text('Omitido'), findsNothing);
      expect(find.text('Pendiente de confirmar'), findsOneWidget);

      await $.tester.pumpAndSettle();
    },
  );

  patrolTest(
    'bugfix scheduled-payment-skip-finish: un `once` omitido queda '
    'Terminada (sin mostrar PAGO EJECUTADO) y recuperarlo lo vuelve Activa',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Ocio');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      await _enterAmount($, [2, 0, 0]); // $200 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Ocio');
      await $.tester.tap(find.text('Único'));
      await $.tester.pumpAndSettle();
      await _enterNote($, 'Boleto concierto');
      // A future date, not the form's own `clock.now()` default: a `once`
      // template due *today* already has `GetScheduledPaymentDetail`
      // computing a live `pendingOccurrence` the moment the detail page
      // loads (`detail.isActive && pending != null` — no async catch-up
      // job, no race, the "Estado" row just reads "Pendiente de confirmar"
      // deterministically for any due-or-overdue `nextDate`) — so without
      // this the very next assertion below would never see "Activa" for
      // any date at or before today, verified against a real emulator run.
      // The recurring sibling scenario above (`"Confirmar ahora" registra
      // la ocurrencia`) already relies on the same future-date pick for the
      // same reason.
      await _pickFutureDate($, label: 'Fecha del pago');
      await _submitScheduledPaymentForm($);

      await $.tester.tap(find.text('Boleto concierto'));
      await $.tester.pumpAndSettle();

      // Same deterministic path as the recurring skip scenario above:
      // "Confirmar ahora" materializes the template's single occurrence
      // regardless of its actual `nextDate`.
      expect(find.text('Activa'), findsOneWidget);
      await $.tester.tap(find.text('Confirmar ahora'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Omitir'));
      await $.tester.pumpAndSettle();

      // Criteria 1/2: a skipped `once`'s only occurrence reads as done —
      // the ficha says "Terminada", not "Activa" — but the hero never
      // claims the payment was executed (skip ≠ confirm: no transaction was
      // ever generated for it). Both "Terminada" (the InfoCard's "Estado"
      // row) and "Omitido"/"Recuperar" (the History row) can sit below the
      // fold on this `ListView` detail page — same caveat
      // `_scrollUntilVisible`'s own doc comment documents for the form —
      // so scroll to "Historial" first.
      await _scrollUntilVisible($, find.text('Historial'));
      expect(find.text('Omitido'), findsOneWidget);
      expect(find.text('Recuperar'), findsOneWidget);
      expect(find.text('Terminada'), findsOneWidget);
      expect(find.text('Activa'), findsNothing);
      expect(find.text('PAGO EJECUTADO'), findsNothing);

      await $.tester.tap(find.text('Recuperar'));
      await _expectSnackbar($, 'Pago recuperado');
      await $.tester.pumpAndSettle();

      // Criterio 3 (this scenario's own title: "recuperarlo lo vuelve
      // Activa" — unlike the recurring sibling above, which recovers back
      // to "Pendiente de confirmar"): the occurrence this scenario recovers
      // was materialized by "Confirmar ahora" at the template's own future
      // `nextDate` (`_ensureDuePendingOccurrence`'s `force: true` branch
      // inserts at `template.nextDate`, not at today), so once it is
      // `pending` again the *non-force* read path's own due-date gate
      // (`ScheduledPaymentOccurrence.dateIsDueOn`) does not surface it as
      // `pendingOccurrence` until that future date actually arrives — the
      // template genuinely reads "Activa" again, not "Pendiente de
      // confirmar", verified against a real emulator run (`DEBUG2` dump of
      // every `Text` on screen at this point during diagnosis showed
      // "Estado, Activa"). Scroll to the "Estado" label itself, not
      // "Historial": recovering empties the History section back out
      // (shorter page overall), so scrolling as far as "Historial" now
      // over-scrolls past the InfoCard and drops "Estado"/"Activa" out of
      // the `ListView`'s cache extent — the same one-directional-scroll
      // pitfall documented above, just pointed the other way.
      await _scrollUntilVisible($, find.text('Estado'));
      expect(find.text('Omitido'), findsNothing);
      expect(find.text('Terminada'), findsNothing);
      expect(find.text('Pendiente de confirmar'), findsNothing);
      expect(find.text('Activa'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-05: eliminar un pago programado pide confirmación y lo quita del '
    'listado activo',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Streaming');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      await _enterAmount($, [4, 0, 0]); // $400 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Streaming');
      await _enterNote($, 'Spotify');
      await _submitScheduledPaymentForm($);

      await $.tester.tap(find.text('Spotify'));
      await $.tester.pumpAndSettle();

      await _openDetailActions($);
      await $.tester.tap(find.text('Eliminar pago programado'));
      await $.tester.pumpAndSettle();

      // Reversible-reading copy (criterion 12: transactions already
      // generated are preserved as history, only future generation stops) —
      // verify the cancel path first, same pattern as `accounts_patrol_test
      // .dart`'s HU-08/`budgets_patrol_test.dart`'s HU-11.
      expect(find.text('¿Eliminar este pago programado?'), findsOneWidget);
      await $.tester.tap(find.text('Cancelar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Spotify'), findsOneWidget);

      await _openDetailActions($);
      await $.tester.tap(find.text('Eliminar pago programado'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar'));
      // The delete (`tombstonedAt`, since `Transactions.scheduledPaymentId`
      // can reference this template's id — CLAUDE.md's borrado rule), the pop
      // back to the list and the Drift stream removing the row from the
      // active list are separate async hops; `pumpAndSettle` alone can race
      // the DB round trip — same reasoning as HU-08 in `accounts_patrol_test
      // .dart`.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('Spotify'), findsNothing);
    },
  );

  patrolTest(
    'HU calendar-fix-height-and-year-nav: el label de mes abre la vista de '
    'año y la fecha elegida ahí se guarda en el pago programado',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Streaming');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      await _enterAmount($, [4, 0, 0]); // $400 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Streaming');
      await _enterNote($, 'Spotify');

      await _pickDateViaYearView($, label: 'Primer pago', year: 2028);

      // The date field now shows "10 ago 2028" (or whatever locale-formatted
      // day the calendar landed on), proving the year picked in the
      // year-selection view — not the month the sheet originally opened
      // on — is what got applied to the form.
      final dateFieldValue = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.contains('2028'),
      );
      expect(dateFieldValue, findsWidgets);

      await _submitScheduledPaymentForm($);

      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('-\$400'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-08: configurar "3 días antes" al crear un pago programado persiste '
    'el lead y muestra el chip "Te avisamos" en la tarjeta',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Suscripciones');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      await _enterAmount($, [7, 0, 0]); // $700 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Suscripciones');
      await _enterNote($, 'Internet fibra');
      await _pickReminder($, '3 días antes');
      // A due date comfortably in the future keeps the reminder's own
      // `fireAt` (due date minus 3 days) after "now" too, so it is real
      // scheduled state, not one `SyncScheduledPaymentReminders` silently
      // dropped as already elapsed.
      await _pickFutureDate($, label: 'Primer pago');
      await _submitScheduledPaymentForm($);

      // The chip names the exact anticipation chosen, not a generic "on".
      expect(find.text('Te avisamos 3 días antes'), findsOneWidget);

      final row = await _scheduledPaymentByNote('Internet fibra');
      expect(row.reminderLeadDays, 3);
    },
  );

  patrolTest(
    'HU-08: cambiar a "Sin recordatorio" al editar un pago programado quita '
    'el chip "Te avisamos" de su tarjeta',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Hogar');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      await _enterAmount($, [5, 5, 0]); // $550 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Hogar');
      await _enterNote($, 'Agua');
      await _pickReminder($, 'El día del pago');
      await _pickFutureDate($, label: 'Primer pago');
      await _submitScheduledPaymentForm($);

      expect(find.text('Te avisamos el día del pago'), findsOneWidget);

      await $.tester.tap(find.text('Agua'));
      await $.tester.pumpAndSettle();
      await _openDetailActions($);
      await $.tester.tap(find.text('Editar'));
      await $.tester.pumpAndSettle();

      await _pickReminder($, 'Sin recordatorio');
      await _submitScheduledPaymentForm($);

      // Editing pops back to the detail (see `_submitScheduledPaymentForm`'s
      // own HU-05 scenario comment above) — the chip only lives on the list
      // card, so go back there to see it gone.
      await $.tester.tap(find.byTooltip('Atrás'));
      await $.tester.pumpAndSettle();

      expect(find.text('Te avisamos el día del pago'), findsNothing);

      final row = await _scheduledPaymentByNote('Agua');
      expect(row.reminderLeadDays, isNull);
    },
  );

  patrolTest(
    'HU-08: borrar un pago programado con recordatorio cancela su '
    'notificación pendiente (no queda huérfana) y lo quita del listado',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Streaming');

      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _openNewScheduledPaymentForm($);
      await _enterAmount($, [3, 5, 0]); // $350 COP
      await _pickAccountField($, 'Cuenta', 'Efectivo');
      await _pickCategory($, 'Streaming');
      await _enterNote($, 'Disney Plus');
      await _pickReminder($, 'Una semana antes');
      // Far enough out that a 7-day lead still fires in the future, so the
      // template really has a live pending notification to cancel below.
      await _pickFutureDate($, label: 'Primer pago');
      await _submitScheduledPaymentForm($);

      expect(find.text('Te avisamos una semana antes'), findsOneWidget);

      final template = await _scheduledPaymentByNote('Disney Plus');
      expect(
        await _hasPendingReminder(template.id),
        isTrue,
        reason: 'the reminder just configured should be really scheduled '
            'with the device notification plugin before this scenario '
            'deletes the template',
      );

      await $.tester.tap(find.text('Disney Plus'));
      await $.tester.pumpAndSettle();
      await _openDetailActions($);
      await $.tester.tap(find.text('Eliminar pago programado'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar'));
      // Same async-hop caveat `_submitScheduledPaymentForm`'s HU-05 scenario
      // documents: the delete write, the reminder cancel and the pop back to
      // the list are separate awaits.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('Disney Plus'), findsNothing);
      expect(
        await _hasPendingReminder(template.id),
        isFalse,
        reason: 'deleting the template must cancel its reminder '
            '(CancelScheduledPaymentReminder), never leave a notification '
            'ringing for a payment that no longer exists',
      );
    },
  );
}
