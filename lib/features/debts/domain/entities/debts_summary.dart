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

/// The debts list plus its per-currency totals (HU-04). Built by `from` so the
/// totals are always consistent with the list they summarize.
class DebtsSummary extends Equatable {
  const DebtsSummary({required this.debts, required this.totals});

  static const DebtsSummary empty =
      DebtsSummary(debts: [], totals: []);

  final List<DebtWithBalance> debts;

  /// One entry per currency present in [debts], ordered by currency code for a
  /// stable UI.
  final List<DebtCurrencyTotal> totals;

  factory DebtsSummary.from(List<DebtWithBalance> debts) {
    final iOwe = <String, int>{};
    final owed = <String, int>{};

    for (final item in debts) {
      final currency = item.debt.currency;
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

    return DebtsSummary(debts: debts, totals: totals);
  }

  @override
  List<Object?> get props => [debts, totals];
}
