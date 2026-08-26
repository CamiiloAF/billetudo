import 'dart:async';

import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../budgets/domain/entities/budget_period_view.dart';
import '../../../budgets/domain/usecases/get_budget_by_id.dart';
import '../../../budgets/domain/usecases/get_budget_progress.dart';
import '../../../goals/domain/usecases/watch_goal_detail.dart';
import '../../../reports/domain/entities/cashflow_series.dart';
import '../../../reports/domain/entities/category_breakdown.dart';
import '../../../reports/domain/entities/category_breakdown_item.dart';
import '../../../reports/domain/entities/date_range.dart';
import '../../../reports/domain/usecases/watch_cashflow_report.dart';
import '../../../reports/domain/usecases/watch_category_breakdown_report.dart';
import '../../../transactions/domain/entities/date_period_filter.dart'
    show DatePeriodFilter;
import '../../../transactions/domain/entities/transaction.dart'
    show TransactionType;
import '../../../transactions/domain/entities/transaction_filter.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/domain/usecases/watch_transactions.dart';
import '../entities/ai_tool_call.dart';
import '../entities/financial_snapshot.dart';

/// Resolves the model's read tools against the **local** database.
///
/// Reads never run on the server: Postgres is a mirror that can lag a sync or
/// sit half-merged right after a login, and answering from a stale mirror is
/// how a model lies with total confidence
/// (`supabase/functions/README.md`, "Herramientas").
///
/// Two rules shape every result:
///
///  - **A tool that cannot be resolved still returns `Right`.** An unknown
///    tool, a missing budget, an unsupported combination — all come back as
///    `{'error': 'not_found', 'message': …}` inside the result, because the
///    prompt instructs the model to explain that rather than invent. Failing
///    the turn instead would turn "I couldn't find that budget" into "algo
///    salió mal".
///  - **No transaction note ever leaves the device.** It is the user's own
///    free text and it is not needed to answer any of these questions.
@injectable
class ResolveAiToolCall {
  const ResolveAiToolCall(
    this._watchTransactions,
    this._watchCategoryBreakdown,
    this._watchCashflow,
    this._watchAccounts,
    this._getBudgetById,
    this._getBudgetProgress,
    this._watchGoalDetail,
  );

  final WatchTransactions _watchTransactions;
  final WatchCategoryBreakdownReport _watchCategoryBreakdown;
  final WatchCashflowReport _watchCashflow;
  final WatchAccounts _watchAccounts;
  final GetBudgetById _getBudgetById;
  final GetBudgetProgress _getBudgetProgress;
  final WatchGoalDetail _watchGoalDetail;

  /// Hard ceiling on rows in any single result, whatever the model asked for.
  /// The body cap is 128 KB and the history travels whole on every turn, so an
  /// oversized read poisons every later turn too, not just this one.
  ///
  /// 50 is not an arbitrary round number: the published privacy policy commits
  /// to "como máximo 50 movimientos" (section 17.2), and the tool schema in
  /// `supabase/functions/_shared/ai/tools.ts` declares the same bound. Raising
  /// it here would make a legal document false, so all three move together or
  /// none do.
  static const int maxRows = 50;

  /// Default row count when the call omits `limit`.
  static const int defaultRows = 25;

  /// Same point-read ceiling as the snapshot: these are reactive sources read
  /// once, and one that never emits would hang the turn.
  static const Duration readTimeout = Duration(seconds: 5);

  static const String errorNotFound = 'not_found';

