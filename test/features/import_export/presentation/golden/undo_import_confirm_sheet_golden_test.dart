import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/undo_import_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-08's "Deshacer esta importación" confirmation (`l1twf`/`r59P4P`). One
/// business state — the sheet has no async status of its own, it always
/// shows the same confirmation shape for a given batch.
void main() {
  final batch = ImportBatch(
    id: 'batch-1',
    fileName: 'movimientos-banco.csv',
    importedAt: DateTime(2026, 7, 20),
    rowsImported: 128,
    rowsSkipped: 3,
    createdAt: DateTime(2026, 7, 20),
    updatedAt: 0,
  );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('undo confirmation ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => UndoImportConfirmSheet.show(context, batch: batch),
              child: const Text('open'),
            ),
          ),
          brightness: brightness,
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(UndoImportConfirmSheet),
        matchesGoldenFile('goldens/undo_import_confirm_sheet_$suffix.png'),
      );
    });
  }
}
