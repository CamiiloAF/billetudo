import 'package:billetudo/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// `Splash - B Wordmark` (`bSOQb` light / `raS94` dark in billetudo.pen —
/// `design-system/billetudo/pages/splash.md`). A single fixed state: no
/// empty/error/loading variants (the spec explicitly rules those out — it
/// doesn't query data that can fail visibly on this screen), just the two
/// themes.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('splash ($suffix)', (tester) async {
      await pumpGolden(
        tester,
        const SplashPage(),
        brightness: brightness,
        // The spinner is an indeterminate `CircularProgressIndicator` whose
        // `AnimationController` repeats forever, so `pumpAndSettle` would
        // never return: capture a single deterministic frame instead (its
        // start position is fixed, not random).
        settle: false,
      );
      // `pumpGolden`'s single `pump()` lands at t=0, where the indeterminate
      // arc's sweep is nearly zero — advance partway into the loop so the
      // golden actually shows the 270° arc, matching the reference frame.
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(SplashPage),
        matchesGoldenFile('goldens/splash_page_$suffix.png'),
      );
    });
  }
}
