import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/accounts_overview.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts_overview.dart';
import 'package:billetudo/features/ai/domain/usecases/build_financial_snapshot.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/zero_based_summary.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_active_budgets.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_zero_based_summary.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_node.dart';
import 'package:billetudo/features/categories/domain/usecases/watch_categories.dart';
import 'package:billetudo/features/debts/domain/entities/debt_balance.dart';
import 'package:billetudo/features/debts/domain/entities/debt_installment.dart';
import 'package:billetudo/features/debts/domain/entities/debt_with_balance.dart';
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
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/domain/usecases/get_app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../categories/domain/usecases/category_repository_mock.dart'
    show buildCategory;
import '../../../debts/domain/debt_test_fixtures.dart';
import '../../../goals/presentation/goals_presentation_fixtures.dart';
import '../../../home/home_fixtures.dart' show buildHomeBudgetProgress;
import '../../../scheduled_payments/scheduled_payment_fixtures.dart'
    as scheduled;
import '../../formatted_twin.dart';

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockWatchAccountsOverview extends Mock implements WatchAccountsOverview {}

class MockGetActiveBudgets extends Mock implements GetActiveBudgets {}

class MockGetZeroBasedSummary extends Mock implements GetZeroBasedSummary {}

class MockWatchGoals extends Mock implements WatchGoals {}

class MockWatchDebts extends Mock implements WatchDebts {}

class MockWatchCategories extends Mock implements WatchCategories {}

class MockWatchCategoryBreakdownReport extends Mock
    implements WatchCategoryBreakdownReport {}

class MockWatchCashflowReport extends Mock implements WatchCashflowReport {}

class MockGetScheduledPayments extends Mock implements GetScheduledPayments {}

