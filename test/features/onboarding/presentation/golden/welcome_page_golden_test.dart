import 'package:billetudo/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-01 (`fRrDQ`/`mmFVh`): "Bienvenida" — the only screen, so there is a
/// single business-state case: the plain welcome content with its
/// "Comenzar"/"Ya tengo cuenta" actions.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
  }) async {
    await pumpGolden(
      tester,
      WelcomePage(onComenzar: () {}, onYaTengoCuenta: () {}),
      brightness: brightness,
    );
    await expectLater(
      find.byType(WelcomePage),
      matchesGoldenFile('goldens/welcome_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('welcome ($suffix)', (tester) async {
      await golden(tester, suffix, brightness: brightness);
    });
  }
}
