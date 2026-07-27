import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/transaction_filter.dart';

/// The label for a single `Sort Menu` option/the Sort Button's tooltip
/// (`xXWi0`/`dbTXb`), one per [TransactionSortOrder] value.
String transactionSortOptionLabel(
  AppLocalizations l10n,
  TransactionSortOrder order,
) =>
    switch (order) {
      TransactionSortOrder.dateDesc => l10n.transactionsSortDateDesc,
      TransactionSortOrder.dateAsc => l10n.transactionsSortDateAsc,
      TransactionSortOrder.amountDesc => l10n.transactionsSortAmountDesc,
      TransactionSortOrder.amountAsc => l10n.transactionsSortAmountAsc,
    };

/// Whether [order] is anything other than the untouched default
/// (`TransactionSortOrder.dateDesc`) — the Sort Button only switches to its
/// active look, and the Sort Label only appears above the list, once this is
/// true (HU-06/`tigaH`/`Q8gSaB`).
bool transactionSortIsActive(TransactionSortOrder order) =>
    order != TransactionSortOrder.dateDesc;

/// Whether [order] sorts by amount rather than by date — this is the case
/// where the list drops its date headers and renders as a flat run of `Rows`
/// (`tigaH`/`Q8gSaB`).
bool transactionSortIsByAmount(TransactionSortOrder order) =>
    order == TransactionSortOrder.amountDesc ||
    order == TransactionSortOrder.amountAsc;

/// The "Ordenado por monto"/"Ordenado por fecha" label shown above the list
/// while [order] is active, or `null` while it is still the untouched
/// default and no label should render.
String? transactionSortActiveLabel(
  AppLocalizations l10n,
  TransactionSortOrder order,
) {
  if (!transactionSortIsActive(order)) {
    return null;
  }
  return transactionSortIsByAmount(order)
      ? l10n.transactionsSortActiveByAmount
      : l10n.transactionsSortActiveByDate;
}
