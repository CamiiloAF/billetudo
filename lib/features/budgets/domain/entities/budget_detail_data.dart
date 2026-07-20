import 'package:equatable/equatable.dart';

import '../../../scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment.dart';
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
    required this.accountName,
    this.categoryIcon,
    this.categoryColor,
    this.note,
  });

  final BudgetExpense expense;

  /// Category name when categorized, otherwise the account name.
  final String title;
  final String accountName;

  /// Category appearance tokens, so the activity row can draw the icon-wrap.
  final String? categoryIcon;
  final String? categoryColor;

  final String? note;

  @override
  List<Object?> get props =>
      [expense, title, accountName, categoryIcon, categoryColor, note];
}

/// An active expense scheduled-payment template eligible for a budget's
/// "programado" segment (HU-12), carrying both the raw [template] (for the
/// scope/window match and for `ProjectUpcomingOccurrences`) and the display
/// fields the scheduled row shows, same pattern as [BudgetExpenseDetail].
class BudgetScheduledTemplateDetail extends Equatable {
  const BudgetScheduledTemplateDetail({
    required this.template,
    required this.title,
    required this.accountName,
    this.categoryIcon,
    this.categoryColor,
  });

  final ScheduledPayment template;

  /// Category name when categorized, otherwise the account name.
  final String title;
  final String accountName;
  final String? categoryIcon;
  final String? categoryColor;

  @override
  List<Object?> get props =>
      [template, title, accountName, categoryIcon, categoryColor];
}

/// Everything the detail screen needs from the data layer in one reactive
/// bundle (HU-04/HU-05): the budget, its raw scope, every expense that could
/// match it (any period), and the alive category-children map for subcategory
/// expansion. The window slicing and progress live in the domain use case, not
/// here, so re-emitting on any transaction change stays cheap.
///
/// [scheduledTemplates] and [pendingScheduledOccurrences] are the HU-12 raw
/// insumos for the "programado" segment: active expense templates (any
/// currency/scope — the use case filters) and occurrences already registered
/// as `pending`, both already enriched for display. [pendingScheduledOccurrences]
/// reuses the Pagos Programados domain entity as-is (already fully enriched),
/// rather than duplicating it.
class BudgetDetailData extends Equatable {
  const BudgetDetailData({
    required this.budget,
    required this.scope,
    required this.expenses,
    required this.categoryChildren,
    required this.scheduledTemplates,
    required this.pendingScheduledOccurrences,
  });

  final Budget budget;
  final BudgetScope scope;
  final List<BudgetExpenseDetail> expenses;
  final Map<String, List<String>> categoryChildren;
  final List<BudgetScheduledTemplateDetail> scheduledTemplates;
  final List<PendingScheduledOccurrence> pendingScheduledOccurrences;

  @override
  List<Object?> get props => [
        budget,
        scope,
        expenses,
        categoryChildren,
        scheduledTemplates,
        pendingScheduledOccurrences,
      ];
}
