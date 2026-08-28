import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
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
import 'package:billetudo/features/debts/domain/entities/debt_balance.dart';
import 'package:billetudo/features/debts/domain/entities/debt_detail.dart';
import 'package:billetudo/features/debts/domain/entities/debt_installment.dart';
import 'package:billetudo/features/debts/domain/entities/debt_ledger_entry.dart';
import 'package:billetudo/features/debts/domain/usecases/watch_debt_detail.dart';
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
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_history_entry.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_linked_debt.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payment_detail.dart'
    as sp;
import 'package:billetudo/features/scheduled_payments/domain/usecases/get_scheduled_payments.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/domain/usecases/get_app_settings.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../debts/domain/debt_test_fixtures.dart';
import '../../../goals/presentation/goals_presentation_fixtures.dart';
import '../../../home/home_fixtures.dart'
    show buildActivity, buildHomeBudgetProgress;
import '../../../scheduled_payments/scheduled_payment_fixtures.dart'
    show buildScheduledPayment;
import '../../../transactions/transaction_fixtures.dart' show buildTransaction;
import '../../formatted_twin.dart';

class MockWatchTransactions extends Mock implements WatchTransactions {}

class MockWatchCategoryBreakdownReport extends Mock
    implements WatchCategoryBreakdownReport {}

class MockWatchCashflowReport extends Mock implements WatchCashflowReport {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockGetBudgetById extends Mock implements GetBudgetById {}

class MockGetBudgetProgress extends Mock implements GetBudgetProgress {}

class MockWatchGoalDetail extends Mock implements WatchGoalDetail {}

class MockWatchDebtDetail extends Mock implements WatchDebtDetail {}

class MockGetScheduledPaymentDetail extends Mock
    implements sp.GetScheduledPaymentDetail {}

class MockGetScheduledPayments extends Mock implements GetScheduledPayments {}

class MockGetAppSettings extends Mock implements GetAppSettings {}

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
  late MockWatchDebtDetail watchDebtDetail;
  late MockGetScheduledPaymentDetail getScheduledPaymentDetail;
  late MockGetScheduledPayments getScheduledPayments;
  late MockGetAppSettings getAppSettings;
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

  /// The `AppSettings.aiNotesAccessEnabled` opt-in, as the use case reads it.
  void stubNotesAccess({required bool enabled}) {
    when(getAppSettings.call).thenAnswer(
      (_) => Stream.value(
        Right(
          const AppSettings.defaults().copyWith(aiNotesAccessEnabled: enabled),
        ),
      ),
    );
  }

