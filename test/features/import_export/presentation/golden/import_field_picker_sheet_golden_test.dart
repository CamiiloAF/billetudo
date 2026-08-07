import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/import_export/domain/entities/column_mapping.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/import_field_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-05/06 mapping step column picker, opened from `ImportMappingStep`.
/// The sheet's render does not vary with the current mapping (every field
/// lists the same way regardless of what is already assigned), so one
/// business state is enough — this covers the "No usar" sentinel row plus
/// the full [ImportField] list, in both themes.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  const mapping = ColumnMapping(
    columns: {ImportField.date: 0, ImportField.amount: 1, ImportField.account: 2},
  );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('field picker ($suffix)', (tester) async {
      setGoldenViewport(tester, tallGoldenPhoneSize(height: 1000));
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BottomSheetBase.show<Object?>(
                context,
                builder: (context) => const ImportFieldPickerSheet(currentMapping: mapping),
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
        find.byType(ImportFieldPickerSheet),
        matchesGoldenFile('goldens/import_field_picker_sheet_$suffix.png'),
      );
    });
  }
}
