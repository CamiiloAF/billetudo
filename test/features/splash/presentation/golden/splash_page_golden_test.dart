import 'package:billetudo/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// `Splash - B Wordmark + Icono (v2)` (`QUsfN` light / `U0WjJ` dark in
/// billetudo.pen — `design-system/billetudo/pages/splash.md`). A single
/// fixed state: no empty/error/loading variants (the spec explicitly rules
/// those out — it doesn't query data that can fail visibly on this screen),
/// just the two themes.
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
      // The App Icon's `Image.asset` decodes its codec through a real
      // (non-fake-clocked) Future; `tester.pump(duration)` alone advances the
      // virtual clock but doesn't reliably let that Future resolve, so
      // without this the icon silently paints as empty on the first run.
      // `runAsync` steps outside the fake-async zone to let it actually
      // finish before the next frame.
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/branding/ic_launcher_master.png'),
          tester.element(find.byType(SplashPage)),
        ),
      );
      // The entrance animation (Brand Block fade/scale + Bottom Block fade)
      // is a one-shot that finishes at 600ms (150ms delay + 200ms fade);
      // advance well past it first so the golden captures the settled
      // post-animation state, deterministically.
      await tester.pump(const Duration(milliseconds: 700));
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
