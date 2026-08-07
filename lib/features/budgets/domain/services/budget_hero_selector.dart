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
///    shown. A budget's [Budget.startDate] is a "freely chosen anchor" (see
///    its docs): the automatic pick never required, and must never require,
///    that anchor to fall on the 1st of the month — a global-monthly budget
///    anchored on, say, the 27th is picked exactly the same as one anchored
///    on the 1st, and in both cases [BudgetWithProgress.window] already
///    carries its **real** `BudgetPeriodWindow` (e.g. `27 jul – 26 ago`),
///    never a calendar month — the caller (Home's hero) must read the
///    window from there, not assume a calendar month of its own. Nothing
///    enforces a single global-monthly budget at creation time, so when more
///    than one qualifies this picks the most recently **created** one.
///    Deterministic, not a hard product rule.
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

  static BudgetWithProgress? _pickGlobalMonthly(
    List<BudgetWithProgress> budgets,
  ) {
    BudgetWithProgress? best;
    for (final entry in budgets) {
      if (!_isGlobalMonthly(entry)) {
        continue;
      }
      if (best == null ||
          entry.budget.createdAt.isAfter(best.budget.createdAt)) {
        best = entry;
      }
    }
    return best;
  }

  /// Global scope + monthly cadence — deliberately silent on the anchor day
  /// ([Budget.startDate] can be any day of the month). Naming this its own
  /// predicate (instead of an inline `isEligible` local) makes that omission
  /// a documented decision instead of something the next reader has to
  /// verify by re-deriving it from the period calculator.
  static bool _isGlobalMonthly(BudgetWithProgress entry) =>
      entry.scope.isGlobal && entry.budget.period == BudgetPeriod.monthly;
}