  FutureResult<AiToolResult> call(AiToolCall toolCall) async {
    final result = switch (toolCall.name) {
      'get_transactions' => await _getTransactions(toolCall.arguments),
      'get_category_breakdown' =>
        await _getCategoryBreakdown(toolCall.arguments),
      'compare_periods' => await _comparePeriods(toolCall.arguments),
      'get_budget_detail' => await _getBudgetDetail(toolCall.arguments),
      'get_goal_detail' => await _getGoalDetail(toolCall.arguments),
      _ => _notFound('unknown tool "${toolCall.name}"'),
    };

    return Right(
      AiToolResult(
        toolCallId: toolCall.id,
        name: toolCall.name,
        result: result,
        thoughtSignature: toolCall.thoughtSignature,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // get_transactions
  // ---------------------------------------------------------------------

  Future<Map<String, Object?>> _getTransactions(
    Map<String, Object?> arguments,
  ) async {
    final from = _dateArg(arguments, 'from');
    final to = _dateArg(arguments, 'to');
    if (from == null || to == null) {
      return _notFound('from and to are required, as unix seconds');
    }
    // `DatePeriodFilter.custom` throws on an inverted range, and a model that
    // mixed up its bounds is a wrong question, not a crash.
    if (!to.isAfter(from)) {
      return _notFound('"to" must be after "from"');
    }

    final types = _typeArg(arguments['type']);
    final filter = TransactionFilter(
      accountIds: _stringSet(arguments['accountIds']),
      categoryIds: _stringSet(arguments['categoryIds']),
      types: types,
      // `to` is exclusive on the wire; `DatePeriodFilter.custom` takes an
      // inclusive last day.
      datePeriod: DatePeriodFilter.custom(
        start: from,
        end: to.subtract(const Duration(days: 1)),
      ),
      sortOrder: _sortOrderArg(arguments['order']),
    );

    final rows = await _once(_watchTransactions(filter));
    if (rows == null) {
      return _notFound('the movement list could not be read');
    }

    // Currency and minimum amount have no place in `TransactionFilter` (no
    // screen filters by them), so they are applied here rather than widening a
    // shared filter for one caller.
    final currency = _stringArg(arguments, 'currency')?.toUpperCase();
    final minAmountMinor = _intArg(arguments, 'minAmountMinor');
    final maxAmountMinor = _intArg(arguments, 'maxAmountMinor');
    final matching = [
      for (final row in rows)
        if ((currency == null || row.transaction.currency == currency) &&
            (minAmountMinor == null ||
                row.transaction.amountMinor >= minAmountMinor) &&
            (maxAmountMinor == null ||
                row.transaction.amountMinor <= maxAmountMinor))
          row,
    ];

    final limit = _rowLimit(_intArg(arguments, 'limit'));
    final page = matching.take(limit).toList();

    return <String, Object?>{
      if (currency != null) 'currency': currency,
      'from': FinancialSnapshot.unixSeconds(from),
      'to': FinancialSnapshot.unixSeconds(to),
      'count': page.length,
      'truncated': matching.length > page.length,
      'items': [for (final row in page) _transactionItem(row)],
    };
  }

  /// Deliberately without `note`: see the class doc.
  Map<String, Object?> _transactionItem(TransactionWithDetails row) =>
      <String, Object?>{
        'id': row.transaction.id,
        'date': FinancialSnapshot.unixSeconds(row.transaction.date),
        'amountMinor': row.transaction.amountMinor,
        'currency': row.transaction.currency,
        'type': row.transaction.type.name,
        if (row.categoryName != null) 'categoryName': row.categoryName,
        'accountName': row.accountName,
      };

  // ---------------------------------------------------------------------
  // get_category_breakdown
  // ---------------------------------------------------------------------

  Future<Map<String, Object?>> _getCategoryBreakdown(
    Map<String, Object?> arguments,
  ) async {
    final from = _dateArg(arguments, 'from');
    final to = _dateArg(arguments, 'to');
    final currency = _stringArg(arguments, 'currency')?.toUpperCase();
    if (from == null || to == null || currency == null) {
      return _notFound('from, to and currency are required');
    }

    // The breakdown report only covers expense (`CategoryBreakdown` is the
    // "estructura de gasto" of HU-03). There is no income equivalent to reuse,
    // and building one here would be a second definition of the same number.
    final type = _stringArg(arguments, 'type');
    if (type != null && type != 'expense') {
      return _notFound(
        'only the expense breakdown is available in this version',
      );
    }

    final guard = await _currencyGuard(currency);
    if (guard != null) {
      return guard;
    }

    final breakdown = await _once(
      _watchCategoryBreakdown(
        WatchCategoryBreakdownReportParams(range: _range(from, to)),
      ),
    );
    if (breakdown == null) {
      return _notFound('the category breakdown could not be read');
    }

    final topN = _rowLimit(_intArg(arguments, 'topN'));
    final includeSubcategories = arguments['includeSubcategories'] == true;
    final items = breakdown.items.take(topN).toList();

    return <String, Object?>{
      'currency': currency,
      'from': FinancialSnapshot.unixSeconds(from),
      'to': FinancialSnapshot.unixSeconds(to),
      'totalMinor': breakdown.totalMinor,
      'count': items.length,
      'truncated': breakdown.items.length > items.length,
      'items': [
        for (final item in items)
          _breakdownItem(item, currency, includeSubcategories),
      ],
    };
  }

  Map<String, Object?> _breakdownItem(
    CategoryBreakdownItem item,
    String currency,
    bool includeSubcategories,
  ) =>
      <String, Object?>{
        if (item.categoryId != null) 'categoryId': item.categoryId,
        'name': item.name ?? '',
        'amountMinor': item.amountMinor,
        'currency': currency,
        'movementCount': item.movementCount,
        if (includeSubcategories && item.subcategories.isNotEmpty)
          'subcategories': [
            for (final child in item.subcategories.take(maxRows))
              _breakdownItem(child, currency, false),
          ],
      };

  // ---------------------------------------------------------------------
  // compare_periods
  // ---------------------------------------------------------------------

  Future<Map<String, Object?>> _comparePeriods(
    Map<String, Object?> arguments,
  ) async {
    final aFrom = _dateArg(arguments, 'aFrom');
    final aTo = _dateArg(arguments, 'aTo');
    final bFrom = _dateArg(arguments, 'bFrom');
    final bTo = _dateArg(arguments, 'bTo');
    final currency = _stringArg(arguments, 'currency')?.toUpperCase();
    if (aFrom == null ||
        aTo == null ||
        bFrom == null ||
        bTo == null ||
        currency == null) {
      return _notFound('aFrom, aTo, bFrom, bTo and currency are required');
    }

    final guard = await _currencyGuard(currency);
    if (guard != null) {
      return guard;
    }

    if (_stringArg(arguments, 'groupBy') == 'category') {
      final a = await _once(
        _watchCategoryBreakdown(
          WatchCategoryBreakdownReportParams(range: _range(aFrom, aTo)),
        ),
      );
      final b = await _once(
        _watchCategoryBreakdown(
          WatchCategoryBreakdownReportParams(range: _range(bFrom, bTo)),
        ),
      );
      if (a == null || b == null) {
        return _notFound('the category breakdown could not be read');
      }
      return <String, Object?>{
        'currency': currency,
        'groupBy': 'category',
        'a': _periodBreakdown(aFrom, aTo, a, currency),
        'b': _periodBreakdown(bFrom, bTo, b, currency),
        'deltaMinor': b.totalMinor - a.totalMinor,
      };
    }

    final a = await _once(
      _watchCashflow(WatchCashflowReportParams(range: _range(aFrom, aTo))),
    );
    final b = await _once(
      _watchCashflow(WatchCashflowReportParams(range: _range(bFrom, bTo))),
    );
    if (a == null || b == null) {
      return _notFound('the cash-flow report could not be read');
    }

    final totalsA = _cashflowTotals(a);
    final totalsB = _cashflowTotals(b);
    return <String, Object?>{
      'currency': currency,
      'groupBy': 'total',
      'a': {
        'from': FinancialSnapshot.unixSeconds(aFrom),
        'to': FinancialSnapshot.unixSeconds(aTo),
        ...totalsA,
      },
      'b': {
        'from': FinancialSnapshot.unixSeconds(bFrom),
        'to': FinancialSnapshot.unixSeconds(bTo),
        ...totalsB,
      },
      'expenseDeltaMinor':
          (totalsB['expenseMinor']! as int) - (totalsA['expenseMinor']! as int),
      'incomeDeltaMinor':
          (totalsB['incomeMinor']! as int) - (totalsA['incomeMinor']! as int),
    };
  }

  Map<String, Object?> _periodBreakdown(
    DateTime from,
    DateTime to,
    CategoryBreakdown breakdown,
    String currency,
  ) =>
      <String, Object?>{
        'from': FinancialSnapshot.unixSeconds(from),
        'to': FinancialSnapshot.unixSeconds(to),
        'totalMinor': breakdown.totalMinor,
        'items': [
          for (final item in breakdown.items.take(maxRows))
            _breakdownItem(item, currency, false),
        ],
      };

  /// Debt movements folded in, matching the report's default — the same
  /// convention the snapshot uses, so the two never disagree.
  Map<String, Object?> _cashflowTotals(CashflowSeries series) {
    var income = 0;
    var expense = 0;
    for (final point in series.points) {
      income += point.incomeMinor + point.debtIncomeMinor;
      expense += point.expenseMinor + point.debtExpenseMinor;
    }
    return <String, Object?>{
      'incomeMinor': income,
      'expenseMinor': expense,
      'netMinor': income - expense,
    };
  }

  // ---------------------------------------------------------------------
  // get_budget_detail
  // ---------------------------------------------------------------------

  Future<Map<String, Object?>> _getBudgetDetail(
    Map<String, Object?> arguments,
  ) async {
    final budgetId = _stringArg(arguments, 'budgetId');
    if (budgetId == null) {
      return _notFound('budgetId is required');
    }

    final data = await _once(_getBudgetById(budgetId));
    if (data == null) {
      return _notFound('no budget with id "$budgetId"');
    }

    final now = clock.now();
    final current = _getBudgetProgress(data, now: now);
    final previousCount =
        (_intArg(arguments, 'includePreviousPeriods') ?? 0).clamp(0, 6);
    final previous = <Map<String, Object?>>[];
    for (var step = 1; step <= previousCount; step++) {
      final index = current.window.index - step;
      if (index < 0) {
        break;
      }
      previous.add(
        _budgetPeriod(_getBudgetProgress(data, now: now, index: index)),
      );
    }

    return <String, Object?>{
      'id': data.budget.id,
      'name': data.budget.name,
      'currency': data.budget.currency,
      'period': data.budget.period.name,
      'current': _budgetPeriod(current),
      if (previous.isNotEmpty) 'previousPeriods': previous,
    };
  }

  Map<String, Object?> _budgetPeriod(BudgetPeriodView view) => <String, Object?>{
        'from': FinancialSnapshot.unixSeconds(view.window.start),
        'to': FinancialSnapshot.unixSeconds(view.window.endExclusive),
        'amountMinor': view.progress.amountMinor,
        'spentMinor': view.progress.spentMinor,
        'remainingMinor': view.progress.remainingMinor,
        'scheduledMinor': view.progress.scheduledMinor,
        'daysLeft': view.progress.daysLeft,
      };

  // ---------------------------------------------------------------------
  // get_goal_detail
  // ---------------------------------------------------------------------

  Future<Map<String, Object?>> _getGoalDetail(
    Map<String, Object?> arguments,
  ) async {
    final goalId = _stringArg(arguments, 'goalId');
    if (goalId == null) {
      return _notFound('goalId is required');
    }

    final detail = await _once(_watchGoalDetail(goalId));
    if (detail == null) {
      return _notFound('no goal with id "$goalId"');
    }

    final goal = detail.progress.goal;
    final history = detail.history.take(maxRows).toList();
    return <String, Object?>{
      'id': goal.id,
      'name': goal.name,
      'currency': goal.currency,
      'targetMinor': goal.targetMinor,
      'savedMinor': detail.progress.savedMinor,
      'remainingMinor': detail.progress.remainingMinor,
      'percent': detail.progress.displayedPercent,
      if (goal.targetDate != null)
        'targetDate': FinancialSnapshot.unixSeconds(goal.targetDate!),
      'completed': goal.isCompleted,
      'count': history.length,
      'truncated': detail.history.length > history.length,
      // No `note`: a goal movement's note is user free text, same rule as a
      // transaction's.
      'movements': [
        for (final movement in history)
          <String, Object?>{
            'date': FinancialSnapshot.unixSeconds(movement.date),
            'amountMinor': movement.amountMinor,
            'direction': movement.direction.name,
          },
      ],
    };
  }

  // ---------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------

  /// Neither the breakdown nor the cash-flow report can filter by currency, so
  /// answering a currency-scoped question with them is only honest when every
  /// active account already uses that currency. Otherwise the figure would mix
  /// currencies while claiming to be one — the exact fabrication the snapshot
  /// rules exist to prevent.
  ///
  /// Returns `null` when it is safe to proceed, or the result to send back.
  Future<Map<String, Object?>?> _currencyGuard(String currency) async {
    final accounts = await _once(_watchAccounts());
    if (accounts == null) {
      return _notFound('the account list could not be read');
    }
    final currencies = {for (final entry in accounts) entry.account.currency};
    if (currencies.length == 1 && currencies.first == currency) {
      return null;
    }
    return _notFound(
      'this report cannot be scoped to a single currency in this version, '
      'and the accounts do not all use $currency',
    );
  }

  DateRange _range(DateTime from, DateTime to) => DateRange(
        start: from,
        endExclusive: to,
        granularity: DateGranularity.monthly,
      );

  Map<String, Object?> _notFound(String message) => <String, Object?>{
        'error': errorNotFound,
        'message': message,
      };

  int _rowLimit(int? requested) {
    final limit = requested ?? defaultRows;
    if (limit < 1) {
      return 1;
    }
    return limit > maxRows ? maxRows : limit;
  }

  /// See `BuildFinancialSnapshot._once`: same point-read semantics, and the
  /// same reason for swallowing the cause — the only reaction available is the
  /// `not_found` result the caller already builds.
  Future<T?> _once<T>(Stream<Result<T>> stream) async {
    try {
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
      // `Object` and not `Exception`, same reasoning as
      // `BuildFinancialSnapshot._once`: an upstream mapper throwing an `Error`
      // rather than an `Exception` must still degrade to the `not_found`
      // result the model knows how to talk about, instead of escaping and
      // failing the whole turn.
      return null;
    }
  }

  DateTime? _dateArg(Map<String, Object?> arguments, String key) {
    final seconds = _intArg(arguments, key);
    if (seconds == null) {
      return null;
    }
    // Unix SECONDS on the wire, per every tool schema.
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * Duration.millisecondsPerSecond,
    );
  }

  int? _intArg(Map<String, Object?> arguments, String key) {
    final value = arguments[key];
    if (value is int) {
      return value;
    }
    // A provider that emits `4500.0` for an integer field is a known failure
    // mode; truncating beats rejecting the whole call.
    if (value is num) {
      return value.toInt();
    }
    return value is String ? int.tryParse(value) : null;
  }

  String? _stringArg(Map<String, Object?> arguments, String key) {
    final value = arguments[key];
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Set<String> _stringSet(Object? value) {
    if (value is! List) {
      return const <String>{};
    }
    return {
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    };
  }

  Set<TransactionType> _typeArg(Object? value) => switch (value) {
        'income' => {TransactionType.income},
        'expense' => {TransactionType.expense},
        'transfer' => {TransactionType.transfer},
        // Inclusive-empty: no filter on this dimension.
        _ => const <TransactionType>{},
      };

  TransactionSortOrder _sortOrderArg(Object? value) => switch (value) {
        'date_asc' => TransactionSortOrder.dateAsc,
        'amount_desc' => TransactionSortOrder.amountDesc,
        _ => TransactionSortOrder.dateDesc,
      };
}
