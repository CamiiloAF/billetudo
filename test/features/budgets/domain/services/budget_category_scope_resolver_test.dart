import 'package:billetudo/features/budgets/domain/services/budget_category_scope_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fix #14: the picker speaks materialized ids, the budget stores canonical
/// scope. A round-trip through [BudgetCategoryScopeResolver] must preserve
/// intent while letting new categories join a "Todas" or whole-root budget.
void main() {
  const resolver = BudgetCategoryScopeResolver();

  // Two roots: `food` with two children, `bills` with one, plus a childless
  // root `misc` to prove a root with no subtree still round-trips.
  const childrenByRoot = {
    'food': ['groceries', 'dining'],
    'bills': ['power'],
    'misc': <String>[],
  };
  const allIds = {'food', 'groceries', 'dining', 'bills', 'power', 'misc'};

  group('collapse', () {
    test('"Todas" (every id) collapses to the empty/global scope', () {
      expect(resolver.collapse(allIds.toSet(), childrenByRoot), isEmpty);
    });

    test('a whole root subtree collapses to just the root id', () {
      final selected = {'food', 'groceries', 'dining'};
      expect(resolver.collapse(selected, childrenByRoot), {'food'});
    });

    test('a childless root collapses to itself', () {
      expect(resolver.collapse({'misc'}, childrenByRoot), {'misc'});
    });

    test('a partial subtree keeps exactly the picked ids', () {
      final selected = {'food', 'groceries'};
      expect(resolver.collapse(selected, childrenByRoot), selected);
    });

    test('a lone subcategory stays itself', () {
      expect(resolver.collapse({'dining'}, childrenByRoot), {'dining'});
    });

    test('mixes a whole root with a partial one', () {
      final selected = {'food', 'groceries', 'dining', 'power'};
      expect(resolver.collapse(selected, childrenByRoot), {'food', 'power'});
    });
  });

  group('expand', () {
    test('empty (global) expands to every id, so "Todas" shows checked', () {
      expect(resolver.expand(const {}, childrenByRoot), allIds);
    });

    test('a stored root expands to the root and all its current children', () {
      expect(
        resolver.expand({'food'}, childrenByRoot),
        {'food', 'groceries', 'dining'},
      );
    });

    test('a stored subcategory expands to itself', () {
      expect(resolver.expand({'dining'}, childrenByRoot), {'dining'});
    });
  });

  group('round-trips (expand then collapse is identity on canonical)', () {
    for (final canonical in [
      <String>{},
      {'food'},
      {'dining'},
      {'food', 'power'},
      {'misc'},
    ]) {
      test('$canonical survives a materialize/canonicalize round-trip', () {
        final materialized = resolver.expand(canonical, childrenByRoot);
        expect(resolver.collapse(materialized, childrenByRoot), canonical);
      });
    }
  });

  test('a new child of a stored root is picked up after expand', () {
    // The budget stored the root only; later a child is added to the tree.
    const grown = {
      'food': ['groceries', 'dining', 'delivery'],
      'bills': ['power'],
      'misc': <String>[],
    };
    expect(
      resolver.expand({'food'}, grown),
      {'food', 'groceries', 'dining', 'delivery'},
    );
  });
}
