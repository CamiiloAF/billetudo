import 'package:billetudo/features/capture/presentation/widgets/suggested_category_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// `oKokr` — "Sugerida: {categoría}", extracted from
/// `MovementPendingCaptureCard` into its own public widget on 2026-09-09.
/// Covers the chip alone (short name and a long one that must truncate
/// rather than push the row wider), since it now has an independent public
/// surface a caller other than the card could reuse.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name,
    String chipName, {
    required Brightness brightness,
  }) async {
    await pumpGolden(
      tester,
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 200,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SuggestedCategoryChip(name: chipName),
            ),
          ),
        ),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/suggested_category_chip_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('short category name ($suffix)', (tester) async {
      await golden(tester, 'short_$suffix', 'Mercado', brightness: brightness);
    });

    testWidgets('long category name truncates ($suffix)', (tester) async {
      await golden(
        tester,
        'long_$suffix',
        'Restaurantes y comida a domicilio',
        brightness: brightness,
      );
    });
  }
}
