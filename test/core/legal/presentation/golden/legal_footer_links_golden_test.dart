import 'package:billetudo/core/legal/presentation/widgets/legal_footer_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// Golden coverage for Bienvenida's discreet legal footer (Pencil
/// `E4mWb`/`fRrDQ`): the two links plus the dot separator, in isolation.
/// The full page context is covered by `welcome_page_golden_test.dart`; this
/// is the widget on its own, which is what AC 16 requires explicitly.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('pie legal con dos enlaces ($suffix)', (tester) async {
      await pumpGolden(
        tester,
        const Padding(
          padding: EdgeInsets.all(24),
          child: LegalFooterLinks(),
        ),
        brightness: brightness,
        size: const Size(390, 120),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/legal_footer_links_$suffix.png'),
      );
    });
  }
}
