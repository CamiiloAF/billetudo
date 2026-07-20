import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-12, criterion 5: the bar renders three contiguous segments — spent
/// (solid), programado (`$primary-light` sano / `$amber` en riesgo) and the
/// unused remainder — with widths proportional to their fractions.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required double fraction,
    required bool overspent,
    double scheduledFraction = 0,
    bool scheduledAtRisk = false,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: BudgetProgressBar(
                fraction: fraction,
                overspent: overspent,
                scheduledFraction: scheduledFraction,
                scheduledAtRisk: scheduledAtRisk,
              ),
            ),
          ),
        ),
      );

  List<Container> segmentContainers(WidgetTester tester) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(BudgetProgressBar),
          matching: find.byType(Container),
        ),
      )
      .toList();

  testWidgets(
      'with no scheduled fraction, only the track and spent segment '
      'render', (tester) async {
    await pump(tester, fraction: 0.4, overspent: false);

    final containers = segmentContainers(tester);
    // Track + spent segment, no third one.
    expect(containers.length, 2);
  });

  testWidgets(
      'a positive scheduled fraction adds a third, contiguous '
      'segment sized to its own width', (tester) async {
    await pump(
      tester,
      fraction: 0.4,
      overspent: false,
      scheduledFraction: 0.3,
    );

    final containers = segmentContainers(tester);
    expect(containers.length, 3);

    const colors = AppColors.light;
    // The 2nd Container drawn is the solid spent fill, the 3rd the sano
    // "programado" one.
    expect(containers[1].color, colors.primary);
    expect(containers[2].color, colors.primaryLight);

    final spentBox = tester.getSize(
      find.byWidgetPredicate((widget) => widget == containers[1]),
    );
    final scheduledBox = tester.getSize(
      find.byWidgetPredicate((widget) => widget == containers[2]),
    );
    // 300 * 0.4 = 120, 300 * 0.3 = 90.
    expect(spentBox.width, closeTo(120, 0.5));
    expect(scheduledBox.width, closeTo(90, 0.5));
  });

  testWidgets(r'overspent switches the spent segment to $expense',
      (tester) async {
    await pump(tester, fraction: 1.2, overspent: true, scheduledFraction: 0.3);

    final containers = segmentContainers(tester);
    // The room left for "programado" is 0 once spent already fills the bar.
    expect(containers.length, 2);
    expect(containers[1].color, AppColors.light.expense);
  });

  testWidgets(
      r'scheduledAtRisk switches the third segment to $amber, not '
      r'$primary-light', (tester) async {
    await pump(
      tester,
      fraction: 0.7,
      overspent: false,
      scheduledFraction: 0.45,
      scheduledAtRisk: true,
    );

    final containers = segmentContainers(tester);
    expect(containers.length, 3);
    expect(containers[1].color, AppColors.light.primary);
    expect(containers[2].color, AppColors.light.amber);

    // Criterion "recorte al 100%": even though 0.45 mathematically overshoots
    // the track, the risk segment is still clipped to the room left (0.3),
    // never drawing past the track's own width.
    final scheduledBox = tester.getSize(
      find.byWidgetPredicate((widget) => widget == containers[2]),
    );
    expect(scheduledBox.width, closeTo(300 * 0.3, 0.5));
  });
}
