import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../domain/entities/transaction_with_details.dart';

/// One date group of the `Movimientos` list (`B3GGa`/`xAk6Y`): the day every
/// one of [items] shares.
class TransactionDateGroup {
  TransactionDateGroup(this.date, this.items);

  final DateTime date;
  final List<TransactionWithDetails> items;
}

/// Groups [items] — already ordered by the repository — into consecutive
/// same-day runs, so a single linear pass is enough (HU-06). Pure data, no
/// widgets, so it is testable without pulling in the app's DI graph.
List<TransactionDateGroup> groupTransactionsByDate(
  List<TransactionWithDetails> items,
) {
  final groups = <TransactionDateGroup>[];
  for (final entry in items) {
    final day = DateUtils.dateOnly(entry.transaction.date);
    final current = groups.isEmpty ? null : groups.last;
    if (current != null && DateUtils.isSameDay(current.date, day)) {
      current.items.add(entry);
    } else {
      groups.add(TransactionDateGroup(day, [entry]));
    }
  }
  return groups;
}

/// "Hoy"/"Ayer"/the formatted date — [date] is already stripped to midnight.
String transactionGroupLabel(AppLocalizations l10n, DateTime date) {
  final today = DateUtils.dateOnly(DateTime.now());
  if (DateUtils.isSameDay(date, today)) {
    return l10n.transactionsGroupToday;
  }
  if (DateUtils.isSameDay(date, today.subtract(const Duration(days: 1)))) {
    return l10n.transactionsGroupYesterday;
  }
  return DateFormat("d 'de' MMMM", 'es_CO').format(date);
}
