import 'package:billetudo/features/budgets/presentation/widgets/sheets/confirm_delete_budget_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The delete confirmation (HU-11): neutral, reversible tone — `trash-2` on
/// `$primary-soft`/`$primary-on-soft` (violeta, nunca rojo: el borrado va a la
/// papelera y se puede deshacer).
///
/// Pencil row (`design-system/billetudo/pages/presupuestos.md`):
/// `confirm_delete_light` → `hxkUC` (Sheet — eliminar presupuesto).
/// `confirm_delete_dark` **no tiene par oscuro en el `.pen`** ("_pendiente
/// (tema oscuro aún no existe)_" en la tabla del spec): se genera igual, pero
/// el auditor no tiene contra qué compararlo hasta que se diseñe.
///
/// The sheet is stateless — one business state per theme.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDeleteBudgetSheet.show(context),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('confirmar eliminar presupuesto ($suffix)', (tester) async {
      await golden(tester, 'confirm_delete_$suffix', brightness: brightness);
    });
  }
}
