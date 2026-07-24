import 'package:equatable/equatable.dart';

import 'debt.dart';
import 'debt_with_balance.dart';

/// Outstanding totals for one currency (HU-04). In Fase 0 totals are segmented
/// by currency — never normalized to a base (see `12-multi-moneda.md`).
class DebtCurrencyTotal extends Equatable {
  const DebtCurrencyTotal({
    required this.currency,
    required this.iOweOutstandingMinor,
    required this.owedToMeOutstandingMinor,
  });

  final String currency;

  /// Total still owed by the user in this currency (clamped, never negative).
  final int iOweOutstandingMinor;

  /// Total still owed to the user in this currency.
  final int owedToMeOutstandingMinor;

  @override
  List<Object?> get props =>
      [currency, iOweOutstandingMinor, owedToMeOutstandingMinor];
}

/// Totals for the "Cerradas" tab (extension, HU-07): not what remains owed
/// (frozen, mostly uninteresting once closed) but what the closed debts moved
/// in total — "Pagué" for `iOwe`, "Me pagaron" for `owedToMe`. Segmented by
/// currency, same Fase 0 rule as [DebtCurrencyTotal].
class DebtClosedCurrencyTotal extends Equatable {
  const DebtClosedCurrencyTotal({
    required this.currency,
    required this.iOwePaidMinor,
    required this.owedToMeCollectedMinor,
  });

  final String currency;

  /// Total paid off across every closed `iOwe` debt in this currency.
  final int iOwePaidMinor;

  /// Total collected across every closed `owedToMe` debt in this currency.
  final int owedToMeCollectedMinor;

  @override
  List<Object?> get props => [currency, iOwePaidMinor, owedToMeCollectedMinor];
}

/// The debts list plus its per-currency totals (HU-04). Built by `from` so the
/// totals are always consistent with the list they summarize.
///
/// [debts] carries every non-trashed debt, open and closed alike (the tab
/// split, extension HU-07, is presentation-only filtering); [totals] and
/// [closedTotals] are each pre-filtered to their own tab so neither leaks a
/// closed debt's frozen balance into the "Activas" summary or vice versa.
class DebtsSummary extends Equatable {
  const DebtsSummary({
    required this.debts,
    required this.totals,
    required this.closedTotals,
  });

  static const DebtsSummary empty =
      DebtsSummary(debts: [], totals: [], closedTotals: []);

  final List<DebtWithBalance> debts;

  /// One entry per currency present among the **open** debts, ordered by
  /// currency code for a stable UI.
  final List<DebtCurrencyTotal> totals;

  /// One entry per currency present among the **closed** debts (extension,
  /// HU-07), ordered by currency code.
  final List<DebtClosedCurrencyTotal> closedTotals;

  /// Debts still open (`closedAt == null`) — the "Activas" tab.
  List<DebtWithBalance> get openDebts =>
      debts.where((item) => !item.debt.isClosed).toList();

  /// Debts the user closed (extension, HU-07) — the "Cerradas" tab.
  List<DebtWithBalance> get closedDebts =>
      debts.where((item) => item.debt.isClosed).toList();

  factory DebtsSummary.from(List<DebtWithBalance> debts) {
    final iOwe = <String, int>{};
    final owed = <String, int>{};
    final iOwePaid = <String, int>{};
    final owedCollected = <String, int>{};

    for (final item in debts) {
      final currency = item.debt.currency;
      if (item.debt.isClosed) {
        final paid = item.balance.totalDecreasesMinor;
        if (item.debt.direction == DebtDirection.iOwe) {
          iOwePaid[currency] = (iOwePaid[currency] ?? 0) + paid;
        } else {
          owedCollected[currency] = (owedCollected[currency] ?? 0) + paid;
        }
        continue;
      }
      final outstanding = item.balance.outstandingMinor;
      if (item.debt.direction == DebtDirection.iOwe) {
        iOwe[currency] = (iOwe[currency] ?? 0) + outstanding;
      } else {
        owed[currency] = (owed[currency] ?? 0) + outstanding;
      }
    }

    final currencies = <String>{...iOwe.keys, ...owed.keys}.toList()..sort();
    final totals = currencies
        .map(
          (currency) => DebtCurrencyTotal(
            currency: currency,
            iOweOutstandingMinor: iOwe[currency] ?? 0,
            owedToMeOutstandingMinor: owed[currency] ?? 0,
          ),
        )
        .toList();

    final closedCurrencies =
        <String>{...iOwePaid.keys, ...owedCollected.keys}.toList()..sort();
    final closedTotals = closedCurrencies
        .map(
          (currency) => DebtClosedCurrencyTotal(
            currency: currency,
            iOwePaidMinor: iOwePaid[currency] ?? 0,
            owedToMeCollectedMinor: owedCollected[currency] ?? 0,
          ),
        )
        .toList();

    return DebtsSummary(
      debts: debts,
      totals: totals,
      closedTotals: closedTotals,
    );
  }

  @override
  List<Object?> get props => [debts, totals, closedTotals];
}
