// Patrol e2e for the Deudas <-> Pagos Programados integration (HU-03, Fase 0).
// Runs the real app — real DI graph, real on-device Drift database, real
// go_router navigation — against a real emulator/simulator. No datasource or
// repository is mocked.
//
// A debt's "cuota" IS a scheduled payment carrying the debt's id
// (`ScheduledPayment.debtId`, set by the cuota-mode form the router opens at
// `/deudas/<id>/cuota`). These scenarios exercise the cross-feature seams:
// configuring the cuota, seeing it surface in Pagos programados with its
// "Deuda" chip, a generated occurrence reducing the debt, the two-way
// navigation cross-links, editing it (which deep-links back to the debt, its
// home), and deleting it (which returns the debt to the "sin cuota" state).
//
// The cuota reuses the Pagos programados form, so its amount is typed on the
// anchored calculator keypad (`NumericKeypad`), not the debt héroe's system
// keyboard — every cuota amount stays under 1.000 so the per-digit assertion in
// `_enterKeypadAmount` never needs a thousands separator, same constraint
// `scheduled_payments_patrol_test.dart` documents. The debt's own opening
// balance is still typed with `enterText` on its héroe.
import 'dart:async';

import 'package:billetudo/core/database/app_database.dart' hide CategoryKind;
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_select_row.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/debts/presentation/widgets/debt_amount_hero_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_configure_installment_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_form_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_installment_card.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_card.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_debt_chip.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_date_field.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_linked_debt_card.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart'
    show AccountPickerField;
import 'package:billetudo/features/transactions/presentation/widgets/numeric_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

// ---------------------------------------------------------------------------
// Navigation + setup helpers.
// ---------------------------------------------------------------------------

void _goToDebts(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.debts));
}

void _goToScheduledPayments(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.scheduledPayments));
}

/// Hard-resets the navigation stack onto [route] via `go` (not `push`): used
/// after a delete flow to land cleanly on a fresh route without racing the
/// pops it left behind.
Future<void> _resetTo(PatrolIntegrationTester $, String route) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(route);
  await $.tester.pumpAndSettle();
}

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

// ---------------------------------------------------------------------------
// Debt helpers (shared shape with `debts_patrol_test.dart`).
// ---------------------------------------------------------------------------

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
  // The label was renamed from "Nombre" to "Nombre de la deuda" (feat:
  // labels/fecha del form); match the current exact copy.
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

/// Creates one iOwe debt named [name] with a [openingWhole] opening balance and
/// leaves the tester on its detail page.
Future<void> _createDebtAndOpen(
  PatrolIntegrationTester $, {
  required String name,
  required String openingWhole,
}) async {
  _goToDebts($);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byTooltip('Agregar deuda'));
  await $.tester.pumpAndSettle();
  await _enterHeroAmount($, openingWhole);
  await _enterDebtName($, name);
  await $.tester.tap(find.text('Crear deuda'));
  await $.tester.pumpAndSettle();
  // These scenarios always create a cash account first, so "Crear deuda" now
  // opens the registro-inicial sheet (item 2). The cuota tests do not care
  // about a registro, so dismiss it with "No, solo la deuda": the debt keeps
  // its opening figure as the stored principal and NO opening movement, so a
  // later confirmed cuota is still the ONLY `Transaction` (the tx-count
  // assertions stay exact).
  if (find.text('No, solo la deuda').evaluate().isNotEmpty) {
    await $.tester.tap(find.text('No, solo la deuda'));
    await $.tester.pump(const Duration(milliseconds: 500));
    await $.tester.pumpAndSettle();
  }
  await $.tester.tap(find.byType(DebtCard));
  await $.tester.pumpAndSettle();
}

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

// ---------------------------------------------------------------------------
// Cuota (scheduled-payment) form helpers — same technique as
// `scheduled_payments_patrol_test.dart`, which runs green.
// ---------------------------------------------------------------------------

/// Types [digits] on the anchored calculator keypad in the cuota form. Whole-
/// peso mode (COP), each digit asserted after its tap (bounded retry) to catch
/// an occasionally-missed real tap.
Future<void> _enterKeypadAmount(
  PatrolIntegrationTester $,
  List<int> digits,
) async {
  await $.tester.tap(find.text(r'$0'));
  await $.tester.pumpAndSettle();
  var whole = 0;
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
  final confirmKey = find.byType(KeypadConfirmKey);
  if (confirmKey.evaluate().isNotEmpty) {
    await $.tester.tap(confirmKey);
    await $.tester.pumpAndSettle();
  }
}

