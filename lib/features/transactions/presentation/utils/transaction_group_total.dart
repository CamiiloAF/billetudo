import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_with_details.dart';

/// A date group's summed amount, when it can be shown as a single figure:
/// every item shares [currency] (there is no correct cross-currency sum, same
/// rule as `accounts_overview.dart`'s "no hay total cross-currency") and
/// [type] (guaranteed by [transactionGroupTotalFor]'s exclusive-type-filter
/// gate, never computed on a mixed-type group).
class TransactionGroupTotal {
  const TransactionGroupTotal({
    required this.amountMinor,
    required this.currency,
    required this.type,
  });

  final int amountMinor;
  final String currency;
  final TransactionType type;
}

/// Sums [items]' `amountMinor`, or returns `null` when [items] is empty or
/// mixes currencies. Pure and currency-agnostic — the exclusive-type check
/// lives in [transactionGroupTotalFor], the caller that knows about the
/// active filter.
TransactionGroupTotal? sumTransactionGroup(
  List<TransactionWithDetails> items,
) {
  if (items.isEmpty) {
    return null;
  }
  final currency = items.first.transaction.currency;
  final type = items.first.transaction.type;
  var total = 0;
  for (final entry in items) {
    if (entry.transaction.currency != currency) {
      return null;
    }
    total += entry.transaction.amountMinor;
  }
  return TransactionGroupTotal(
    amountMinor: total,
    currency: currency,
    type: type,
  );
}

/// Whether [items] should show a date group's total instead of its count
/// (bugfix #11): only when [filter] narrows the list to *exclusively*
/// `income` or *exclusively* `expense` — never for "all types", a
/// multi-type selection, or `transfer` (which never shows a total) — and
/// only when every item in [items] actually shares one currency.
///
/// Returns `null` whenever the count must be shown instead, so callers can
/// treat a non-null result as "safe to sum and format".
TransactionGroupTotal? transactionGroupTotalFor(
  TransactionFilter filter,
  List<TransactionWithDetails> items,
) {
  if (filter.types.length != 1) {
    return null;
  }
  final onlyType = filter.types.single;
  if (onlyType == TransactionType.transfer) {
    return null;
  }
  return sumTransactionGroup(items);
}
