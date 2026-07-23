import 'package:equatable/equatable.dart';

import 'debt.dart';
import 'debt_balance.dart';
import 'debt_ledger_entry.dart';

/// Everything the debt detail screen needs (HU-04): the debt, its derived
/// balance/progress, and its unified newest-first history.
class DebtDetail extends Equatable {
  const DebtDetail({
    required this.debt,
    required this.balance,
    required this.ledger,
  });

  final Debt debt;
  final DebtBalance balance;
  final List<DebtLedgerEntry> ledger;

  @override
  List<Object?> get props => [debt, balance, ledger];
}
