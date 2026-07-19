import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_detail_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The detail overflow ("⋮") sheet: Editar · Cerrar (guardar en histórico) ·
/// Eliminar (en `$expense-text`).
///
/// Pencil row (`design-system/billetudo/pages/presupuestos.md`):
/// `detail_actions` → `G26c4T` / `f1WviW` (Sheet — acciones del detalle ⋮).
///
/// The sheet is stateless — it offers the same three actions for every budget
/// (recurrente, una única vez, sobregastado), so there is a single business
/// state to capture per theme. Opened through a real trigger so the golden
/// includes the scrim, the drag handle and the `BottomSheetBase` chrome.
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
            onPressed: () => BudgetDetailActionsSheet.show(context),
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

    testWidgets('acciones del detalle ($suffix)', (tester) async {
      await golden(tester, 'detail_actions_$suffix', brightness: brightness);
    });
  }
}
