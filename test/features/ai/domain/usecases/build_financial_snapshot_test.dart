import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/accounts_overview.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts_overview.dart';
import 'package:billetudo/features/ai/domain/usecases/build_financial_snapshot.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/zero_based_summary.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_active_budgets.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_zero_based_summary.dart';
import 'package:billetudo/features/debts/domain/entities/debts_summary.dart';
import 'package:billetudo/features/debts/domain/usecases/watch_debts.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goals.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_point.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_series.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown_item.dart';
import 'package:billetudo/features/reports/domain/entities/chart_history_bounds.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_cashflow_report.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_category_breakdown_report.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payments.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../goals/presentation/goals_presentation_fixtures.dart';
import '../../../home/home_fixtures.dart' show buildHomeBudgetProgress;
import '../../../scheduled_payments/scheduled_payment_fixtures.dart'
    as scheduled;

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockWatchAccountsOverview extends Mock
    implements WatchAccountsOverview {}

class MockGetActiveBudgets extends Mock implements GetActiveBudgets {}

class MockGetZeroBasedSummary extends Mock implements GetZeroBasedSummary {}

class MockWatchGoals extends Mock implements WatchGoals {}

class MockWatchDebts extends Mock implements WatchDebts {}

class MockWatchCategoryBreakdownReport extends Mock
    implements WatchCategoryBreakdownReport {}

class MockWatchCashflowReport extends Mock implements WatchCashflowReport {}

class MockGetScheduledPayments extends Mock implements GetScheduledPayments {}

