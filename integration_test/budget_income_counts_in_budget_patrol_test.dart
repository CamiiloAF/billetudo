// Patrol e2e for budget-income-counts-in-budget. Runs the real app — real DI
// graph, real on-device Drift database, real go_router navigation — against a
// real emulator/simulator. No datasource or repository is mocked.
//
// This is the one scenario in this feature that genuinely needs a live device
// rather than a widget/unit test: it exercises the write path across two
// features (Deudas writes a `Transaction` via `RegisterDebtCashEvent`,
// Presupuestos reads it back via the real Drift datasource/repository/
// calculator stack) end to end, through real navigation between them. Every
// individual link in that chain already has its own unit/widget/data test
// with a real in-memory Drift db (`debt_repository_impl_test.dart`,
// `budget_progress_calculator_test.dart`, `get_budget_progress_test.dart`);
// this test is the integration proof that they compose correctly on-device.
//
// Uses a "Todo" (global) scope budget on purpose — same reasoning as
// `budgets_patrol_test.dart`'s file comment: a custom scope needs a category
// from the remote `category_seeds` catalog, not deterministic offline. Global
// scope is itself first-class (HU-02) and keeps this scenario free of that
// network dependency while still exercising the real account-matching code
// path (an empty `BudgetScope` matches every account/category).
//
// Money entry for the debt hero field follows `debts_patrol_test.dart`'s
// convention: `enterText` into the plain `TextField`, not the anchored
// keypad; COP has no decimals, so `enterText('300')` reads `$300`.
//
// Starts from `startApp`, which wipes the on-device sqlite file first, so
// this scenario never leaks state into (or from) any other suite.
import 'dart:async';

import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_select_row.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/debts/presentation/widgets/debt_amount_hero_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_card.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_cash_switch.dart';
import 'package:billetudo/features/debts/presentation/widgets/debt_form_field.dart';
import 'package:billetudo/features/debts/presentation/widgets/sheets/debt_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Creates one cash account named [name] from `/cuentas`, same flow as
/// `debts_patrol_test.dart`'s private `_createCashAccount`.
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

/// Goes to `/presupuestos` (a shell branch, so this also works from a
/// top-level route like `/cuentas` that left the bottom tab bar behind —
/// `go`, not a tab tap, same reasoning as `_createCashAccount`'s `go` into
/// `/cuentas`).
void _goToBudgets(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.budgets);
}

/// Creates a global-scope monthly budget from the Presupuestos tab, same
/// minimal-form shape `budgets_patrol_test.dart`'s `_fillMinimalBudgetForm`
/// uses.
Future<void> _createGlobalBudget(
  PatrolIntegrationTester $, {
  required String name,
  required String amount,
}) async {
  _goToBudgets($);
  await $.tester.pumpAndSettle();
  await dismissAutoTutorialIfShown($);
  await $.tester.tap(find.byTooltip('Nuevo presupuesto'));
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField).first, name);
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField).at(1), amount);
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

/// Pushes `/deudas` (no bottom-tab entry of its own), same reasoning as
/// `debts_patrol_test.dart`'s private `_goToDebts`.
void _goToDebts(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.debts));
}

