import 'package:equatable/equatable.dart';

/// One entry of a budget's scope (an account or a category reference), carrying
/// whether its referent still exists.
///
/// The `referentAlive` flag is the heart of the **global-vs-emptied** rule
/// (HU-04): a scope row survives even when the account/category it points at is
/// deleted, so we must tell "no scope rows at all" (global) apart from "scope
/// rows whose referents are all gone" (matches nothing). See
/// `docs/requirements/06-presupuestos.md`.
class BudgetScopeRef extends Equatable {
  const BudgetScopeRef({required this.id, required this.referentAlive});

  /// The referenced account or category id.
  final String id;

  /// Whether the referenced row still exists (accounts: `tombstonedAt IS NULL`;
  /// categories: `deletedAt IS NULL AND tombstonedAt IS NULL`).
  final bool referentAlive;

  @override
  List<Object?> get props => [id, referentAlive];
}

/// A budget's configurable scope: which accounts and which categories it covers
/// (HU-01/HU-02). An empty list on a dimension means "all" (no filter) for that
/// dimension; both empty = the global budget.
///
/// Rows are the **raw** scope (they keep referents that were deleted elsewhere),
/// so the progress calculation can apply the global-vs-emptied rule correctly.
class BudgetScope extends Equatable {
  const BudgetScope({
    this.accounts = const [],
    this.categories = const [],
  });

  const BudgetScope.empty() : this();

  /// Raw account scope rows (may include deleted referents).
  final List<BudgetScopeRef> accounts;

  /// Raw category scope rows (may include deleted referents). A root category
  /// expands to its subcategories at calculation time, not here.
  final List<BudgetScopeRef> categories;

  /// No scope rows on the account dimension = every account (HU-02).
  bool get isAccountGlobal => accounts.isEmpty;

  /// No scope rows on the category dimension = every expense category (HU-02).
  bool get isCategoryGlobal => categories.isEmpty;

  /// Both dimensions unbounded = the global budget.
  bool get isGlobal => isAccountGlobal && isCategoryGlobal;

  /// Account ids whose referent still exists.
  Set<String> get aliveAccountIds => {
        for (final ref in accounts)
          if (ref.referentAlive) ref.id,
      };

  /// Category ids whose referent still exists (before subcategory expansion).
  Set<String> get aliveCategoryIds => {
        for (final ref in categories)
          if (ref.referentAlive) ref.id,
      };

  /// The account dimension has rows but every referent is gone: it matches no
  /// account at all (never "all"). Same idea for [isCategoryStranded].
  bool get isAccountStranded => accounts.isNotEmpty && aliveAccountIds.isEmpty;

  bool get isCategoryStranded =>
      categories.isNotEmpty && aliveCategoryIds.isEmpty;

  /// A scope that can never match a transaction: some dimension was narrowed but
  /// all its referents were deleted. The UI warns about this (HU-04).
  bool get isStranded => isAccountStranded || isCategoryStranded;

  @override
  List<Object?> get props => [accounts, categories];
}
