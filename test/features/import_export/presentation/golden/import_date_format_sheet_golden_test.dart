import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/import_date_format_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-05 mapping step, "Formato de fecha" field: every `DateComponentOrder` ×
/// `DateSeparatorChar` combination, the active one highlighted, live preview
/// of the first real row's raw date value under the currently highlighted
/// option.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('date format sheet ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ImportDateFormatSheet.show(
                context,
                currentOrder: DateComponentOrder.dayMonthYear,
                currentSeparator: DateSeparatorChar.slash,
                sampleValue: '05/07/2026 22:14:10',
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
        find.byType(ImportDateFormatSheet),
        matchesGoldenFile('goldens/import_date_format_sheet_$suffix.png'),
      );
    });
  }
}