  /// The settings row unreadable — the failure path that must fall back to
  /// "no notes", never to "send them anyway".
  void stubNotesAccessUnreadable() {
    when(getAppSettings.call).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('settings unreadable'))),
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
    watchDebtDetail = MockWatchDebtDetail();
    getScheduledPaymentDetail = MockGetScheduledPaymentDetail();
    getScheduledPayments = MockGetScheduledPayments();
    getAppSettings = MockGetAppSettings();
    // Notes access OFF by default in every test, exactly like a real install
    // that never touched the switch. The tests that need it on say so.
    stubNotesAccess(enabled: false);
    usecase = ResolveAiToolCall(
      watchTransactions,
      watchCategoryBreakdown,
      watchCashflow,
      watchAccounts,
      getBudgetById,
      getBudgetProgress,
      watchGoalDetail,
      watchDebtDetail,
      getScheduledPaymentDetail,
      getScheduledPayments,
      getAppSettings,
      const MoneyFormatter(),
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

    test(
        'a thoughtSignature on the call survives unread onto the result, so '
        'it can ride back to the next turn', () async {
      final result = await usecase(
        const AiToolCall(
          id: 'tc_0_0',
          name: 'drop_database',
          arguments: <String, Object?>{},
          thoughtSignature: 'opaque-signature-abc',
        ),
      );

      expect(
        result.getRight().toNullable()!.thoughtSignature,
        'opaque-signature-abc',
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
      expect(
          item['date'], DateTime(2026, 8, 10).millisecondsSinceEpoch ~/ 1000);
      expect(result['from'], augustFirst);
      expect(result['to'], septemberFirst);
    });

    test(
        'filters by currency and minimum amount the shared filter cannot '
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

    test(
        'filters by a min/max amount range to isolate small recurring '
        'purchases from one big purchase in the same category', () async {
      when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(
          Right([
            buildActivity(id: 'tx-too-small', amountMinor: 2000),
            buildActivity(id: 'tx-in-range-1', amountMinor: 5000),
            buildActivity(id: 'tx-in-range-2', amountMinor: 20000),
            buildActivity(id: 'tx-too-big', amountMinor: 90000),
          ]),
        ),
      );

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
        'minAmountMinor': 3000,
        'maxAmountMinor': 25000,
      });

      expect(
        (result['items']! as List)
            .map((item) => (item! as Map<String, Object?>)['id']),
        ['tx-in-range-1', 'tx-in-range-2'],
      );
    });

    test('filters by maximum amount alone, with no minimum given', () async {
      when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(
          Right([
            buildActivity(id: 'tx-small', amountMinor: 1000),
            buildActivity(id: 'tx-big', amountMinor: 90000),
          ]),
        ),
      );

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
        'maxAmountMinor': 25000,
      });

      expect(
        (result['items']! as List)
            .map((item) => (item! as Map<String, Object?>)['id']),
        ['tx-small'],
      );
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
    BudgetPeriodView periodView(
            {required int index, int spentMinor = 300000}) =>
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

  group('get_debt_detail', () {
    test(
        'resolves a debt by id — dogfooding fix: without this, a debt '
        'named in chat ("la KTM 1390") had nothing to look up beyond the '
        'currency-blended debtTotals aggregate', () async {
      when(() => watchDebtDetail('d1')).thenAnswer(
        (_) => Stream.value(
          Right(
            DebtDetail(
              debt: buildDebt(
                id: 'd1',
                name: 'KTM 1390',
                currency: 'COP',
              ),
              balance: const DebtBalance(
                principalMinor: 500000000,
                totalIncreasesMinor: 500000000,
                totalDecreasesMinor: 87169980,
                interestAccruedMinor: 0,
                displayTotalMinor: 500000000,
              ),
              ledger: [
                DebtLedgerEntry(
                  id: 'e1',
                  kind: DebtLedgerKind.cashPayment,
                  date: DateTime(2026, 8, 1),
                  createdAt: DateTime(2026, 8, 1),
                  effectMinor: -41283020,
                  note: 'ahorré para esto',
                ),
              ],
              installment: DebtInstallment(
                scheduledPaymentId: 'sp1',
                amountMinor: 41283020,
                nextDate: DateTime(2026, 9, 1),
                currency: 'COP',
              ),
            ),
          ),
        ),
      );

      final result = await resolve(
        'get_debt_detail',
        <String, Object?>{'debtId': 'd1'},
      );

      expect(result['name'], 'KTM 1390');
      expect(result['outstandingMinor'], 500000000 - 87169980);
      expect(result['nextInstallmentAmountMinor'], 41283020);
      final entry = (result['ledger']! as List).single as Map<String, Object?>;
      expect(entry['effectMinor'], -41283020);
      expect(entry.containsKey('note'), isFalse);
      expect(result.toString(), isNot(contains('ahorré para esto')));
    });

    test('caps the ledger history and flags the truncation', () async {
      when(() => watchDebtDetail('d1')).thenAnswer(
        (_) => Stream.value(
          Right(
            DebtDetail(
              debt: buildDebt(id: 'd1'),
              balance: DebtBalance.empty,
              ledger: [
                for (var i = 0; i < 70; i++)
                  DebtLedgerEntry(
                    id: 'e$i',
                    kind: DebtLedgerKind.cashPayment,
                    date: DateTime(2026, 8, 1),
                    createdAt: DateTime(2026, 8, 1),
                    effectMinor: -1000,
                  ),
              ],
            ),
          ),
        ),
      );

      final result = await resolve(
        'get_debt_detail',
        <String, Object?>{'debtId': 'd1'},
      );

      expect(result['count'], ResolveAiToolCall.maxRows);
      expect(result['ledger'], hasLength(ResolveAiToolCall.maxRows));
      expect(result['truncated'], isTrue);
    });

    test('a debt with no id in the arguments is refused', () async {
      final result = await resolve('get_debt_detail');

      expect(result['error'], ResolveAiToolCall.errorNotFound);
      verifyNever(() => watchDebtDetail(any()));
    });
  });

  group('get_scheduled_payment_detail', () {
    test(
        'resolves a scheduled payment by id, with the same category+account '
        'name convention as the snapshot\'s "upcoming" — dogfooding fix: the '
        'model had no way to look up a payment past the 30-day/25-row cap',
        () async {
      when(
        () => getScheduledPaymentDetail(
          'sp-1',
          historyPageSize: ResolveAiToolCall.maxRows,
        ),
      ).thenAnswer(
        (_) => Stream.value(
          Right(
            ScheduledPaymentDetail(
              scheduledPayment: buildScheduledPayment(
                id: 'sp-1',
                amountMinor: 41283020,
                currency: 'COP',
                nextDate: DateTime(2026, 9, 25),
              ),
              accountName: 'Bancolombia',
              categoryName: 'Abono a capital',
              historyTotalCount: 1,
              generatedTransactionCount: 1,
              linkedDebt: const ScheduledPaymentLinkedDebt(
                id: 'debt-1',
                name: 'KTM 1390',
                iOwe: true,
              ),
              history: [
                ScheduledConfirmedHistoryEntry(
                  buildTransaction(
                    id: 'tx-1',
                    amountMinor: 41283020,
                    currency: 'COP',
                    date: DateTime(2026, 8, 25),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final result = await resolve(
        'get_scheduled_payment_detail',
        <String, Object?>{'scheduledPaymentId': 'sp-1'},
      );

      expect(result['name'], 'Abono a capital · Bancolombia');
      expect(result['amountMinor'], 41283020);
      expect(result['amountFormatted'], r'$412.830,20');
      expect(result['linkedDebtId'], 'debt-1');
      expect(result['linkedDebtName'], 'KTM 1390');
      final entry = (result['history']! as List).single as Map<String, Object?>;
      expect(entry['kind'], 'confirmed');
      expect(entry['amountMinor'], 41283020);
      expect(entry.containsKey('note'), isFalse);
    });

    test('caps the history and flags the truncation', () async {
      when(
        () => getScheduledPaymentDetail(
          'sp-1',
          historyPageSize: ResolveAiToolCall.maxRows,
        ),
      ).thenAnswer(
        (_) => Stream.value(
          Right(
            ScheduledPaymentDetail(
              scheduledPayment: buildScheduledPayment(id: 'sp-1'),
              accountName: 'Bancolombia',
              historyTotalCount: 70,
              history: [
                for (var i = 0; i < 70; i++)
                  ScheduledConfirmedHistoryEntry(
                    buildTransaction(id: 'tx-$i', amountMinor: 1000),
                  ),
              ],
            ),
          ),
        ),
      );

      final result = await resolve(
        'get_scheduled_payment_detail',
        <String, Object?>{'scheduledPaymentId': 'sp-1'},
      );

      expect(result['count'], ResolveAiToolCall.maxRows);
      expect(result['history'], hasLength(ResolveAiToolCall.maxRows));
      expect(result['truncated'], isTrue);
    });

    test('a scheduled payment with no id in the arguments is refused',
        () async {
      final result = await resolve('get_scheduled_payment_detail');

      expect(result['error'], ResolveAiToolCall.errorNotFound);
      verifyNever(
        () => getScheduledPaymentDetail(
          any(),
          historyPageSize: any(named: 'historyPageSize'),
        ),
      );
    });
  });

  group('get_transactions searches notes without ever returning one', () {
    test(
        'the search term rides into the shared filter, where the match runs '
        'on the device', () async {
      when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(
          Right([
            TransactionWithDetails(
              transaction: buildTransaction(
                id: 'tx-ktm',
                amountMinor: 41283020,
                currency: 'COP',
                note: 'Abono a capital KTM 1390',
                date: DateTime(2026, 8, 25),
              ),
              accountName: 'Bancolombia',
              categoryName: 'Deudas',
            ),
          ]),
        ),
      );

      final result = await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
        'searchText': 'KTM 1390',
      });

      final filter = verify(() => watchTransactions(captureAny()))
          .captured
          .single as TransactionFilter;
      expect(
        filter.searchText,
        'KTM 1390',
        reason: 'the datasource is what matches it against the local note',
      );

      final item = (result['items']! as List).single as Map<String, Object?>;
      expect(item['id'], 'tx-ktm');
      expect(item.containsKey('note'), isFalse);
      expect(
        result.toString(),
        isNot(contains('Abono a capital KTM 1390')),
        reason: 'the note is a search key, never a value that travels',
      );
    });

    test(
        'an omitted searchText leaves the filter unsearched, not empty-matched',
        () async {
      when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(const Right([])));

      await resolve('get_transactions', <String, Object?>{
        'from': augustFirst,
        'to': septemberFirst,
      });

      final filter = verify(() => watchTransactions(captureAny()))
          .captured
          .single as TransactionFilter;
      expect(filter.searchText, isEmpty);
    });
  });

  group('find_scheduled_payments', () {
    ScheduledPaymentSummary summary({
      required String id,
      String? note,
      String accountName = 'Bancolombia',
      String? categoryName = 'Abono a capital',
      int amountMinor = 41283020,
    }) =>
        ScheduledPaymentSummary(
          scheduledPayment: buildScheduledPayment(
            id: id,
            amountMinor: amountMinor,
            currency: 'COP',
            note: note,
            nextDate: DateTime(2026, 9, 25),
          ),
          accountName: accountName,
          categoryName: categoryName,
        );

    void stubList(List<ScheduledPaymentSummary> summaries) {
      when(getScheduledPayments.call)
          .thenAnswer((_) => Stream.value(Right(summaries)));
    }

    test(
        'finds a payment by the words of its note, ignoring case and accents — '
        'the user types "credito hipotecario", the note says "Crédito '
        'Hipotecario"', () async {
      stubList([
        summary(id: 'sp-ktm', note: 'Abono a capital KTM 1390'),
        summary(
          id: 'sp-casa',
          note: 'Crédito Hipotecario',
          categoryName: 'Vivienda',
          amountMinor: 230000000,
        ),
      ]);

      final result = await resolve(
        'find_scheduled_payments',
        <String, Object?>{'query': 'credito hipotecario'},
      );

      expect(result['count'], 1);
      expect(result['truncated'], isFalse);
      final item = (result['items']! as List).single as Map<String, Object?>;
      expect(item['id'], 'sp-casa');
      expect(item['name'], 'Vivienda · Bancolombia');
      expect(item['amountMinor'], 230000000);
      expect(item['amountFormatted'], r'$2.300.000');
      expect(item['currency'], 'COP');
      expect(item['type'], 'expense');
      expect(item['frequency'], 'monthly');
      expect(item['isActive'], isTrue);
      expect(
        item['nextDate'],
        DateTime(2026, 9, 25).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test(
        'matches an accented query against an unaccented note too, so the '
        'fold works in both directions', () async {
      stubList([summary(id: 'sp-casa', note: 'credito hipotecario')]);

      final result = await resolve(
        'find_scheduled_payments',
        <String, Object?>{'query': 'Crédito'},
      );

      expect(result['count'], 1);
    });

    test('falls back to the category and account names, which already travel',
        () async {
      stubList([
        summary(id: 'sp-1', categoryName: 'Servicios', accountName: 'Nequi'),
      ]);

      final result = await resolve(
        'find_scheduled_payments',
        <String, Object?>{'query': 'nequi'},
      );

      expect(result['count'], 1);
      expect(
        ((result['items']! as List).single as Map<String, Object?>)['id'],
        'sp-1',
      );
    });

    test(
        'THE POINT OF THIS TOOL: the note never appears anywhere in the '
        'result, not even as proof of why it matched', () async {
      stubList([
        summary(id: 'sp-ktm', note: 'Abono a capital de la KTM 1390 de Cami'),
      ]);

      final result = await resolve(
        'find_scheduled_payments',
        <String, Object?>{'query': 'KTM'},
      );

      final item = (result['items']! as List).single as Map<String, Object?>;
      expect(item['id'], 'sp-ktm');
      expect(item.containsKey('note'), isFalse);
      expect(
        result.toString(),
        isNot(contains('Abono a capital de la KTM 1390 de Cami')),
      );
      expect(
        result.toString(),
        isNot(contains('de Cami')),
        reason: 'no fragment of the note either — no snippet, no matched text',
      );
    });

    test('a payment whose note has nothing to do with the query is left out',
        () async {
      stubList([
        summary(
          id: 'sp-gym',
          note: 'Mensualidad del gimnasio',
          categoryName: 'Salud',
        ),
      ]);

      final result = await resolve(
        'find_scheduled_payments',
        <String, Object?>{'query': 'hipotecario'},
      );

      expect(result['count'], 0);
      expect(result['items'], isEmpty);
      expect(result['scope'], 'active');
    });

    test('caps the results and flags the truncation', () async {
      stubList([
        for (var i = 0; i < 70; i++)
          summary(id: 'sp-$i', note: 'Cuota crédito $i'),
      ]);

      final result = await resolve(
        'find_scheduled_payments',
        <String, Object?>{'query': 'credito', 'limit': 200},
      );

      expect(result['count'], ResolveAiToolCall.maxRows);
      expect(result['items'], hasLength(ResolveAiToolCall.maxRows));
      expect(result['truncated'], isTrue);
    });

    test('a missing query is refused without reading the list', () async {
      final result = await resolve('find_scheduled_payments');

      expect(result['error'], ResolveAiToolCall.errorNotFound);
      verifyNever(getScheduledPayments.call);
    });

    test('a blank query is refused too, instead of matching everything',
        () async {
      final result = await resolve(
        'find_scheduled_payments',
        <String, Object?>{'query': '   '},
      );

      expect(result['error'], ResolveAiToolCall.errorNotFound);
      verifyNever(getScheduledPayments.call);
    });

    test('an unreadable list answers not_found, never a Left', () async {
      when(getScheduledPayments.call).thenAnswer(
        (_) => Stream.value(
          const Left<Failure, List<ScheduledPaymentSummary>>(
            DatabaseFailure('drift is down'),
          ),
        ),
      );

      final result = await resolve(
        'find_scheduled_payments',
        <String, Object?>{'query': 'credito'},
      );

      expect(result['error'], ResolveAiToolCall.errorNotFound);
    });
  });

  // -------------------------------------------------------------------------
  // AppSettings.aiNotesAccessEnabled
  // -------------------------------------------------------------------------

  /// The opt-in, tool by tool. Every case is a PAIR: off (the default, and the
  /// state of anyone who never touched the switch) must produce exactly the
  /// payload this file asserted before the opt-in existed, and on must add the
  /// note and nothing else.
  group('notes travel only when the user opted in', () {
    const txNote = 'regalo de cumpleaños de mi mamá';
    const goalNote = 'plata del aguinaldo';
    const ledgerNote = 'ahorré para esto';
    const scheduledNote = 'Abono a capital de la KTM 1390 de Cami';

    void stubTransaction() {
      when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(
          Right([
            TransactionWithDetails(
              transaction: buildTransaction(
                id: 'tx-1',
                amountMinor: 41283020,
                currency: 'COP',
                note: txNote,
                date: DateTime(2026, 8, 25),
              ),
              accountName: 'Bancolombia',
              categoryName: 'Deudas',
            ),
          ]),
        ),
      );
    }

    Future<Map<String, Object?>> transactions() =>
        resolve('get_transactions', <String, Object?>{
          'from': augustFirst,
          'to': septemberFirst,
        });

    void stubGoal() {
      when(() => watchGoalDetail('g1')).thenAnswer(
        (_) => Stream.value(
          Right(
            buildGoalDetail(
              progress: buildGoalWithProgress(savedMinor: 120000),
              history: [
                buildGoalContribution(amountMinor: 50000, note: goalNote),
              ],
            ),
          ),
        ),
      );
    }

    void stubDebt() {
      when(() => watchDebtDetail('d1')).thenAnswer(
        (_) => Stream.value(
          Right(
            DebtDetail(
              debt: buildDebt(id: 'd1', name: 'KTM 1390', currency: 'COP'),
              balance: const DebtBalance(
                principalMinor: 500000000,
                totalIncreasesMinor: 500000000,
                totalDecreasesMinor: 41283020,
                interestAccruedMinor: 0,
                displayTotalMinor: 500000000,
              ),
              ledger: [
                DebtLedgerEntry(
                  id: 'e1',
                  kind: DebtLedgerKind.cashPayment,
                  date: DateTime(2026, 8, 1),
                  createdAt: DateTime(2026, 8, 1),
                  effectMinor: -41283020,
                  note: ledgerNote,
                ),
              ],
            ),
          ),
        ),
      );
    }

    void stubScheduledDetail() {
      when(
        () => getScheduledPaymentDetail(
          'sp-1',
          historyPageSize: ResolveAiToolCall.maxRows,
        ),
      ).thenAnswer(
        (_) => Stream.value(
          Right(
            ScheduledPaymentDetail(
              scheduledPayment: buildScheduledPayment(
                id: 'sp-1',
                amountMinor: 41283020,
                currency: 'COP',
                note: scheduledNote,
                nextDate: DateTime(2026, 9, 25),
              ),
              accountName: 'Bancolombia',
              categoryName: 'Abono a capital',
              historyTotalCount: 0,
              generatedTransactionCount: 0,
              history: const [],
            ),
          ),
        ),
      );
    }

    void stubScheduledList() {
      when(getScheduledPayments.call).thenAnswer(
        (_) => Stream.value(
          Right([
            ScheduledPaymentSummary(
              scheduledPayment: buildScheduledPayment(
                id: 'sp-1',
                amountMinor: 41283020,
                currency: 'COP',
                note: scheduledNote,
                nextDate: DateTime(2026, 9, 25),
              ),
              accountName: 'Bancolombia',
              categoryName: 'Abono a capital',
            ),
          ]),
        ),
      );
    }

    group('get_transactions', () {
      test('off: no note key and the text appears nowhere', () async {
        stubTransaction();

        final result = await transactions();

        final item = (result['items']! as List).single as Map<String, Object?>;
        expect(item.containsKey('note'), isFalse);
        expect(result.toString(), isNot(contains(txNote)));
      });

      test('on: the note rides along with the movement', () async {
        stubNotesAccess(enabled: true);
        stubTransaction();

        final result = await transactions();

        final item = (result['items']! as List).single as Map<String, Object?>;
        expect(item['note'], txNote);
      });
    });

    group('get_goal_detail', () {
      test('off: the movement carries no note', () async {
        stubGoal();

        final result =
            await resolve('get_goal_detail', <String, Object?>{'goalId': 'g1'});

        final movement =
            (result['movements']! as List).single as Map<String, Object?>;
        expect(movement.containsKey('note'), isFalse);
        expect(result.toString(), isNot(contains(goalNote)));
      });

      test('on: the movement carries its note', () async {
        stubNotesAccess(enabled: true);
        stubGoal();

        final result =
            await resolve('get_goal_detail', <String, Object?>{'goalId': 'g1'});

        final movement =
            (result['movements']! as List).single as Map<String, Object?>;
        expect(movement['note'], goalNote);
      });
    });

    group('get_debt_detail', () {
      test('off: the ledger row carries no note', () async {
        stubDebt();

        final result =
            await resolve('get_debt_detail', <String, Object?>{'debtId': 'd1'});

        final entry =
            (result['ledger']! as List).single as Map<String, Object?>;
        expect(entry.containsKey('note'), isFalse);
        expect(result.toString(), isNot(contains(ledgerNote)));
      });

      test('on: the ledger row carries its note', () async {
        stubNotesAccess(enabled: true);
        stubDebt();

        final result =
            await resolve('get_debt_detail', <String, Object?>{'debtId': 'd1'});

        final entry =
            (result['ledger']! as List).single as Map<String, Object?>;
        expect(entry['note'], ledgerNote);
      });
    });

    group('get_scheduled_payment_detail', () {
      test('off: the template note stays on the device', () async {
        stubScheduledDetail();

        final result = await resolve(
          'get_scheduled_payment_detail',
          <String, Object?>{'scheduledPaymentId': 'sp-1'},
        );

        expect(result.containsKey('note'), isFalse);
        expect(result.toString(), isNot(contains(scheduledNote)));
      });

      test('on: the template note travels', () async {
        stubNotesAccess(enabled: true);
        stubScheduledDetail();

        final result = await resolve(
          'get_scheduled_payment_detail',
          <String, Object?>{'scheduledPaymentId': 'sp-1'},
        );

        expect(result['note'], scheduledNote);
      });
    });

    group('find_scheduled_payments', () {
      test('off: the match happens but the note never comes back', () async {
        stubScheduledList();

        final result = await resolve(
          'find_scheduled_payments',
          <String, Object?>{'query': 'KTM'},
        );

        final item = (result['items']! as List).single as Map<String, Object?>;
        expect(item['id'], 'sp-1');
        expect(item.containsKey('note'), isFalse);
        expect(result.toString(), isNot(contains(scheduledNote)));
      });

      test('on: the matched payment comes back with its note', () async {
        stubNotesAccess(enabled: true);
        stubScheduledList();

        final result = await resolve(
          'find_scheduled_payments',
          <String, Object?>{'query': 'KTM'},
        );

        final item = (result['items']! as List).single as Map<String, Object?>;
        expect(item['note'], scheduledNote);
      });
    });

    test(
        'an unreadable settings row falls back to OFF, never to sending the '
        'note', () async {
      stubNotesAccessUnreadable();
      stubTransaction();

      final result = await transactions();

      final item = (result['items']! as List).single as Map<String, Object?>;
      expect(item.containsKey('note'), isFalse);
      expect(result.toString(), isNot(contains(txNote)));
    });

    test('the switch is re-read per call, not cached at construction',
        () async {
      stubTransaction();
      expect(
        ((await transactions())['items']! as List).single,
        isNot(contains('note')),
      );

      stubNotesAccess(enabled: true);
      final after = ((await transactions())['items']! as List).single
          as Map<String, Object?>;
      expect(after['note'], txNote);
    });
  });

  // The server prompt ASSERTS to the model that every `...Minor` it receives
  // arrives beside a `...Formatted` twin it can copy verbatim, and forbids it
  // from dividing by 100 itself. Where the twin was missing the model did the
  // arithmetic anyway and quoted a balance a hundred times too large
  // ("$379.931.350" for $3.799.313,50). The snapshot was fixed first; these
  // are the OTHER path the model reads, which had the same hole.
  group('every amount carries its formatted twin', () {
    /// Every source stubbed at once, so a single tool call resolves fully
    /// instead of short-circuiting on a `not_found` that would make the twin
    /// check pass vacuously.
    void stubEveryTool() {
      stubSingleCurrencyAccounts();
      when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(
          Right([
            buildActivity(id: 'tx-cop', amountMinor: 379931350),
            buildActivity(
              id: 'tx-usd',
              amountMinor: 120050,
              currency: 'USD',
            ),
          ]),
        ),
      );
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
      when(() => watchCashflow(any())).thenAnswer(
        (_) => Stream.value(
          Right(
            CashflowSeries(
              points: [
                CashflowPoint(
                  periodStart: DateTime(2026, 8),
                  incomeMinor: 300000000,
                  expenseMinor: 500000000,
                  debtIncomeMinor: 0,
                  debtExpenseMinor: 0,
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
            ),
          ),
        ),
      );
      when(() => getBudgetById('budget-1')).thenAnswer(
        (_) => Stream.value(
          Right(
            BudgetDetailData(
              budget: buildHomeBudgetProgress(id: 'budget-1').budget,
              scope: const BudgetScope.empty(),
              expenses: const [],
              categoryChildren: const {},
              scheduledTemplates: const [],
              pendingScheduledOccurrences: const [],
            ),
          ),
        ),
      );
      when(
        () => getBudgetProgress(
          any(),
          now: any(named: 'now'),
          index: any(named: 'index'),
        ),
      ).thenReturn(
        BudgetPeriodView(
          window: BudgetPeriodWindow(
            start: DateTime(2026, 8),
            endExclusive: DateTime(2026, 9),
            index: 3,
            status: BudgetWindowStatus.current,
            hasPrevious: true,
            hasNext: true,
          ),
          progress: const BudgetProgress(
            amountMinor: 600000,
            // Overspent on purpose: `remainingMinor` goes negative and its
            // twin has to say so.
            spentMinor: 900000,
            scheduledMinor: 120000,
            daysLeft: 6,
          ),
          activity: const [],
        ),
      );
      when(() => watchGoalDetail('g1')).thenAnswer(
        (_) => Stream.value(
          Right(
            buildGoalDetail(
              progress: buildGoalWithProgress(
                goal: buildGoal(id: 'g1', targetMinor: 500000000),
                savedMinor: 120000000,
              ),
              history: [buildGoalContribution(amountMinor: 50000)],
            ),
          ),
        ),
      );
      when(() => watchDebtDetail('d1')).thenAnswer(
        (_) => Stream.value(
          Right(
            DebtDetail(
              debt: buildDebt(id: 'd1', name: 'KTM 1390'),
              balance: const DebtBalance(
                principalMinor: 500000000,
                totalIncreasesMinor: 500000000,
                totalDecreasesMinor: 87169980,
                interestAccruedMinor: 0,
                displayTotalMinor: 500000000,
              ),
              ledger: [
                DebtLedgerEntry(
                  id: 'e1',
                  kind: DebtLedgerKind.cashPayment,
                  date: DateTime(2026, 8, 1),
                  createdAt: DateTime(2026, 8, 1),
                  effectMinor: -41283020,
                ),
              ],
              installment: DebtInstallment(
                scheduledPaymentId: 'sp-1',
                amountMinor: 41283020,
                nextDate: DateTime(2026, 9, 1),
                currency: 'COP',
              ),
            ),
          ),
        ),
      );
      when(
        () => getScheduledPaymentDetail(
          'sp-1',
          historyPageSize: ResolveAiToolCall.maxRows,
        ),
      ).thenAnswer(
        (_) => Stream.value(
          Right(
            ScheduledPaymentDetail(
              scheduledPayment: buildScheduledPayment(
                id: 'sp-1',
                amountMinor: 41283020,
                currency: 'COP',
                nextDate: DateTime(2026, 9, 25),
              ),
              accountName: 'Bancolombia',
              categoryName: 'Abono a capital',
              historyTotalCount: 2,
              generatedTransactionCount: 1,
              history: [
                ScheduledConfirmedHistoryEntry(
                  buildTransaction(
                    id: 'tx-1',
                    amountMinor: 41283020,
                    currency: 'COP',
                    date: DateTime(2026, 8, 25),
                  ),
                ),
                ScheduledSkippedHistoryEntry(
                  occurrenceId: 'occ-1',
                  date: DateTime(2026, 7, 25),
                  amountMinor: 41283020,
                  currency: 'COP',
                ),
              ],
            ),
          ),
        ),
      );
      when(getScheduledPayments.call).thenAnswer(
        (_) => Stream.value(
          Right([
            ScheduledPaymentSummary(
              scheduledPayment: buildScheduledPayment(
                id: 'sp-1',
                amountMinor: 41283020,
                currency: 'COP',
                note: 'Abono a capital KTM 1390',
                nextDate: DateTime(2026, 9, 25),
              ),
              accountName: 'Bancolombia',
              categoryName: 'Abono a capital',
            ),
          ]),
        ),
      );
    }

    /// Every tool, with arguments that reach its richest payload — nested
    /// items, previous periods, both history kinds.
    const window = <String, Object?>{
      'from': augustFirst,
      'to': septemberFirst,
    };
    final everyToolCall = <String, Map<String, Object?>>{
      'get_transactions': window,
      'get_category_breakdown': {
        ...window,
        'currency': 'COP',
        'includeSubcategories': true,
      },
      'compare_periods': <String, Object?>{
        'aFrom': augustFirst,
        'aTo': septemberFirst,
        'bFrom': augustFirst,
        'bTo': septemberFirst,
        'currency': 'COP',
      },
      'compare_periods by category': <String, Object?>{
        'aFrom': augustFirst,
        'aTo': septemberFirst,
        'bFrom': augustFirst,
        'bTo': septemberFirst,
        'currency': 'COP',
        'groupBy': 'category',
      },
      'get_budget_detail': <String, Object?>{
        'budgetId': 'budget-1',
        'includePreviousPeriods': 2,
      },
      'get_goal_detail': <String, Object?>{'goalId': 'g1'},
      'get_debt_detail': <String, Object?>{'debtId': 'd1'},
      'get_scheduled_payment_detail': <String, Object?>{
        'scheduledPaymentId': 'sp-1',
      },
      'find_scheduled_payments': <String, Object?>{'query': 'KTM'},
    };

    for (final entry in everyToolCall.entries) {
      test('${entry.key} sends no bare *Minor', () async {
        stubEveryTool();

        // The map key carries the variant; the tool name is its first word.
        final result = await withClock(
          Clock.fixed(DateTime(2026, 8, 25)),
          () => resolve(entry.key.split(' ').first, entry.value),
        );

        expect(
          result['error'],
          isNull,
          reason: 'a not_found would make the twin check pass vacuously',
        );
        expect(amountsMissingFormattedTwin(result), isEmpty);
      });
    }

    test('a movement is formatted in its OWN currency, never a global one',
        () async {
      stubEveryTool();

      final result = await resolve('get_transactions', window);

      final items = (result['items']! as List).cast<Map<String, Object?>>();
      expect(items[0]['amountFormatted'], r'$3.799.313,50');
      // USD keeps its two decimals; the COP row above only shows them
      // because it genuinely carries cents.
      expect(items[1]['amountFormatted'], r'$1.200,50');
    });

    test(
        'an overspent budget period reads as a negative remainder, not a '
        'surplus', () async {
      stubEveryTool();

      final result = await withClock(
        Clock.fixed(DateTime(2026, 8, 25)),
        () => resolve(
          'get_budget_detail',
          <String, Object?>{'budgetId': 'budget-1'},
        ),
      );

      final current = result['current']! as Map<String, Object?>;
      expect(current['remainingMinor'], -300000);
      expect(current['remainingFormatted'], r'$-3.000');
    });

    test('a period that spent more than it earned keeps its negative net',
        () async {
      stubEveryTool();

      final result = await resolve('compare_periods', <String, Object?>{
        'aFrom': augustFirst,
        'aTo': septemberFirst,
        'bFrom': augustFirst,
        'bTo': septemberFirst,
        'currency': 'COP',
      });

      final a = result['a']! as Map<String, Object?>;
      expect(a['netMinor'], -200000000);
      expect(a['netFormatted'], r'$-2.000.000');
    });

    test('a debt payment keeps the minus that says it REDUCED the debt',
        () async {
      stubEveryTool();

      final result = await resolve(
        'get_debt_detail',
        <String, Object?>{'debtId': 'd1'},
      );

      final entry = (result['ledger']! as List).single as Map<String, Object?>;
      expect(entry['effectMinor'], -41283020);
      expect(entry['effectFormatted'], r'$-412.830,20');
    });
  });
}
