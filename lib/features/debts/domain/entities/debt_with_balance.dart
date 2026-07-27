import 'package:equatable/equatable.dart';

import 'debt.dart';
import 'debt_balance.dart';
import 'debt_installment.dart';

/// A [Debt] paired with its derived [DebtBalance], for the debts list (HU-04).
class DebtWithBalance extends Equatable {
  const DebtWithBalance({
    required this.debt,
    required this.balance,
    this.installment,
  });

  final Debt debt;
  final DebtBalance balance;

  /// The scheduled payment linked to this debt as its cuota, or `null` when the
  /// debt has none configured (HU-03). Drives the "Cuota · <fecha>" badge on
  /// the card (`xSpw7`); the "Vence …" line is shown instead when the debt has
  /// a `dueDate` but no cuota.
  final DebtInstallment? installment;

  @override
  List<Object?> get props => [debt, balance, installment];
}
