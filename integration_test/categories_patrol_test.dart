// Patrol e2e for Categorías (HU-01 to HU-04). Same criteria as
// `accounts_patrol_test.dart`: the real app, real on-device Drift database,
// real go_router navigation, nothing mocked.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`).
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
}
