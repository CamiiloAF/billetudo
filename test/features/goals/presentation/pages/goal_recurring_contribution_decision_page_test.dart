import 'package:billetudo/features/goals/presentation/cubit/goal_recurring_contribution_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_recurring_contribution_decision_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// HU-16's entry sheet (`HOdfO`/`XB4rS`): behavior coverage complementing the
/// golden — which decision each CTA resolves the sheet's future to.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  testWidgets(
      'tocar "Crear uno nuevo" cierra la hoja con GoalRecurringContributionDecision.createNew',
      (tester) async {
    GoalRecurringContributionDecision? result;
    await pumpGolden(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await GoalRecurringContributionDecisionPage.show(
              context,
              goalName: 'Viaje a Cartagena',
            );
          },
          child: const Text('open'),
        ),
      ),
      brightness: Brightness.light,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('goal-recurring-contribution-create-new')),
    );
    await tester.pumpAndSettle();

    expect(result, GoalRecurringContributionDecision.createNew);
  });

  testWidgets(
      'tocar "Enlazar existente" cierra la hoja con GoalRecurringContributionDecision.linkExisting',
      (tester) async {
    GoalRecurringContributionDecision? result;
    await pumpGolden(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await GoalRecurringContributionDecisionPage.show(
              context,
              goalName: 'Viaje a Cartagena',
            );
          },
          child: const Text('open'),
        ),
      ),
      brightness: Brightness.light,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('goal-recurring-contribution-link-existing')),
    );
    await tester.pumpAndSettle();

    expect(result, GoalRecurringContributionDecision.linkExisting);
  });
}
