import 'package:equatable/equatable.dart';

import 'account_with_balance.dart';

/// Net worth and debt for a single currency. Both figures are cents of
/// [currency]; they are never mixed with another currency's.
class CurrencySubtotal extends Equatable {
  const CurrencySubtotal({
    required this.currency,
    required this.netWorthMinor,
    required this.debtMinor,
  });

  final String currency;

  /// Sum of the balances of the active accounts in this currency, **excluding
  /// credit cards entirely**: a card neither adds to net worth as an asset nor
  /// nets it down as a liability here. Its debt is reported separately, in
  /// [debtMinor].
  final int netWorthMinor;

  /// Sum of the debts of the cards in this currency, as a positive figure.
  final int debtMinor;

  bool get hasDebt => debtMinor > 0;

  @override
  List<Object?> get props => [currency, netWorthMinor, debtMinor];
}

/// Aggregate behind the Total Card.
///
/// There is deliberately **no** cross-currency total: adding COP to USD would
/// be a made-up number. With a single currency there is one subtotal (shown as
/// "the" total); with several, the UI shows one subtotal per currency. The
/// conversion rules live in `docs/requirements/12-multi-moneda.md`.
class AccountsOverview extends Equatable {
  const AccountsOverview(this.subtotals);

  /// Builds the subtotals from the active accounts, one per currency, ordered
  /// by currency code so the UI is stable across emissions.
  factory AccountsOverview.from(Iterable<AccountWithBalance> accounts) {
    final netWorthByCurrency = <String, int>{};
    final debtByCurrency = <String, int>{};

    for (final entry in accounts) {
      final currency = entry.account.currency;
      // A credit card is excluded from net worth altogether — it neither adds
      // as an asset nor nets in as debt there; its debt is only ever reported
      // through the separate `debtByCurrency` sub-total below.
      if (!entry.account.isCard) {
        netWorthByCurrency.update(
          currency,
          (value) => value + entry.balance.balanceMinor,
          ifAbsent: () => entry.balance.balanceMinor,
        );
      } else {
        final debtMinor = entry.balance.debtMinor;
        debtByCurrency.update(
          currency,
          (value) => value + debtMinor,
          ifAbsent: () => debtMinor,
        );
      }
    }

    final currencies =
        {...netWorthByCurrency.keys, ...debtByCurrency.keys}.toList()..sort();
    return AccountsOverview([
      for (final currency in currencies)
        CurrencySubtotal(
          currency: currency,
          netWorthMinor: netWorthByCurrency[currency] ?? 0,
          debtMinor: debtByCurrency[currency] ?? 0,
        ),
    ]);
  }

  final List<CurrencySubtotal> subtotals;

  bool get isEmpty => subtotals.isEmpty;

  /// True when every active account shares one currency: the UI can show a
  /// single net worth figure.
  bool get isSingleCurrency => subtotals.length == 1;

  /// The only subtotal, or `null` when there are none or several currencies.
  CurrencySubtotal? get singleCurrencySubtotal =>
      isSingleCurrency ? subtotals.first : null;

  @override
  List<Object?> get props => [subtotals];
}
