import 'package:injectable/injectable.dart';

import '../entities/budget.dart';
import '../entities/budget_expense.dart';
import '../entities/budget_period_window.dart';
import '../entities/budget_progress.dart';
import '../entities/budget_scope.dart';

/// Computes a budget's spend over a window (HU-04). Pure and deterministic: the
/// single implementation of the scope-matching rule, shared by the list, the
/// detail hero and the detail activity, so the tricky edge cases live in exactly
/// one place.
///
/// Critical rule — **global vs. emptied scope**: "no scope rows" (global) is not
/// the same as "scope rows whose referents were all deleted". [BudgetScope]
/// already keeps the raw rows and their alive flags; here, a dimension that has
/// rows but no surviving referent matches **nothing** (never "all"). A naive
/// `IN (empty) -> match all` would silently turn a narrow budget global.
@lazySingleton
class BudgetProgressCalculator {
  const BudgetProgressCalculator();

  /// Total matched expense in [window], in cents. [categoryChildren] maps an
  /// (alive) category id to its (alive) direct children, so a scoped root also
  /// counts its subcategories' spend.
  int spentIn({
    required Budget budget,
    required BudgetScope scope,
    required BudgetPeriodWindow window,
    required Iterable<BudgetExpense> expenses,
    Map<String, List<String>> categoryChildren = const {},
  }) {
    final expandedCategories =
        expandCategories(scope.aliveCategoryIds, categoryChildren);

    var total = 0;
    for (final expense in expenses) {
      if (matches(
        budget: budget,
        scope: scope,
        window: window,
        expandedCategories: expandedCategories,
        expense: expense,
      )) {
        total += expense.amountMinor;
      }
    }
    return total;
  }

  /// Convenience wrapper returning a full [BudgetProgress] for [now].
  BudgetProgress progressIn({
    required Budget budget,
    required BudgetScope scope,
    required BudgetPeriodWindow window,
    required Iterable<BudgetExpense> expenses,
    required DateTime now,
    Map<String, List<String>> categoryChildren = const {},
  }) =>
      BudgetProgress(
        amountMinor: budget.amountMinor,
        spentMinor: spentIn(
          budget: budget,
          scope: scope,
          window: window,
          expenses: expenses,
          categoryChildren: categoryChildren,
        ),
        daysLeft: window.daysLeftFrom(now),
      );

  /// Whether [expense] belongs to the budget in [window]. Every clause must
  /// hold: same currency, inside the window, and within both scope dimensions.
  /// [expandedCategories] comes from [expandCategories].
  bool matches({
    required Budget budget,
    required BudgetScope scope,
    required BudgetPeriodWindow window,
    required Set<String> expandedCategories,
    required BudgetExpense expense,
  }) {
    if (expense.currency != budget.currency) {
      return false;
    }
    if (expense.date.isBefore(window.start) ||
        !expense.date.isBefore(window.endExclusive)) {
      return false;
    }
    if (!_matchesAccounts(scope, expense)) {
      return false;
    }
    return _matchesCategories(scope, expandedCategories, expense);
  }

  bool _matchesAccounts(BudgetScope scope, BudgetExpense expense) {
    // No rows = every account. With rows, only surviving referents count; an
    // emptied dimension (rows but none alive) matches nothing, never "all".
    if (scope.isAccountGlobal) {
      return true;
    }
    return scope.aliveAccountIds.contains(expense.accountId);
  }

  bool _matchesCategories(
    BudgetScope scope,
    Set<String> expandedCategories,
    BudgetExpense expense,
  ) {
    if (scope.isCategoryGlobal) {
      return true;
    }
    final categoryId = expense.categoryId;
    return categoryId != null && expandedCategories.contains(categoryId);
  }

  /// Expands each scoped category to itself plus its subcategories (HU-04). The
  /// hierarchy is two levels (root -> sub), but a BFS keeps it correct if that
  /// ever deepens.
  Set<String> expandCategories(
    Set<String> roots,
    Map<String, List<String>> children,
  ) {
    final result = <String>{};
    final queue = [...roots];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (result.add(id)) {
        queue.addAll(children[id] ?? const []);
      }
    }
    return result;
  }
}
