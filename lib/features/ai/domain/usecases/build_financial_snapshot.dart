import 'dart:async';

import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../accounts/domain/entities/accounts_overview.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../accounts/domain/usecases/watch_accounts_overview.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../budgets/domain/entities/zero_based_summary.dart';
import '../../../budgets/domain/usecases/get_active_budgets.dart';
import '../../../budgets/domain/usecases/get_zero_based_summary.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../categories/domain/entities/category_node.dart';
import '../../../categories/domain/usecases/watch_categories.dart';
import '../../../debts/domain/entities/debt_with_balance.dart';
import '../../../debts/domain/entities/debts_summary.dart';
import '../../../debts/domain/usecases/watch_debts.dart';
import '../../../goals/domain/entities/goal_with_progress.dart';
import '../../../goals/domain/usecases/watch_goals.dart';
import '../../../reports/domain/entities/cashflow_series.dart';
import '../../../reports/domain/entities/category_breakdown.dart';
import '../../../reports/domain/entities/date_range.dart';
import '../../../reports/domain/usecases/watch_cashflow_report.dart';
import '../../../reports/domain/usecases/watch_category_breakdown_report.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import '../../../scheduled_payments/domain/usecases/get_scheduled_payments.dart';
import '../../../scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import '../../../settings/domain/usecases/get_app_settings.dart';
import '../entities/financial_snapshot.dart';

/// Builds the aggregated picture that travels with every turn.
///
/// This use case computes **nothing**: every figure comes from an aggregator
/// that already exists and is already tested (accounts overview, budget
/// progress, goal progress, debt totals, the reports' breakdown/cash-flow).
/// Re-deriving any of them here would create a second definition of "spent
/// this month" that drifts from the one the screens show, and the assistant
/// contradicting the app is worse than the assistant saying nothing.
///
/// Failure is per-section: a source that errors or hangs leaves its section
/// **absent** from the payload, which is not the same as empty (see
/// [FinancialSnapshot.toJson], rule 4). Only when every source is down does
/// the whole build fail.
@injectable
class BuildFinancialSnapshot {
  const BuildFinancialSnapshot(
    this._watchAccounts,
    this._watchAccountsOverview,
    this._getActiveBudgets,
    this._getZeroBasedSummary,
    this._watchGoals,
    this._watchDebts,
    this._watchCategories,
    this._watchCategoryBreakdown,
    this._watchCashflow,
    this._getScheduledPayments,
    this._projectUpcomingOccurrences,
    this._getAppSettings,
    this._money,
  );

  final WatchAccounts _watchAccounts;
  final WatchAccountsOverview _watchAccountsOverview;
  final GetActiveBudgets _getActiveBudgets;
  final GetZeroBasedSummary _getZeroBasedSummary;
  final WatchGoals _watchGoals;
  final WatchDebts _watchDebts;
  final WatchCategories _watchCategories;
  final WatchCategoryBreakdownReport _watchCategoryBreakdown;
  final WatchCashflowReport _watchCashflow;
  final GetScheduledPayments _getScheduledPayments;
  final ProjectUpcomingOccurrences _projectUpcomingOccurrences;

  /// Read for one thing only: `AppSettings.aiNotesAccessEnabled`, the opt-in
  /// that decides whether a scheduled payment's free text may travel in the
  /// `upcoming` section. Unreadable settings mean `false`: [_once] collapses a
  /// `Left`, a timeout and a throwing source into `null`, and "we could not
  /// read it" can only mean "do not send the note".
  final GetAppSettings _getAppSettings;

  /// The same formatter every screen renders amounts with — never re-derive
  /// the "$1.234.567" shape here, or the two will eventually drift.
  final MoneyFormatter _money;

  /// Per-source ceiling. Drift emits on subscription, so this is a point read,
  /// not a listener — but a source that never emits would otherwise hang the
  /// whole snapshot and, with it, the user's message.
  static const Duration readTimeout = Duration(seconds: 5);

  /// How many rows of each list travel. `counts` still reports the real
  /// totals, so the model can tell a short list from a truncated one.
  static const int maxListRows = 25;

  /// The breakdown is the densest section and the least useful past the top
  /// few rows.
  static const int maxCategoryRows = 15;

  /// Months of cash-flow history.
  static const int cashflowMonths = 6;

