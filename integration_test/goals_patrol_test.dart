// Patrol e2e for Metas de ahorro (Nivel 0, `docs/requirements/07-metas.md`,
// design spec `design-system/billetudo/pages/metas.md`). Runs the real app —
// real DI graph, real on-device Drift database, real go_router navigation —
// against a real emulator/simulator. No datasource or repository is mocked:
// this is the exact code path a user's phone runs, on top of the
// unit/widget/golden suites already covering the domain math
// (`goal_progress_calculator_test.dart`, `goal_milestone_tracker_test.dart`,
// the usecase tests) and the render pixel-by-pixel (`goal_*_golden_test.dart`).
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so scenarios never leak state
// into each other even though they share one app process.
//
// Money goes through `GoalAmountHeroField`'s `TextField` +
// `MoneyInputFormatter` via `enterText`, same convention as
// `DebtAmountHeroField` in `debts_patrol_test.dart`: COP shows no decimals,
// so `enterText('600')` reads `$600` and stores `60000` minor. Every fixed
// widget key (`goal-amount-target`, `goal-amount-movement`,
// `goal-movement-submit`) is the one `GoalFormPage`/`GoalContributionSheet`
// already declare for exactly this purpose.
//
// One scenario links a goal to an account (HU-02) to exercise that path, but
// creates the account directly through the real `AppDatabase` rather than
// driving the Cuentas UI — Cuentas already owns its own Patrol suite
// (`accounts_patrol_test.dart`) covering that creation flow; here the account
// is a fixture, not the thing under test.
import 'dart:async';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

// ---------------------------------------------------------------------------
// Navigation + setup helpers.
// ---------------------------------------------------------------------------

void _goToGoals(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.goals));
}

/// Pushes straight to "Metas archivadas" via the router rather than the
/// list's own footer link: once the only active goal gets archived, the list
/// falls back to `GoalsEmptyView` (HU-13's template-selling empty state),
/// which has no "Metas archivadas" link of its own — same direct-push
/// convention `_goToGoals`/`_goToDebts` (in `debts_patrol_test.dart`) already
/// use for a destination the current screen state does not expose.
void _goToArchivedGoals(PatrolIntegrationTester $) {
  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.archivedGoals));
}

Future<void> _openNewGoalForm(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Nueva meta'));
  await $.tester.pumpAndSettle();
}

/// Replaces the value of a money field found by [key] with [value] (a bare
/// digit string, e.g. `'300000'`) — cleared first so the new figure is an
/// insert-into-empty, same reasoning as `_replaceAmount` in
/// `budgets_patrol_test.dart`.
Future<void> _enterAmount(
  PatrolIntegrationTester $,
  Key key,
  String value,
) async {
  final field = find.byKey(key);
  await $.tester.enterText(field, '');
  await $.tester.pumpAndSettle();
  await $.tester.enterText(field, value);
  await $.tester.pumpAndSettle();
}

Future<void> _enterGoalName(PatrolIntegrationTester $, String name) async {
  await $.tester.enterText(find.byType(TextFormField), name);
  await $.tester.pumpAndSettle();
}

