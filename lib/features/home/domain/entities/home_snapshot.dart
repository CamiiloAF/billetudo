import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account_with_balance.dart';
import '../../../transactions/domain/entities/transaction_with_details.dart';
import 'month_spending.dart';

/// Everything the Home renders for the selected month (HU-03/HU-05): the hero's
/// spending total and the recent-activity feed, both derived from the same
/// month of transactions plus the set of active accounts.
///
/// Pure aggregation lives here (a `from` factory), so it is unit-testable
/// without a cubit, a repository or Flutter.
class HomeSnapshot extends Equatable {
  const HomeSnapshot({required this.spending, required this.recentActivity});

  final MonthSpending spending;

  /// The most recent movements of active accounts (HU-05): a literal activity
  /// feed — income, expense **and** transfer — ordered newest first and capped
  /// at [recentActivityLimit]. Unlike [spending], it applies no expense-only
  /// exclusion.
  final List<TransactionWithDetails> recentActivity;

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
    String fallbackCurrency = 'COP',
  }) {
    final activeAccountIds = {
      for (final entry in accounts) entry.account.id,
    };

    // The hero's currency, when the month has no expenses, follows the active
    // accounts so a `$0` still reads in the user's money.
    final currency =
        accounts.isNotEmpty ? accounts.first.account.currency : fallbackCurrency;

    final recent = transactions
        .where((entry) => activeAccountIds.contains(entry.transaction.accountId))
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
    );
  }

  @override
  List<Object?> get props => [spending, recentActivity];
}
