import 'package:billetudo/features/import_export/presentation/widgets/sheets/import_type_values_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-05 mapping step, "Gasto o ingreso se expresa con" field: toggle
/// between a `tipo` column (editable literals, prefilled from what was
/// detected/confirmed) and the amount's sign, with a live preview of how the
/// first real row classifies under whichever option is highlighted — the
/// scenario a foreign export like Wallet/BudgetBakers needs (its own
/// "Gastos"/"Ingresos" literals typed in by hand).
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('type values sheet, column mode ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ImportTypeValuesSheet.show(
                context,
                initialUseColumn: true,
                currentValues: null,
                columnSampleValue: 'Gastos',
                amountSampleValue: '19.99',
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
        find.byType(ImportTypeValuesSheet),
        matchesGoldenFile('goldens/import_type_values_sheet_column_$suffix.png'),
      );
    });

    testWidgets('type values sheet, amount sign mode ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ImportTypeValuesSheet.show(
                context,
                initialUseColumn: false,
                currentValues: null,
                columnSampleValue: null,
                amountSampleValue: '-19.99',
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
        find.byType(ImportTypeValuesSheet),
        matchesGoldenFile('goldens/import_type_values_sheet_sign_$suffix.png'),
      );
    });
  }
}
