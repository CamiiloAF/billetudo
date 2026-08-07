import '../entities/budget.dart';
import '../entities/budget_with_progress.dart';

/// Picks which of the user's active budgets, if any, is featured on Home's
/// hero card (`docs/requirements/04-inicio.md`,
/// `design-system/billetudo/pages/ajustes.md`).
///
/// Two selection modes, tried in order:
/// 1. **Explicit** (`AppSettings.featuredBudgetId`): the user picked one in
///    Ajustes. Only honored while it is still active — an archived or
///    deleted budget simply falls through to the automatic pick below, with
///    no error and no stale reference kept anywhere (criterion 4/5 of the
///    "presupuesto destacado" entrega).
/// 2. **Automatic**: the single active budget, if any, that is both global
///    (no account/category scope, `BudgetScope.isGlobal`) and on the
///    [BudgetPeriod.monthly] cadence — the same profile Home has always
///    shown. Nothing enforces a single global-monthly budget at creation
///    time, so when more than one qualifies this picks the most recently
///    **created** one. Deterministic, not a hard product rule.
class BudgetHeroSelector {
  const BudgetHeroSelector._();

  static BudgetWithProgress? pick(
    List<BudgetWithProgress> budgets, {
    String? featuredBudgetId,
  }) {
    if (featuredBudgetId != null) {
      for (final entry in budgets) {
        if (entry.budget.id == featuredBudgetId) {
          return entry;
        }
      }
    }
    return _pickGlobalMonthly(budgets);
  }

  /// Indifferent to the anchor day-of-month **by design**: the automatic pick
  /// only compares `budget.period`/`scope.isGlobal` eligibility and
  /// `createdAt` recency, never `budget.startDate`'s day. Home's hero (once it
  /// navigates the featured budget's own real period window, `BudgetPeriodWindow`
  /// / `BudgetPeriodCalculator`, instead of a calendar month) already reads the
  /// budget's true anchor from that window, so this selector has no reason to
  /// also weigh the anchor day — doing so would just duplicate, and could
  /// disagree with, the window math. No behavior change here.
  static BudgetWithProgress? _pickGlobalMonthly(
    List<BudgetWithProgress> budgets,
  ) {
    BudgetWithProgress? best;
    for (final entry in budgets) {
      final isEligible =
          entry.scope.isGlobal && entry.budget.period == BudgetPeriod.monthly;
      if (!isEligible) {
        continue;
      }
      if (best == null ||
          entry.budget.createdAt.isAfter(best.budget.createdAt)) {
        best = entry;
      }
    }
    return best;
  }
}
