import 'package:billetudo/features/onboarding/presentation/pages/closing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-04 (`Gi0NV`/`Bylcp`, skipped-account variant `bAKS6`/`ld3xh`): "Cierre:
/// tu primer movimiento" — two distinguishable business states: an account
/// was created (CTA registers a movement) vs. the account step was skipped
/// (CTA bridges to creating one, `15-gate-cuenta.md`'s generic copy).
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required bool accountSkipped,
    required Brightness brightness,
  }) async {
    await pumpGolden(
      tester,
      ClosingPage(accountSkipped: accountSkipped, onPrimary: () {}, onSkip: () {}),
      brightness: brightness,
    );
    await expectLater(
      find.byType(ClosingPage),
      matchesGoldenFile('goldens/closing_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('account created ($suffix)', (tester) async {
      await golden(
        tester,
        'account_created_$suffix',
        accountSkipped: false,
        brightness: brightness,
      );
    });

    testWidgets('account skipped ($suffix)', (tester) async {
      await golden(
        tester,
        'account_skipped_$suffix',
        accountSkipped: true,
        brightness: brightness,
      );
    });
  }
}
