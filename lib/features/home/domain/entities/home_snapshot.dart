import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../budgets/domain/entities/budget_with_progress.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import 'month_spending.dart';

/// Everything the Home renders (HU-03/HU-05): the hero's spending total for
/// the selected month, and the recent-activity feed.
///
/// The two are **not** derived from the same source: [spending] stays scoped
/// to the given month (or to the featured budget's own period window, chosen
/// by the caller), while [recentActivity] is a literal activity feed with no
/// month/period bound of its own — see `WatchRecentTransactions` and the
/// `recentTransactions` parameter of [HomeSnapshot.from]. Both still filter
/// down to the set of active [accounts].
///
/// Pure aggregation lives here (a `from` factory), so it is unit-testable
/// without a cubit, a repository or Flutter.
class HomeSnapshot extends Equatable {
  const HomeSnapshot({
    required this.spending,
    required this.recentActivity,
    required this.accounts,
    this.budgetProgress,
  });

  final MonthSpending spending;

  /// The active accounts with their balances (HU-01), in the repository's
  /// order. Feeds the "Mis cuentas" balance strip (bugfix item 8); kept as the
  /// full list because the strip scrolls horizontally rather than capping.
  final List<AccountWithBalance> accounts;

  /// The most recent movements of active accounts (HU-05): a literal activity
  /// feed — income, expense **and** transfer — ordered newest first and capped
  /// at [recentActivityLimit]. Unlike [spending], it applies no expense-only
  /// exclusion, and (per [HomeSnapshot.from]'s `recentTransactions` param) no
  /// month/period filter either — it is deliberately decoupled from whatever
  /// period the hero is navigating.
  final List<TransactionWithDetails> recentActivity;

  /// The active global (no account/category scope) monthly budget's progress
  /// for the viewed month (HU-03, `aOhoY`), or `null` when none qualifies —
  /// reuses `budgets/domain`'s own entity instead of duplicating it, same
  /// pattern as depending on `accounts`/`transactions`. This is an independent
  /// input (not derived from the transactions/accounts aggregation), passed
  /// straight through by the caller.
  final BudgetWithProgress? budgetProgress;

  /// How many rows the recent feed shows (HU-05: "~5 filas").
  static const int recentActivityLimit = 5;

  /// The welcome/empty state (HU-08): no movements at all this month. A month
  /// with only transfers is **not** empty (there is activity), even though its
  /// [spending] is `$0`.
  bool get isEmpty => recentActivity.isEmpty;

  factory HomeSnapshot.from({
    required DateTime month,
    required Iterable<TransactionWithDetails> transactions,
    required Iterable<AccountWithBalance> accounts,
    BudgetWithProgress? budgetProgress,
    String fallbackCurrency = 'COP',
    // The unbound source for `recentActivity` (`WatchRecentTransactions`,
    // HU-05): when omitted, [transactions] is reused so a caller that has not
    // migrated yet keeps its previous (month-scoped) behavior — the decoupling
    // only takes effect once a caller actually supplies this.
    Iterable<TransactionWithDetails>? recentTransactions,
  }) {
    final accountList = accounts.toList();
    final activeAccountIds = {
      for (final entry in accountList) entry.account.id,
    };

    // The hero's currency, when the month has no expenses, follows the active
    // accounts so a `$0` still reads in the user's money.
    final currency = accountList.isNotEmpty
        ? accountList.first.account.currency
        : fallbackCurrency;

    final recent = (recentTransactions ?? transactions)
        .where(
            (entry) => activeAccountIds.contains(entry.transaction.accountId))
        .toList()
      ..sort((a, b) => b.transaction.date.compareTo(a.transaction.date));

    return HomeSnapshot(
      spending: MonthSpending.from(
        month: month,
        transactions: transactions,
        activeAccountIds: activeAccountIds,
        fallbackCurrency: currency,
      ),
      recentActivity: recent.take(recentActivityLimit).toList(),
      accounts: accountList,
      budgetProgress: budgetProgress,
    );
  }

  @override
  List<Object?> get props =>
      [spending, recentActivity, accounts, budgetProgress];
}
