import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';

/// Expense total for a single currency in a month (HU-03). Both figures are
/// cents; currencies are never mixed into a made-up cross-currency sum, same
/// rule as `AccountsOverview`.
class CurrencySpending extends Equatable {
  const CurrencySpending({required this.currency, required this.totalMinor});

  final String currency;

  /// Sum of the month's expenses in [currency], as a positive figure of cents.
  final int totalMinor;

  @override
  List<Object?> get props => [currency, totalMinor];
}

/// The hero's "Gastado en <mes>" figure (HU-03).
///
/// The total is built **only** from `expense` transactions of active accounts,
/// excluding `transfer` (never an expense) and any movement tied to a debt
/// (`debtId != null`) — coherent with `10-graficas-informes.md`. Money stays an
/// integer of cents throughout; there is no `double`.
class MonthSpending extends Equatable {
  const MonthSpending({
    required this.month,
    required this.subtotals,
    required this.displayCurrency,
  });

  /// The month this total belongs to (first day, at midnight).
  final DateTime month;

  /// One subtotal per currency with expenses, ordered by currency code so the
  /// UI is stable across emissions. Empty when the month has no expenses.
  final List<CurrencySpending> subtotals;

  /// The currency the hero shows: the one with the largest total, or the
  /// `fallbackCurrency` when there are no expenses yet.
  final String displayCurrency;

  /// Builds the per-currency expense totals from [transactions], keeping only
  /// the ones that count as real spending (see class docs) and belong to an
  /// account in [activeAccountIds]. [fallbackCurrency] is used only to show a
  /// `$0` hero when there are no expenses.
  factory MonthSpending.from({
    required DateTime month,
    required Iterable<TransactionWithDetails> transactions,
    required Set<String> activeAccountIds,
    required String fallbackCurrency,
  }) {
    final totalByCurrency = <String, int>{};
    for (final entry in transactions) {
      final tx = entry.transaction;
      final counts = tx.type == TransactionType.expense &&
          tx.debtId == null &&
          activeAccountIds.contains(tx.accountId);
      if (!counts) {
        continue;
      }
      totalByCurrency.update(
        tx.currency,
        (value) => value + tx.amountMinor,
        ifAbsent: () => tx.amountMinor,
      );
    }

    final currencies = totalByCurrency.keys.toList()..sort();
    final subtotals = [
      for (final currency in currencies)
        CurrencySpending(
          currency: currency,
          totalMinor: totalByCurrency[currency] ?? 0,
        ),
    ];

    // The dominant currency (largest total) leads the hero; ties break by the
    // already-sorted code so the pick is deterministic.
    String displayCurrency = fallbackCurrency;
    var max = -1;
    for (final subtotal in subtotals) {
      if (subtotal.totalMinor > max) {
        max = subtotal.totalMinor;
        displayCurrency = subtotal.currency;
      }
    }

    return MonthSpending(
      month: DateTime(month.year, month.month),
      subtotals: subtotals,
      displayCurrency: displayCurrency,
    );
  }

  bool get hasExpenses => subtotals.isNotEmpty;

  /// The amount shown in the hero, in [displayCurrency]. `0` when there are no
  /// expenses this month.
  int get displayTotalMinor {
    for (final subtotal in subtotals) {
      if (subtotal.currency == displayCurrency) {
        return subtotal.totalMinor;
      }
    }
    return 0;
  }

  @override
  List<Object?> get props => [month, subtotals, displayCurrency];
}
