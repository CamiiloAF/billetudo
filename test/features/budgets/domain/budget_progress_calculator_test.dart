import 'package:billetudo/features/budgets/domain/entities/budget_detail_data.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_expense.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/services/budget_progress_calculator.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'budget_fixtures.dart';

void main() {
  const calc = BudgetProgressCalculator();

  // A January monthly window: [Jan 1, Feb 1).
  final window = BudgetPeriodWindow(
    start: DateTime(2024, 1, 1),
    endExclusive: DateTime(2024, 2, 1),
    index: 0,
    status: BudgetWindowStatus.current,
    hasPrevious: false,
    hasNext: true,
  );

  final budget = buildBudget(startDate: DateTime(2024, 1, 1));

  BudgetExpense expense({
    String id = 'e',
    String accountId = 'a1',
    String? categoryId,
    int amountMinor = 1000,
    String currency = 'COP',
    DateTime? date,
  }) =>
      BudgetExpense(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        amountMinor: amountMinor,
        currency: currency,
        date: date ?? DateTime(2024, 1, 10),
      );

  int spent(BudgetScope scope, List<BudgetExpense> expenses,
          {Map<String, List<String>> children = const {}}) =>
      calc.spentIn(
        budget: budget,
        scope: scope,
        window: window,
        expenses: expenses,
        categoryChildren: children,
      );

  group('window + currency', () {
    test('only sums expenses inside the window', () {
      final total = spent(const BudgetScope.empty(), [
        expense(id: 'in', date: DateTime(2024, 1, 10), amountMinor: 500),
        expense(id: 'before', date: DateTime(2023, 12, 31), amountMinor: 700),
        expense(id: 'after', date: DateTime(2024, 2, 1), amountMinor: 900),
      ]);
      expect(total, 500);
    });

    test('only sums the budget currency', () {
      final total = spent(const BudgetScope.empty(), [
        expense(id: 'cop', currency: 'COP', amountMinor: 500),
        expense(id: 'usd', currency: 'USD', amountMinor: 900),
      ]);
      expect(total, 500);
    });
  });

  group('global scope (HU-02)', () {
    test('an empty scope matches every account and category', () {
      final total = spent(const BudgetScope.empty(), [
        expense(id: 'a', accountId: 'a1', categoryId: 'c1', amountMinor: 300),
        expense(id: 'b', accountId: 'a2', categoryId: null, amountMinor: 200),
      ]);
      expect(total, 500);
    });
  });

  group('account scope', () {
    test('matches only accounts in the (alive) scope', () {
      const scope = BudgetScope(
        accounts: [BudgetScopeRef(id: 'a1', referentAlive: true)],
      );
      final total = spent(scope, [
        expense(id: 'a', accountId: 'a1', amountMinor: 300),
        expense(id: 'b', accountId: 'a2', amountMinor: 200),
      ]);
      expect(total, 300);
    });
  });

  group('category scope + subcategory expansion (HU-04)', () {
    test('a scoped root also counts its subcategories', () {
      const scope = BudgetScope(
        categories: [BudgetScopeRef(id: 'root', referentAlive: true)],
      );
      final total = spent(
        scope,
        [
          expense(id: 'root', categoryId: 'root', amountMinor: 100),
          expense(id: 'sub', categoryId: 'sub', amountMinor: 200),
          expense(id: 'other', categoryId: 'x', amountMinor: 400),
        ],
        children: {
          'root': ['sub'],
        },
      );
      expect(total, 300);
    });

    test('an uncategorized expense never matches a category scope', () {
      const scope = BudgetScope(
        categories: [BudgetScopeRef(id: 'c1', referentAlive: true)],
      );
      final total = spent(scope, [
        expense(id: 'none', categoryId: null, amountMinor: 500),
      ]);
      expect(total, 0);
    });
  });

  group('global-vs-emptied (critical rule)', () {
    test('a scope whose only account referent is deleted matches NOTHING', () {
      const scope = BudgetScope(
        accounts: [BudgetScopeRef(id: 'gone', referentAlive: false)],
      );
      final total = spent(scope, [
        expense(id: 'a', accountId: 'a1', amountMinor: 500),
        expense(id: 'b', accountId: 'gone', amountMinor: 700),
      ]);
      // Emptied scope != global: it must not fall back to "all".
      expect(total, 0);
    });

    test('a stranded category scope matches NOTHING', () {
      const scope = BudgetScope(
        categories: [BudgetScopeRef(id: 'gone', referentAlive: false)],
      );
      final total = spent(scope, [
        expense(id: 'a', categoryId: 'c1', amountMinor: 500),
      ]);
      expect(total, 0);
    });

    test('surviving referents still count when a sibling is deleted', () {
      const scope = BudgetScope(
        accounts: [
          BudgetScopeRef(id: 'a1', referentAlive: true),
          BudgetScopeRef(id: 'gone', referentAlive: false),
        ],
      );
      final total = spent(scope, [
        expense(id: 'a', accountId: 'a1', amountMinor: 500),
        expense(id: 'b', accountId: 'gone', amountMinor: 700),
      ]);
      expect(total, 500);
    });

    test('BudgetScope reports the stranded state', () {
      const stranded = BudgetScope(
        accounts: [BudgetScopeRef(id: 'gone', referentAlive: false)],
      );
      expect(stranded.isStranded, isTrue);
      expect(stranded.isGlobal, isFalse);
      expect(const BudgetScope.empty().isGlobal, isTrue);
      expect(const BudgetScope.empty().isStranded, isFalse);
    });
  });

  group('HU-12: scheduledItemsIn', () {
    ScheduledPayment template({
      String id = 't1',
      String accountId = 'a1',
      String? categoryId,
      String currency = 'COP',
      int amountMinor = 1000,
      ScheduledPaymentFrequency frequency = ScheduledPaymentFrequency.monthly,
      int interval = 1,
      DateTime? nextDate,
      DateTime? endDate,
    }) =>
        ScheduledPayment(
          id: id,
          accountId: accountId,
          categoryId: categoryId,
          amountMinor: amountMinor,
          currency: currency,
          type: ScheduledPaymentType.expense,
          frequency: frequency,
          interval: interval,
          firstPaymentDate: nextDate ?? DateTime(2024, 1, 5),
          nextDate: nextDate ?? DateTime(2024, 1, 5),
          endDate: endDate,
          requiresConfirmation: false,
          createdAt: DateTime(2024),
          updatedAt: 0,
        );

    BudgetScheduledTemplateDetail detail(
      ScheduledPayment template, {
      String title = 'Renta',
      String accountName = 'Efectivo',
    }) =>
        BudgetScheduledTemplateDetail(
          template: template,
          title: title,
          accountName: accountName,
        );

    PendingScheduledOccurrence pending({
      String id = 'p1',
      required ScheduledPayment scheduledPayment,
      required DateTime occurrenceDate,
      ScheduledOccurrenceStatus status = ScheduledOccurrenceStatus.pending,
      String accountName = 'Efectivo',
    }) =>
        PendingScheduledOccurrence(
          occurrence: ScheduledPaymentOccurrence(
            id: id,
            scheduledPaymentId: scheduledPayment.id,
            occurrenceDate: occurrenceDate,
            status: status,
            createdAt: DateTime(2024),
            updatedAt: 0,
          ),
          scheduledPayment: scheduledPayment,
          accountName: accountName,
        );

    const projector = ProjectUpcomingOccurrences();

    test(
        'criterion 1: an eligible template contributes its window '
        'occurrence(s) to scheduledMinor', () {
      final t = template(nextDate: DateTime(2024, 1, 20));
      final projected = projector(
        templates: [t],
        windowStart: window.start,
        windowEndInclusive:
            window.endExclusive.subtract(const Duration(days: 1)),
      );

      final items = calc.scheduledItemsIn(
        budget: budget,
        scope: const BudgetScope.empty(),
        window: window,
        templates: [detail(t)],
        projected: projected,
        pendingOccurrences: const [],
      );

      expect(items, hasLength(1));
      expect(items.single.amountMinor, 1000);
      expect(items.single.date, DateTime(2024, 1, 20));
    });

    test(
        'criterion 2: a date already materialized (confirmed) is not '
        're-projected, because nextDate has advanced past it', () {
      // The template's nextDate has already moved past Jan 5 (materialized as
      // a Transaction there); only the still-future date counts.
      final t = template(nextDate: DateTime(2024, 2, 5));
      final projected = projector(
        templates: [t],
        windowStart: window.start,
        windowEndInclusive:
            window.endExclusive.subtract(const Duration(days: 1)),
      );

      final items = calc.scheduledItemsIn(
        budget: budget,
        scope: const BudgetScope.empty(),
        window: window,
        templates: [detail(t)],
        projected: projected,
        pendingOccurrences: const [],
      );

      expect(items, isEmpty);
    });

    test(
        'criterion 3: a weekly template inside a monthly window projects '
        'multiple occurrences, bounded by the window and by endDate', () {
      final t = template(
        frequency: ScheduledPaymentFrequency.weekly,
        nextDate: DateTime(2024, 1, 1),
      );
      final projected = projector(
        templates: [t],
        windowStart: window.start,
        windowEndInclusive:
            window.endExclusive.subtract(const Duration(days: 1)),
      );

      final items = calc.scheduledItemsIn(
        budget: budget,
        scope: const BudgetScope.empty(),
        window: window,
        templates: [detail(t)],
        projected: projected,
        pendingOccurrences: const [],
      );

      // Jan 1, 8, 15, 22, 29 all fall inside [Jan 1, Feb 1).
      expect(items, hasLength(5));
      expect(items.map((i) => i.date), [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 8),
        DateTime(2024, 1, 15),
        DateTime(2024, 1, 22),
        DateTime(2024, 1, 29),
      ]);

      final bounded = template(
        id: 'bounded',
        frequency: ScheduledPaymentFrequency.weekly,
        nextDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 10),
      );
      final boundedProjected = projector(
        templates: [bounded],
        windowStart: window.start,
        windowEndInclusive:
            window.endExclusive.subtract(const Duration(days: 1)),
      );
      final boundedItems = calc.scheduledItemsIn(
        budget: budget,
        scope: const BudgetScope.empty(),
        window: window,
        templates: [detail(bounded)],
        projected: boundedProjected,
        pendingOccurrences: const [],
      );
      // Only Jan 1 and Jan 8 are on/before endDate (Jan 10).
      expect(boundedItems, hasLength(2));
    });

    test(
        'criterion 4: a registered pending occurrence counts, combined '
        'without double-counting a projected date', () {
      // nextDate already advanced past the pending occurrence's date (it was
      // caught up by the manual-mode generator, which never re-derives it
      // from nextDate).
      final t = template(nextDate: DateTime(2024, 2, 1));
      final projected = projector(
        templates: [t],
        windowStart: window.start,
        windowEndInclusive:
            window.endExclusive.subtract(const Duration(days: 1)),
      );
      final pendingOccurrence =
          pending(scheduledPayment: t, occurrenceDate: DateTime(2024, 1, 15));

      final items = calc.scheduledItemsIn(
        budget: budget,
        scope: const BudgetScope.empty(),
        window: window,
        templates: [detail(t)],
        projected: projected,
        pendingOccurrences: [pendingOccurrence],
      );

      expect(items, hasLength(1));
      expect(items.single.date, DateTime(2024, 1, 15));
      expect(items.single.amountMinor, 1000);
    });

    test(
        'a confirmed occurrence in the ledger is never counted (only '
        '`pending` is)', () {
      final t = template(nextDate: DateTime(2024, 2, 1));
      final confirmed = pending(
        scheduledPayment: t,
        occurrenceDate: DateTime(2024, 1, 15),
        status: ScheduledOccurrenceStatus.confirmed,
      );

      final items = calc.scheduledItemsIn(
        budget: budget,
        scope: const BudgetScope.empty(),
        window: window,
        templates: [detail(t)],
        projected: const [],
        pendingOccurrences: [confirmed],
      );

      expect(items, isEmpty);
    });

    test('respects scope and currency, same rule as matched expenses', () {
      final wrongCurrency = template(id: 'wrong-currency', currency: 'USD');
      final wrongAccount = template(id: 'wrong-account', accountId: 'other');
      final eligible = template(id: 'eligible', accountId: 'a1');

      const scope = BudgetScope(
        accounts: [BudgetScopeRef(id: 'a1', referentAlive: true)],
      );

      final templates = [
        detail(wrongCurrency),
        detail(wrongAccount),
        detail(eligible),
      ];
      final projected = [
        for (final t in [wrongCurrency, wrongAccount, eligible])
          ...projector(
            templates: [t],
            windowStart: window.start,
            windowEndInclusive:
                window.endExclusive.subtract(const Duration(days: 1)),
          ),
      ];

      final items = calc.scheduledItemsIn(
        budget: budget,
        scope: scope,
        window: window,
        templates: templates,
        projected: projected,
        pendingOccurrences: const [],
      );

      expect(items, hasLength(1));
      expect(items.single.scheduledPaymentId, 'eligible');
    });
  });

  group('both dimensions (AND)', () {
    test('an expense must satisfy account AND category scope', () {
      const scope = BudgetScope(
        accounts: [BudgetScopeRef(id: 'a1', referentAlive: true)],
        categories: [BudgetScopeRef(id: 'c1', referentAlive: true)],
      );
      final total = spent(scope, [
        expense(
            id: 'match', accountId: 'a1', categoryId: 'c1', amountMinor: 300),
        expense(
            id: 'wrongAcc',
            accountId: 'a2',
            categoryId: 'c1',
            amountMinor: 200),
        expense(
            id: 'wrongCat',
            accountId: 'a1',
            categoryId: 'c2',
            amountMinor: 400),
      ]);
      expect(total, 300);
    });
  });
}
