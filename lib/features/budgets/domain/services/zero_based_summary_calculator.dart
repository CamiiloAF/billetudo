import 'package:injectable/injectable.dart';

import '../entities/budget.dart';
import '../entities/period_income.dart';
import '../entities/zero_based_summary.dart';

/// Computes the "Modo sobres" summary (HU-06) deterministically and locally:
/// **income of the current calendar month − total assigned = unassigned**.
///
/// Money never crosses currencies. A single reference currency is picked (the
/// one most active budgets share; falling back to the month's income), and both
/// income and assignment are summed only for that currency. Returns `null` when
/// there is nothing to show (no active budget and no income this month), so the
/// UI can hide the hero rather than render a currency-less zero.
@lazySingleton
class ZeroBasedSummaryCalculator {
  const ZeroBasedSummaryCalculator();

  ZeroBasedSummary? summarize({
    required List<Budget> activeBudgets,
    required List<PeriodIncome> income,
    required DateTime now,
  }) {
    final monthStart = DateTime(now.year, now.month);
    final nextMonthStart = DateTime(now.year, now.month + 1);
    final monthlyIncome = [
      for (final entry in income)
        if (!entry.date.isBefore(monthStart) &&
            entry.date.isBefore(nextMonthStart))
          entry,
    ];

    final currency = _referenceCurrency(activeBudgets, monthlyIncome);
    if (currency == null) {
      return null;
    }

    final assignedMinor = activeBudgets
        .where((budget) => budget.currency == currency)
        .fold<int>(0, (sum, budget) => sum + budget.amountMinor);
    final incomeMinor = monthlyIncome
        .where((entry) => entry.currency == currency)
        .fold<int>(0, (sum, entry) => sum + entry.amountMinor);

    return ZeroBasedSummary(
      currency: currency,
      incomeMinor: incomeMinor,
      assignedMinor: assignedMinor,
    );
  }

  /// The currency the hero is expressed in: the one most active budgets share,
  /// else the one most of this month's income arrived in. Ties break by ISO
  /// code so the result is stable. `null` when there is neither budget nor
  /// income.
  String? _referenceCurrency(
    List<Budget> activeBudgets,
    List<PeriodIncome> monthlyIncome,
  ) {
    final byBudget = _mostFrequent(
      activeBudgets.map((budget) => budget.currency),
    );
    if (byBudget != null) {
      return byBudget;
    }
    return _mostFrequent(monthlyIncome.map((entry) => entry.currency));
  }

  String? _mostFrequent(Iterable<String> currencies) {
    final counts = <String, int>{};
    for (final currency in currencies) {
      counts[currency] = (counts[currency] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return null;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return entries.first.key;
  }
}
