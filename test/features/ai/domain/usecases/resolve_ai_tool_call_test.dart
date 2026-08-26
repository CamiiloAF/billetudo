import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/ai/domain/entities/ai_tool_call.dart';
import 'package:billetudo/features/ai/domain/usecases/resolve_ai_tool_call.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_detail_data.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_view.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_by_id.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_progress.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/usecases/watch_goal_detail.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_point.dart';
import 'package:billetudo/features/reports/domain/entities/cashflow_series.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown_item.dart';
import 'package:billetudo/features/reports/domain/entities/chart_history_bounds.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_cashflow_report.dart';
import 'package:billetudo/features/reports/domain/usecases/watch_category_breakdown_report.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../goals/presentation/goals_presentation_fixtures.dart';
import '../../../home/home_fixtures.dart'
    show buildActivity, buildHomeBudgetProgress;

class MockWatchTransactions extends Mock implements WatchTransactions {}

class MockWatchCategoryBreakdownReport extends Mock
    implements WatchCategoryBreakdownReport {}

class MockWatchCashflowReport extends Mock implements WatchCashflowReport {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockGetBudgetById extends Mock implements GetBudgetById {}

class MockGetBudgetProgress extends Mock implements GetBudgetProgress {}

class MockWatchGoalDetail extends Mock implements WatchGoalDetail {}

/// The model's reads, answered from the local database. Two promises are on
/// the line here: a tool that cannot be resolved still answers `Right` with an
/// `error` payload (so the model explains instead of inventing), and no
/// transaction note ever leaves the device.
void main() {
  late MockWatchTransactions watchTransactions;
  late MockWatchCategoryBreakdownReport watchCategoryBreakdown;
  late MockWatchCashflowReport watchCashflow;
  late MockWatchAccounts watchAccounts;
  late MockGetBudgetById getBudgetById;
  late MockGetBudgetProgress getBudgetProgress;
  late MockWatchGoalDetail watchGoalDetail;
  late ResolveAiToolCall usecase;

  const augustFirst = 1754006400;
  const septemberFirst = 1756684800;

  final range = DateRange(
    start: DateTime(2026, 8),
    endExclusive: DateTime(2026, 9),
    granularity: DateGranularity.monthly,
  );

  void stubSingleCurrencyAccounts([String currency = 'COP']) {
    when(watchAccounts.call).thenAnswer(
      (_) => Stream.value(
        Right<Failure, List<AccountWithBalance>>([
          buildAccountWithBalance(
            account: buildAccount(id: 'acc-1', currency: currency),
            balanceMinor: 1000,
          ),
        ]),
      ),
    );
  }

  Future<Map<String, Object?>> resolve(
    String name, [
    Map<String, Object?> arguments = const <String, Object?>{},
  ]) async {
    final result = await usecase(
      AiToolCall(id: 'tc_0_0', name: name, arguments: arguments),
    );
    final toolResult = result.getRight().toNullable()!;
    expect(
      toolResult.toolCallId,
      'tc_0_0',
      reason: 'the answer must be addressable to the call that asked for it',
    );
    return toolResult.result;
  }

  setUpAll(() {
    registerFallbackValue(WatchCashflowReportParams(range: range));
    registerFallbackValue(WatchCategoryBreakdownReportParams(range: range));
    registerFallbackValue(TransactionFilter());
    registerFallbackValue(
      BudgetDetailData(
        budget: buildHomeBudgetProgress().budget,
        scope: const BudgetScope.empty(),
        expenses: const [],
        categoryChildren: const {},
        scheduledTemplates: const [],
        pendingScheduledOccurrences: const [],
      ),
    );
  });

  setUp(() {
    watchTransactions = MockWatchTransactions();
    watchCategoryBreakdown = MockWatchCategoryBreakdownReport();
    watchCashflow = MockWatchCashflowReport();
    watchAccounts = MockWatchAccounts();
    getBudgetById = MockGetBudgetById();
    getBudgetProgress = MockGetBudgetProgress();
    watchGoalDetail = MockWatchGoalDetail();
    usecase = ResolveAiToolCall(
      watchTransactions,
      watchCategoryBreakdown,
      watchCashflow,
      watchAccounts,
      getBudgetById,
      getBudgetProgress,
      watchGoalDetail,
    );
  });

  group('unresolvable calls answer with an error result, never a Left', () {
    test('an unknown tool name', () async {
      final result = await usecase(
        const AiToolCall(
          id: 'tc_0_0',
          name: 'drop_database',
          arguments: <String, Object?>{},
        ),
      );

      expect(result.isRight(), isTrue);
      expect(
        result.getRight().toNullable()!.result,
        containsPair('error', ResolveAiToolCall.errorNotFound),
      );
      expect(
        result.getRight().toNullable()!.result['message'],
        contains('drop_database'),
      );
    });

    test('get_transactions without a window', () async {
      final result = await resolve('get_transactions');

      expect(result['error'], ResolveAiToolCall.errorNotFound);
    });

    test('get_transactions with an inverted window', () async {
      final result = await resolve('get_transactions', <String, Object?>{
        'from': septemberFirst,
        'to': augustFirst,
      });

      expect(result['error'], ResolveAiToolCall.errorNotFound);
    });

    test('a movement list that could not be read', () async {
      when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('drift is down'))),
      );

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
      });

