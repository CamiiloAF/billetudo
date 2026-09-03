import 'dart:async';

import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../budgets/domain/entities/budget_period_view.dart';
import '../../../budgets/domain/usecases/get_budget_by_id.dart';
import '../../../budgets/domain/usecases/get_budget_progress.dart';
import '../../../debts/domain/entities/debt_ledger_entry.dart';
import '../../../debts/domain/usecases/watch_debt_detail.dart';
import '../../../goals/domain/usecases/watch_goal_detail.dart';
import '../../../reports/domain/entities/cashflow_series.dart';
import '../../../reports/domain/entities/category_breakdown.dart';
import '../../../reports/domain/entities/category_breakdown_item.dart';
import '../../../reports/domain/entities/date_range.dart';
import '../../../reports/domain/usecases/watch_cashflow_report.dart';
import '../../../reports/domain/usecases/watch_category_breakdown_report.dart';
import '../../../scheduled_payments/domain/entities/scheduled_history_entry.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import '../../../scheduled_payments/domain/usecases/get_scheduled_payment_detail.dart'
    as sp;
import '../../../scheduled_payments/domain/usecases/get_scheduled_payments.dart';
import '../../../settings/domain/usecases/get_app_settings.dart';
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
///  - **A note only leaves the device when the user opted in.**
///    `AppSettings.aiNotesAccessEnabled` is off by default, and while it is
///    off not one of these tools returns a `note` key — the behavior every
///    version before the opt-in had. When it is on, the notes of the records
///    the model already asked for ride along, and nothing else changes. If the
///    setting cannot be read at all, it counts as off ([_notesAccessEnabled]).
///
/// That second rule is why `find_scheduled_payments` exists in the shape it
/// does. A scheduled payment has no name of its own — the title on screen IS
/// its `note` — so "el abono a capital de la KTM 1390" had nothing to resolve
/// against, and the category alone ("Deudas · Bancolombia") cannot tell two
/// payments apart. The fix was NOT to start sending notes: the model sends the
/// search term the user already typed (so it already travelled), **the device**
/// matches it against the local notes, and only structured fields come back.
/// With the opt-in off, the note stays a comparison key that is read and
/// dropped, never a value — the search itself never depended on the switch.
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
    this._watchDebtDetail,
    this._getScheduledPaymentDetail,
    this._getScheduledPayments,
    this._getAppSettings,
    this._money,
  );

  final WatchTransactions _watchTransactions;
  final WatchCategoryBreakdownReport _watchCategoryBreakdown;
  final WatchCashflowReport _watchCashflow;
  final WatchAccounts _watchAccounts;
  final GetBudgetById _getBudgetById;
  final GetBudgetProgress _getBudgetProgress;
  final WatchGoalDetail _watchGoalDetail;
  final WatchDebtDetail _watchDebtDetail;
  final sp.GetScheduledPaymentDetail _getScheduledPaymentDetail;
  final GetScheduledPayments _getScheduledPayments;

  /// Read for one thing only: `AppSettings.aiNotesAccessEnabled` — see
  /// [_notesAccessEnabled] and the class doc.
  final GetAppSettings _getAppSettings;

  /// Same formatter the snapshot uses (`BuildFinancialSnapshot._money`), for
  /// the same reason: the server prompt ASSERTS to the model that every
  /// `...Minor` it receives ships next to a `...Formatted` twin it can copy
  /// verbatim, so it never divides by 100 in its head. When a twin was
  /// missing the model did the arithmetic anyway and quoted a balance a
  /// hundred times too large ("$379.931.350" for $3.799.313,50).
  ///
  /// So: **every** amount every tool hands back carries its twin, formatted
  /// in the currency of its own row ([_fmt]) — these payloads are
  /// multi-currency and there is no single global one to fall back on. The
  /// `...Minor` integers stay: they are what the model adds and compares
  /// with. The twin is only what it copies when quoting a figure to a person.
  final MoneyFormatter _money;

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
      'get_debt_detail' => await _getDebtDetail(toolCall.arguments),
      'get_scheduled_payment_detail' =>
        await _getScheduledPaymentDetailResult(toolCall.arguments),
      'find_scheduled_payments' =>
        await _findScheduledPayments(toolCall.arguments),
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
    // The match runs ON THE DEVICE, against `note` and the category name (see
    // `TransactionsLocalDatasource`) — that has always been true and does not
    // depend on the opt-in. Only the term the user already typed travels; the
    // note itself comes back only when `aiNotesAccessEnabled` is on.
    final searchText = _stringArg(arguments, 'searchText');
    final filter = TransactionFilter(
      searchText: searchText ?? '',
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
    final withNotes = await _notesAccessEnabled();

    return <String, Object?>{
      if (currency != null) 'currency': currency,
      'from': FinancialSnapshot.unixSeconds(from),
      'to': FinancialSnapshot.unixSeconds(to),
      'count': page.length,
      'truncated': matching.length > page.length,
      'items': [
        for (final row in page) _transactionItem(row, withNotes: withNotes),
      ],
    };
  }

  /// `note` only when the user opted in: see the class doc. The key is absent
  /// (never `null`) otherwise, so an off switch is byte-for-byte the payload
  /// this tool has always produced.
  Map<String, Object?> _transactionItem(
    TransactionWithDetails row, {
    required bool withNotes,
  }) =>
      <String, Object?>{
        'id': row.transaction.id,
        'date': FinancialSnapshot.unixSeconds(row.transaction.date),
        'amountMinor': row.transaction.amountMinor,
        'amountFormatted':
            _fmt(row.transaction.amountMinor, row.transaction.currency),
        'currency': row.transaction.currency,
        'type': row.transaction.type.name,
        if (row.categoryName != null) 'categoryName': row.categoryName,
        'accountName': row.accountName,
        if (withNotes && row.transaction.note != null)
          'note': row.transaction.note,
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
      'totalFormatted': _fmt(breakdown.totalMinor, currency),
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
        'amountFormatted': _fmt(item.amountMinor, currency),
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
      // Signed on purpose: b − a, so a drop in spending is negative and reads
      // back as `$-120.000` rather than as an increase.
      final deltaMinor = b.totalMinor - a.totalMinor;
      return <String, Object?>{
        'currency': currency,
        'groupBy': 'category',
        'a': _periodBreakdown(aFrom, aTo, a, currency),
        'b': _periodBreakdown(bFrom, bTo, b, currency),
        'deltaMinor': deltaMinor,
        'deltaFormatted': _fmt(deltaMinor, currency),
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

    final totalsA = _cashflowTotals(a, currency);
    final totalsB = _cashflowTotals(b, currency);
    final expenseDeltaMinor =
        (totalsB['expenseMinor']! as int) - (totalsA['expenseMinor']! as int);
    final incomeDeltaMinor =
        (totalsB['incomeMinor']! as int) - (totalsA['incomeMinor']! as int);
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
      // Both signed b − a: spending less than last period is a NEGATIVE
      // expense delta, and the twin has to say so.
      'expenseDeltaMinor': expenseDeltaMinor,
      'expenseDeltaFormatted': _fmt(expenseDeltaMinor, currency),
      'incomeDeltaMinor': incomeDeltaMinor,
      'incomeDeltaFormatted': _fmt(incomeDeltaMinor, currency),
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
        'totalFormatted': _fmt(breakdown.totalMinor, currency),
        'items': [
          for (final item in breakdown.items.take(maxRows))
            _breakdownItem(item, currency, false),
        ],
      };

  /// Debt movements folded in, matching the report's default — the same
  /// convention the snapshot uses, so the two never disagree.
  ///
  /// [currency] is the one the call was scoped to, which `_currencyGuard`
  /// already proved is the only currency in play before this runs.
  Map<String, Object?> _cashflowTotals(CashflowSeries series, String currency) {
    var income = 0;
    var expense = 0;
    for (final point in series.points) {
      income += point.incomeMinor + point.debtIncomeMinor;
      expense += point.expenseMinor + point.debtExpenseMinor;
    }
    // `netMinor` goes negative whenever the period spent more than it earned,
    // and that sign is the whole answer to "¿me alcanzó?".
    final net = income - expense;
    return <String, Object?>{
      'incomeMinor': income,
      'incomeFormatted': _fmt(income, currency),
      'expenseMinor': expense,
      'expenseFormatted': _fmt(expense, currency),
      'netMinor': net,
      'netFormatted': _fmt(net, currency),
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
        _budgetPeriod(
          _getBudgetProgress(data, now: now, index: index),
          data.budget.currency,
        ),
      );
    }

    return <String, Object?>{
      'id': data.budget.id,
      'name': data.budget.name,
      'currency': data.budget.currency,
      'period': data.budget.period.name,
      'current': _budgetPeriod(current, data.budget.currency),
      if (previous.isNotEmpty) 'previousPeriods': previous,
    };
  }

  /// [currency] is the budget's own — a period has no currency of its own,
  /// every figure in it is expressed in the budget's.
  Map<String, Object?> _budgetPeriod(BudgetPeriodView view, String currency) =>
      <String, Object?>{
        'from': FinancialSnapshot.unixSeconds(view.window.start),
        'to': FinancialSnapshot.unixSeconds(view.window.endExclusive),
        'amountMinor': view.progress.amountMinor,
        'amountFormatted': _fmt(view.progress.amountMinor, currency),
        'spentMinor': view.progress.spentMinor,
        'spentFormatted': _fmt(view.progress.spentMinor, currency),
        // Negative once the period is overspent, which is exactly when the
        // sign matters most.
        'remainingMinor': view.progress.remainingMinor,
        'remainingFormatted': _fmt(view.progress.remainingMinor, currency),
        'scheduledMinor': view.progress.scheduledMinor,
        'scheduledFormatted': _fmt(view.progress.scheduledMinor, currency),
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
    final withNotes = await _notesAccessEnabled();
    return <String, Object?>{
      'id': goal.id,
      'name': goal.name,
      'currency': goal.currency,
      'targetMinor': goal.targetMinor,
      'targetFormatted': _fmt(goal.targetMinor, goal.currency),
      'savedMinor': detail.progress.savedMinor,
      'savedFormatted': _fmt(detail.progress.savedMinor, goal.currency),
      'remainingMinor': detail.progress.remainingMinor,
      'remainingFormatted': _fmt(detail.progress.remainingMinor, goal.currency),
      'percent': detail.progress.displayedPercent,
      if (goal.targetDate != null)
        'targetDate': FinancialSnapshot.unixSeconds(goal.targetDate!),
      'completed': goal.isCompleted,
      'count': history.length,
      'truncated': detail.history.length > history.length,
      // `note` only when the user opted in, same rule as a transaction's.
      'movements': [
        for (final movement in history)
          <String, Object?>{
            'date': FinancialSnapshot.unixSeconds(movement.date),
            // A contribution carries no currency of its own; it is always in
            // the goal's. `direction` below, not a sign, says whether it
            // added or withdrew.
            'amountMinor': movement.amountMinor,
            'amountFormatted': _fmt(movement.amountMinor, goal.currency),
            'direction': movement.direction.name,
            if (withNotes && movement.note != null) 'note': movement.note,
          },
      ],
    };
  }

  // ---------------------------------------------------------------------
  // get_debt_detail
  // ---------------------------------------------------------------------

  /// Lets the model find a SPECIFIC debt by id and reason about it —
  /// `debts` in the snapshot gives the name/id, this gives the rest.
  /// Dogfooding bug: without this, a question naming a debt by name (e.g.
  /// "la KTM 1390", "el crédito hipotecario") had nothing to resolve against
  /// beyond the currency-blended `debtTotals` aggregate.
  Future<Map<String, Object?>> _getDebtDetail(
    Map<String, Object?> arguments,
  ) async {
    final debtId = _stringArg(arguments, 'debtId');
    if (debtId == null) {
      return _notFound('debtId is required');
    }

    final detail = await _once(_watchDebtDetail(debtId));
    if (detail == null) {
      return _notFound('no debt with id "$debtId"');
    }

    final debt = detail.debt;
    final installment = detail.installment;
    final history = detail.ledger.take(maxRows).toList();
    final withNotes = await _notesAccessEnabled();
    return <String, Object?>{
      'id': debt.id,
      'name': debt.name,
      'direction': debt.direction.name,
      'currency': debt.currency,
      'outstandingMinor': detail.balance.outstandingMinor,
      'outstandingFormatted':
          _fmt(detail.balance.outstandingMinor, debt.currency),
      'settled': detail.balance.settled,
      if (installment != null) ...{
        'nextInstallmentAmountMinor': installment.amountMinor,
        'nextInstallmentAmountFormatted':
            _fmt(installment.amountMinor, installment.currency),
        'nextInstallmentDate':
            FinancialSnapshot.unixSeconds(installment.nextDate),
      },
      'count': history.length,
      'truncated': detail.ledger.length > history.length,
      // `note` only when the user opted in, same rule as a transaction's.
      'ledger': [
        for (final entry in history)
          _debtLedgerItem(entry, debt.currency, withNotes: withNotes),
      ],
    };
  }

  /// [currency] is the debt's: a ledger entry is always expressed in it.
  Map<String, Object?> _debtLedgerItem(
    DebtLedgerEntry entry,
    String currency, {
    required bool withNotes,
  }) =>
      <String, Object?>{
        'date': FinancialSnapshot.unixSeconds(entry.date),
        'kind': entry.kind.name,
        // Signed: + increased the debt, − reduced it — same convention the
        // domain entity itself documents, and the twin has to carry that sign
        // through or a payment would read as new borrowing.
        'effectMinor': entry.effectMinor,
        'effectFormatted': _fmt(entry.effectMinor, currency),
        if (withNotes && entry.note != null) 'note': entry.note,
      };

  // ---------------------------------------------------------------------
  // get_scheduled_payment_detail
  // ---------------------------------------------------------------------

  /// Lets the model look up ONE scheduled payment beyond what the snapshot's
  /// `upcoming` section can show — that section is capped to the next 30
  /// days and 25 rows (`BuildFinancialSnapshot.maxListRows`), so a payment
  /// further out, or pushed past the cap by a busy calendar, or whose past
  /// occurrences the model needs, has nothing to resolve against without
  /// this. Same structural gap `get_debt_detail` closed for debts.
  Future<Map<String, Object?>> _getScheduledPaymentDetailResult(
    Map<String, Object?> arguments,
  ) async {
    final id = _stringArg(arguments, 'scheduledPaymentId');
    if (id == null) {
      return _notFound('scheduledPaymentId is required');
    }

    final detail = await _once(
      _getScheduledPaymentDetail(id, historyPageSize: maxRows),
    );
    if (detail == null) {
      return _notFound('no scheduled payment with id "$id"');
    }

    final template = detail.scheduledPayment;
    final currency = template.currency;
    final linkedDebt = detail.linkedDebt;
    final linkedGoal = detail.linkedGoal;
    final history = detail.history.take(maxRows).toList();
    final withNotes = await _notesAccessEnabled();

    return <String, Object?>{
      'id': template.id,
      // Category AND account, same disambiguation rule as the snapshot's
      // `upcoming` section (dogfooding fix there: two payments sharing a
      // category were indistinguishable by name alone).
      'name': _categoryAccountName(detail.categoryName, detail.accountName),
      'type': template.type.name,
      'amountMinor': template.amountMinor,
      'amountFormatted': _fmt(template.amountMinor, currency),
      'currency': currency,
      'frequency': template.frequency.name,
      'nextDate': FinancialSnapshot.unixSeconds(detail.nextPaymentDate),
      'isActive': detail.isActive,
      // The template's own free text — the title the user sees on screen —
      // only when they opted in.
      if (withNotes && template.note != null) 'note': template.note,
      if (linkedDebt != null) ...{
        'linkedDebtId': linkedDebt.id,
        'linkedDebtName': linkedDebt.name,
      },
      if (linkedGoal != null) ...{
        'linkedGoalId': linkedGoal.id,
        'linkedGoalName': linkedGoal.name,
      },
      'historyTotalCount': detail.historyTotalCount,
      'generatedTransactionCount': detail.generatedTransactionCount,
      'count': history.length,
      'truncated': detail.history.length > history.length,
      // The history rows stay note-free even with the opt-in on: they are
      // generated occurrences of the template above, whose note already
      // travels, and a confirmed row's transaction note belongs to
      // `get_transactions`' scope, not this one.
      'history': [
        for (final entry in history) _scheduledHistoryItem(entry, currency),
      ],
    };
  }

  /// Category AND account, the one naming convention for a scheduled payment
  /// across every tool and the snapshot's `upcoming` section — a scheduled
  /// payment has no name column, and the category alone left two payments
  /// sharing it indistinguishable.
  String _categoryAccountName(String? categoryName, String accountName) {
    if (categoryName == null || categoryName.isEmpty) {
      return accountName;
    }
    return '$categoryName · $accountName';
  }

  Map<String, Object?> _scheduledHistoryItem(
    ScheduledHistoryEntry entry,
    String currency,
  ) =>
      switch (entry) {
        ScheduledConfirmedHistoryEntry(:final transaction) => <String, Object?>{
            'date': FinancialSnapshot.unixSeconds(transaction.date),
            'kind': 'confirmed',
            'amountMinor': transaction.amountMinor,
            'amountFormatted':
                _fmt(transaction.amountMinor, transaction.currency),
          },
        ScheduledSkippedHistoryEntry(:final date, :final amountMinor) =>
          <String, Object?>{
            'date': FinancialSnapshot.unixSeconds(date),
            'kind': 'skipped',
            'amountMinor': amountMinor,
            'amountFormatted': _fmt(amountMinor, currency),
          },
      };

  // ---------------------------------------------------------------------
  // find_scheduled_payments
  // ---------------------------------------------------------------------

  /// Turns a phrase the user typed ("el abono a capital de la KTM 1390") into
  /// the `id` that `get_scheduled_payment_detail` needs, **without the note
  /// leaving the device unless the user opted in**.
  ///
  /// The whole design lives in one line: with the opt-in off the note is read
  /// here, compared here, and dropped here, and every field that goes back is
  /// structured. Do not add a matched fragment, a snippet or any "why it
  /// matched" echo — an unconditional echo would hand the model exactly the
  /// free text this tool was built to keep local, opt-in or not; only the
  /// whole `note`, behind `aiNotesAccessEnabled`, ever goes back.
  ///
  /// Only ACTIVE templates are searched (`GetScheduledPayments` is HU-04's
  /// list); a finished one is absent, not inactive, so the answer says which
  /// scope it looked in rather than letting the model conclude it never
  /// existed.
  Future<Map<String, Object?>> _findScheduledPayments(
    Map<String, Object?> arguments,
  ) async {
    final query = _stringArg(arguments, 'query');
    if (query == null) {
      return _notFound(
        'query is required: the words the user used to name the payment',
      );
    }

    final summaries = await _once(_getScheduledPayments());
    if (summaries == null) {
      return _notFound('the scheduled payment list could not be read');
    }

    // In memory, not in SQL: the active list is small (it is the same list one
    // screen renders whole), and a new datasource query would spread the
    // note-matching rule across another layer.
    final needle = _searchKey(query);
    final matching = [
      for (final summary in summaries)
        if (_matchesQuery(summary, needle)) summary,
    ];

    final limit = _rowLimit(_intArg(arguments, 'limit'));
    final page = matching.take(limit).toList();
    final withNotes = await _notesAccessEnabled();

    return <String, Object?>{
      'query': query,
      'scope': 'active',
      'count': page.length,
      'truncated': matching.length > page.length,
      'items': [
        for (final summary in page)
          _scheduledPaymentItem(summary, withNotes: withNotes),
      ],
    };
  }

  /// Matches the note plus the two names that already travel to the model
  /// anyway (category, account), which costs nothing in privacy and catches
  /// "el pago de Bancolombia" as readily as a phrase from the note.
  bool _matchesQuery(ScheduledPaymentSummary summary, String needle) {
    if (needle.isEmpty) {
      return false;
    }
    final note = summary.scheduledPayment.note;
    return (note != null && _searchKey(note).contains(needle)) ||
        _searchKey(summary.categoryName ?? '').contains(needle) ||
        _searchKey(summary.accountName).contains(needle);
  }

  /// `note` only when the user opted in: see the class doc.
  Map<String, Object?> _scheduledPaymentItem(
    ScheduledPaymentSummary summary, {
    required bool withNotes,
  }) {
    final template = summary.scheduledPayment;
    return <String, Object?>{
      'id': template.id,
      'name': _categoryAccountName(summary.categoryName, summary.accountName),
      'amountMinor': template.amountMinor,
      'amountFormatted': _fmt(template.amountMinor, template.currency),
      'currency': template.currency,
      'type': template.type.name,
      'nextDate': FinancialSnapshot.unixSeconds(summary.nextPaymentDate),
      'frequency': template.frequency.name,
      // Free, not asserted: the source stream only carries active templates.
      'isActive': true,
      if (withNotes && template.note != null) 'note': template.note,
    };
  }

  /// Comparison key for the on-device search: lowercase and unaccented, so
  /// "credito hipotecario" finds a note that reads "Crédito Hipotecario".
  /// Spanish keyboards on mobile drop tildes constantly and a model echoing
  /// the user drops them too.
  String _searchKey(String value) {
    final buffer = StringBuffer();
    for (final char in value.toLowerCase().split('')) {
      buffer.write(_unaccented[char] ?? char);
    }
    return buffer.toString().trim();
  }

  /// `ñ` is folded to `n` on purpose: this is a search key, not display text,
  /// and "montañismo"/"montanismo" must land on the same row.
  static const Map<String, String> _unaccented = <String, String>{
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };

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

  /// The one place an amount becomes text, mirroring
  /// `BuildFinancialSnapshot._fmt`. [currency] is always the row's own, and
  /// `formatSymbol` keeps a negative's sign after the symbol (`$-2.000.000`),
  /// which is the convention the whole app reads — a delta that lost its sign
  /// would turn an overspend into a saving.
  String _fmt(int minor, String currency) =>
      _money.formatSymbol(minor, currencyCode: currency);

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

  /// Whether the user opted into letting the assistant read their free-text
  /// notes (`AppSettings.aiNotesAccessEnabled`).
  ///
  /// Read fresh per tool call — the switch can be flipped mid-conversation and
  /// the next read must obey it, not a value cached at construction.
  ///
  /// **`false` on every failure path**, and that direction is not negotiable:
  /// [_once] already collapses a `Left`, a timeout and a throwing source into
  /// `null`, and `null` means "we do not know", which here can only mean "do
  /// not send". Defaulting the other way would leak notes precisely when the
  /// device is in a state we failed to read.
  Future<bool> _notesAccessEnabled() async =>
      (await _once(_getAppSettings()))?.aiNotesAccessEnabled ?? false;

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
