import 'package:equatable/equatable.dart';

/// A single expense line the budget math consumes (HU-04). A minimal domain
/// value — not the full Transactions entity — so the scope/progress rule has no
/// cross-feature coupling and stays trivially testable.
///
/// Real expenses (`type = expense`) always become one of these; income is
/// irrelevant, so the data layer filters `deletedAt IS NULL` and either
/// `type = expense` or (`type = transfer` and `countsInBudget = true`) before
/// mapping. A plain transfer (the default, `countsInBudget = false`) is never
/// budget spend — that would double-count a card payment. An **opted-in**
/// transfer (Fase B1 — transferencia presupuestable,
/// `docs/plan-cuentas-tipos-y-transferencias-presupuestables.md` §3) is folded
/// in as an origin-side expense row so it counts for any budget scoped to its
/// origin account, exactly like a normal expense.
class BudgetExpense extends Equatable {
  const BudgetExpense({
    required this.id,
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.date,
    this.categoryId,
  });

  final String id;
  final String accountId;

  /// null for an uncategorized expense. It can still match a global budget, but
  /// never a category-scoped one.
  final String? categoryId;

  final int amountMinor;
  final String currency;
  final DateTime date;

  @override
  List<Object?> get props =>
      [id, accountId, categoryId, amountMinor, currency, date];
}
