import 'package:injectable/injectable.dart';

import '../../../scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment.dart';
import '../../../scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import '../entities/budget.dart';
import '../entities/budget_detail_data.dart';
import '../entities/budget_expense.dart';
import '../entities/budget_period_window.dart';
import '../entities/budget_progress.dart';
import '../entities/budget_scheduled_item.dart';
import '../entities/budget_scope.dart';

/// Computes a budget's spend over a window (HU-04). Pure and deterministic: the
/// single implementation of the scope-matching rule, shared by the list, the
/// detail hero and the detail activity, so the tricky edge cases live in exactly
/// one place.
///
/// Critical rule — **global vs. emptied scope**: "no scope rows" (global) is not
/// the same as "scope rows whose referents were all deleted". [BudgetScope]
/// already keeps the raw rows and their alive flags; here, a dimension that has
/// rows but no surviving referent matches **nothing** (never "all"). A naive
/// `IN (empty) -> match all` would silently turn a narrow budget global.
@lazySingleton
class BudgetProgressCalculator {
  const BudgetProgressCalculator();

  /// Total matched expense in [window], in cents. [categoryChildren] maps an
  /// (alive) category id to its (alive) direct children, so a scoped root also
  /// counts its subcategories' spend.
  int spentIn({
    required Budget budget,
    required BudgetScope scope,
    required BudgetPeriodWindow window,
    required Iterable<BudgetExpense> expenses,
    Map<String, List<String>> categoryChildren = const {},
  }) {
    final expandedCategories =
        expandCategories(scope.aliveCategoryIds, categoryChildren);

    var total = 0;
    for (final expense in expenses) {
      if (matches(
        budget: budget,
        scope: scope,
        window: window,
        expandedCategories: expandedCategories,
        expense: expense,
      )) {
        total += expense.amountMinor;
      }
    }
    return total;
  }

  /// Convenience wrapper returning a full [BudgetProgress] for [now].
  ///
  /// [amountMinorOverride] is the per-period target amount for [window] when a
  /// `BudgetPeriodOverride` (Wallet-style "adjust just the next period") covers
  /// its start; `null` falls back to the budget's own amount.
  BudgetProgress progressIn({
    required Budget budget,
    required BudgetScope scope,
    required BudgetPeriodWindow window,
    required Iterable<BudgetExpense> expenses,
    required DateTime now,
    int? amountMinorOverride,
    Map<String, List<String>> categoryChildren = const {},
  }) =>
      BudgetProgress(
        amountMinor: amountMinorOverride ?? budget.amountMinor,
        spentMinor: spentIn(
          budget: budget,
          scope: scope,
          window: window,
          expenses: expenses,
          categoryChildren: categoryChildren,
        ),
        daysLeft: window.daysLeftFrom(now),
      );

  /// Whether [expense] belongs to the budget in [window]. Every clause must
  /// hold: same currency, inside the window, and within both scope dimensions.
  /// [expandedCategories] comes from [expandCategories].
  bool matches({
    required Budget budget,
    required BudgetScope scope,
    required BudgetPeriodWindow window,
    required Set<String> expandedCategories,
    required BudgetExpense expense,
  }) {
    if (expense.currency != budget.currency) {
      return false;
    }
    if (expense.date.isBefore(window.start) ||
        !expense.date.isBefore(window.endExclusive)) {
      return false;
    }
    if (!_matchesAccountId(scope, expense.accountId)) {
      return false;
    }
    return _matchesCategoryId(scope, expandedCategories, expense.categoryId);
  }

  /// Whether [template] belongs to the budget's scope (HU-12): same currency,
  /// same account/category rule as [matches], generalized to `type = expense`
  /// scheduled-payment templates. Deliberately date-less — window membership
  /// is decided per-occurrence, once a date has been projected or read off the
  /// pending ledger (see [matchesProjectedOccurrence] /
  /// [matchesPendingScheduledOccurrence]).
  bool matchesTemplateScope({
    required Budget budget,
    required BudgetScope scope,
    required Set<String> expandedCategories,
    required ScheduledPayment template,
  }) {
    if (template.type != ScheduledPaymentType.expense) {
      return false;
    }
    if (template.currency != budget.currency) {
      return false;
    }
    if (!_matchesAccountId(scope, template.accountId)) {
      return false;
    }
    return _matchesCategoryId(scope, expandedCategories, template.categoryId);
  }

  /// Whether a still-future [occurrence] (projected from a template's cadence,
  /// not yet a `Transaction` nor a `ScheduledPaymentOccurrence` row) belongs in
  /// [window] and in the budget's scope (HU-12, criteria 1/3).
  bool matchesProjectedOccurrence({
    required Budget budget,
    required BudgetScope scope,
    required Set<String> expandedCategories,
    required BudgetPeriodWindow window,
    required ProjectedScheduledOccurrence occurrence,
    required ScheduledPayment template,
  }) {
    if (!matchesTemplateScope(
      budget: budget,
      scope: scope,
      expandedCategories: expandedCategories,
      template: template,
    )) {
      return false;
    }
    return _inWindow(window, occurrence.date);
  }

