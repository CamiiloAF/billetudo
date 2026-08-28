import '../../../../accounts/domain/entities/account.dart';
import '../../../../accounts/domain/entities/account_with_balance.dart';

/// One currency's accounts and pre-computed total (`CurrencyGroup.from`),
/// used by `BalancesSheet`. Pure aggregation, unit-testable without Flutter.
class CurrencyGroup {
  const CurrencyGroup({
    required this.currency,
    required this.entries,
    required this.totalMinor,
    required this.excludesSomething,
  });

  final String currency;
  final List<AccountWithBalance> entries;

  /// `TU DINERO`: cash + bank + savings + other. Excludes card (borrowed
  /// money, not the user's own) and investment (theirs, but not liquid).
  final int totalMinor;

  /// Whether at least one account in this group is a card or an investment
  /// — only then does the "no incluye tarjetas ni inversiones" note draw.
  final bool excludesSomething;

  static List<CurrencyGroup> from(List<AccountWithBalance> accounts) {
    final byCurrency = <String, List<AccountWithBalance>>{};
    for (final entry in accounts) {
      byCurrency.putIfAbsent(entry.account.currency, () => []).add(entry);
    }
    final currencies = byCurrency.keys.toList()..sort();
    return [
      for (final currency in currencies)
        _build(currency, byCurrency[currency]!),
    ];
  }

  static CurrencyGroup _build(
    String currency,
    List<AccountWithBalance> entries,
  ) {
    var total = 0;
    var excludesSomething = false;
    for (final entry in entries) {
      final type = entry.account.type;
      if (type == AccountType.card || type == AccountType.investment) {
        excludesSomething = true;
        continue;
      }
      total += entry.balance.balanceMinor;
    }
    return CurrencyGroup(
      currency: currency,
      entries: entries,
      totalMinor: total,
      excludesSomething: excludesSomething,
    );
  }
}
