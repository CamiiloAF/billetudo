import 'package:equatable/equatable.dart';

/// A single expense line the budget math consumes (HU-04). A minimal domain
/// value — not the full Transactions entity — so the scope/progress rule has no
/// cross-feature coupling and stays trivially testable.
///
/// Only real expenses ever become one of these: transfers are never budget
/// spend (they would double-count a card payment) and income is irrelevant, so
/// the data layer filters `type = expense`, `deletedAt IS NULL` before mapping.
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
