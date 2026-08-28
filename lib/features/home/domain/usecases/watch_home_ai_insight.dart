import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../transactions/domain/entities/date_period_filter.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_filter.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../entities/home_ai_insight.dart';
import '../entities/month_spending.dart';

/// Resolves the insight the AI card shows in its "with insight" variant
/// (`design-system/billetudo/pages/inicio.md` § "Card de IA"), or `null` when
/// none applies — in which case the card falls back to its "with chips"
/// variant instead (criterion 10, decided in the presentation layer, not
/// here).
///
/// `hasAnyBudget` `false` forces [HomeAiInsight.createBudget] unconditionally
/// — the "Sin presupuesto (nunca creó uno)" hero state always wins, per the
/// spec's "sin ningún insight forzado" contrast with "con presupuestos,
/// ninguno destacado" (row 64 of the states table), which instead falls
/// through to the normal queue below.
///
/// The normal queue has two candidates, in this order:
///  1. [HomeAiInsightType.budgetProjectionRisk], when `featuredBudget` is in
///     `HomeHeroState.scheduledOverspendRisk` (its own
///     `BudgetProgress.isScheduledOverspendRisk`).
///  2. [HomeAiInsightType.spendingVsAverage], when the trailing 3 full
///     calendar months (before `month`) each have at least one expense to
///     compare against — "no requiere 3 meses de historia" is explicitly
///     called out as unique to `createBudget`, implying every other insight
///     kind does.
///
/// The first candidate is emitted; [HomeAiInsight.queueLength] carries how
/// many are waiting so the card's "1 de N" counter can render (criterion 10).
@injectable
class WatchHomeAiInsight {
  const WatchHomeAiInsight(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  /// Minimum absolute deviation from the trailing average, as a whole
  /// percent, before it is worth surfacing as an insight — a 2% wobble is
  /// noise, not something the user needs an insight to notice.
  static const int _minPercentDeltaToSurface = 15;

  Stream<Result<HomeAiInsight?>> call({
    required DateTime month,
    required MonthSpending spending,
    required bool hasAnyBudget,
    BudgetWithProgress? featuredBudget,
  }) {
    if (!hasAnyBudget) {
      return Stream.value(const Right(HomeAiInsight.createBudget()));
    }

    final monthStart = DateTime(month.year, month.month);
    final historyStart = DateTime(monthStart.year, monthStart.month - 3);
    // Inclusive last day of the month right before [monthStart].
    final historyEndInclusive =
        DateTime(monthStart.year, monthStart.month, 0);

    return _transactionRepository
        .watchTransactions(
          TransactionFilter(
            datePeriod: DatePeriodFilter.custom(
              start: historyStart,
              end: historyEndInclusive,
            ),
          ),
        )
        .map(
          (result) => result.map(
            (history) => _resolve(
              monthStart: monthStart,
              historyStart: historyStart,
              spending: spending,
              history: history,
              featuredBudget: featuredBudget,
            ),
          ),
        );
  }

  HomeAiInsight? _resolve({
    required DateTime monthStart,
    required DateTime historyStart,
    required MonthSpending spending,
    required List<TransactionWithDetails> history,
    required BudgetWithProgress? featuredBudget,
  }) {
    final candidates = <HomeAiInsight>[];

    final progress = featuredBudget?.progress;
    if (progress != null && progress.isScheduledOverspendRisk) {
      candidates.add(
        HomeAiInsight(
          type: HomeAiInsightType.budgetProjectionRisk,
          overageMinor: progress.scheduledOverageMinor,
          currency: featuredBudget!.budget.currency,
        ),
      );
    }

    final average = _trailingAverageExpenseMinor(
      historyStart: historyStart,
      monthStart: monthStart,
      history: history,
      currency: spending.displayCurrency,
    );
    if (average != null && average > 0) {
      final current = spending.displayTotalMinor;
      final deltaPercent = (((current - average) / average) * 100).round();
      if (deltaPercent.abs() >= _minPercentDeltaToSurface) {
        candidates.add(
          HomeAiInsight(
            type: HomeAiInsightType.spendingVsAverage,
            percentDelta: deltaPercent,
            currency: spending.displayCurrency,
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    final first = candidates.first;
    return HomeAiInsight(
      type: first.type,
      percentDelta: first.percentDelta,
      overageMinor: first.overageMinor,
      currency: first.currency,
      queueLength: candidates.length,
    );
  }

  /// Average monthly expense (in [currency], same `expense`/no-`debtId`
  /// exclusion `MonthSpending` applies) across the 3 full calendar months in
  /// `[historyStart, monthStart)`. Unlike `MonthSpending`, this does **not**
  /// restrict to currently-active accounts — a deliberate simplification: a
  /// trailing average is about the user's overall spending pattern, and an
  /// account archived last week should not silently erase the months it was
  /// still active in from the comparison. Returns `null` when any of the 3
  /// months has zero qualifying expense — "no history yet" for that month, so
  /// the comparison would be misleading.
  int? _trailingAverageExpenseMinor({
    required DateTime historyStart,
    required DateTime monthStart,
    required List<TransactionWithDetails> history,
    required String currency,
  }) {
    final totalsByMonth = <DateTime, int>{
      for (var i = 1; i <= 3; i++)
        DateTime(monthStart.year, monthStart.month - i): 0,
    };

    for (final entry in history) {
      final tx = entry.transaction;
      final counts = tx.type == TransactionType.expense &&
          tx.debtId == null &&
          tx.currency == currency;
      if (!counts) {
        continue;
      }
      final bucket = DateTime(tx.date.year, tx.date.month);
      if (!totalsByMonth.containsKey(bucket)) {
        continue;
      }
      totalsByMonth[bucket] = totalsByMonth[bucket]! + tx.amountMinor;
    }

    if (totalsByMonth.values.any((total) => total <= 0)) {
      return null;
    }
    final sum = totalsByMonth.values.reduce((a, b) => a + b);
    return sum ~/ totalsByMonth.length;
  }
}
