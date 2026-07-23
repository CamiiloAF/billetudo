import 'package:equatable/equatable.dart';

import 'debt.dart';
import 'debt_balance.dart';

/// A [Debt] paired with its derived [DebtBalance], for the debts list (HU-04).
class DebtWithBalance extends Equatable {
  const DebtWithBalance({required this.debt, required this.balance});

  final Debt debt;
  final DebtBalance balance;

  @override
  List<Object?> get props => [debt, balance];
}
