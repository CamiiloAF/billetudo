import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_icon_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// The budget icon picker: the shared 64-icon catalog grid, **icon only, no
/// color** (a budget's wrap stays neutral `$muted`, HU-01).
///
/// Pencil row (`design-system/billetudo/pages/presupuestos.md`):
/// `icon_sheet_none_selected` and `icon_sheet_selected` → `XsnnD` / `Al6tQ`
/// (Sheet — elegir ícono). Two business states: nothing picked yet (creating)
/// and one picked (`credit-card`, a real entry of `CategoryIconCatalog.names`,
/// so the selected treatment is actually visible).
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String? selected,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BudgetIconSheet.show(context, selected: selected),
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

    testWidgets('elegir ícono, sin selección ($suffix)', (tester) async {
      await golden(
        tester,
        null,
        'icon_sheet_none_selected_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('elegir ícono, con uno seleccionado ($suffix)', (tester) async {
      await golden(
        tester,
        'credit-card',
        'icon_sheet_selected_$suffix',
        brightness: brightness,
      );
    });
  }
}
