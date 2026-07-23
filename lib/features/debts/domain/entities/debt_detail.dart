import 'package:equatable/equatable.dart';

import 'debt.dart';
import 'debt_balance.dart';
import 'debt_installment.dart';
import 'debt_ledger_entry.dart';

/// Everything the debt detail screen needs (HU-04): the debt, its derived
/// balance/progress, its unified newest-first history, and the linked cuota
/// when one is configured (HU-03).
class DebtDetail extends Equatable {
  const DebtDetail({
    required this.debt,
    required this.balance,
    required this.ledger,
    this.installment,
  });

  final Debt debt;
  final DebtBalance balance;
  final List<DebtLedgerEntry> ledger;

  /// The scheduled payment linked to this debt as its cuota, or `null` when the
  /// debt has none configured (HU-03).
  final DebtInstallment? installment;

  @override
  List<Object?> get props => [debt, balance, ledger, installment];
}
