import 'package:billetudo/features/budgets/domain/entities/budget_expense.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/services/budget_progress_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'budget_fixtures.dart';

void main() {
  const calc = BudgetProgressCalculator();

  // A January monthly window: [Jan 1, Feb 1).
  final window = BudgetPeriodWindow(
    start: DateTime(2024, 1, 1),
    endExclusive: DateTime(2024, 2, 1),
    index: 0,
    status: BudgetWindowStatus.current,
    hasPrevious: false,
    hasNext: true,
  );

  final budget = buildBudget(startDate: DateTime(2024, 1, 1));

  BudgetExpense expense({
    String id = 'e',
    String accountId = 'a1',
    String? categoryId,
    int amountMinor = 1000,
    String currency = 'COP',
    DateTime? date,
  }) =>
      BudgetExpense(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        amountMinor: amountMinor,
        currency: currency,
        date: date ?? DateTime(2024, 1, 10),
      );

  int spent(BudgetScope scope, List<BudgetExpense> expenses,
          {Map<String, List<String>> children = const {}}) =>
      calc.spentIn(
        budget: budget,
        scope: scope,
        window: window,
        expenses: expenses,
        categoryChildren: children,
      );

  group('window + currency', () {
    test('only sums expenses inside the window', () {
      final total = spent(const BudgetScope.empty(), [
        expense(id: 'in', date: DateTime(2024, 1, 10), amountMinor: 500),
        expense(id: 'before', date: DateTime(2023, 12, 31), amountMinor: 700),
        expense(id: 'after', date: DateTime(2024, 2, 1), amountMinor: 900),
      ]);
      expect(total, 500);
    });

    test('only sums the budget currency', () {
      final total = spent(const BudgetScope.empty(), [
        expense(id: 'cop', currency: 'COP', amountMinor: 500),
        expense(id: 'usd', currency: 'USD', amountMinor: 900),
      ]);
      expect(total, 500);
    });
  });

  group('global scope (HU-02)', () {
    test('an empty scope matches every account and category', () {
      final total = spent(const BudgetScope.empty(), [
        expense(id: 'a', accountId: 'a1', categoryId: 'c1', amountMinor: 300),
        expense(id: 'b', accountId: 'a2', categoryId: null, amountMinor: 200),
      ]);
      expect(total, 500);
    });
  });

  group('account scope', () {
    test('matches only accounts in the (alive) scope', () {
      const scope = BudgetScope(
        accounts: [BudgetScopeRef(id: 'a1', referentAlive: true)],
      );
      final total = spent(scope, [
        expense(id: 'a', accountId: 'a1', amountMinor: 300),
        expense(id: 'b', accountId: 'a2', amountMinor: 200),
      ]);
      expect(total, 300);
    });
  });

  group('category scope + subcategory expansion (HU-04)', () {
    test('a scoped root also counts its subcategories', () {
      const scope = BudgetScope(
        categories: [BudgetScopeRef(id: 'root', referentAlive: true)],
      );
      final total = spent(
        scope,
        [
          expense(id: 'root', categoryId: 'root', amountMinor: 100),
          expense(id: 'sub', categoryId: 'sub', amountMinor: 200),
          expense(id: 'other', categoryId: 'x', amountMinor: 400),
        ],
        children: {
          'root': ['sub'],
        },
      );
      expect(total, 300);
    });

    test('an uncategorized expense never matches a category scope', () {
      const scope = BudgetScope(
        categories: [BudgetScopeRef(id: 'c1', referentAlive: true)],
      );
      final total = spent(scope, [
        expense(id: 'none', categoryId: null, amountMinor: 500),
      ]);
      expect(total, 0);
    });
  });

  group('global-vs-emptied (critical rule)', () {
    test('a scope whose only account referent is deleted matches NOTHING', () {
      const scope = BudgetScope(
        accounts: [BudgetScopeRef(id: 'gone', referentAlive: false)],
      );
      final total = spent(scope, [
        expense(id: 'a', accountId: 'a1', amountMinor: 500),
        expense(id: 'b', accountId: 'gone', amountMinor: 700),
      ]);
      // Emptied scope != global: it must not fall back to "all".
      expect(total, 0);
    });

    test('a stranded category scope matches NOTHING', () {
      const scope = BudgetScope(
        categories: [BudgetScopeRef(id: 'gone', referentAlive: false)],
      );
      final total = spent(scope, [
        expense(id: 'a', categoryId: 'c1', amountMinor: 500),
      ]);
      expect(total, 0);
    });

    test('surviving referents still count when a sibling is deleted', () {
      const scope = BudgetScope(
        accounts: [
          BudgetScopeRef(id: 'a1', referentAlive: true),
          BudgetScopeRef(id: 'gone', referentAlive: false),
        ],
      );
      final total = spent(scope, [
        expense(id: 'a', accountId: 'a1', amountMinor: 500),
        expense(id: 'b', accountId: 'gone', amountMinor: 700),
      ]);
      expect(total, 500);
    });

    test('BudgetScope reports the stranded state', () {
      const stranded = BudgetScope(
        accounts: [BudgetScopeRef(id: 'gone', referentAlive: false)],
      );
      expect(stranded.isStranded, isTrue);
      expect(stranded.isGlobal, isFalse);
      expect(const BudgetScope.empty().isGlobal, isTrue);
      expect(const BudgetScope.empty().isStranded, isFalse);
    });
  });

  group('both dimensions (AND)', () {
    test('an expense must satisfy account AND category scope', () {
      const scope = BudgetScope(
        accounts: [BudgetScopeRef(id: 'a1', referentAlive: true)],
        categories: [BudgetScopeRef(id: 'c1', referentAlive: true)],
      );
      final total = spent(scope, [
        expense(id: 'match', accountId: 'a1', categoryId: 'c1', amountMinor: 300),
        expense(id: 'wrongAcc', accountId: 'a2', categoryId: 'c1', amountMinor: 200),
        expense(id: 'wrongCat', accountId: 'a1', categoryId: 'c2', amountMinor: 400),
      ]);
      expect(total, 300);
    });
  });
}
