import 'package:billetudo/features/debts/presentation/widgets/sheets/debts_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/golden_helpers.dart';

/// Pencil row (`design-system/billetudo/pages/minitutoriales.md` HU-03):
/// `lTUQr` (menú `⋮` de Deudas, claro) → `LftRt` (oscuro). The sheet is
/// stateless — one business state per theme.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('golden: menú ⋮ de Deudas ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DebtsMenuSheet.show(context),
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
        matchesGoldenFile('goldens/debts_menu_sheet_$suffix.png'),
      );
    });
  }
}
