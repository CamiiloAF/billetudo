import 'package:equatable/equatable.dart';

/// What the user would lose by deleting an account (HU-08). Shown before
/// confirming, in neutral terms — never as a scolding.
class AccountDeletionImpact extends Equatable {
  const AccountDeletionImpact({
    required this.transactionCount,
    required this.goalCount,
    required this.debtCount,
    required this.isLastAccount,
  });

  /// Active transactions that belong to the account, on either side of a
  /// transfer.
  final int transactionCount;

  /// Active goals tied to the account.
  final int goalCount;

  /// Distinct active debts touched by the account's transactions.
  final int debtCount;

  /// Whether this is the only active account left: the app always needs one to
  /// record on, so deleting is blocked (HU-08).
  final bool isLastAccount;

  bool get hasImpact => transactionCount > 0 || goalCount > 0 || debtCount > 0;

  @override
  List<Object?> get props => [
        transactionCount,
        goalCount,
        debtCount,
        isLastAccount,
      ];
}
