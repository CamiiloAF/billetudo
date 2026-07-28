import 'package:injectable/injectable.dart';

import '../entities/goal_with_progress.dart';

/// A goal's derived progress plus the two account facts
/// `GoalCoherenceCalculator` needs, without leaking Drift/Accounts types into
/// this feature's domain.
class GoalAccountFact {
  const GoalAccountFact({
    required this.goal,
    required this.accountBalanceMinor,
    required this.accountCurrency,
    required this.accountName,
  });

  final GoalWithProgress goal;
  final int accountBalanceMinor;
  final String accountCurrency;
  final String accountName;
}

/// Pure domain service implementing HU-12: for every account with active
/// (non-archived) goals linked, whether the sum of their `savedMinor`
/// exceeds the account's real balance. Purely informative — this never
/// blocks anything, it only produces a signal for the UI to show.
@lazySingleton
class GoalCoherenceCalculator {
  const GoalCoherenceCalculator();

  /// [facts] must already exclude archived and trashed goals, and goals with
  /// no linked account (HU-12: "no se calcula... para metas sin cuenta
  /// vinculada ni para metas archivadas").
  Map<String, GoalCoherenceSignal> calculate(List<GoalAccountFact> facts) {
    final totalsByAccount = <String, int>{};
    final balanceByAccount = <String, int>{};
    final currencyByAccount = <String, String>{};
    final nameByAccount = <String, String>{};

    for (final fact in facts) {
      final accountId = fact.goal.goal.accountId;
      if (accountId == null) {
        continue;
      }
      totalsByAccount[accountId] =
          (totalsByAccount[accountId] ?? 0) + fact.goal.savedMinor;
      balanceByAccount[accountId] = fact.accountBalanceMinor;
      currencyByAccount[accountId] = fact.accountCurrency;
      nameByAccount[accountId] = fact.accountName;
    }

    final signals = <String, GoalCoherenceSignal>{};
    for (final entry in totalsByAccount.entries) {
      final accountId = entry.key;
      final total = entry.value;
      final balance = balanceByAccount[accountId] ?? 0;
      if (total > balance) {
        signals[accountId] = GoalCoherenceSignal(
          accountId: accountId,
          accountName: nameByAccount[accountId]!,
          totalSavedMinor: total,
          accountBalanceMinor: balance,
          currency: currencyByAccount[accountId]!,
        );
      }
    }
    return signals;
  }
}