/// Picks the goal form's linked account (HU-02): opens the account selector,
/// then the picker sheet's only row. Only valid when at least one account
/// exists and none is selected yet.
Future<void> _linkAccount(PatrolIntegrationTester $, String accountName) async {
  await $.tester.tap(find.text('Elige una cuenta'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text(accountName));
  await $.tester.pumpAndSettle();
}

/// Picks the goal form's target date (HU-01, optional): opens the selector
/// and confirms the sheet's own default selection (today + 30 days) without
/// navigating the calendar — this suite never asserts a specific date, only
/// that a target date can be set at all.
Future<void> _pickDefaultTargetDate(PatrolIntegrationTester $) async {
  // The tappable surface is the `GoalSelectorBox`'s own hint text, not the
  // plain `GoalFieldLabel` above it ("Fecha objetivo (opcional)") — that
  // label has no `onTap` of its own.
  await $.tester.tap(find.text('Elegir una fecha posterior a hoy'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Confirmar'));
  await $.tester.pumpAndSettle();
}

/// Creates a goal with [name]/[targetWhole] and leaves the tester back on the
/// list. [accountName] links it to an already-fixtured account (HU-02) when
/// provided; [withTargetDate] exercises the optional fecha objetivo (HU-01).
Future<void> _createGoal(
  PatrolIntegrationTester $, {
  required String name,
  required String targetWhole,
  String? accountName,
  bool withTargetDate = false,
}) async {
  await _openNewGoalForm($);
  await _enterAmount($, const ValueKey('goal-amount-target'), targetWhole);
  await _enterGoalName($, name);
  if (accountName != null) {
    await _linkAccount($, accountName);
  }
  if (withTargetDate) {
    await _pickDefaultTargetDate($);
  }
  await $.tester.tap(find.text('Crear meta'));
  await $.tester.pumpAndSettle();
}

/// Opens the only `GoalCard` on the list. Only safe with exactly one card on
/// screen.
Future<void> _openOnlyGoal(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byType(GoalCard));
  await $.tester.pumpAndSettle();
}

/// Registers a contribution of [wholeAmount] on the currently open goal's
/// detail through its "Aportar" CTA (always available while the goal is
/// active and not archived, unlike the fixed quick-amount chips).
Future<void> _contribute(PatrolIntegrationTester $, String wholeAmount) async {
  await $.tester.tap(find.text('Aportar'));
  await $.tester.pumpAndSettle();
  await _enterAmount($, const ValueKey('goal-amount-movement'), wholeAmount);
  await _submitMovement($);
}

/// Registers a withdrawal of [wholeAmount] on the currently open goal's
/// detail through its "Retirar" CTA.
Future<void> _withdraw(PatrolIntegrationTester $, String wholeAmount) async {
  await $.tester.tap(find.text('Retirar'));
  await $.tester.pumpAndSettle();
  await _enterAmount($, const ValueKey('goal-amount-movement'), wholeAmount);
  await _submitMovement($);
}

/// Submits the contribution/withdrawal sheet's own CTA, then bounds the pump
/// so the write, the sheet pop, and the detail's Drift stream re-emitting all
/// land before the next assertion — same reasoning as `_submitAbono` in
/// `debts_lifecycle_patrol_test.dart`.
Future<void> _submitMovement(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byKey(const ValueKey('goal-movement-submit')));
  await $.tester.pump(const Duration(milliseconds: 500));
  await $.tester.pumpAndSettle();
}

/// Dismisses the 25/50/75% `GoalMilestoneSheet` fired automatically by a
/// contribution that crosses a threshold.
Future<void> _dismissMilestoneSheet(PatrolIntegrationTester $) async {
  await $.tester.tap(find.text('Seguir ahorrando'));
  await $.tester.pumpAndSettle();
}

/// Opens the detail's `⋮` "Más acciones" sheet.
Future<void> _openActionsMenu(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Más acciones'));
  await $.tester.pumpAndSettle();
}

Future<void> _goBack(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Atrás'));
  await $.tester.pumpAndSettle();
}

/// Inserts a bare fixture account directly through `AppDatabase` — see the
/// file header for why this bypasses the Cuentas UI.
Future<String> _insertAccount(String name) async {
  final db = getIt<AppDatabase>();
  final row = await db.into(db.accounts).insertReturning(
        AccountsCompanion.insert(
          name: name,
          type: AccountType.savings,
          currency: 'COP',
        ),
      );
  return row.id;
}

void main() {
  patrolTest(
    'HU-01 y HU-02: crear una meta con cuenta vinculada y fecha objetivo la '
    'deja visible en la lista',
    ($) async {
      await startApp($);
      final accountId = await _insertAccount('Nequi');

      _goToGoals($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createGoal(
        $,
        name: 'Viaje a Cartagena',
        targetWhole: '1000000',
        accountName: 'Nequi',
        withTargetDate: true,
      );

      // Back on the list: name, and the "Te faltan $X" headline with nothing
      // saved yet (HU-11's card).
      expect(find.text('Viaje a Cartagena'), findsOneWidget);
      expect(find.text(r'Te faltan $1.000.000'), findsOneWidget);

      final db = getIt<AppDatabase>();
      final row = await db.select(db.goals).getSingle();
      expect(row.name, 'Viaje a Cartagena');
      expect(row.targetMinor, 100000000);
      expect(row.currency, 'COP');
      expect(row.accountId, accountId);
      expect(row.targetDate, isNotNull);
      // UUID text id, never autoincrement.
      expect(int.tryParse(row.id), isNull);
      expect(row.id, hasLength(36));
      expect(row.createdAt, isNotNull);
      expect(row.updatedAt, greaterThan(0));
    },
  );

  patrolTest(
    'HU-03 y HU-06: aportar dinero a una meta reduce lo que falta y celebra el '
    'hito de 25%',
    ($) async {
      await startApp($);

      _goToGoals($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createGoal($, name: 'Fondo de emergencia', targetWhole: '1000000');

      await _openOnlyGoal($);
      expect(find.text(r'Te faltan $1.000.000'), findsOneWidget);

      final db = getIt<AppDatabase>();
      final before = await db.select(db.goals).getSingle();

      // 30% of the target: crosses the 25% threshold from a clean start, so
      // the milestone sheet (never the 100% full-screen one) must fire.
      await _contribute($, '300000');
      expect(find.text('¡Llegaste al 25%!'), findsOneWidget);
      await _dismissMilestoneSheet($);

      // Progress reflects the aporte: $700.000 left, one "Aporte" movement of
      // "+$300.000".
      expect(find.text(r'Te faltan $700.000'), findsOneWidget);
      expect(find.text('Movimientos (1)'), findsOneWidget);
      expect(find.text('Aporte'), findsOneWidget);
      expect(find.text(r'+$300.000'), findsOneWidget);

      await _goBack($);
      // The list card reflects the same figures.
      expect(find.text(r'Te faltan $700.000'), findsOneWidget);
      expect(find.text('30% completado'), findsOneWidget);

      final after = await db.select(db.goals).getSingle();
      // Crossing a milestone stamps `updatedAt` on the goal row (the
      // contribution itself lives in `GoalContributions`, a separate table).
      expect(after.updatedAt, greaterThan(before.updatedAt));
      expect(after.lastMilestonePct, 25);

      final contributions = await db.select(db.goalContributions).get();
      expect(contributions, hasLength(1));
      expect(contributions.single.amountMinor, 30000000);
      expect(
          contributions.single.direction, GoalMovementDirection.contribution);
    },
  );

  patrolTest(
    'HU-04: retirar dinero de una meta reduce lo ahorrado sin tocar el '
    'objetivo',
    ($) async {
      await startApp($);

      _goToGoals($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createGoal($, name: 'Portátil nuevo', targetWhole: '1000000');

      await _openOnlyGoal($);
      // 50% — crosses straight to the 50% milestone (25% is skipped, per
      // `GoalMilestoneTracker`'s "only the highest threshold" rule).
      await _contribute($, '500000');
      expect(find.text('¡Llegaste al 50%!'), findsOneWidget);
      await _dismissMilestoneSheet($);
      expect(find.text(r'Te faltan $500.000'), findsOneWidget);

      await _withdraw($, '200000');

      // $300.000 saved of $1.000.000 => $700.000 remaining. No new milestone
      // sheet: 30% never exceeds the already-celebrated 50%.
      expect(find.text(r'Te faltan $700.000'), findsOneWidget);
      expect(find.text('Movimientos (2)'), findsOneWidget);
      expect(find.text('Retiro'), findsOneWidget);
      expect(find.text(r'−$200.000'), findsOneWidget);

      final db = getIt<AppDatabase>();
      final row = await db.select(db.goals).getSingle();
      // A withdrawal never crosses a NEW milestone downward.
      expect(row.lastMilestonePct, 50);
      expect(row.completedAt, isNull);

      final withdrawals = await (db.select(db.goalContributions)
            ..where((t) =>
                t.direction.equalsValue(GoalMovementDirection.withdrawal)))
          .get();
      expect(withdrawals, hasLength(1));
      expect(withdrawals.single.amountMinor, 20000000);
    },
  );

  patrolTest(
    'HU-07: alcanzar el 100% abre la celebración de cierre; archivar desde '
    'ahí la saca de la lista activa y la deja en "Metas archivadas"',
    ($) async {
      await startApp($);

      _goToGoals($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createGoal($, name: 'Meta chiquita', targetWhole: '500');

      await _openOnlyGoal($);
      // A full payoff in one aporte crosses straight to 100%, which opens
      // the full-screen celebration automatically — no dismiss option, unlike
      // Deudas' "Ahora no" (see file header note in `debts_lifecycle_patrol_
      // test.dart` for that contrast; Metas has no equivalent skip here).
      await _contribute($, '500');

      expect(find.text('Meta cumplida'), findsOneWidget);
      expect(find.text('¡Cumpliste Meta chiquita!'), findsOneWidget);
      expect(find.text('Crear la próxima meta'), findsOneWidget);
      expect(find.text('Archivar meta'), findsOneWidget);

      await $.tester.tap(find.text('Archivar meta'));
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // Back on the detail: archiving hides the Aportar/Retirar row entirely.
      expect(find.text('Aportar'), findsNothing);
      expect(find.text('Retirar'), findsNothing);

      await _goBack($);
      // The list falls back to the HU-13 empty state now that its only goal
      // was archived — no "Metas archivadas" link on screen, hence the
      // direct push below.
      expect(find.text('Meta chiquita'), findsNothing);

      _goToArchivedGoals($);
      await $.tester.pumpAndSettle();
      expect(find.text('Metas archivadas'), findsOneWidget);
      expect(find.text('Meta chiquita'), findsOneWidget);

      final db = getIt<AppDatabase>();
      final row = await db.select(db.goals).getSingle();
      expect(row.completedAt, isNotNull);
      expect(row.archivedAt, isNotNull);
      // Archiving is a distinct business state, never the papelera/undo
      // mechanism.
      expect(row.deletedAt, isNull);
    },
  );

  patrolTest(
    'HU-09: archivar una meta activa desde su detalle la mueve a "Metas '
    'archivadas"; desarchivarla la devuelve a la lista principal',
    ($) async {
      await startApp($);

      _goToGoals($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createGoal($, name: 'Colchón financiero', targetWhole: '2000000');

      await _openOnlyGoal($);
      await _openActionsMenu($);
      await $.tester.tap(find.text('Archivar meta'));
      await $.tester.pumpAndSettle();
      expect(find.text('¿Archivar esta meta?'), findsOneWidget);
      await $.tester.tap(find.text('Archivar'));
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('Aportar'), findsNothing);

      await _goBack($);
      // Same empty-list fallback as the previous scenario: direct push.
      expect(find.text('Colchón financiero'), findsNothing);

      _goToArchivedGoals($);
      await $.tester.pumpAndSettle();
      expect(find.text('Colchón financiero'), findsOneWidget);

      // Desarchivarla: back into the goal, ⋮ now offers "Desarchivar meta".
      await $.tester.tap(find.text('Colchón financiero'));
      await $.tester.pumpAndSettle();
      await _openActionsMenu($);
      expect(find.text('Desarchivar meta'), findsOneWidget);
      await $.tester.tap(find.text('Desarchivar meta'));
      await $.tester.pumpAndSettle();
      expect(find.text('¿Desarchivar esta meta?'), findsOneWidget);
      await $.tester.tap(find.text('Desarchivar'));
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // Aportar/Retirar are back: no longer archived.
      expect(find.text('Aportar'), findsOneWidget);

      final db = getIt<AppDatabase>();
      final row = await db.select(db.goals).getSingle();
      expect(row.archivedAt, isNull);
    },
  );

  patrolTest(
    'HU-10: eliminar una meta pide confirmación y la quita de la lista',
    ($) async {
      await startApp($);

      _goToGoals($);
      await $.tester.pumpAndSettle();
      await dismissAutoTutorialIfShown($);
      await _createGoal($, name: 'Meta a borrar', targetWhole: '300000');

      await _openOnlyGoal($);
      await _openActionsMenu($);
      await $.tester.tap(find.text('Eliminar'));
      await $.tester.pumpAndSettle();

      // Reversible papelera copy (HU-10), never a punitive tone. Cancel path
      // first.
      expect(find.text('¿Eliminar esta meta?'), findsOneWidget);
      await $.tester.tap(find.text('Cancelar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Meta a borrar'), findsOneWidget);

      await _openActionsMenu($);
      await $.tester.tap(find.text('Eliminar'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar'));
      // Delete, the auto-pop back to the list, and the Drift stream removing
      // the row are separate async hops.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('Meta a borrar'), findsNothing);

      final db = getIt<AppDatabase>();
      final row = await db.select(db.goals).getSingle();
      expect(row.deletedAt, isNotNull);
      expect(row.tombstonedAt, isNull);
    },
  );
}
