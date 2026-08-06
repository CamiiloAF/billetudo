import 'package:equatable/equatable.dart';

/// A single expense (or presupuestable income) line the budget math consumes
/// (HU-04). A minimal domain value — not the full Transactions entity — so the
/// scope/progress rule has no cross-feature coupling and stays trivially
/// testable.
///
/// Real expenses (`type = expense`) always become one of these; the data layer
/// filters `deletedAt IS NULL` and one of: `type = expense`, `type = transfer`
/// with `countsInBudget = true`, or `type = income` with `countsInBudget = true`
/// (budget-income-counts-in-budget) before mapping. A plain transfer (the
/// default, `countsInBudget = false`) is never budget spend — that would
/// double-count a card payment. An **opted-in** transfer (Fase B1 —
/// transferencia presupuestable,
/// `docs/plan-cuentas-tipos-y-transferencias-presupuestables.md` §3) is folded
/// in as an origin-side expense row so it counts for any budget scoped to its
/// origin account, exactly like a normal expense.
///
/// [amountMinor] is always the movement's positive magnitude, regardless of
/// [isIncome] — the sign of its *contribution* to a budget's spend (raising
/// vs. lowering the disponible) is resolved by `BudgetProgressCalculator`,
/// never carried in the data itself.
class BudgetExpense extends Equatable {
  const BudgetExpense({
    required this.id,
    required this.accountId,
    required this.amountMinor,
    required this.currency,
    required this.date,
    this.categoryId,
    this.isIncome = false,
  });

  final String id;
  final String accountId;

  /// null for an uncategorized expense. It can still match a global budget, but
  /// never a category-scoped one.
  final String? categoryId;

  final int amountMinor;
  final String currency;
  final DateTime date;

  /// `true` for a presupuestable income row (budget-income-counts-in-budget):
  /// a `type = income` transaction with `countsInBudget = true`, e.g. a debt
  /// repayment received. `false` for every real expense and every
  /// presupuestable transfer, which still lower the disponible as before.
  final bool isIncome;

  @override
  List<Object?> get props =>
      [id, accountId, categoryId, amountMinor, currency, date, isIncome];
}
