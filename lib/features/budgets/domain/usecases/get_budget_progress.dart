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

    // budget-income-counts-in-budget: a matched presupuestable income row
    // subtracts instead of adds, same net-of-income rule as
    // `BudgetProgressCalculator.spentIn` (kept in sync manually — this fold
    // duplicates it because it also needs to keep the sorted `matched` list
    // for `activity` below, not just the total).
    final spent = matched.fold<int>(
      0,
      (sum, d) =>
          sum + (d.expense.isIncome ? -d.expense.amountMinor : d.expense.amountMinor),
    );

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

    // Wallet-style per-period override: for the navigated window, the target
    // amount is the override covering its start, if any, else the budget's own.
    final amountMinor =
        data.periodOverrides[window.start] ?? data.budget.amountMinor;

    return BudgetPeriodView(
      window: window,
      progress: BudgetProgress(
        amountMinor: amountMinor,
        spentMinor: spent,
        daysLeft: window.daysLeftFrom(now),
        scheduledMinor: scheduled,
      ),
      activity: _buildActivity(matched),
      scheduledItems: scheduledItems,
    );
  }

  /// Builds the activity list from [matched] (already scope/window-filtered,
  /// newest first), collapsing a presupuestable transfer's two synthetic
  /// rows (origin-side expense id `X`, destination-side income id `X-dest`
  /// — see `BudgetsLocalDatasource.watchExpenses`) into a single netted row
  /// whenever **both** landed in this same budget's scope
  /// (`design-system/billetudo/pages/presupuestos.md`, "Fila especial —
  /// Transferencia interna neteada"). When only one side matched — the other
  /// account sits outside this budget's scope — that lone row renders as
  /// before (a plain expense or a `+amount` presupuestable income), no
  /// change from prior behaviour.
  List<BudgetActivityItem> _buildActivity(List<BudgetExpenseDetail> matched) {
    final byId = {for (final detail in matched) detail.expense.id: detail};
    final consumed = <String>{};
    final activity = <BudgetActivityItem>[];

    for (final detail in matched) {
      final id = detail.expense.id;
      if (consumed.contains(id)) {
        continue;
      }

      final baseId = id.endsWith(_destSuffix)
          ? id.substring(0, id.length - _destSuffix.length)
          : id;
      final origin = byId[baseId];
      final destination = byId['$baseId$_destSuffix'];

      if (origin != null && destination != null) {
        consumed
          ..add(baseId)
          ..add('$baseId$_destSuffix');
        activity.add(
          BudgetActivityItem(
            id: baseId,
            title: origin.title,
            accountName: origin.accountName,
            secondaryAccountName: destination.accountName,
            amountMinor: 0,
            currency: origin.expense.currency,
            date: origin.expense.date,
            isNettedTransfer: true,
          ),
        );
        continue;
      }

      consumed.add(id);
      activity.add(
        BudgetActivityItem(
          id: id,
          title: detail.title,
          accountName: detail.accountName,
          categoryIcon: detail.categoryIcon,
          categoryColor: detail.categoryColor,
          amountMinor: detail.expense.amountMinor,
          currency: detail.expense.currency,
          date: detail.expense.date,
          note: detail.note,
          isIncome: detail.expense.isIncome,
        ),
      );
    }

    return activity;
  }

  /// Suffix `BudgetsLocalDatasource.watchExpenses` appends to a
  /// presupuestable transfer's synthetic destination-side row id.
  static const String _destSuffix = '-dest';

  /// The window at [index] alone (no progress), for the cubit to read the
  /// navigation bounds when the user steps to an empty period.
  BudgetPeriodWindow windowAt(
    BudgetDetailData data, {
    required int index,
    required DateTime now,
  }) =>
      BudgetPeriodCalculator(data.budget).windowAt(index, now);
}