/// The snapshot is the whole picture the model reasons about, so the rules it
/// enforces are about honesty: integer minor units next to their currency,
/// unix seconds, nothing summed across currencies, and — the one that matters
/// most — a section that could not be read is OMITTED, never emitted empty.
void main() {
  late MockWatchAccounts watchAccounts;
  late MockWatchAccountsOverview watchAccountsOverview;
  late MockGetActiveBudgets getActiveBudgets;
  late MockGetZeroBasedSummary getZeroBasedSummary;
  late MockWatchGoals watchGoals;
  late MockWatchDebts watchDebts;
  late MockWatchCategoryBreakdownReport watchCategoryBreakdown;
  late MockWatchCashflowReport watchCashflow;
  late MockGetScheduledPayments getScheduledPayments;
  late BuildFinancialSnapshot usecase;

  final now = DateTime(2026, 8, 25, 10);
  final monthRange = DateRange(
    start: DateTime(2026, 8),
    endExclusive: DateTime(2026, 9),
    granularity: DateGranularity.monthly,
  );

  final breakdown = CategoryBreakdown(
    items: const [
      CategoryBreakdownItem(
        categoryId: 'cat-food',
        name: 'Comida',
        amountMinor: 124000000,
        movementCount: 18,
      ),
      CategoryBreakdownItem(
        categoryId: null,
        name: 'Sin categoría',
        amountMinor: 2000000,
        movementCount: 1,
      ),
    ],
    totalMinor: 126000000,
    range: monthRange,
  );

  final cashflow = CashflowSeries(
    points: [
      CashflowPoint(
        periodStart: DateTime(2026, 7),
        incomeMinor: 500000000,
        expenseMinor: 300000000,
        debtIncomeMinor: 1000000,
        debtExpenseMinor: 2000000,
      ),
    ],
    includeDebtMovements: true,
    bounds: ChartHistoryBounds(
      earliestDataDate: DateTime(2026, 3),
      requestedRange: monthRange,
      effectiveRange: monthRange,
      isClamped: false,
      isDailyGranularity: false,
    ),
  );

  const debts = DebtsSummary(
    debts: [],
    totals: [
      DebtCurrencyTotal(
        currency: 'COP',
        iOweOutstandingMinor: 80000000,
        owedToMeOutstandingMinor: 15000000,
      ),
    ],
    closedTotals: [],
  );

  ScheduledPaymentSummary scheduledSummary({
    String id = 'sp-1',
    String? categoryName = 'Arriendo',
    String accountName = 'Bancolombia',
    DateTime? nextDate,
  }) =>
      ScheduledPaymentSummary(
        scheduledPayment: scheduled.buildScheduledPayment(
          id: id,
          amountMinor: 150000000,
          nextDate: nextDate ?? DateTime(2026, 9, 1),
          frequency: ScheduledPaymentFrequency.monthly,
          note: 'arriendo del apto — no debe viajar',
        ),
        accountName: accountName,
        categoryName: categoryName,
      );

  /// Every source healthy and single-currency, so each test only overrides the
  /// one source it is about.
  void stubHealthySources({
    List<AccountWithBalance>? accounts,
    List<BudgetWithProgress>? budgets,
    List<GoalWithProgress>? goals,
    ZeroBasedSummary? zeroBased,
    List<ScheduledPaymentSummary>? scheduledPayments,
  }) {
    final resolvedAccounts = accounts ??
        [
          buildAccountWithBalance(
            account: buildAccount(id: 'acc-1', currency: 'COP'),
            balanceMinor: 250000000,
          ),
        ];

    when(watchAccounts.call).thenAnswer(
      (_) => Stream.value(Right(resolvedAccounts)),
    );
    when(watchAccountsOverview.call).thenAnswer(
      (_) => Stream.value(Right(AccountsOverview.from(resolvedAccounts))),
    );
    when(getActiveBudgets.call).thenAnswer(
      (_) => Stream.value(
        Right(budgets ?? [buildHomeBudgetProgress()]),
      ),
    );
    when(getZeroBasedSummary.call).thenAnswer(
      (_) => Stream.value(
        Right(
          zeroBased ??
              const ZeroBasedSummary(
                currency: 'COP',
                incomeMinor: 500000000,
                assignedMinor: 420000000,
              ),
        ),
      ),
    );
    when(watchGoals.call).thenAnswer(
      (_) => Stream.value(
        Right(goals ?? [buildGoalWithProgress(savedMinor: 120000)]),
      ),
    );
    when(watchDebts.call).thenAnswer((_) => Stream.value(const Right(debts)));
    when(() => watchCategoryBreakdown(any()))
        .thenAnswer((_) => Stream.value(Right(breakdown)));
    when(() => watchCashflow(any()))
        .thenAnswer((_) => Stream.value(Right(cashflow)));
    when(getScheduledPayments.call).thenAnswer(
      (_) => Stream.value(
        Right(scheduledPayments ?? [scheduledSummary()]),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(WatchCashflowReportParams(range: monthRange));
    registerFallbackValue(
      WatchCategoryBreakdownReportParams(range: monthRange),
    );
  });

  setUp(() {
    watchAccounts = MockWatchAccounts();
    watchAccountsOverview = MockWatchAccountsOverview();
    getActiveBudgets = MockGetActiveBudgets();
    getZeroBasedSummary = MockGetZeroBasedSummary();
    watchGoals = MockWatchGoals();
    watchDebts = MockWatchDebts();
    watchCategoryBreakdown = MockWatchCategoryBreakdownReport();
    watchCashflow = MockWatchCashflowReport();
    getScheduledPayments = MockGetScheduledPayments();
    usecase = BuildFinancialSnapshot(
      watchAccounts,
      watchAccountsOverview,
      getActiveBudgets,
      getZeroBasedSummary,
      watchGoals,
      watchDebts,
      watchCategoryBreakdown,
      watchCashflow,
      getScheduledPayments,
      const ProjectUpcomingOccurrences(),
    );
  });

  Future<Map<String, Object?>> buildJson() async {
    final result = await usecase(now: now);
    return result.getRight().toNullable()!.toJson();
  }

  group('happy path', () {
    test('emits every section it could read', () async {
      stubHealthySources();

      final json = await buildJson();

      expect(
        json.keys,
        containsAll(<String>[
          'generatedAt',
          'periodStart',
          'periodEnd',
          'accounts',
          'currencyTotals',
          'spendingByCategory',
          'cashflow',
          'budgets',
          'goals',
          'debtTotals',
          'upcoming',
          'zeroBased',
          'counts',
        ]),
      );
    });

    test('every amount is an integer of minor units beside its currency',
        () async {
      stubHealthySources();

      final json = await buildJson();

      final account = (json['accounts']! as List).first as Map<String, Object?>;
      expect(account['balanceMinor'], isA<int>());
      expect(account['balanceMinor'], 250000000);
      expect(account['currency'], 'COP');

      final spending = json['spendingByCategory']! as Map<String, Object?>;
      expect(spending['totalMinor'], 126000000);
      expect(spending['currency'], 'COP');
      expect(
        (spending['items']! as List)
            .map((item) => (item! as Map<String, Object?>)['amountMinor']),
        everyElement(isA<int>()),
      );
    });

    test('dates are unix seconds, never milliseconds', () async {
      stubHealthySources();

      final json = await buildJson();

      expect(json['generatedAt'], now.millisecondsSinceEpoch ~/ 1000);
      expect(
        json['periodStart'],
        DateTime(2026, 8).millisecondsSinceEpoch ~/ 1000,
      );
      expect(
        json['periodEnd'],
        DateTime(2026, 9).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('cash-flow points fold debt movements into income and expense',
        () async {
      stubHealthySources();

      final json = await buildJson();

      final points = (json['cashflow']! as Map<String, Object?>)['points']!
          as List;
      final point = points.first as Map<String, Object?>;
      expect(point['incomeMinor'], 500000000 + 1000000);
      expect(point['expenseMinor'], 300000000 + 2000000);
      expect(point['netMinor'], 501000000 - 302000000);
    });

    test('an upcoming payment travels by category, never by its note',
        () async {
      stubHealthySources();

      final json = await buildJson();

      final upcoming = (json['upcoming']! as List).first as Map<String, Object?>;
      expect(upcoming['name'], 'Arriendo');
      expect(json.toString(), isNot(contains('no debe viajar')));
    });

    test('an upcoming payment with no category falls back to the account name',
        () async {
      stubHealthySources(
        scheduledPayments: [scheduledSummary(categoryName: null)],
      );

      final json = await buildJson();

      final upcoming = (json['upcoming']! as List).first as Map<String, Object?>;
      expect(upcoming['name'], 'Bancolombia');
    });

    test('counts report the real totals even when a list is capped', () async {
      stubHealthySources(
        goals: [
          for (var i = 0; i < 30; i++)
            buildGoalWithProgress(goal: buildGoal(id: 'g$i')),
        ],
      );

      final json = await buildJson();

      expect(
        json['goals']! as List,
        hasLength(BuildFinancialSnapshot.maxListRows),
      );
      expect((json['counts']! as Map<String, Object?>)['goals'], 30);
    });

    test('the category breakdown is capped at its own tighter limit', () async {
      stubHealthySources();
      when(() => watchCategoryBreakdown(any())).thenAnswer(
        (_) => Stream.value(
          Right(
            CategoryBreakdown(
              items: [
                for (var i = 0; i < 20; i++)
                  CategoryBreakdownItem(
                    categoryId: 'cat-$i',
                    name: 'Categoría $i',
                    amountMinor: 1000 * (i + 1),
                    movementCount: 1,
                  ),
              ],
              totalMinor: 210000,
              range: monthRange,
            ),
          ),
        ),
      );

      final json = await buildJson();

      expect(
        (json['spendingByCategory']! as Map<String, Object?>)['items'],
        hasLength(BuildFinancialSnapshot.maxCategoryRows),
      );
    });

    test('the uncategorised bucket travels with no categoryId at all',
        () async {
      stubHealthySources();

      final json = await buildJson();

      final items =
          (json['spendingByCategory']! as Map<String, Object?>)['items']!
              as List;
      final uncategorised = items.last! as Map<String, Object?>;
      expect(uncategorised.containsKey('categoryId'), isFalse);
    });
  });

  group('a section that could not be read is omitted, never emitted empty', () {
    test('a failing budgets source drops the key instead of sending an empty '
        'list', () async {
      stubHealthySources();
      when(getActiveBudgets.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('budgets are down'))),
      );

      final json = await buildJson();

      expect(json.containsKey('budgets'), isFalse);
      expect((json['counts']! as Map<String, Object?>)['budgets'], 0);
      expect(json.containsKey('goals'), isTrue);
    });

    test('a budgets source with genuinely nothing to show still emits an empty '
        'list', () async {
      stubHealthySources(budgets: []);

      final json = await buildJson();

      expect(json['budgets'], isEmpty);
      expect(json.containsKey('budgets'), isTrue);
    });

    test('a stream that errors drops only its own section', () async {
      stubHealthySources();
      when(watchGoals.call).thenAnswer(
        (_) => Stream<Result<List<GoalWithProgress>>>.error(
          Exception('goals blew up'),
        ),
      );

      final json = await buildJson();

      expect(json.containsKey('goals'), isFalse);
      expect(json.containsKey('accounts'), isTrue);
    });

    test('a stream that throws an Error also drops only its own section',
        () async {
      // Separate from the `Exception` case above because it is the one that
      // regressed: `_once` used to catch only `Exception`, so a `TypeError`
      // from a bad cast in any upstream mapper escaped `call()` and took the
      // WHOLE snapshot down instead of one section. That is the opposite of
      // the degradation this use case promises, and it bites hardest on real
      // data — the only place a mapper actually mishandles something.
      stubHealthySources();
      when(watchGoals.call).thenAnswer(
        (_) => Stream<Result<List<GoalWithProgress>>>.error(
          StateError('goals mapper blew up'),
        ),
      );

      final json = await buildJson();

      expect(json.containsKey('goals'), isFalse);
      expect(json.containsKey('accounts'), isTrue);
    });

    test('a stream that closes without emitting drops only its own section',
        () async {
      stubHealthySources();
      when(watchDebts.call).thenAnswer(
        (_) => const Stream<Result<DebtsSummary>>.empty(),
      );

      final json = await buildJson();

      expect(json.containsKey('debtTotals'), isFalse);
      expect(json.containsKey('accounts'), isTrue);
    });

    test('a zero-based summary that is legitimately null omits its section '
        'without counting as an outage', () async {
      stubHealthySources();
      when(getZeroBasedSummary.call).thenAnswer(
        (_) => Stream.value(const Right<Failure, ZeroBasedSummary?>(null)),
      );

      final json = await buildJson();

      expect(json.containsKey('zeroBased'), isFalse);
      expect(json.containsKey('accounts'), isTrue);
    });

    test('a source that never emits does not hang the rest of the snapshot',
        () async {
      stubHealthySources();
      when(getScheduledPayments.call).thenAnswer(
        (_) => StreamController<Result<List<ScheduledPaymentSummary>>>().stream,
      );

      final json = await buildJson();

      expect(json.containsKey('upcoming'), isFalse);
      expect(json.containsKey('accounts'), isTrue);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('total outage', () {
    test('fails with a DatabaseFailure when no source at all could be read',
        () async {
      when(watchAccounts.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('down'))),
      );
      when(watchAccountsOverview.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('down'))),
      );
      when(getActiveBudgets.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('down'))),
      );
      when(getZeroBasedSummary.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('down'))),
      );
      when(watchGoals.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('down'))),
      );
      when(watchDebts.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('down'))),
      );
      when(() => watchCategoryBreakdown(any())).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('down'))),
      );
      when(() => watchCashflow(any())).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('down'))),
      );
      when(getScheduledPayments.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('down'))),
      );

      final result = await usecase(now: now);

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });

  group('multi-currency', () {
    test('omits the category breakdown and the cash flow, which cannot be '
        'split by currency', () async {
      stubHealthySources(
        accounts: [
          buildAccountWithBalance(
            account: buildAccount(id: 'acc-1', currency: 'COP'),
            balanceMinor: 250000000,
          ),
          buildAccountWithBalance(
            account: buildAccount(id: 'acc-2', currency: 'USD'),
            balanceMinor: 40000,
          ),
        ],
      );

      final json = await buildJson();

      expect(json.containsKey('spendingByCategory'), isFalse);
      expect(json.containsKey('cashflow'), isFalse);
      expect(json['accounts'], hasLength(2));
      expect(json['currencyTotals'], hasLength(2));
    });

    test('an unreadable account list also omits the currency-bound sections',
        () async {
      stubHealthySources();
      when(watchAccounts.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('accounts are down'))),
      );

      final json = await buildJson();

      expect(json.containsKey('accounts'), isFalse);
      expect(json.containsKey('spendingByCategory'), isFalse);
      expect(json.containsKey('cashflow'), isFalse);
      expect(json.containsKey('budgets'), isTrue);
    });
  });
}