class MockGetAppSettings extends Mock implements GetAppSettings {}

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
  late MockWatchCategories watchCategories;
  late MockWatchCategoryBreakdownReport watchCategoryBreakdown;
  late MockWatchCashflowReport watchCashflow;
  late MockGetScheduledPayments getScheduledPayments;
  late MockGetAppSettings getAppSettings;
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
    DebtsSummary? debtsSummary,
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
    when(watchDebts.call).thenAnswer(
      (_) => Stream.value(Right(debtsSummary ?? debts)),
    );
    when(() => watchCategories(any())).thenAnswer(
      (invocation) => Stream.value(
        Right([
          CategoryNode(
            root: buildCategory(
              id: 'cat-food',
              kind: invocation.positionalArguments.single as CategoryKind,
            ),
          ),
        ]),
      ),
    );
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

  setUpAll(() {
    registerFallbackValue(WatchCashflowReportParams(range: monthRange));
    registerFallbackValue(
      WatchCategoryBreakdownReportParams(range: monthRange),
    );
    registerFallbackValue(CategoryKind.expense);
  });

  setUp(() {
    watchAccounts = MockWatchAccounts();
    watchAccountsOverview = MockWatchAccountsOverview();
    getActiveBudgets = MockGetActiveBudgets();
    getZeroBasedSummary = MockGetZeroBasedSummary();
    watchGoals = MockWatchGoals();
    watchDebts = MockWatchDebts();
    watchCategories = MockWatchCategories();
    watchCategoryBreakdown = MockWatchCategoryBreakdownReport();
    watchCashflow = MockWatchCashflowReport();
    getScheduledPayments = MockGetScheduledPayments();
    getAppSettings = MockGetAppSettings();
    // Notes access OFF by default, like a real install that never touched the
    // switch — the section must be byte-identical to the pre-opt-in payload.
    stubNotesAccess(enabled: false);
    usecase = BuildFinancialSnapshot(
      watchAccounts,
      watchAccountsOverview,
      getActiveBudgets,
      getZeroBasedSummary,
      watchGoals,
      watchDebts,
      watchCategories,
      watchCategoryBreakdown,
      watchCashflow,
      getScheduledPayments,
      const ProjectUpcomingOccurrences(),
      getAppSettings,
      const MoneyFormatter(),
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
          'categories',
          'spendingByCategory',
          'cashflow',
          'budgets',
          'goals',
          'debtTotals',
          'debts',
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

      final points =
          (json['cashflow']! as Map<String, Object?>)['points']! as List;
      final point = points.first as Map<String, Object?>;
      expect(point['incomeMinor'], 500000000 + 1000000);
      expect(point['expenseMinor'], 300000000 + 2000000);
      expect(point['netMinor'], 501000000 - 302000000);
    });

    test(
        'an upcoming payment travels by category AND account, never by its '
        'note (dogfooding fix: category alone collided when two payments '
        'shared one, e.g. rent and a mortgage both under "Vivienda")',
        () async {
      stubHealthySources();

      final json = await buildJson();

      final upcoming =
          (json['upcoming']! as List).first as Map<String, Object?>;
      expect(upcoming['name'], 'Arriendo · Bancolombia');
      expect(json.toString(), isNot(contains('no debe viajar')));
    });

    test('an upcoming payment with no category falls back to the account name',
        () async {
      stubHealthySources(
        scheduledPayments: [scheduledSummary(categoryName: null)],
      );

      final json = await buildJson();

      final upcoming =
          (json['upcoming']! as List).first as Map<String, Object?>;
      expect(upcoming['name'], 'Bancolombia');
    });

    test(
        'a budget carries BudgetProgress.scheduledMinor verbatim, plus '
        'pre-formatted strings and the projected-overspend-risk flag '
        '(dogfooding fix: the assistant used to only see spentMinor vs. '
        'amountMinor, so a budget on track by real spend alone but at risk '
        'once its scheduled payments land read as "you are fine")', () async {
      final atRisk = BudgetWithProgress(
        budget: Budget(
          id: 'budget-risk',
          name: 'Mercado',
          amountMinor: 60000000,
          currency: 'COP',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 7, 1),
          recurring: true,
          rollover: false,
          createdAt: DateTime(2026, 7, 1),
          updatedAt: 0,
        ),
        scope: const BudgetScope.empty(),
        window: BudgetPeriodWindow(
          start: DateTime(2026, 7, 1),
          endExclusive: DateTime(2026, 8, 1),
          index: 0,
          status: BudgetWindowStatus.current,
          hasPrevious: false,
          hasNext: true,
        ),
        // 40M spent (well under the 60M budget on its own) + 30M still
        // scheduled this window projects to 70M — over the budget, even
        // though spentMinor alone reads as "70% used, you are fine".
        progress: const BudgetProgress(
          amountMinor: 60000000,
          spentMinor: 40000000,
          daysLeft: 10,
          scheduledMinor: 30000000,
        ),
      );
      stubHealthySources(budgets: [atRisk]);

      final json = await buildJson();

      final budget = (json['budgets']! as List).first as Map<String, Object?>;
      expect(budget['scheduledMinor'], 30000000);
      expect(budget['projectedTotalMinor'], 40000000 + 30000000);
      expect(budget['isProjectedOverspendRisk'], isTrue);
      expect(budget['amountFormatted'], r'$600.000');
      expect(budget['spentFormatted'], r'$400.000');
      expect(budget['scheduledFormatted'], r'$300.000');
      expect(budget['projectedTotalFormatted'], r'$700.000');
    });

    test(
        'a debt travels by name+id with its outstanding balance and, when '
        'it has a cuota, the next installment amount — dogfooding fix: a '
        'debt named in chat ("la KTM 1390") had nothing to look up beyond '
        'the currency-blended debtTotals aggregate', () async {
      final withInstallment = DebtWithBalance(
        debt: buildDebt(id: 'debt-1', name: 'KTM 1390', currency: 'COP'),
        balance: const DebtBalance(
          principalMinor: 500000000,
          totalIncreasesMinor: 500000000,
          totalDecreasesMinor: 87169980,
          interestAccruedMinor: 0,
          displayTotalMinor: 500000000,
        ),
        installment: DebtInstallment(
          scheduledPaymentId: 'sp-1',
          amountMinor: 41283020,
          nextDate: DateTime(2026, 9, 25),
          currency: 'COP',
        ),
      );
      stubHealthySources(
        debtsSummary: DebtsSummary.from([withInstallment]),
      );

      final json = await buildJson();

      final debt = (json['debts']! as List).single as Map<String, Object?>;
      expect(debt['id'], 'debt-1');
      expect(debt['name'], 'KTM 1390');
      expect(debt['outstandingMinor'], 500000000 - 87169980);
      expect(debt['outstandingFormatted'], r'$4.128.300,20');
      expect(debt['nextInstallmentAmountMinor'], 41283020);
      expect(debt['nextInstallmentAmountFormatted'], r'$412.830,20');
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

      final items = (json['spendingByCategory']!
          as Map<String, Object?>)['items']! as List;
      final uncategorised = items.last! as Map<String, Object?>;
      expect(uncategorised.containsKey('categoryId'), isFalse);
    });

    test(
        '"categories" lists a category that has NO spend this period at all '
        '— found live: a category used every month except this one (a debt '
        'payment due outside the current cycle) was invisible to the model, '
        'which only ever saw ids via "spendingByCategory", so it proposed a '
        'duplicate instead of reusing the real one', () async {
      stubHealthySources();
      // Registered AFTER `stubHealthySources()` on purpose — mocktail's
      // `when()` resolves a matching call to whichever stub was registered
      // LAST, so this has to override its default single-category stub, not
      // the other way around.
      when(() => watchCategories(any())).thenAnswer(
        (invocation) => Stream.value(
          Right([
            CategoryNode(
              root: buildCategory(
                id: 'cat-debts',
                name: 'Deudas',
                kind: invocation.positionalArguments.single as CategoryKind,
              ),
              subcategories: [
                buildCategory(
                  id: 'cat-debts-ktm',
                  name: 'KTM',
                  parentId: 'cat-debts',
                  kind: invocation.positionalArguments.single as CategoryKind,
                ),
              ],
            ),
          ]),
        ),
      );

      final json = await buildJson();

      final categoryEntries = json['categories']! as List;
      final ids = categoryEntries
          .cast<Map<String, Object?>>()
          .map((entry) => entry['categoryId'])
          .toSet();
      // Neither id appears anywhere in `spendingByCategory` (only 'cat-food'
      // does, from `breakdown` above) — this list is the only place the
      // model can find them.
      expect(ids, containsAll(<String>['cat-debts', 'cat-debts-ktm']));

      final subcategory = categoryEntries.cast<Map<String, Object?>>().firstWhere(
            (entry) => entry['categoryId'] == 'cat-debts-ktm',
          );
      expect(subcategory['parentId'], 'cat-debts');
    });
  });

  group('a section that could not be read is omitted, never emitted empty', () {
    test(
        'a failing budgets source drops the key instead of sending an empty '
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

    test(
        'a budgets source with genuinely nothing to show still emits an empty '
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

    test(
        'a zero-based summary that is legitimately null omits its section '
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
      when(() => watchCategories(any())).thenAnswer(
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
    test(
        'omits the category breakdown and the cash flow, which cannot be '
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

  /// The `upcoming` section is the only place in the snapshot where a
  /// user-written note can appear at all, so the pair is asserted here.
  group('AppSettings.aiNotesAccessEnabled gates the upcoming note', () {
    test('off: no note key, and the text appears nowhere in the payload',
        () async {
      stubHealthySources();

      final json = await buildJson();

      final upcoming =
          (json['upcoming']! as List).first as Map<String, Object?>;
      expect(upcoming.containsKey('note'), isFalse);
      expect(upcoming['name'], 'Arriendo · Bancolombia');
      expect(json.toString(), isNot(contains('no debe viajar')));
    });

    test('on: the scheduled payment note rides in its upcoming row', () async {
      stubNotesAccess(enabled: true);
      stubHealthySources();

      final json = await buildJson();

      final upcoming =
          (json['upcoming']! as List).first as Map<String, Object?>;
      expect(upcoming['note'], 'arriendo del apto — no debe viajar');
      expect(
        upcoming['name'],
        'Arriendo · Bancolombia',
        reason: 'the note is added to the row, it never replaces the name',
      );
    });

    test('an unreadable settings row falls back to OFF, not to sending it',
        () async {
      when(getAppSettings.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('settings are down'))),
      );
      stubHealthySources();

      final json = await buildJson();

      final upcoming =
          (json['upcoming']! as List).first as Map<String, Object?>;
      expect(upcoming.containsKey('note'), isFalse);
      expect(json.toString(), isNot(contains('no debe viajar')));
    });

    test('an unreadable settings row never fails the snapshot by itself',
        () async {
      when(getAppSettings.call).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('settings are down'))),
      );
      stubHealthySources();

      final result = await usecase(now: now);

      expect(result.isRight(), isTrue);
    });
  });

  group('every amount carries its formatted twin', () {
    test(
        'no `*Minor` anywhere in the payload is missing its `*Formatted` '
        'sibling', () async {
      // The server prompt ASSERTS to the model that every amount ships
      // pre-formatted. When that was only true of budgets, the model fell
      // back to dividing by 100 in its head and told the user a balance 100x
      // too big ("$379.931.350" for $3.799.313,50). This test is the
      // assertion made checkable: it walks the whole wire payload instead of
      // naming fields, so a new amount added without its twin fails here.
      stubHealthySources();

      final json = await buildJson();

      expect(amountsMissingFormattedTwin(json), isEmpty);
    });

    test('an account balance is quoted as pesos, never as raw cents', () async {
      stubHealthySources(
        accounts: [
          buildAccountWithBalance(
            account: buildAccount(id: 'acc-1', currency: 'COP'),
            // The exact figure from the live report.
            balanceMinor: 379931350,
          ),
        ],
      );

      final json = await buildJson();

      final account = (json['accounts']! as List).first as Map<String, Object?>;
      expect(account['balanceMinor'], 379931350);
      expect(account['balanceFormatted'], r'$3.799.313,50');
    });

    test('each row is formatted in its OWN currency, never a global one',
        () async {
      stubHealthySources(
        accounts: [
          buildAccountWithBalance(
            account: buildAccount(id: 'acc-cop', currency: 'COP'),
            balanceMinor: 379931350,
          ),
          buildAccountWithBalance(
            account: buildAccount(id: 'acc-usd', currency: 'USD'),
            balanceMinor: 120050,
          ),
        ],
      );

      final json = await buildJson();

      final accounts = (json['accounts']! as List).cast<Map<String, Object?>>();
      expect(accounts[0]['balanceFormatted'], r'$3.799.313,50');
      // USD keeps its two decimals; COP above only shows them because the
      // balance genuinely carries cents.
      expect(accounts[1]['balanceFormatted'], r'$1.200,50');
    });

    test('a negative net keeps its sign instead of reading as a surplus',
        () async {
      stubHealthySources();
      when(() => watchCashflow(any())).thenAnswer(
        (_) => Stream.value(
          Right(
            CashflowSeries(
              points: [
                CashflowPoint(
                  periodStart: DateTime(2026, 7),
                  incomeMinor: 300000000,
                  expenseMinor: 500000000,
                  debtIncomeMinor: 0,
                  debtExpenseMinor: 0,
                ),
              ],
              includeDebtMovements: true,
              bounds: cashflow.bounds,
            ),
          ),
        ),
      );

      final json = await buildJson();

      final point = ((json['cashflow']! as Map<String, Object?>)['points']!
          as List)[0] as Map<String, Object?>;
      expect(point['netMinor'], -200000000);
      expect(point['netFormatted'], r'$-2.000.000');
    });

    test('an over-assigned zero-based budget reads negative', () async {
      stubHealthySources(
        zeroBased: const ZeroBasedSummary(
          currency: 'COP',
          incomeMinor: 400000000,
          assignedMinor: 450000000,
        ),
      );

      final json = await buildJson();

      final zeroBased = json['zeroBased']! as Map<String, Object?>;
      expect(zeroBased['unassignedMinor'], -50000000);
      expect(zeroBased['unassignedFormatted'], r'$-500.000');
    });

    test('the spending section carries a formatted total too', () async {
      stubHealthySources();

      final json = await buildJson();

      final spending = json['spendingByCategory']! as Map<String, Object?>;
      expect(spending['totalMinor'], 126000000);
      expect(spending['totalFormatted'], r'$1.260.000');
    });
  });
}
