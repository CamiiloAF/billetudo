import 'package:billetudo/features/budgets/domain/services/budget_period_calculator.dart';
import 'package:billetudo/features/budgets/presentation/utils/budget_adjustment_windows.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/budget_fixtures.dart';

/// Pins AC6 of "fix-budget-adjust-current-period": under the retargeted
/// mechanism `windows.current` must be the window the adjusted fork covers
/// (i.e. exactly `BudgetPeriodCalculator.currentWindow(now)`), and
/// `windows.next` must be the window where the *original* amount resumes
/// (i.e. `currentWindow.index + 1`) — never a window two cycles out. This is
/// the contract `BudgetAdjustAmountSheet` and `BudgetAdjustmentEntryCard`
/// build their copy on top of, so a regression here would silently mislabel
/// every date in the sheet even if `scheduleBudgetAdjustment` itself is
/// correct.
void main() {
  test(
      'current is exactly currentWindow(now), and next is the immediately '
      'following window (where the original amount resumes) — not two '
      'cycles out', () {
    final budget = buildBudget(
      id: 'bud-1',
      startDate: DateTime(2025, 1, 21),
    );
    final now = DateTime(2025, 7, 25);
    final calculator = BudgetPeriodCalculator(budget);
    final expectedCurrent = calculator.currentWindow(now);
    final expectedResume = calculator.windowAt(expectedCurrent.index + 1, now);

    final windows = BudgetAdjustmentWindows(budget, now);

    expect(windows.current.index, expectedCurrent.index);
    expect(windows.current.start, expectedCurrent.start);
    expect(windows.current.lastDay, expectedCurrent.lastDay);
    expect(windows.next.index, expectedCurrent.index + 1);
    expect(windows.next.start, expectedResume.start);
  });

  test(
      'current.index == 0 case (no previous cycle): next is still the '
      'immediate following window, not a window two cycles out', () {
    // now falls inside the budget's very first monthly cycle.
    final budget = buildBudget(
      id: 'bud-2',
      startDate: DateTime(2025, 7, 1),
    );
    final now = DateTime(2025, 7, 10);
    final calculator = BudgetPeriodCalculator(budget);
    final expectedCurrent = calculator.currentWindow(now);
    expect(expectedCurrent.index, 0);

    final windows = BudgetAdjustmentWindows(budget, now);

    expect(windows.current.index, 0);
    expect(windows.next.index, 1);
    expect(
      windows.next.start,
      calculator.windowAt(1, now).start,
    );
  });
}