/// Creates a root category of [kind] from `/categorias`, same flow as
/// `debts_patrol_test.dart`'s private `_createCategory`. Needed here because
/// `DebtPaymentCubit`'s category auto-default only resolves against the
/// remote `category_seeds` catalog (`DebtCategorySeed`), not deterministic
/// offline/on a throwaway test project — without any category to fall back
/// to, `canSubmit` (which requires one, fix 7) stays false and the abono
/// silently never submits.
Future<void> _createCategory(
  PatrolIntegrationTester $,
  String name, {
  required CategoryKind kind,
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

void main() {
  patrolTest(
    'budget-income-counts-in-budget (criterion 6): a debt disbursement '
    'lowers a global budget\'s disponible, and the repayment countsInBudget '
    'automatically brings it back to the original amount',
    ($) async {
      await startApp($);
      await _createCashAccount($, 'Efectivo');
      await _createCategory($, 'Cobros', kind: CategoryKind.income);
      await _createGlobalBudget(
        $,
        name: 'Presupuesto del mes',
        amount: '1000',
      );

      // Back on the list right after creating the budget (HU-01/02): nothing
      // spent yet, the full amount is available.
      expect(find.text(r'$1.000'), findsOneWidget);

      // Lend $300 to someone ("Me deben"): owedToMe + disbursement resolves
      // to an *expense* (criterion 2, countsInBudget=false by default) that
      // still lowers this global-scope budget's disponible, since global
      // scope matches every account.
      _goToDebts($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await $.tester.tap(find.byTooltip('Agregar deuda'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Me deben'));
      await $.tester.pumpAndSettle();
      final heroField = find.descendant(
        of: find.byType(DebtAmountHeroField),
        matching: find.byType(TextField),
      );
      await $.tester.enterText(heroField, '300');
      await $.tester.pumpAndSettle();
      final nameField = find.descendant(
        of: find
            .ancestor(
              of: find.text('Nombre de la deuda'),
              matching: find.byType(DebtFormField),
            )
            .first,
        matching: find.byType(TextFormField),
      );
      await $.tester.enterText(nameField, 'Préstamo a Andrés');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Crear deuda'));
      await $.tester.pumpAndSettle();
      // The registro-inicial sheet (positive opening figure + an account
      // exists): choose to materialize it against Efectivo.
      await $.tester.tap(find.text('Sí, elegir cuenta'));
      await $.tester.pumpAndSettle();
      final accountRow = find.byWidgetPredicate(
        (widget) =>
            widget is AccountSelectRow && widget.account.name == 'Efectivo',
      );
      await $.tester.tap(accountRow);
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // Back on the Presupuestos tab: the $300 disbursement lowered the
      // disponible.
      _goToBudgets($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      expect(find.text(r'$700'), findsOneWidget);

      // Register the repayment ("Registrar abono" on an owedToMe debt reads
      // as "Pago recibido"): owedToMe + payment resolves to income with
      // countsInBudget=true automatically (criterion 1) — no toggle for the
      // user to flip.
      _goToDebts($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await $.tester.tap(find.byType(DebtCard));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Registrar abono'));
      await $.tester.pumpAndSettle();
      final abonoHeroField = find.descendant(
        of: find.byType(DebtAmountHeroField),
        matching: find.byType(TextField),
      );
      await $.tester.enterText(abonoHeroField, '300');
      await $.tester.pumpAndSettle();
      final isCashOn =
          find.byType(DebtSelectedAccountRow).evaluate().isNotEmpty;
      if (!isCashOn) {
        await $.tester.tap(find.byType(DebtCashSwitch));
        await $.tester.pumpAndSettle();
      }
      // The abono's own category (kind follows direction — income for
      // owedToMe) has no deterministic offline default (see `_createCategory`
      // doc): pick the one created above explicitly, or `canSubmit` stays
      // false and the check icon below does nothing. The field sits below the
      // fold in this sheet's own `Scrollable`, so it must be dragged into
      // view before the tap lands on it (same reasoning as
      // `_scrollUntilVisible` in `debts_patrol_test.dart`).
      final categoryField = find.text('Elige una categoría');
      await $.tester.dragUntilVisible(
        categoryField,
        find.byType(Scrollable).first,
        const Offset(0, -220),
      );
      await $.tester.pumpAndSettle();
      await $.tester.tap(categoryField);
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Cobros'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(
        find.descendant(
          of: find.byType(DebtPaymentSheetBody),
          matching: find.byIcon(LucideIcons.check),
        ),
      );
      await $.tester.pumpAndSettle();
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();
      // $300 fully settles the $300 outstanding: the detail auto-opens the
      // felicitación sheet (`DebtCelebrationSheet`, fix 5) the instant the
      // balance crosses to settled — dismiss it ("Ahora no") without closing
      // the debt, so the scenario stays focused on the budget effect.
      if (find.text('Ahora no').evaluate().isNotEmpty) {
        await $.tester.tap(find.text('Ahora no'));
        await $.tester.pumpAndSettle();
      }

      // Back on Presupuestos (criterion 6): the $300 gasto and the $300
      // presupuestable repago net to 0 — the disponible is back to the
      // original $1.000, not stuck at $700.
      _goToBudgets($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      expect(find.text(r'$1.000'), findsOneWidget);
      expect(find.text(r'$700'), findsNothing);

      // The detail's activity list shows the repayment with a leading "+"
      // (criterion 10), distinct from the "-" the disbursement itself would
      // carry.
      await $.tester.tap(find.text('Presupuesto del mes'));
      await $.tester.pumpAndSettle();
      await $.tester.dragUntilVisible(
        find.textContaining(r'+$300'),
        find.byType(Scrollable).first,
        const Offset(0, -250),
      );
      expect(find.textContaining(r'+$300'), findsOneWidget);
    },
  );
}
