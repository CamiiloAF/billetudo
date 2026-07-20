import 'package:injectable/injectable.dart';

import '../../../scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import '../entities/budget_activity_item.dart';
import '../entities/budget_detail_data.dart';
import '../entities/budget_period_view.dart';
import '../entities/budget_period_window.dart';
import '../entities/budget_progress.dart';
import '../entities/budget_scheduled_item.dart';
import '../services/budget_period_calculator.dart';
import '../services/budget_progress_calculator.dart';

/// HU-04/HU-05: the progress and activity of a budget for one period window.
///
/// Given the detail bundle and a target period `index` (or the current one when
/// `index` is null), it computes the window, sums the matched expense and builds
/// the activity list — the single place the period math and the scope-matching
/// rule meet for the detail screen. HU-12 adds the "programado" segment: it
/// reuses `ProjectUpcomingOccurrences` (built in Pagos Programados for this
/// purpose) to project each eligible template's still-future dates inside the
/// window, and combines them with occurrences already `pending` there.
@injectable
class GetBudgetProgress {
  const GetBudgetProgress(this._progressCalculator, this._projectOccurrences);

  final BudgetProgressCalculator _progressCalculator;
  final ProjectUpcomingOccurrences _projectOccurrences;

  BudgetPeriodView call(
    BudgetDetailData data, {
    required DateTime now,
    int? index,
  }) {
    final periods = BudgetPeriodCalculator(data.budget);
    final window = index == null
        ? periods.currentWindow(now)
        : periods.windowAt(index, now);

    final expanded = _progressCalculator.expandCategories(
      data.scope.aliveCategoryIds,
      data.categoryChildren,
    );

    final matched = [
      for (final detail in data.expenses)
        if (_progressCalculator.matches(
          budget: data.budget,
          scope: data.scope,
          window: window,
          expandedCategories: expanded,
          expense: detail.expense,
        ))
          detail,
    ]..sort((a, b) => b.expense.date.compareTo(a.expense.date));

    final spent = matched.fold<int>(0, (sum, d) => sum + d.expense.amountMinor);

    // A past window is closed history: nothing "programado" is still owed
    // inside it (criterion 7), regardless of a stale `pending` occurrence
    // that was never resolved.
    final scheduledItems = window.status == BudgetWindowStatus.past
        ? const <BudgetScheduledItem>[]
        : _progressCalculator.scheduledItemsIn(
            budget: data.budget,
            scope: data.scope,
            window: window,
            templates: data.scheduledTemplates,
            projected: _projectOccurrences(
              templates: [
                for (final detail in data.scheduledTemplates) detail.template,
              ],
              windowStart: window.start,
              windowEndInclusive: window.lastDay,
            ),
            pendingOccurrences: data.pendingScheduledOccurrences,
            categoryChildren: data.categoryChildren,
          );

    final scheduled =
        scheduledItems.fold<int>(0, (sum, item) => sum + item.amountMinor);

    return BudgetPeriodView(
      window: window,
      progress: BudgetProgress(
        amountMinor: data.budget.amountMinor,
        spentMinor: spent,
        daysLeft: window.daysLeftFrom(now),
        scheduledMinor: scheduled,
      ),
      activity: [
        for (final detail in matched)
          BudgetActivityItem(
            id: detail.expense.id,
            title: detail.title,
            accountName: detail.accountName,
            categoryIcon: detail.categoryIcon,
            categoryColor: detail.categoryColor,
            amountMinor: detail.expense.amountMinor,
            currency: detail.expense.currency,
            date: detail.expense.date,
            note: detail.note,
          ),
      ],
      scheduledItems: scheduledItems,
    );
  }

  /// The window at [index] alone (no progress), for the cubit to read the
  /// navigation bounds when the user steps to an empty period.
  BudgetPeriodWindow windowAt(
    BudgetDetailData data, {
    required int index,
    required DateTime now,
  }) =>
      BudgetPeriodCalculator(data.budget).windowAt(index, now);
}
