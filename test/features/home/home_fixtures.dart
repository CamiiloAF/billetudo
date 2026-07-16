import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';

import '../accounts/account_fixtures.dart' as accounts;
import '../transactions/transaction_fixtures.dart' as transactions;

/// A [TransactionWithDetails] built from the shared [transactions] builder, so
/// Home tests only state the fields they care about.
TransactionWithDetails buildActivity({
  String id = 'tx-1',
  String accountId = 'acc-1',
  String accountName = 'Bancolombia',
  String? categoryId,
  String? categoryName,
  int amountMinor = 10000,
  String currency = 'COP',
  TransactionType type = TransactionType.expense,
  DateTime? date,
  String? debtId,
}) =>
    TransactionWithDetails(
      transaction: transactions.buildTransaction(
        id: id,
        accountId: accountId,
        categoryId: categoryId,
        amountMinor: amountMinor,
        currency: currency,
        type: type,
        date: date,
        debtId: debtId,
      ),
      accountName: accountName,
      categoryName: categoryName,
    );

AccountWithBalance buildActiveAccount({
  String id = 'acc-1',
  String currency = 'COP',
  int balanceMinor = 100000,
}) =>
    accounts.buildAccountWithBalance(
      account: accounts.buildAccount(id: id, currency: currency),
      balanceMinor: balanceMinor,
    );

Account buildAccount({String id = 'acc-1', String currency = 'COP'}) =>
    accounts.buildAccount(id: id, currency: currency);