  /// Look-ahead for scheduled payments.
  static const int upcomingDays = 30;

  FutureResult<FinancialSnapshot> call({DateTime? now}) async {
    final at = now ?? clock.now();
    final monthStart = DateTime(at.year, at.month);
    final nextMonthStart = DateTime(at.year, at.month + 1);

    final monthRange = DateRange(
      start: monthStart,
      endExclusive: nextMonthStart,
      granularity: DateGranularity.monthly,
    );
    final historyRange = DateRange(
      start: DateTime(at.year, at.month - (cashflowMonths - 1)),
      endExclusive: nextMonthStart,
      granularity: DateGranularity.monthly,
    );

    // Subscribing to every stream before the first `await` is what makes the
    // reads overlap; awaiting them one by one below costs nothing extra.
    final accountsRead = _once(_watchAccounts());
    final overviewRead = _once(_watchAccountsOverview());
    final budgetsRead = _once(_getActiveBudgets());
    final zeroBasedRead = _once(_getZeroBasedSummary());
    final goalsRead = _once(_watchGoals());
    final debtsRead = _once(_watchDebts());
    final expenseCategoriesRead = _once(_watchCategories(CategoryKind.expense));
    final incomeCategoriesRead = _once(_watchCategories(CategoryKind.income));
    final breakdownRead = _once(
      _watchCategoryBreakdown(
        WatchCategoryBreakdownReportParams(range: monthRange),
      ),
    );
    final cashflowRead = _once(
      _watchCashflow(WatchCashflowReportParams(range: historyRange)),
    );
    final scheduledRead = _once(_getScheduledPayments());
    final settingsRead = _once(_getAppSettings());

    await Future.wait<void>([
      accountsRead,
      overviewRead,
      budgetsRead,
      zeroBasedRead,
      goalsRead,
      debtsRead,
      expenseCategoriesRead,
      incomeCategoriesRead,
      breakdownRead,
      cashflowRead,
      scheduledRead,
      settingsRead,
    ]);

    final accounts = await accountsRead;
    final overview = await overviewRead;
    final budgets = await budgetsRead;
    final zeroBased = await zeroBasedRead;
    final goals = await goalsRead;
    final debts = await debtsRead;
    final expenseCategories = await expenseCategoriesRead;
    final incomeCategories = await incomeCategoriesRead;
    final breakdown = await breakdownRead;
    final cashflow = await cashflowRead;
    final scheduled = await scheduledRead;
    // Deliberately NOT part of `everySourceDown` below: this is not a
    // financial section, and an unreadable settings row must degrade to "no
    // notes", never to a failed snapshot.
    final notesAccessEnabled =
        (await settingsRead)?.aiNotesAccessEnabled ?? false;

    // `zeroBased` is excluded on purpose: its payload is legitimately `null`
    // when there is nothing to show, so it cannot tell "unreadable" from
    // "nothing to say" and would mask a total outage.
    final everySourceDown = accounts == null &&
        overview == null &&
        budgets == null &&
        goals == null &&
        debts == null &&
        breakdown == null &&
        cashflow == null &&
        scheduled == null;
    if (everySourceDown) {
      return const Left(
        DatabaseFailure('no financial data source could be read'),
      );
    }

    // Neither the breakdown nor the cash-flow report is currency-segmented
    // today: they aggregate every account's rows into one figure. That is
    // fine for a single-currency user and a fabricated number for anyone
    // else, so both sections are dropped entirely when more than one currency
    // is in play — omitting beats emitting a total that means nothing.
    final currencies = accounts == null
        ? const <String>{}
        : {for (final entry in accounts) entry.account.currency};
    final singleCurrency = currencies.length == 1 ? currencies.first : null;

    final upcoming = scheduled == null
        ? null
        : _upcoming(
            scheduled,
            at: at,
            notesAccessEnabled: notesAccessEnabled,
          );

    return Right(
      FinancialSnapshot(
        generatedAt: at,
        periodStart: monthStart,
        periodEndExclusive: nextMonthStart,
        accounts: accounts == null ? null : _accounts(accounts),
        currencyTotals: overview == null ? null : _currencyTotals(overview),
        categories: expenseCategories == null && incomeCategories == null
            ? null
            : _categories(expenseCategories, incomeCategories),
        spendingByCategory: breakdown == null || singleCurrency == null
            ? null
            : _categoryLines(breakdown, singleCurrency),
        spendingCurrency:
            breakdown == null || singleCurrency == null ? null : singleCurrency,
        spendingTotalMinor: breakdown == null || singleCurrency == null
            ? null
            : breakdown.totalMinor,
        spendingTotalFormatted: breakdown == null || singleCurrency == null
            ? null
            : _fmt(breakdown.totalMinor, singleCurrency),
        cashflow: cashflow == null || singleCurrency == null
            ? null
            : _cashflowPoints(cashflow, singleCurrency),
        cashflowCurrency:
            cashflow == null || singleCurrency == null ? null : singleCurrency,
        budgets: budgets == null ? null : _budgets(budgets),
        goals: goals == null ? null : _goals(goals),
        debtTotals: debts == null ? null : _debtTotals(debts),
        debts: debts == null ? null : _debts(debts),
        upcoming: upcoming,
        zeroBased: zeroBased == null ? null : _zeroBased(zeroBased),
        counts: SnapshotCounts(
          accounts: accounts?.length ?? 0,
          budgets: budgets?.length ?? 0,
          goals: goals?.length ?? 0,
          debts: debts?.openDebts.length ?? 0,
          upcoming: upcoming?.length ?? 0,
        ),
      ),
    );
  }

