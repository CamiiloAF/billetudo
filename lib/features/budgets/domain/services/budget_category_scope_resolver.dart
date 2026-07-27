import 'package:injectable/injectable.dart';

/// Translates between the **materialized** category selection the shared picker
/// speaks (a root carries every one of its subcategory ids, "Todas" carries the
/// whole set) and the **canonical** budget scope the domain persists (a root is
/// stored by its id alone, "Todas" is the empty set / global).
///
/// This is the heart of fix #14: a budget scoped to "Todas" or to a whole root
/// must keep matching categories created *after* it was saved. Persisting the
/// materialized ids froze the scope at its creation-time snapshot; storing the
/// canonical form lets `BudgetProgressCalculator.expandCategories` resolve the
/// live children at calculation time instead.
///
/// Both maps use the same shape: `childrenByRoot` maps **every** root id to the
/// list of its (direct) child ids — an empty list for a childless root. The
/// full universe of ids is derived from it (keys plus every child), so a root
/// with no children still round-trips.
///
/// The transactions filter deliberately keeps materializing (it is a one-shot
/// filter, not a living rule), so this resolver is used only on the budget path.
@lazySingleton
class BudgetCategoryScopeResolver {
  const BudgetCategoryScopeResolver();

  /// Materialized selection -> canonical budget scope.
  ///
  /// - Everything selected -> `{}` (global / "Todas"): new categories join
  ///   automatically.
  /// - A root whose whole subtree is selected -> just the root id: new
  ///   subcategories of that root join automatically.
  /// - A partially-selected subtree keeps exactly the ids that were picked.
  Set<String> collapse(
    Set<String> selected,
    Map<String, List<String>> childrenByRoot,
  ) {
    final allIds = _allIds(childrenByRoot);
    if (allIds.isNotEmpty && selected.containsAll(allIds)) {
      return <String>{};
    }

    final result = <String>{};
    for (final entry in childrenByRoot.entries) {
      final rootId = entry.key;
      final childIds = entry.value;
      final wholeSubtree = <String>{rootId, ...childIds};
      if (selected.containsAll(wholeSubtree)) {
        // Store the root alone; its live children are resolved at calc time.
        result.add(rootId);
        continue;
      }
      if (selected.contains(rootId)) {
        result.add(rootId);
      }
      for (final childId in childIds) {
        if (selected.contains(childId)) {
          result.add(childId);
        }
      }
    }
    return result;
  }

  /// Canonical budget scope -> materialized selection, so the shared picker
  /// shows the right rows checked when editing.
  ///
  /// - Empty scope (global) -> every id checked ("Todas").
  /// - A stored root -> the root and all its current children checked.
  /// - A stored subcategory -> that subcategory checked.
  Set<String> expand(
    Set<String> canonical,
    Map<String, List<String>> childrenByRoot,
  ) {
    if (canonical.isEmpty) {
      return _allIds(childrenByRoot);
    }

    final result = <String>{};
    for (final entry in childrenByRoot.entries) {
      final rootId = entry.key;
      final childIds = entry.value;
      if (canonical.contains(rootId)) {
        result
          ..add(rootId)
          ..addAll(childIds);
      }
      for (final childId in childIds) {
        if (canonical.contains(childId)) {
          result.add(childId);
        }
      }
    }
    return result;
  }

  Set<String> _allIds(Map<String, List<String>> childrenByRoot) => {
        for (final entry in childrenByRoot.entries) ...[
          entry.key,
          ...entry.value,
        ],
      };
}
