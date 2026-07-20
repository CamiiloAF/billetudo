import 'package:billetudo/features/budgets/domain/entities/budget_detail_data.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/services/budget_progress_calculator.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_progress.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:flutter_test/flutter_test.dart';

import '../budget_fixtures.dart';

/// HU-12: `GetBudgetProgress` populates `BudgetProgress.scheduledMinor` and
/// `BudgetPeriodView.scheduledItems`, reusing `ProjectUpcomingOccurrences` and
/// the calculator's HU-12 matching, and zeroes it out for a past window
/// (criterion 7).
void main() {
  const usecase = GetBudgetProgress(
      BudgetProgressCalculator(), ProjectUpcomingOccurrences());

  ScheduledPayment template({
    String id = 't1',
    String accountId = 'a1',
    DateTime? nextDate,
  }) =>
      ScheduledPayment(
        id: id,
        accountId: accountId,
        amountMinor: 1000,
        currency: 'COP',
        type: ScheduledPaymentType.expense,
        frequency: ScheduledPaymentFrequency.monthly,
        interval: 1,
        nextDate: nextDate ?? DateTime(2024, 1, 20),
        requiresConfirmation: false,
        createdAt: DateTime(2024),
        updatedAt: 0,
      );

  BudgetScheduledTemplateDetail detail(ScheduledPayment template) =>
      BudgetScheduledTemplateDetail(
        template: template,
        title: 'Renta',
        accountName: 'Efectivo',
      );

  test(
      'a future window with no spend still reports scheduledMinor '
      '(criterion 7)', () {
    final budget = buildBudget(startDate: DateTime(2024, 3, 1));
    final t = template(nextDate: DateTime(2024, 3, 10));
    final data = BudgetDetailData(
      budget: budget,
      scope: const BudgetScope.empty(),
      expenses: const [],
      categoryChildren: const {},
      scheduledTemplates: [detail(t)],
      pendingScheduledOccurrences: const [],
    );

    final view = usecase.call(data, now: DateTime(2024, 1, 15));

    expect(view.window.status, BudgetWindowStatus.future);
    expect(view.progress.spentMinor, 0);
    expect(view.progress.scheduledMinor, 1000);
    expect(view.scheduledItems, hasLength(1));
  });

  test(
      'a past window always reports scheduledMinor 0, even with a stale '
      'pending occurrence inside it (criterion 7)', () {
    final budget = buildBudget(startDate: DateTime(2024, 1, 1));
    final t = template(id: 'stale', nextDate: DateTime(2024, 3, 1));
    final stalePending = PendingScheduledOccurrence(
      occurrence: ScheduledPaymentOccurrence(
        id: 'p1',
        scheduledPaymentId: t.id,
        occurrenceDate: DateTime(2024, 1, 15),
        status: ScheduledOccurrenceStatus.pending,
        createdAt: DateTime(2024),
        updatedAt: 0,
      ),
      scheduledPayment: t,
      accountName: 'Efectivo',
    );
    final data = BudgetDetailData(
      budget: budget,
      scope: const BudgetScope.empty(),
      expenses: const [],
      categoryChildren: const {},
      scheduledTemplates: [detail(t)],
      pendingScheduledOccurrences: [stalePending],
    );

    // `now` is well past January: the January window is closed history.
    final view = usecase.call(data, now: DateTime(2024, 6, 1), index: 0);

    expect(view.window.status, BudgetWindowStatus.past);
    expect(view.progress.scheduledMinor, 0);
    expect(view.scheduledItems, isEmpty);
  });

  test(
      'combines projected and pending sources into scheduledMinor without '
      'double counting', () {
    final budget = buildBudget(startDate: DateTime(2024, 1, 1));
    // nextDate already advanced past a pending occurrence's date.
    final t = template(nextDate: DateTime(2024, 1, 25));
    final pendingOccurrence = PendingScheduledOccurrence(
      occurrence: ScheduledPaymentOccurrence(
        id: 'p1',
        scheduledPaymentId: t.id,
        occurrenceDate: DateTime(2024, 1, 10),
        status: ScheduledOccurrenceStatus.pending,
        createdAt: DateTime(2024),
        updatedAt: 0,
      ),
      scheduledPayment: t,
      accountName: 'Efectivo',
    );
    final data = BudgetDetailData(
      budget: budget,
      scope: const BudgetScope.empty(),
      expenses: const [],
      categoryChildren: const {},
      scheduledTemplates: [detail(t)],
      pendingScheduledOccurrences: [pendingOccurrence],
    );

    final view = usecase.call(data, now: DateTime(2024, 1, 5), index: 0);

    expect(view.window.status, BudgetWindowStatus.current);
    // 1000 (pending Jan 10) + 1000 (projected Jan 25) = 2000, never 3000.
    expect(view.progress.scheduledMinor, 2000);
    expect(view.scheduledItems, hasLength(2));
  });
}
