import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/import_export/domain/entities/import_summary.dart';
import 'package:billetudo/features/import_export/presentation/widgets/sheets/import_skipped_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// "Ver N omitidas y por qué" (`XRBVa`/`Aa1ek`): the closing summary always
/// exposes why rows were skipped, not only the count. Three distinguishable
/// business states — only duplicates, only errors, both reasons at once —
/// since the sheet conditionally renders each reason row independently.
void main() {
  ImportBatch batchWith({required int imported, required int skipped}) => ImportBatch(
        id: 'batch-1',
        fileName: 'movimientos-banco.csv',
        importedAt: DateTime(2026, 7, 20),
        rowsImported: imported,
        rowsSkipped: skipped,
        createdAt: DateTime(2026, 7, 20),
        updatedAt: 0,
      );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('only duplicates ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ImportSkippedSheet.show(
                context,
                summary: ImportSummary(
                  batch: batchWith(imported: 40, skipped: 3),
                  rowsImported: 40,
                  rowsSkippedDuplicate: 3,
                  rowsSkippedError: 0,
                  accountsCreated: 0,
                  categoriesCreated: 0,
                  tagsCreated: 0,
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
        find.byType(ImportSkippedSheet),
        matchesGoldenFile('goldens/import_skipped_sheet_duplicates_only_$suffix.png'),
      );
    });

    testWidgets('only errors ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ImportSkippedSheet.show(
                context,
                summary: ImportSummary(
                  batch: batchWith(imported: 38, skipped: 2),
                  rowsImported: 38,
                  rowsSkippedDuplicate: 0,
                  rowsSkippedError: 2,
                  accountsCreated: 0,
                  categoriesCreated: 0,
                  tagsCreated: 0,
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
        find.byType(ImportSkippedSheet),
        matchesGoldenFile('goldens/import_skipped_sheet_errors_only_$suffix.png'),
      );
    });

    testWidgets('both reasons ($suffix)', (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ImportSkippedSheet.show(
                context,
                summary: ImportSummary(
                  batch: batchWith(imported: 35, skipped: 5),
                  rowsImported: 35,
                  rowsSkippedDuplicate: 3,
                  rowsSkippedError: 2,
                  accountsCreated: 1,
                  categoriesCreated: 1,
                  tagsCreated: 0,
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
        find.byType(ImportSkippedSheet),
        matchesGoldenFile('goldens/import_skipped_sheet_both_$suffix.png'),
      );
    });
  }
}
