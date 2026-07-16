// Patrol e2e for Categorías (HU-01 to HU-05). Same criteria as
// `accounts_patrol_test.dart`: the real app, real on-device Drift database,
// real go_router navigation, nothing mocked.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`).
//
// HU-06 (seed categories) is deliberately not covered here: `SeedDefaultCategories`
// has no consumer in `presentation/` yet (it depends on an onboarding flow
// that does not exist as a feature), so there is nothing on screen for
// Patrol to drive — already documented as such in
// `docs/dev-runs/categorias-feature.md`, not a new finding.
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// The "add category" app bar action's tooltip (`categoriesAdd` in the arb).
const _addCategoryTooltip = 'Crear categoría';

void main() {
  patrolTest(
    // No slash in the scenario name: AndroidTestOrchestrator turns each Dart
    // test name into an output filename, and a literal "/" is treated as a
    // path separator, crashing the whole native test run — same caveat as
    // `accounts_patrol_test.dart`, verified against a real emulator run.
    'HU-01 y HU-02: crear una categoría raíz y una subcategoría las deja '
    'visibles en el acordeón',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Ver mis categorías'));
      await $.tester.pumpAndSettle();

      // HU-01: root category, default kind (Gasto).
      await $.tester.tap(find.byTooltip(_addCategoryTooltip));
      await $.tester.pumpAndSettle();
      expect(find.text('Nueva categoría'), findsOneWidget);

      await $.tester.enterText(find.byType(TextFormField), 'Suscripciones test');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byIcon(Icons.check));
      await $.tester.pumpAndSettle();

      expect(find.text('Suscripciones test'), findsOneWidget);

      // Expand the new root (the whole row toggles the accordion) and add a
      // subcategory under it (HU-02).
      await $.tester.tap(find.text('Suscripciones test'));
      await $.tester.pumpAndSettle();
      expect(find.text('Agregar subcategoría'), findsOneWidget);

      await $.tester.tap(find.text('Agregar subcategoría'));
      await $.tester.pumpAndSettle();
      expect(find.text('Nueva subcategoría'), findsOneWidget);
      // Tipo is locked and pre-filled with the parent's kind: no Tipo toggle
      // interaction needed here, only the "Categoría padre" read-only field
      // already showing the parent's name.
      expect(find.text('Suscripciones test'), findsOneWidget);

      await $.tester.enterText(find.byType(TextFormField), 'Netflix test');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byIcon(Icons.check));
      await $.tester.pumpAndSettle();

      // Back on the (still expanded) list: root, subcategory count and the
      // new subcategory are all visible.
      expect(find.text('Suscripciones test'), findsOneWidget);
      expect(find.text('1 subcategoría'), findsOneWidget);
      expect(find.text('Netflix test'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-04 caso 1: eliminar una categoría sin subcategorías ni transacciones '
    'la quita de la lista',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Ver mis categorías'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip(_addCategoryTooltip));
      await $.tester.pumpAndSettle();
      await $.tester.enterText(find.byType(TextFormField), 'Borrame test');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byIcon(Icons.check));
      await $.tester.pumpAndSettle();

      expect(find.text('Borrame test'), findsOneWidget);

      // The row's own edit affordance (next to the chevron), not the row tap
      // (which only toggles the accordion).
      await $.tester.tap(find.byTooltip('Editar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Editar categoría'), findsOneWidget);

      await $.tester.tap(find.text('Eliminar categoría'));
      await $.tester.pumpAndSettle();

      // No dependents: the neutral (non-destructive-styled) confirm sheet.
      expect(find.text('¿Eliminar esta categoría?'), findsOneWidget);
      await $.tester.tap(find.text('Eliminar'));
      await $.tester.pumpAndSettle();
      // Same async-hop caveat as accounts_patrol_test.dart: the delete, the
      // pop back to the list and the Drift stream update are separate hops.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('Borrame test'), findsNothing);
    },
  );

  patrolTest(
    'HU-03: renombrar una categoría raíz actualiza el listado',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Ver mis categorías'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip(_addCategoryTooltip));
      await $.tester.pumpAndSettle();
      await $.tester.enterText(find.byType(TextFormField), 'Original test');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byIcon(Icons.check));
      await $.tester.pumpAndSettle();

      expect(find.text('Original test'), findsOneWidget);

      await $.tester.tap(find.byTooltip('Editar'));
      await $.tester.pumpAndSettle();
      expect(find.text('Editar categoría'), findsOneWidget);

      await $.tester.enterText(find.byType(TextFormField), 'Renombrada test');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byIcon(Icons.check));
      await $.tester.pumpAndSettle();

      // Back on the list: the rename persisted, the old name is gone.
      expect(find.text('Renombrada test'), findsOneWidget);
      expect(find.text('Original test'), findsNothing);
    },
  );

  patrolTest(
    'HU-04 caso 2: eliminar una categoría con transacciones asociadas y '
    'dejarlas sin categoría las quita de la lista sin borrar los '
    'movimientos',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Ver mis categorías'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip(_addCategoryTooltip));
      await $.tester.pumpAndSettle();
      await $.tester.enterText(find.byType(TextFormField), 'ConTx test');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byIcon(Icons.check));
      await $.tester.pumpAndSettle();

      expect(find.text('ConTx test'), findsOneWidget);

      // There is no Transacciones UI to seed a real movement from yet (the
      // feature is a blank canvas per CLAUDE.md), so this seeds one directly
      // against the same real on-device Drift database the app itself reads
      // from — a genuine row in `Transactions.categoryId`, not a mock —
      // which is the simplest way to exercise this branch end to end. The
      // category id is not user-visible, so it is read back from the DB by
      // the name just typed above.
      final db = getIt<AppDatabase>();
      final category = await (db.select(db.categories)
            ..where((c) => c.name.equals('ConTx test')))
          .getSingle();
      final account = await db.into(db.accounts).insertReturning(
            AccountsCompanion.insert(
              name: 'Cuenta seed',
              type: AccountType.cash,
              currency: 'COP',
            ),
          );
      final transaction = await db.into(db.transactions).insertReturning(
            TransactionsCompanion.insert(
              accountId: account.id,
              categoryId: Value(category.id),
              amountMinor: 50000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 7, 15),
            ),
          );

      await $.tester.tap(find.byTooltip('Editar'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar categoría'));
      await $.tester.pumpAndSettle();

      // With an associated transaction, this is the "reasignar / dejar sin
      // categoría" sheet, distinguishable from the simple one by its count
      // message.
      expect(find.text('Tiene 1 movimiento asociado.'), findsOneWidget);
      // "Dejar sin categoría" is already the default radio choice: no extra
      // tap needed before confirming.
      await $.tester.tap(find.text('Eliminar'));
      await $.tester.pumpAndSettle();
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('ConTx test'), findsNothing);

      // The transaction itself survived (only its category link was
      // cleared) — asserted against the same real database, not inferred
      // from the UI, since there is no Transacciones screen yet to show it.
      final survivingTransaction = await (db.select(db.transactions)
            ..where((t) => t.id.equals(transaction.id)))
          .getSingle();
      expect(survivingTransaction.categoryId, isNull);
      expect(survivingTransaction.deletedAt, isNull);
    },
  );

  patrolTest(
    'HU-04 caso 3: eliminar una categoría raíz con subcategorías activas '
    'en cascada las borra a ambas',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Ver mis categorías'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip(_addCategoryTooltip));
      await $.tester.pumpAndSettle();
      await $.tester.enterText(find.byType(TextFormField), 'RootCascade test');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byIcon(Icons.check));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.text('RootCascade test'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Agregar subcategoría'));
      await $.tester.pumpAndSettle();
      await $.tester.enterText(find.byType(TextFormField), 'SubCascade test');
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byIcon(Icons.check));
      await $.tester.pumpAndSettle();

      expect(find.text('RootCascade test'), findsOneWidget);
      expect(find.text('SubCascade test'), findsOneWidget);

      await $.tester.tap(find.byTooltip('Editar'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar categoría'));
      await $.tester.pumpAndSettle();

      // Active subcategories: the "system restriction" sheet, not the plain
      // confirm one.
      expect(find.text('Esta categoría tiene subcategorías'), findsOneWidget);
      await $.tester.tap(find.text('Eliminar todo en cascada'));
      await $.tester.pumpAndSettle();

      // Cascade asks for a second, explicit confirmation before it commits.
      expect(
        find.text('¿Eliminar la categoría y sus subcategorías?'),
        findsOneWidget,
      );
      await $.tester.tap(find.text('Eliminar'));
      await $.tester.pumpAndSettle();
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('RootCascade test'), findsNothing);
      expect(find.text('SubCascade test'), findsNothing);
    },
  );

  patrolTest(
    'HU-05: arrastrar una categoría raíz reordena la lista y el nuevo '
    'orden persiste',
    ($) async {
      await startApp($);

      await $.tester.tap(find.text('Ver mis categorías'));
      await $.tester.pumpAndSettle();

      for (final name in ['Primera cat', 'Segunda cat']) {
        await $.tester.tap(find.byTooltip(_addCategoryTooltip));
        await $.tester.pumpAndSettle();
        await $.tester.enterText(find.byType(TextFormField), name);
        await $.tester.pumpAndSettle();
        await $.tester.tap(find.byIcon(Icons.check));
        await $.tester.pumpAndSettle();
      }

      // Created in this order, "Primera cat" sorts first (lowest sortOrder).
      final firstTop = $.tester.getCenter(find.text('Primera cat')).dy;
      final secondTop = $.tester.getCenter(find.text('Segunda cat')).dy;
      expect(firstTop, lessThan(secondTop));

      // Long-press-drag "Primera cat" below "Segunda cat" — small
      // incremental steps with a pump after each, same reasoning as
      // `accounts_patrol_test.dart`'s HU-09: a single big `moveTo` jump does
      // not give the delayed drag recognizer per-frame pointer updates to
      // react to, so the item never actually picks up.
      final start = $.tester.getCenter(find.text('Primera cat'));
      final end =
          $.tester.getCenter(find.text('Segunda cat')) + const Offset(0, 40);
      final gesture = await $.tester.startGesture(start);
      await $.tester.pump(const Duration(milliseconds: 600));
      const steps = 10;
      for (var i = 1; i <= steps; i++) {
        await gesture.moveTo(Offset.lerp(start, end, i / steps)!);
        await $.tester.pump(const Duration(milliseconds: 50));
      }
      await $.tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await $.tester.pumpAndSettle();

      final newFirstTop = $.tester.getCenter(find.text('Segunda cat')).dy;
      final newSecondTop = $.tester.getCenter(find.text('Primera cat')).dy;
      expect(
        newFirstTop,
        lessThan(newSecondTop),
        reason: 'after the drag, Segunda cat should render above Primera cat',
      );
    },
  );
}