  /// The one place an amount becomes text in this snapshot. Every
  /// `*Formatted` twin goes through it, with the currency of its OWN row —
  /// there is no global currency here (dogfooding bug: the twins only existed
  /// on budgets, so the model read `379931350` cents of a savings account as
  /// "$379.931.350" and told the user a figure 100x their balance; the prompt
  /// meanwhile asserted that every amount carried one).
  String _fmt(int minor, String currency) =>
      _money.formatSymbol(minor, currencyCode: currency);

  /// One point read off a reactive source. `null` means "this section is
  /// unavailable", for any reason: a `Left`, a stream that errored, or one
  /// that never emitted.
  ///
  /// Swallowing the cause is the contract here, not an oversight — the caller
  /// has exactly one way to react (omit the section), and a section-level
  /// outage is already visible in the payload by its absence. A total outage
  /// still surfaces as a `DatabaseFailure`.
  Future<T?> _once<T>(Stream<Result<T>> stream) async {
    try {
      // `take(1).toList()` rather than `first`: a source that closes without
      // ever emitting yields an empty list here, instead of the `StateError`
      // `first` throws — an absent section, not an error to catch.
      final emitted = await stream.take(1).toList().timeout(readTimeout);
      if (emitted.isEmpty) {
        return null;
      }
      return emitted.first.fold((failure) => null, (value) => value);
      // ignore: avoid_catching_errors
    } on Object {
      // Covers the `TimeoutException` above and anything a source throws
      // instead of returning a `Left`.
      //
      // `Object` and not `Exception` on purpose, lint suppressed deliberately:
      // the whole point of this method is that ONE unreadable section degrades
      // to an absent key while the rest of the snapshot still goes out. An
      // upstream mapper throwing a `TypeError` on a bad cast — or a
      // `StateError`, or a `RangeError` — is an `Error`, not an `Exception`,
      // and catching only the latter would let it escape `call()` and take
      // down the entire turn. That is the opposite of what the caller is
      // promised two doc comments above, and it fails in exactly the case
      // where degrading matters most: real data that some mapper mishandles.
      return null;
    }
  }

  List<SnapshotAccount> _accounts(List<AccountWithBalance> accounts) => [
        for (final entry in accounts.take(maxListRows))
          SnapshotAccount(
            id: entry.account.id,
            name: entry.account.name,
            type: entry.account.type,
            currency: entry.account.currency,
            balanceMinor: entry.balance.balanceMinor,
            balanceFormatted:
                _fmt(entry.balance.balanceMinor, entry.account.currency),
          ),
      ];

  /// Flattens both kinds' root+subcategory trees into one flat list — the
  /// model reasons about a single `categories` array, not two kind-keyed
  /// ones, and each row already carries its own `kind`. Either argument can
  /// be null on its own (one kind's read failing does not sink the other);
  /// only both together mean there is nothing to report.
  List<SnapshotCategory> _categories(
    List<CategoryNode>? expense,
    List<CategoryNode>? income,
  ) =>
      [
        for (final node in [...?expense, ...?income]) ...[
          SnapshotCategory(
            categoryId: node.root.id,
            name: node.root.name,
            kind: node.root.kind,
          ),
          for (final sub in node.subcategories)
            SnapshotCategory(
              categoryId: sub.id,
              name: sub.name,
              kind: sub.kind,
              parentId: node.root.id,
            ),
        ],
      ];

