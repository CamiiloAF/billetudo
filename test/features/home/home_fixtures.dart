import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
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

/// A global-monthly [BudgetWithProgress] (the only profile Home's hero cares
/// about — see `WatchGlobalMonthlyBudgetProgress`), so Home tests only state
/// the amount/spend they care about.
BudgetWithProgress buildHomeBudgetProgress({
  String id = 'budget-1',
  String name = 'Presupuesto general',
  int amountMinor = 600000,
  int spentMinor = 300000,
  String currency = 'COP',
  int daysLeft = 12,
  DateTime? createdAt,
}) =>
    BudgetWithProgress(
      budget: Budget(
        id: id,
        name: name,
        amountMinor: amountMinor,
        currency: currency,
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 7, 1),
        recurring: true,
        rollover: false,
        createdAt: createdAt ?? DateTime(2026, 7, 1),
        updatedAt: 0,
      ),
      scope: const BudgetScope.empty(),
      window: BudgetPeriodWindow(
        start: DateTime(2026, 7, 1),
        endExclusive: DateTime(2026, 8, 1),
        index: 0,
        status: BudgetWindowStatus.current,
        hasPrevious: false,
        hasNext: true,
      ),
      progress: BudgetProgress(
        amountMinor: amountMinor,
        spentMinor: spentMinor,
        daysLeft: daysLeft,
      ),
    );
