import 'package:billetudo/features/goals/presentation/widgets/sheets/goals_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/golden_helpers.dart';

/// Pencil row (`design-system/billetudo/pages/minitutoriales.md` HU-03):
/// `c9tyn1` (menú `⋮` de Metas, claro) → `V46Bbp` (oscuro). The sheet is
/// stateless — one business state per theme.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('golden: menú ⋮ de Metas ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => GoalsMenuSheet.show(context),
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
        matchesGoldenFile('goldens/goals_menu_sheet_$suffix.png'),
      );
    });
  }
}
