import 'package:billetudo/core/sync/presentation/widgets/discard_all_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// "Descartar todo (N)" (`CXdn5`, inside `OgoAn`): the bulk discard entry
/// point on the full pending list (`rxUil`). Only the count changes what
/// renders (singular vs. plural label), the rest of the visual is fixed.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('discard all link — plural ($suffix)', (tester) async {
      await pumpGolden(
        tester,
        DiscardAllLink(count: 89, onTap: () {}),
        brightness: brightness,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/discard_all_link_$suffix.png'),
      );
    });

    testWidgets('discard all link — singular ($suffix)', (tester) async {
      await pumpGolden(
        tester,
        DiscardAllLink(count: 1, onTap: () {}),
        brightness: brightness,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/discard_all_link_singular_$suffix.png'),
      );
    });
  }
}
