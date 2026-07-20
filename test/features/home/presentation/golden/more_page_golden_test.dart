import 'package:billetudo/features/home/presentation/pages/more_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required bool isSignedIn,
  }) async {
    await pumpGolden(
      tester,
      MorePage(
        onOpenAccounts: () {},
        onOpenCategories: () {},
        onOpenScheduledPayments: () {},
        onOpenComingSoon: (_) {},
        onOpenSettings: () {},
        isSignedIn: isSignedIn,
        onSignOut: () {},
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(MorePage),
      matchesGoldenFile('goldens/more_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('signed out, no "Cerrar sesión" row ($suffix)',
        (tester) async {
      await golden(
        tester,
        'signed_out_$suffix',
        brightness: brightness,
        isSignedIn: false,
      );
    });

    testWidgets('signed in, "Cerrar sesión" row visible (HU-06) ($suffix)',
        (tester) async {
      await golden(
        tester,
        'signed_in_$suffix',
        brightness: brightness,
        isSignedIn: true,
      );
    });
  }
}
