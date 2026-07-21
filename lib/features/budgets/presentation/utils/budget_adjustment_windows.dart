import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_period_window.dart';
import '../../domain/services/budget_period_calculator.dart';

/// The two cycles "Ajustar monto" touches, built from the window the stepper is
/// currently showing (the [target]) so the sheet's copy and date labels always
/// match what actually gets persisted: the override applies to [target], and
/// every other period keeps the budget's base amount — [resume] is just the
/// next cycle, used to spell out when the base takes back over.
class BudgetAdjustmentWindows {
  factory BudgetAdjustmentWindows(
    Budget budget,
    BudgetPeriodWindow visible,
    DateTime now,
  ) {
    final calculator = BudgetPeriodCalculator(budget);
    return BudgetAdjustmentWindows._(
      target: visible,
      resume: calculator.windowAt(visible.index + 1, now),
    );
  }

  const BudgetAdjustmentWindows._({
    required this.target,
    required this.resume,
  });

  /// The window the stepper is showing — where the adjusted amount applies.
  final BudgetPeriodWindow target;

  /// The cycle right after [target], where the base amount resumes.
  final BudgetPeriodWindow resume;
}
