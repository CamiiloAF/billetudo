import 'package:billetudo/features/goals/presentation/pages/goal_completed_celebration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-07's 100% full-screen celebration: a festive `$mint-soft` background, a
/// trophy medallion, permanent-achievement copy, and two forward-looking
/// CTAs. Pure `StatelessWidget`, no cubit — parameterized directly.
///
/// States captured: the default case and a long goal name (wraps to two
/// lines without overflowing). Each in light and dark.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    Widget page,
    String name, {
    required Brightness brightness,
  }) async {
    await pumpGolden(tester, page, brightness: brightness);
    await expectLater(
      find.byType(GoalCompletedCelebrationPage),
      matchesGoldenFile('goldens/goal_completed_celebration_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('meta cumplida ($suffix)', (tester) async {
      await golden(
        tester,
        GoalCompletedCelebrationPage(
          goalName: 'Fondo de emergencia',
          savedMinor: 2000000,
          currency: 'COP',
          onCreateNext: () {},
          onArchive: () {},
        ),
        'default_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('nombre largo: envuelve a dos líneas ($suffix)',
        (tester) async {
      await golden(
        tester,
        GoalCompletedCelebrationPage(
          goalName: 'Viaje familiar de fin de año a la playa',
          savedMinor: 12500000,
          currency: 'COP',
          onCreateNext: () {},
          onArchive: () {},
        ),
        'long_name_$suffix',
        brightness: brightness,
      );
    });
  }
}
