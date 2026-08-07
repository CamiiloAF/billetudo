import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/import_export/domain/entities/named_entity.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/existing_destination_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-06 "mapear a existente" picker, opened from `UnresolvedDestinationRow`.
/// Two distinguishable business states: options available to map to, and no
/// existing entities of that kind at all (`importExportDestinationsPickerEmpty`).
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('with options ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BottomSheetBase.show<NamedEntity>(
                context,
                builder: (context) => const ExistingDestinationPickerSheet(
                  options: [
                    NamedEntity(id: 'acc-1', name: 'Bancolombia'),
                    NamedEntity(id: 'acc-2', name: 'Nequi'),
                    NamedEntity(id: 'acc-3', name: 'Efectivo'),
                  ],
                ),
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
        find.byType(ExistingDestinationPickerSheet),
        matchesGoldenFile('goldens/existing_destination_picker_sheet_with_options_$suffix.png'),
      );
    });

    testWidgets('empty ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BottomSheetBase.show<NamedEntity>(
                context,
                builder: (context) => const ExistingDestinationPickerSheet(options: []),
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
        find.byType(ExistingDestinationPickerSheet),
        matchesGoldenFile('goldens/existing_destination_picker_sheet_empty_$suffix.png'),
      );
    });
  }
}
