import 'package:equatable/equatable.dart';

import 'budget.dart';
import 'budget_expense.dart';
import 'budget_scope.dart';

/// An eligible expense for a budget's detail, carrying both the math fields
/// ([expense]) and the display fields ([title]/[note]) so the activity list
/// renders without a second lookup.
class BudgetExpenseDetail extends Equatable {
  const BudgetExpenseDetail({
    required this.expense,
    required this.title,
    this.note,
  });

  final BudgetExpense expense;

  /// Category name when categorized, otherwise the account name.
  final String title;
  final String? note;

  @override
  List<Object?> get props => [expense, title, note];
}

/// Everything the detail screen needs from the data layer in one reactive
/// bundle (HU-04/HU-05): the budget, its raw scope, every expense that could
/// match it (any period), and the alive category-children map for subcategory
/// expansion. The window slicing and progress live in the domain use case, not
/// here, so re-emitting on any transaction change stays cheap.
class BudgetDetailData extends Equatable {
  const BudgetDetailData({
    required this.budget,
    required this.scope,
    required this.expenses,
    required this.categoryChildren,
  });

  final Budget budget;
  final BudgetScope scope;
  final List<BudgetExpenseDetail> expenses;
  final Map<String, List<String>> categoryChildren;

  @override
  List<Object?> get props => [budget, scope, expenses, categoryChildren];
}
