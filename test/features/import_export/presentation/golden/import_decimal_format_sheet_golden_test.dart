import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/import_decimal_format_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-05 mapping step, "Convención decimal" field: punto vs. coma, the
/// active one highlighted, live preview of the first real row's raw amount
/// value under the currently highlighted option.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('decimal format sheet ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ImportDecimalFormatSheet.show(
                context,
                current: DecimalConvention.dot,
                sampleValue: '1.234,56',
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
        find.byType(ImportDecimalFormatSheet),
        matchesGoldenFile('goldens/import_decimal_format_sheet_$suffix.png'),
      );
    });
  }
}
