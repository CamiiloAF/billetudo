import 'package:billetudo/features/auth/presentation/pages/account_deleted_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-07 paso 3 (`sqm4I` / `q43mHJ`): the neutral closing screen of account
/// deletion. Stateless — a single business state per theme.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('account deleted ($suffix)', (tester) async {
      await pumpGolden(
        tester,
        AccountDeletedPage(onGoHome: () {}),
        brightness: brightness,
      );
      await expectLater(
        find.byType(AccountDeletedPage),
        matchesGoldenFile('goldens/account_deleted_page_$suffix.png'),
      );
    });
  }
}
