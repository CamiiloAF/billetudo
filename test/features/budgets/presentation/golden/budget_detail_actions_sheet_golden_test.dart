import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_detail_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The detail overflow ("⋮") sheet: Editar · Usar como destacado en Inicio
/// (o Quitar de Inicio) · Ajustar monto · Cerrar (guardar en histórico) ·
/// Eliminar (en `$expense-text`).
///
/// Pencil row (`design-system/billetudo/pages/presupuestos.md`):
/// `detail_actions` → `G26c4T` / `f1WviW` (Sheet — acciones del detalle ⋮);
/// the "Destacar en Inicio" row is `gFBcD` (OFF) / `yaRtv` (ON).
///
/// The sheet has one piece of business state — `isFeatured` — so both values
/// get their own golden per theme. Opened through a real trigger so the
/// golden includes the scrim, the drag handle and the `BottomSheetBase`
/// chrome.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required bool isFeatured,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BudgetDetailActionsSheet.show(
              context,
              budgetName: 'Mercado del mes',
              isFeatured: isFeatured,
            ),
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

    testWidgets('acciones del detalle, no destacado ($suffix)',
        (tester) async {
      await golden(
        tester,
        'detail_actions_$suffix',
        brightness: brightness,
        isFeatured: false,
      );
    });

    testWidgets('acciones del detalle, ya destacado ($suffix)',
        (tester) async {
      await golden(
        tester,
        'detail_actions_featured_$suffix',
        brightness: brightness,
        isFeatured: true,
      );
    });
  }
}