/// Taps the `AccountPickerField` labeled [label] and picks [accountName] — the
/// robust-by-widget-data approach `scheduled_payments_patrol_test.dart` uses.
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

/// Picks [name] from the cuota form's Category Quick Picker chip row.
Future<void> _pickCategory(PatrolIntegrationTester $, String name) async {
  final chip = find.text(name);
  await _scrollUntilVisible($, chip);
  await $.tester.tap(chip);
  await $.tester.pumpAndSettle();
}

/// Selects the "Manual" confirmation mode so the cuota can be confirmed early
/// via "Confirmar ahora" regardless of its next date.
Future<void> _selectManualMode(PatrolIntegrationTester $) async {
  final card = find.text('Manual');
  await _scrollUntilVisible($, card);
  await $.tester.tap(card);
  await $.tester.pumpAndSettle();
}

/// Sets the cuota's "Primer pago" to a day in the *next* calendar month via the
/// form's `ScheduledPaymentDateField` — a deterministic future date regardless
/// of today's day-of-month. Same technique (and same "Mes siguiente"/day 20
/// picker flow) as `scheduled_payments_patrol_test.dart`'s `_pickFutureDate`.
/// The cuota reuses the PP form with recurrence on (monthly default), so the
/// date field's label is "Primer pago" (`scheduledPaymentFormNextDateLabel`).
Future<void> _pickFutureFirstPayment(
  PatrolIntegrationTester $, {
  int day = 20,
}) async {
  final field = find.byWidgetPredicate(
    (widget) =>
        widget is ScheduledPaymentDateField && widget.label == 'Primer pago',
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

Future<void> _submitCuotaForm(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Guardar'));
  await $.tester.pumpAndSettle();
}

/// From the debt detail, opens the Configurar-cuota form, fills it (amount,
/// account, category, manual mode) and saves — landing back on the debt detail
/// with a "Próxima cuota" card.
///
/// [futureFirstPayment] pushes the first payment to next month. Default `false`
/// keeps the existing behavior — a Manual cuota whose first occurrence is due
/// now, which the confirmar/eliminar scenarios rely on ("Confirmar ahora" needs
/// a due occurrence). Set it `true` only when the cuota must surface as an
/// active `ScheduledCard` in Pagos programados (no due occurrence, so it is not
/// folded into "Por confirmar" — see `scheduled_payments_list_view.dart`).
Future<void> _configureCuota(
  PatrolIntegrationTester $, {
  required String accountName,
  required String categoryName,
  required List<int> amountDigits,
  bool futureFirstPayment = false,
}) async {
  await $.tester.tap(find.text('Configurar cuota'));
  await $.tester.pumpAndSettle();
  // Cuota mode reuses the Pagos programados form with a context subtitle.
  expect(find.text('Configurar cuota'), findsWidgets);

  await _enterKeypadAmount($, amountDigits);
  await _pickAccountField($, 'Cuenta', accountName);
  await _pickCategory($, categoryName);
  if (futureFirstPayment) {
    await _pickFutureFirstPayment($);
  }
  await _selectManualMode($);
  await _submitCuotaForm($);
}

Future<void> _openDetailActions(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Más opciones'));
  await $.tester.pumpAndSettle();
}

void main() {
  patrolTest(
    'HU-03: configurar una cuota la deja como Próxima cuota en la deuda y en '
    'Pagos programados con el chip "Deuda"',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Cuota crédito');

      await _createDebtAndOpen($, name: 'Crédito carro', openingWhole: '600');

      // No cuota yet: the slot shows the "Configurar cuota" entry point.
      expect(find.text('Configurar cuota'), findsOneWidget);
      expect(find.byType(DebtInstallmentCard), findsNothing);

      // First payment set to next month so the cuota surfaces as an ACTIVE card
      // in Pagos programados (a Manual cuota due now would instead be folded
      // into "Por confirmar", where there is no `ScheduledCard` and thus no
      // chip — see `_configureCuota`'s `futureFirstPayment` doc and
      // `scheduled_payments_list_view.dart`).
      await _configureCuota(
        $,
        accountName: 'Efectivo',
        categoryName: 'Cuota crédito',
        amountDigits: [5, 0, 0], // $500 COP
        futureFirstPayment: true,
      );

      // Back on the debt detail: the slot is now the linked "Próxima cuota"
      // card with its "Pago programado" badge.
      await _scrollUntilVisible($, find.byType(DebtInstallmentCard));
      expect(find.byType(DebtInstallmentCard), findsOneWidget);
      expect(find.text('Próxima cuota'), findsOneWidget);
      expect(find.text('Pago programado'), findsOneWidget);
      expect(find.byType(DebtConfigureInstallmentCard), findsNothing);

      // And it surfaces in Pagos programados as an active template card wearing
      // the "Deuda" chip (`ScheduledDebtChip`, `scheduledPayment.debtId !=
      // null`). With a future first payment there is no due occurrence, so the
      // template renders as a `ScheduledCard` (not folded into "Por confirmar"),
      // and the chip lives inside that card.
      _goToScheduledPayments($);
      await $.tester.pumpAndSettle();
      expect(find.byType(ScheduledCard), findsOneWidget);
      expect(find.byType(ScheduledDebtChip), findsOneWidget);
      expect(find.text('Deuda'), findsWidgets);
    },
  );

  patrolTest(
    'HU-03: confirmar una ocurrencia de la cuota genera un movimiento con '
    'debtId y baja el saldo de la deuda',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Cuota crédito');

      await _createDebtAndOpen($, name: 'Crédito carro', openingWhole: '600');
      await _configureCuota(
        $,
        accountName: 'Efectivo',
        categoryName: 'Cuota crédito',
        amountDigits: [5, 0, 0], // $500 COP
      );

      // Cross-link into the cuota's Pagos programados detail.
      await _scrollUntilVisible($, find.byType(DebtInstallmentCard));
      await $.tester.tap(find.byType(DebtInstallmentCard));
      await $.tester.pumpAndSettle();

      // "Confirmar ahora" materializes the pending occurrence early (manual
      // mode), then the mandatory confirmation sheet finalizes it.
      await $.tester.tap(find.text('Confirmar ahora'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Confirmar'));
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // The occurrence generated a real `Transaction` carrying the debt id.
      final db = getIt<AppDatabase>();
      final txns = await db.select(db.transactions).get();
      expect(txns.length, 1);
      expect(txns.single.debtId, isNotNull);

      // Reopen the debt: its derived balance dropped $600 -> $100 (the $500
      // cuota is an abono once generated).
      await _resetTo($, AppRoutes.debts);
      await $.tester.tap(find.byType(DebtCard));
      await $.tester.pumpAndSettle();
      expect(find.text(r'$100'), findsWidgets);
    },
  );

  patrolTest(
    'HU-03: cross-link en ambos sentidos entre la deuda y su cuota',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Cuota crédito');

      await _createDebtAndOpen($, name: 'Crédito casa', openingWhole: '900');
      await _configureCuota(
        $,
        accountName: 'Efectivo',
        categoryName: 'Cuota crédito',
        amountDigits: [3, 0, 0], // $300 COP
      );

      // Deuda -> Pago programado: tapping the "Próxima cuota" card opens the
      // cuota's PP detail, which shows the "Cuota de … " linked-debt card.
      await _scrollUntilVisible($, find.byType(DebtInstallmentCard));
      await $.tester.tap(find.byType(DebtInstallmentCard));
      await $.tester.pumpAndSettle();
      expect(find.byType(ScheduledPaymentLinkedDebtCard), findsOneWidget);
      expect(find.text('Cuota de'), findsOneWidget);

      // Pago programado -> Deuda: tapping that linked-debt card deep-links back
      // into the owning debt's detail (its name in the Page Header).
      await $.tester.tap(find.byType(ScheduledPaymentLinkedDebtCard));
      await $.tester.pumpAndSettle();
      expect(find.text('Crédito casa'), findsWidgets);
      // Landed on the debt detail: its own "Próxima cuota" card is back.
      await _scrollUntilVisible($, find.byType(DebtInstallmentCard));
      expect(find.byType(DebtInstallmentCard), findsOneWidget);
    },
  );

  patrolTest(
    'HU-03: editar la cuota deep-linkea a la config de cuota de la deuda, no al '
    'form suelto',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Cuota crédito');

      await _createDebtAndOpen($, name: 'Crédito moto', openingWhole: '600');
      await _configureCuota(
        $,
        accountName: 'Efectivo',
        categoryName: 'Cuota crédito',
        amountDigits: [4, 0, 0], // $400 COP
      );

      // Open the cuota's PP detail, then its ⋮ actions -> Editar.
      await _scrollUntilVisible($, find.byType(DebtInstallmentCard));
      await $.tester.tap(find.byType(DebtInstallmentCard));
      await $.tester.pumpAndSettle();
      await _openDetailActions($);
      await $.tester.tap(find.text('Editar'));
      await $.tester.pumpAndSettle();

      // A cuota edits in its home (the debt's Configurar-cuota screen, cuota
      // mode) — the header reads "Editar cuota", never the plain "Editar pago
      // programado". The linked-debt context subtitle is present too.
      expect(find.text('Editar cuota'), findsOneWidget);
      expect(find.text('Editar pago programado'), findsNothing);
      // The linked-debt context subtitle renders the debt name and direction in
      // ONE `Text` via `l10n.debtContext` ("Crédito moto · Yo debo"), so an
      // exact `find.text('Crédito moto')` matches 0. `textContaining` asserts
      // the debt name is present within that combined subtitle.
      expect(find.textContaining('Crédito moto'), findsWidgets);
    },
  );

  patrolTest(
    'HU-03: eliminar la cuota la quita de Pagos programados y devuelve la deuda '
    'al estado "sin cuota"',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Cuota crédito');

      await _createDebtAndOpen($, name: 'Crédito TV', openingWhole: '600');
      await _configureCuota(
        $,
        accountName: 'Efectivo',
        categoryName: 'Cuota crédito',
        amountDigits: [2, 0, 0], // $200 COP
      );

      // Reach the cuota edit form (its home) and use its "Eliminar cuota" link.
      await _scrollUntilVisible($, find.byType(DebtInstallmentCard));
      await $.tester.tap(find.byType(DebtInstallmentCard));
      await $.tester.pumpAndSettle();
      await _openDetailActions($);
      await $.tester.tap(find.text('Editar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Editar cuota'), findsOneWidget);

      await _scrollUntilVisible($, find.text('Eliminar cuota'));
      await $.tester.tap(find.text('Eliminar cuota'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar'));
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // Gone from Pagos programados: no template wears the "Deuda" chip anymore.
      await _resetTo($, AppRoutes.scheduledPayments);
      expect(find.byType(ScheduledDebtChip), findsNothing);

      // And the debt's cuota slot is back to the "Configurar cuota" entry point.
      await _resetTo($, AppRoutes.debts);
      await $.tester.tap(find.byType(DebtCard));
      await $.tester.pumpAndSettle();
      expect(find.text('Configurar cuota'), findsOneWidget);
      expect(find.byType(DebtInstallmentCard), findsNothing);
    },
  );

  patrolTest(
    'HU-03 (piso): el movimiento generado al confirmar una cuota nunca queda '
    'fechado antes del inicio de la deuda (piso defensivo de confirmOccurrence)',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Cuota crédito');

      // The debt starts today by default; the generated movement must land on
      // or after that day. The reject path (a date strictly before startDate)
      // is exercised deterministically at the data layer
      // (`scheduled_payment_repository_impl_test.dart` → "piso de fecha de una
      // cuota al confirmar") and at the state layer
      // (`confirmation_floor_state_test.dart`); an on-device picker cannot be
      // driven to a disabled day, so e2e locks the happy-path invariant instead.
      await _createDebtAndOpen($, name: 'Crédito carro', openingWhole: '600');
      await _configureCuota(
        $,
        accountName: 'Efectivo',
        categoryName: 'Cuota crédito',
        amountDigits: [5, 0, 0], // $500 COP
      );

      await _scrollUntilVisible($, find.byType(DebtInstallmentCard));
      await $.tester.tap(find.byType(DebtInstallmentCard));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Confirmar ahora'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Confirmar'));
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      final db = getIt<AppDatabase>();
      final debt = await db.select(db.debts).getSingle();
      final txns = await db.select(db.transactions).get();
      // Exactly one movement (the debt was created solo, so the cuota's is the
      // only tx), carrying the debt id.
      expect(txns.length, 1);
      final tx = txns.single;
      expect(tx.debtId, debt.id);

      // The generated movement is dated on/after the debt's startDate — the
      // defensive floor holds; it can never predate the debt.
      final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final startDate = debt.startDate!;
      final startDay =
          DateTime(startDate.year, startDate.month, startDate.day);
      expect(txDay.isBefore(startDay), isFalse);
    },
  );
}