  List<SnapshotCurrencyTotal> _currencyTotals(AccountsOverview overview) => [
        for (final subtotal in overview.subtotals)
          SnapshotCurrencyTotal(
            currency: subtotal.currency,
            netWorthMinor: subtotal.netWorthMinor,
            debtMinor: subtotal.debtMinor,
            netWorthFormatted: _fmt(subtotal.netWorthMinor, subtotal.currency),
            debtFormatted: _fmt(subtotal.debtMinor, subtotal.currency),
          ),
      ];

  List<SnapshotCategoryLine> _categoryLines(
    CategoryBreakdown breakdown,
    String currency,
  ) =>
      [
        for (final item in breakdown.items.take(maxCategoryRows))
          SnapshotCategoryLine(
            categoryId: item.categoryId,
            // `name` is null exactly for the "sin categoría" bucket, whose
            // label lives in l10n and must not be hardcoded in domain. The
            // empty id is the signal; the model is told what it means.
            name: item.name ?? '',
            amountMinor: item.amountMinor,
            amountFormatted: _fmt(item.amountMinor, currency),
            movementCount: item.movementCount,
          ),
      ];

  List<SnapshotCashflowPoint> _cashflowPoints(
    CashflowSeries series,
    String currency,
  ) =>
      [
        for (final point in series.points)
          // Debt movements folded in, matching the report's default: pulling
          // them out here would make the net stop reconciling with the
          // account balances in the same payload.
          _cashflowPoint(
            periodStart: point.periodStart,
            incomeMinor: point.incomeMinor + point.debtIncomeMinor,
            expenseMinor: point.expenseMinor + point.debtExpenseMinor,
            currency: currency,
          ),
      ];

  /// Named so the net's formatted twin is computed from the very same
  /// subtraction the entity's `netMinor` getter exposes — a month that spent
  /// more than it earned keeps its minus sign.
  SnapshotCashflowPoint _cashflowPoint({
    required DateTime periodStart,
    required int incomeMinor,
    required int expenseMinor,
    required String currency,
  }) =>
      SnapshotCashflowPoint(
        periodStart: periodStart,
        incomeMinor: incomeMinor,
        expenseMinor: expenseMinor,
        incomeFormatted: _fmt(incomeMinor, currency),
        expenseFormatted: _fmt(expenseMinor, currency),
        netFormatted: _fmt(incomeMinor - expenseMinor, currency),
      );

  List<SnapshotBudget> _budgets(List<BudgetWithProgress> budgets) => [
        for (final entry in budgets.take(maxListRows)) _budget(entry),
      ];

  SnapshotBudget _budget(BudgetWithProgress entry) {
    final currency = entry.budget.currency;
    // The window's amounts, not the budget row's: a Wallet-style per-period
    // override changes what this period is actually worth.
    final amountMinor = entry.progress.amountMinor;
    final spentMinor = entry.progress.spentMinor;
    final scheduledMinor = entry.progress.scheduledMinor;
    String fmt(int minor) => _fmt(minor, currency);
    return SnapshotBudget(
      id: entry.budget.id,
      name: entry.budget.name,
      amountMinor: amountMinor,
      spentMinor: spentMinor,
      scheduledMinor: scheduledMinor,
      currency: currency,
      period: entry.budget.period,
      periodStart: entry.window.start,
      periodEndExclusive: entry.window.endExclusive,
      amountFormatted: fmt(amountMinor),
      spentFormatted: fmt(spentMinor),
      remainingFormatted: fmt(amountMinor - spentMinor),
      scheduledFormatted: fmt(scheduledMinor),
      projectedTotalFormatted: fmt(spentMinor + scheduledMinor),
    );
  }