  /// Whether an already-registered `pending` occurrence belongs in [window]
  /// and in the budget's scope (HU-12, criterion 4). Only `pending` counts —
  /// `confirmed`/`skipped`/`snoozed` are excluded here (a `confirmed` one is
  /// already a `Transaction`, counted via [spentIn] instead).
  bool matchesPendingScheduledOccurrence({
    required Budget budget,
    required BudgetScope scope,
    required Set<String> expandedCategories,
    required BudgetPeriodWindow window,
    required PendingScheduledOccurrence pending,
  }) {
    if (!pending.occurrence.isPending) {
      return false;
    }
    if (!matchesTemplateScope(
      budget: budget,
      scope: scope,
      expandedCategories: expandedCategories,
      template: pending.scheduledPayment,
    )) {
      return false;
    }
    return _inWindow(window, pending.occurrence.effectiveDate);
  }

  /// The items behind [BudgetProgress.scheduledMinor] for [window] (HU-12):
  /// combines still-future occurrences [projected] from eligible templates'
  /// cadence with occurrences already registered in
  /// [pendingOccurrences]. The two sources never overlap by construction — the
  /// catch-up generator always advances a template's `nextDate` past whatever
  /// due date it processed (confirmed *or* pending), so [projected] (which
  /// starts at each template's current `nextDate`) never re-covers a date
  /// already sitting in [pendingOccurrences] or already materialized as a
  /// `Transaction`.
  List<BudgetScheduledItem> scheduledItemsIn({
    required Budget budget,
    required BudgetScope scope,
    required BudgetPeriodWindow window,
    required List<BudgetScheduledTemplateDetail> templates,
    required List<ProjectedScheduledOccurrence> projected,
    required List<PendingScheduledOccurrence> pendingOccurrences,
    Map<String, List<String>> categoryChildren = const {},
  }) {
    final expanded = expandCategories(scope.aliveCategoryIds, categoryChildren);
    final detailById = {
      for (final detail in templates) detail.template.id: detail,
    };

    final items = <BudgetScheduledItem>[];

    for (final occurrence in projected) {
      final detail = detailById[occurrence.scheduledPaymentId];
      if (detail == null) {
        continue;
      }
      if (!matchesProjectedOccurrence(
        budget: budget,
        scope: scope,
        expandedCategories: expanded,
        window: window,
        occurrence: occurrence,
        template: detail.template,
      )) {
        continue;
      }
      items.add(
        BudgetScheduledItem(
          id: '${occurrence.scheduledPaymentId}@'
              '${occurrence.date.toIso8601String()}',
          scheduledPaymentId: occurrence.scheduledPaymentId,
          title: detail.title,
          accountName: detail.accountName,
          categoryIcon: detail.categoryIcon,
          categoryColor: detail.categoryColor,
          amountMinor: occurrence.amountMinor,
          currency: occurrence.currency,
          date: occurrence.date,
        ),
      );
    }

    for (final pending in pendingOccurrences) {
      if (!matchesPendingScheduledOccurrence(
        budget: budget,
        scope: scope,
        expandedCategories: expanded,
        window: window,
        pending: pending,
      )) {
        continue;
      }
      items.add(
        BudgetScheduledItem(
          id: pending.occurrence.id,
          scheduledPaymentId: pending.scheduledPayment.id,
          title: pending.categoryName ?? pending.accountName,
          accountName: pending.accountName,
          categoryIcon: pending.categoryIcon,
          categoryColor: pending.categoryColor,
          amountMinor: pending.scheduledPayment.amountMinor,
          currency: pending.scheduledPayment.currency,
          date: pending.occurrence.effectiveDate,
        ),
      );
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  bool _matchesAccountId(BudgetScope scope, String accountId) {
    // No rows = every account. With rows, only surviving referents count; an
    // emptied dimension (rows but none alive) matches nothing, never "all".
    if (scope.isAccountGlobal) {
      return true;
    }
    return scope.aliveAccountIds.contains(accountId);
  }

  bool _matchesCategoryId(
    BudgetScope scope,
    Set<String> expandedCategories,
    String? categoryId,
  ) {
    if (scope.isCategoryGlobal) {
      return true;
    }
    return categoryId != null && expandedCategories.contains(categoryId);
  }

  bool _inWindow(BudgetPeriodWindow window, DateTime date) =>
      !date.isBefore(window.start) && date.isBefore(window.endExclusive);

  /// Expands each scoped category to itself plus its subcategories (HU-04). The
  /// hierarchy is two levels (root -> sub), but a BFS keeps it correct if that
  /// ever deepens.
  Set<String> expandCategories(
    Set<String> roots,
    Map<String, List<String>> children,
  ) {
    final result = <String>{};
    final queue = [...roots];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (result.add(id)) {
        queue.addAll(children[id] ?? const []);
      }
    }
    return result;
  }
}
