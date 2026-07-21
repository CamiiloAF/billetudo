import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_period_window.dart';
import '../../domain/services/budget_period_calculator.dart';

/// The three cycles "Ajustar monto — solo el próximo período" touches,
/// computed the same deterministic way
/// `BudgetRepositoryImpl.scheduleBudgetAdjustment` does (same
/// [BudgetPeriodCalculator], same anchor/period), so the sheet's copy and
/// date labels always match what actually gets persisted.
class BudgetAdjustmentWindows {
  factory BudgetAdjustmentWindows(Budget budget, DateTime now) {
    final calculator = BudgetPeriodCalculator(budget);
    final current = calculator.currentWindow(now);
    return BudgetAdjustmentWindows._(
      current: current,
      next: calculator.windowAt(current.index + 1, now),
      resume: calculator.windowAt(current.index + 2, now),
    );
  }

  const BudgetAdjustmentWindows._({
    required this.current,
    required this.next,
    required this.resume,
  });

  /// The vigente cycle — [Budget.amountMinor] is still its amount.
  final BudgetPeriodWindow current;

  /// The next cycle, where the adjusted amount takes over.
  final BudgetPeriodWindow next;

  /// The cycle after [next], where the original amount resumes.
  final BudgetPeriodWindow resume;
}