  List<SnapshotGoal> _goals(List<GoalWithProgress> goals) => [
        for (final entry in goals.take(maxListRows))
          SnapshotGoal(
            id: entry.goal.id,
            name: entry.goal.name,
            targetMinor: entry.goal.targetMinor,
            savedMinor: entry.savedMinor,
            currency: entry.goal.currency,
            targetFormatted: _fmt(entry.goal.targetMinor, entry.goal.currency),
            savedFormatted: _fmt(entry.savedMinor, entry.goal.currency),
            targetDate: entry.goal.targetDate,
          ),
      ];

  List<SnapshotDebtTotal> _debtTotals(DebtsSummary summary) => [
        for (final total in summary.totals)
          SnapshotDebtTotal(
            currency: total.currency,
            iOweMinor: total.iOweOutstandingMinor,
            owedToMeMinor: total.owedToMeOutstandingMinor,
            iOweFormatted: _fmt(total.iOweOutstandingMinor, total.currency),
            owedToMeFormatted:
                _fmt(total.owedToMeOutstandingMinor, total.currency),
          ),
      ];

  /// Same scope as [_debtTotals]: open debts only — a closed debt's frozen
  /// balance is uninteresting to a "should I pay X from this account"
  /// question, same reasoning as the totals it sits beside.
  List<SnapshotDebt> _debts(DebtsSummary summary) => [
        for (final entry in summary.openDebts.take(maxListRows)) _debt(entry),
      ];

  SnapshotDebt _debt(DebtWithBalance entry) {
    final currency = entry.debt.currency;
    final installment = entry.installment;
    return SnapshotDebt(
      id: entry.debt.id,
      name: entry.debt.name,
      direction: entry.debt.direction,
      currency: currency,
      outstandingMinor: entry.balance.outstandingMinor,
      outstandingFormatted: _fmt(entry.balance.outstandingMinor, currency),
      nextInstallmentAmountMinor: installment?.amountMinor,
      nextInstallmentAmountFormatted: installment == null
          ? null
          : _fmt(installment.amountMinor, installment.currency),
      nextInstallmentDate: installment?.nextDate,
    );
  }

  List<SnapshotUpcoming> _upcoming(
    List<ScheduledPaymentSummary> templates, {
    required DateTime at,
    required bool notesAccessEnabled,
  }) {
    final byId = {
      for (final summary in templates) summary.scheduledPayment.id: summary,
    };
    final projected = _projectUpcomingOccurrences(
      templates: [
        for (final summary in templates) summary.scheduledPayment,
      ],
      windowStart: at,
      windowEndInclusive: at.add(const Duration(days: upcomingDays)),
    );

    return [
      for (final occurrence in projected.take(maxListRows))
        SnapshotUpcoming(
          scheduledPaymentId: occurrence.scheduledPaymentId,
          name: _upcomingName(byId[occurrence.scheduledPaymentId]),
          note: notesAccessEnabled
              ? byId[occurrence.scheduledPaymentId]?.scheduledPayment.note
              : null,
          date: occurrence.date,
          amountMinor: occurrence.amountMinor,
          currency: occurrence.currency,
          type: occurrence.type,
          amountFormatted: _fmt(occurrence.amountMinor, occurrence.currency),
        ),
    ];
  }

  /// Category AND account, never just the category (dogfooding bug: two
  /// scheduled payments sharing a category, e.g. rent and a mortgage both
  /// filed under "Vivienda", were indistinguishable to the model). Never the
  /// template's own `note`: the name is structured data that always travels,
  /// while the note is the user's free text and only ever rides in
  /// `SnapshotUpcoming.note`, gated on `AppSettings.aiNotesAccessEnabled`.
  String _upcomingName(ScheduledPaymentSummary? summary) {
    if (summary == null) {
      return '';
    }
    final category = summary.categoryName;
    final account = summary.accountName;
    if (category == null || category.isEmpty) {
      return account;
    }
    return '$category · $account';
  }

  SnapshotZeroBased _zeroBased(ZeroBasedSummary summary) => SnapshotZeroBased(
        currency: summary.currency,
        incomeMinor: summary.incomeMinor,
        assignedMinor: summary.assignedMinor,
        incomeFormatted: _fmt(summary.incomeMinor, summary.currency),
        assignedFormatted: _fmt(summary.assignedMinor, summary.currency),
        // Over-assigning is negative and stays negative.
        unassignedFormatted: _fmt(
          summary.incomeMinor - summary.assignedMinor,
          summary.currency,
        ),
      );
}