      expect(result['error'], ResolveAiToolCall.errorNotFound);
    });

    test('a budget id that does not exist', () async {
      when(() => getBudgetById('budget-ghost')).thenAnswer(
        (_) => Stream.value(const Left(NotFoundFailure('gone'))),
      );

      final result = await resolve(
        'get_budget_detail',
        <String, Object?>{'budgetId': 'budget-ghost'},
      );

      expect(result['error'], ResolveAiToolCall.errorNotFound);
      expect(result['message'], contains('budget-ghost'));
    });

    test('a goal id that does not exist', () async {
      when(() => watchGoalDetail('goal-ghost')).thenAnswer(
        (_) => Stream.value(const Left(NotFoundFailure('gone'))),
      );

      final result = await resolve(
        'get_goal_detail',
        <String, Object?>{'goalId': 'goal-ghost'},
      );

      expect(result['error'], ResolveAiToolCall.errorNotFound);
    });

    test('a breakdown of income, which no aggregator can answer', () async {
      stubSingleCurrencyAccounts();

      final result = await resolve(
        'get_category_breakdown',
        <String, Object?>{
          'from': augustFirst,
          'to': septemberFirst,
          'currency': 'COP',
          'type': 'income',
        },
      );

      expect(result['error'], ResolveAiToolCall.errorNotFound);
      verifyNever(() => watchCategoryBreakdown(any()));
    });
  });

  group('get_transactions', () {
    List<TransactionWithDetails> rows(int count) => [
          for (var i = 0; i < count; i++)
            buildActivity(
              id: 'tx-$i',
              amountMinor: 10000 + i,
              categoryName: 'Comida',
              date: DateTime(2026, 8, 10),
            ),
        ];

    test('caps the page at 50 rows even when the model asks for more',
        () async {
      when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right(rows(120))));

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
        'limit': 500,
      });

      expect(result['count'], ResolveAiToolCall.maxRows);
      expect(result['items'], hasLength(ResolveAiToolCall.maxRows));
      expect(result['truncated'], isTrue);
    });

    test('reports truncated: false when nothing was cut', () async {
      when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right(rows(3))));

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
      });

      expect(result['count'], 3);
      expect(result['truncated'], isFalse);
    });

    test('falls back to the default page size when no limit is given',
        () async {
      when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right(rows(80))));

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
      });

      expect(result['count'], ResolveAiToolCall.defaultRows);
      expect(result['truncated'], isTrue);
    });

    test('a limit below one still returns a usable row', () async {
      when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right(rows(3))));

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
        'limit': 0,
      });

      expect(result['count'], 1);
    });

    test('never sends the note the user wrote on a movement', () async {
      when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(
          Right([
            buildActivity(
              id: 'tx-1',
              categoryName: 'Comida',
              date: DateTime(2026, 8, 10),
            ),
          ]),
        ),
      );

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
      });

      final item = (result['items']! as List).single as Map<String, Object?>;
      expect(item.containsKey('note'), isFalse);
      expect(
        item.keys,
        containsAll(<String>[
          'id',
          'date',
          'amountMinor',
          'currency',
          'type',
          'accountName',
        ]),
      );
    });

    test('amounts stay integer minor units and dates unix seconds', () async {
      when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(
          Right([
            buildActivity(
              id: 'tx-1',
              amountMinor: 4500000,
              date: DateTime(2026, 8, 10),
            ),
          ]),
        ),
      );

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
      });

      final item = (result['items']! as List).single as Map<String, Object?>;
      expect(item['amountMinor'], 4500000);
      expect(item['amountMinor'], isA<int>());
      expect(item['date'], DateTime(2026, 8, 10).millisecondsSinceEpoch ~/ 1000);
      expect(result['from'], augustFirst);
      expect(result['to'], septemberFirst);
    });

    test('filters by currency and minimum amount the shared filter cannot '
        'express', () async {
      when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(
          Right([
            buildActivity(id: 'tx-cop-big', amountMinor: 9000000),
            buildActivity(id: 'tx-cop-small', amountMinor: 1000),
            buildActivity(id: 'tx-usd', amountMinor: 9000000, currency: 'USD'),
          ]),
        ),
      );

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
        'currency': 'cop',
        'minAmountMinor': 5000,
      });

      expect(
        (result['items']! as List)
            .map((item) => (item! as Map<String, Object?>)['id']),
        ['tx-cop-big'],
      );
      expect(result['currency'], 'COP');
    });

    test('translates the exclusive wire window into an inclusive last day',
        () async {
      when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right(rows(1))));

      await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
        'type': 'expense',
        'accountIds': <Object?>['acc-1', '  ', 7],
      });

      final filter = verify(() => watchTransactions(captureAny()))
          .captured
          .single as TransactionFilter;
      expect(filter.types, {TransactionType.expense});
      expect(filter.accountIds, {'acc-1'});
      // `DatePeriodFilter.custom` strips the time; what matters is that the
      // exclusive `to` of the wire became an inclusive last day.
      final wireTo = DateTime.fromMillisecondsSinceEpoch(septemberFirst * 1000);
      final expectedLastDay = wireTo.subtract(const Duration(days: 1));
      expect(
        filter.datePeriod.customEnd,
        DateTime(
          expectedLastDay.year,
          expectedLastDay.month,
          expectedLastDay.day,
        ),
      );
    });
  });

  group('the currency guard', () {
    final breakdown = CategoryBreakdown(
      items: const [
        CategoryBreakdownItem(
          categoryId: 'cat-food',
          name: 'Comida',
          amountMinor: 124000000,
          movementCount: 18,
        ),
      ],
      totalMinor: 124000000,
      range: range,
    );

    test('answers when every account already uses the requested currency',
        () async {
      stubSingleCurrencyAccounts();
      when(() => watchCategoryBreakdown(any()))
          .thenAnswer((_) => Stream.value(Right(breakdown)));

      final result = await resolve(
        'get_category_breakdown',
        <String, Object?>{
          'from': augustFirst,
          'to': septemberFirst,
          'currency': 'COP',
        },
      );

      expect(result['error'], isNull);
      expect(result['currency'], 'COP');
      expect(result['totalMinor'], 124000000);
    });

    test('refuses when the accounts hold more than one currency', () async {
      when(watchAccounts.call).thenAnswer(
        (_) => Stream.value(
          Right<Failure, List<AccountWithBalance>>([
            buildAccountWithBalance(
              account: buildAccount(id: 'acc-1', currency: 'COP'),
              balanceMinor: 1000,
            ),
            buildAccountWithBalance(
              account: buildAccount(id: 'acc-2', currency: 'USD'),
              balanceMinor: 1000,
            ),
          ]),
        ),
      );

      final result = await resolve(
        'get_category_breakdown',
        <String, Object?>{
          'from': augustFirst,
          'to': septemberFirst,
          'currency': 'COP',
        },
      );

      expect(result['error'], ResolveAiToolCall.errorNotFound);
      expect(result['message'], contains('COP'));
      verifyNever(() => watchCategoryBreakdown(any()));
    });

    test('refuses when the account list itself could not be read', () async {
      when(watchAccounts.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('drift is down'))),
      );

      final result = await resolve(
        'compare_periods',
        <String, Object?>{
          'aFrom': augustFirst,
          'aTo': septemberFirst,
          'bFrom': augustFirst,
          'bTo': septemberFirst,
          'currency': 'COP',
        },
      );

      expect(result['error'], ResolveAiToolCall.errorNotFound);
      verifyNever(() => watchCashflow(any()));
    });
  });

  group('get_category_breakdown', () {
    test('caps the rows it returns and flags the truncation', () async {
      stubSingleCurrencyAccounts();
      when(() => watchCategoryBreakdown(any())).thenAnswer(
        (_) => Stream.value(
          Right(
            CategoryBreakdown(
              items: [
                for (var i = 0; i < 80; i++)
                  CategoryBreakdownItem(
                    categoryId: 'cat-$i',
                    name: 'Categoría $i',
                    amountMinor: 1000,
                    movementCount: 1,
                  ),
              ],
              totalMinor: 80000,
              range: range,
            ),
          ),
        ),
      );

      final result = await resolve(
        'get_category_breakdown',
        <String, Object?>{
          'from': augustFirst,
          'to': septemberFirst,
          'currency': 'COP',
          'topN': 500,
        },
      );

      expect(result['count'], ResolveAiToolCall.maxRows);
      expect(result['truncated'], isTrue);
    });

    test('every line carries the currency it is expressed in', () async {
      stubSingleCurrencyAccounts();
      when(() => watchCategoryBreakdown(any())).thenAnswer(
        (_) => Stream.value(
          Right(
            CategoryBreakdown(
              items: const [
                CategoryBreakdownItem(
                  categoryId: 'cat-food',
                  name: 'Comida',
                  amountMinor: 124000000,
                  movementCount: 18,
                  subcategories: [
                    CategoryBreakdownItem(
                      categoryId: 'cat-market',
                      name: 'Mercado',
                      amountMinor: 90000000,
                      movementCount: 4,
                    ),
                  ],
                ),
              ],
              totalMinor: 124000000,
              range: range,
            ),
          ),
        ),
      );

      final result = await resolve(
        'get_category_breakdown',
        <String, Object?>{
          'from': augustFirst,
          'to': septemberFirst,
          'currency': 'COP',
          'includeSubcategories': true,
        },
      );

      final item = (result['items']! as List).single as Map<String, Object?>;
      expect(item['currency'], 'COP');
      expect(item['amountMinor'], 124000000);
      final child =
          (item['subcategories']! as List).single as Map<String, Object?>;
      expect(child['currency'], 'COP');
      expect(child['amountMinor'], 90000000);
    });

    test('subcategories are omitted unless the model asked for them', () async {
      stubSingleCurrencyAccounts();
      when(() => watchCategoryBreakdown(any())).thenAnswer(
        (_) => Stream.value(
          Right(
            CategoryBreakdown(
              items: const [
                CategoryBreakdownItem(
                  categoryId: 'cat-food',
                  name: 'Comida',
                  amountMinor: 124000000,
                  movementCount: 18,
                  subcategories: [
                    CategoryBreakdownItem(
                      categoryId: 'cat-market',
                      name: 'Mercado',
                      amountMinor: 90000000,
                      movementCount: 4,
                    ),
                  ],
                ),
              ],
              totalMinor: 124000000,
              range: range,
            ),
          ),
        ),
      );

      final result = await resolve(
        'get_category_breakdown',
        <String, Object?>{
          'from': augustFirst,
          'to': septemberFirst,
          'currency': 'COP',
        },
      );

      final item = (result['items']! as List).single as Map<String, Object?>;
      expect(item.containsKey('subcategories'), isFalse);
    });
  });

  group('compare_periods', () {
    CashflowSeries series({required int income, required int expense}) =>
        CashflowSeries(
          points: [
            CashflowPoint(
              periodStart: DateTime(2026, 8),
              incomeMinor: income,
              expenseMinor: expense,
              debtIncomeMinor: 1000,
              debtExpenseMinor: 2000,
            ),
          ],
          includeDebtMovements: true,
          bounds: ChartHistoryBounds(
            earliestDataDate: DateTime(2026, 3),
            requestedRange: range,
            effectiveRange: range,
            isClamped: false,
            isDailyGranularity: false,
          ),
        );

    test('reports the deltas between two windows, debt movements folded in',
        () async {
      stubSingleCurrencyAccounts();
      var call = 0;
      when(() => watchCashflow(any())).thenAnswer(
        (_) => Stream.value(
          Right(
            call++ == 0
                ? series(income: 100000, expense: 50000)
                : series(income: 120000, expense: 90000),
          ),
        ),
      );

      final result = await resolve('compare_periods', <String, Object?>{
        'aFrom': augustFirst,
        'aTo': septemberFirst,
        'bFrom': augustFirst,
        'bTo': septemberFirst,
        'currency': 'COP',
      });

      expect(result['groupBy'], 'total');
      expect(
        (result['a']! as Map<String, Object?>)['incomeMinor'],
        100000 + 1000,
      );
      expect(result['expenseDeltaMinor'], 92000 - 52000);
      expect(result['incomeDeltaMinor'], 121000 - 101000);
    });

    test('groups by category when asked', () async {
      stubSingleCurrencyAccounts();
      when(() => watchCategoryBreakdown(any())).thenAnswer(
        (_) => Stream.value(
          Right(
            CategoryBreakdown(
              items: const [
                CategoryBreakdownItem(
                  categoryId: 'cat-food',
                  name: 'Comida',
                  amountMinor: 50000,
                  movementCount: 3,
                ),
              ],
              totalMinor: 50000,
              range: range,
            ),
          ),
        ),
      );

      final result = await resolve('compare_periods', <String, Object?>{
        'aFrom': augustFirst,
        'aTo': septemberFirst,
        'bFrom': augustFirst,
        'bTo': septemberFirst,
        'currency': 'COP',
        'groupBy': 'category',
      });

      expect(result['groupBy'], 'category');
      expect(result['deltaMinor'], 0);
      verifyNever(() => watchCashflow(any()));
    });
  });

  group('get_budget_detail', () {
    BudgetPeriodView periodView({required int index, int spentMinor = 300000}) =>
        BudgetPeriodView(
          window: BudgetPeriodWindow(
            start: DateTime(2026, 8),
            endExclusive: DateTime(2026, 9),
            index: index,
            status: BudgetWindowStatus.current,
            hasPrevious: index > 0,
            hasNext: true,
          ),
          progress: BudgetProgress(
            amountMinor: 600000,
            spentMinor: spentMinor,
            daysLeft: 6,
          ),
          activity: const [],
        );

    test('answers the current period with integer minor units', () async {
      final data = BudgetDetailData(
        budget: buildHomeBudgetProgress(id: 'budget-1').budget,
        scope: const BudgetScope.empty(),
        expenses: const [],
        categoryChildren: const {},
        scheduledTemplates: const [],
        pendingScheduledOccurrences: const [],
      );
      when(() => getBudgetById('budget-1'))
          .thenAnswer((_) => Stream.value(Right(data)));
      when(
        () => getBudgetProgress(
          any(),
          now: any(named: 'now'),
          index: any(named: 'index'),
        ),
      ).thenReturn(periodView(index: 3));

      final result = await withClock(
        Clock.fixed(DateTime(2026, 8, 25)),
        () => resolve(
          'get_budget_detail',
          <String, Object?>{'budgetId': 'budget-1'},
        ),
      );

      expect(result['id'], 'budget-1');
      expect(
        (result['current']! as Map<String, Object?>)['spentMinor'],
        300000,
      );
      expect(
        (result['current']! as Map<String, Object?>)['remainingMinor'],
        300000,
      );
      expect(result.containsKey('previousPeriods'), isFalse);
    });

    test('caps how far back the model can walk the periods', () async {
      final data = BudgetDetailData(
        budget: buildHomeBudgetProgress(id: 'budget-1').budget,
        scope: const BudgetScope.empty(),
        expenses: const [],
        categoryChildren: const {},
        scheduledTemplates: const [],
        pendingScheduledOccurrences: const [],
      );
      when(() => getBudgetById('budget-1'))
          .thenAnswer((_) => Stream.value(Right(data)));
      when(
        () => getBudgetProgress(
          any(),
          now: any(named: 'now'),
          index: any(named: 'index'),
        ),
      ).thenReturn(periodView(index: 20));

      final result = await withClock(
        Clock.fixed(DateTime(2026, 8, 25)),
        () => resolve('get_budget_detail', <String, Object?>{
          'budgetId': 'budget-1',
          'includePreviousPeriods': 99,
        }),
      );

      expect(result['previousPeriods'], hasLength(6));
    });

    test('stops at the budget start instead of inventing earlier periods',
        () async {
      final data = BudgetDetailData(
        budget: buildHomeBudgetProgress(id: 'budget-1').budget,
        scope: const BudgetScope.empty(),
        expenses: const [],
        categoryChildren: const {},
        scheduledTemplates: const [],
        pendingScheduledOccurrences: const [],
      );
      when(() => getBudgetById('budget-1'))
          .thenAnswer((_) => Stream.value(Right(data)));
      when(
        () => getBudgetProgress(
          any(),
          now: any(named: 'now'),
          index: any(named: 'index'),
        ),
      ).thenReturn(periodView(index: 1));

      final result = await withClock(
        Clock.fixed(DateTime(2026, 8, 25)),
        () => resolve('get_budget_detail', <String, Object?>{
          'budgetId': 'budget-1',
          'includePreviousPeriods': 4,
        }),
      );

      expect(result['previousPeriods'], hasLength(1));
    });
  });

  group('get_goal_detail', () {
    test('never sends the note attached to a goal movement', () async {
      when(() => watchGoalDetail('g1')).thenAnswer(
        (_) => Stream.value(
          Right(
            buildGoalDetail(
              progress: buildGoalWithProgress(savedMinor: 120000),
              history: [
                buildGoalContribution(
                  amountMinor: 50000,
                  note: 'regalo de la abuela',
                ),
              ],
            ),
          ),
        ),
      );

      final result = await resolve(
        'get_goal_detail',
        <String, Object?>{'goalId': 'g1'},
      );

      final movement =
          (result['movements']! as List).single as Map<String, Object?>;
      expect(movement.containsKey('note'), isFalse);
      expect(movement['amountMinor'], 50000);
      expect(
        movement['direction'],
        GoalMovementDirection.contribution.name,
      );
      expect(result.toString(), isNot(contains('regalo de la abuela')));
    });

    test('caps the movement history and flags the truncation', () async {
      when(() => watchGoalDetail('g1')).thenAnswer(
        (_) => Stream.value(
          Right(
            buildGoalDetail(
              history: [
                for (var i = 0; i < 70; i++)
                  buildGoalContribution(id: 'm$i', amountMinor: 1000),
              ],
            ),
          ),
        ),
      );

      final result = await resolve(
        'get_goal_detail',
        <String, Object?>{'goalId': 'g1'},
      );

      expect(result['count'], ResolveAiToolCall.maxRows);
      expect(result['movements'], hasLength(ResolveAiToolCall.maxRows));
      expect(result['truncated'], isTrue);
    });

    test('a goal with no id in the arguments is refused', () async {
      final result = await resolve('get_goal_detail');

      expect(result['error'], ResolveAiToolCall.errorNotFound);
      verifyNever(() => watchGoalDetail(any()));
    });
  });
}
