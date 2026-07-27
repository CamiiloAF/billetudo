import 'package:billetudo/features/budgets/domain/services/budget_period_calculator.dart';
import 'package:billetudo/features/budgets/presentation/utils/budget_adjustment_windows.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget_fixtures.dart';

/// Pins the retargeted override mechanism: `windows.target` must be exactly the
/// *visible* window the stepper is showing (where the override amount applies),
/// and `windows.resume` must be the window immediately after it (where the base
/// amount resumes) — never a window two cycles out. This is the contract
/// `BudgetAdjustAmountSheet` and `BudgetAdjustmentEntryCard` build their copy on
/// top of, so a regression here would silently mislabel every date in the sheet
/// even if `scheduleBudgetAdjustment` itself is correct.
void main() {
  test(
      'target is exactly the visible window, and resume is the immediately '
      'following window (where the base amount resumes) — not two cycles out',
      () {
    final budget = buildBudget(
      id: 'bud-1',
      startDate: DateTime(2025, 1, 21),
    );
    final now = DateTime(2025, 7, 25);
    final calculator = BudgetPeriodCalculator(budget);
    final visible = calculator.currentWindow(now);
    final expectedResume = calculator.windowAt(visible.index + 1, now);

    final windows = BudgetAdjustmentWindows(budget, visible, now);

    expect(windows.target.index, visible.index);
    expect(windows.target.start, visible.start);
    expect(windows.target.lastDay, visible.lastDay);
    expect(windows.resume.index, visible.index + 1);
    expect(windows.resume.start, expectedResume.start);
  });

  test(
      'a future visible window: target follows it and resume is the next one, '
      'not anchored to the current cycle', () {
    final budget = buildBudget(
      id: 'bud-2',
      startDate: DateTime(2025, 7, 1),
    );
    final now = DateTime(2025, 7, 10);
    final calculator = BudgetPeriodCalculator(budget);
    final current = calculator.currentWindow(now);
    expect(current.index, 0);

    // Stepper moved forward one cycle: the override targets that future window.
    final visible = calculator.windowAt(current.index + 1, now);
    final windows = BudgetAdjustmentWindows(budget, visible, now);

    expect(windows.target.index, 1);
    expect(windows.resume.index, 2);
    expect(
      windows.resume.start,
      calculator.windowAt(2, now).start,
    );
  });
}
