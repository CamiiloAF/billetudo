import 'package:equatable/equatable.dart';

import 'account.dart';
import 'account_balance.dart';

/// An account together with its derived balance: what every list and detail
/// view consumes. Pairing them avoids recomputing the balance in presentation.
class AccountWithBalance extends Equatable {
  const AccountWithBalance({required this.account, required this.balance});

  final Account account;
  final AccountBalance balance;

  @override
  List<Object?> get props => [account, balance];
}
