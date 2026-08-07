import 'package:billetudo/features/import_export/presentation/pages/import_file_select_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// Former HU-05 entry sheet (`W2hiZK`/`rsBfI`, marked OBSOLETO in
/// `billetudo.pen`, decisión 2026-08-06). `ImportFlowPage` no longer routes
/// here in the normal flow — "Importar desde un CSV" opens the OS's native
/// file picker directly — but `ImportFlowBody` still falls back to it for
/// the defensive (should never happen) case of reaching the mapping step
/// without a parsed sample. One business state: it renders the same shape
/// regardless of how it was reached.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('file select fallback ($suffix)', (tester) async {
      await pumpGolden(
        tester,
        ImportFileSelectStep(onPickFile: () {}, onCancel: () {}),
        brightness: brightness,
      );

      await expectLater(
        find.byType(ImportFileSelectStep),
        matchesGoldenFile('goldens/import_file_select_step_$suffix.png'),
      );
    });
  }
}
