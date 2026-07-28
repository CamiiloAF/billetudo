import 'package:billetudo/features/goals/presentation/widgets/goal_milestone_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-06's 25/50/75% celebration sheet (`E2RRw`/`YUwKy`/`CFFdo`): an arc
/// filled to the crossed threshold plus forward-looking copy. The 100%
/// milestone opens `GoalCompletedCelebrationPage` instead, never this sheet
/// — so only the 3 intermediate thresholds are captured here.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    int milestonePct,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => GoalMilestoneSheet.show(
              context,
              goalName: 'Viaje a Cartagena',
              milestonePct: milestonePct,
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('hito 25% ($suffix)', (tester) async {
      await golden(tester, 25, 'goal_milestone_25_$suffix', brightness: brightness);
    });

    testWidgets('hito 50% ($suffix)', (tester) async {
      await golden(tester, 50, 'goal_milestone_50_$suffix', brightness: brightness);
    });

    testWidgets('hito 75% ($suffix)', (tester) async {
      await golden(tester, 75, 'goal_milestone_75_$suffix', brightness: brightness);
    });
  }
}
