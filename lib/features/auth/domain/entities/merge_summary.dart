import 'package:equatable/equatable.dart';

/// What got folded into the account on first sign-in (HU-04): how many rows
/// of each kind were already sitting on this device before the user ever
/// created an account. Shown on the "Tus datos están a salvo" screen.
class MergeSummary extends Equatable {
  const MergeSummary({
    required this.accountsCount,
    required this.transactionsCount,
    required this.categoriesCount,
  });

  final int accountsCount;
  final int transactionsCount;
  final int categoriesCount;

  /// Whether there was anything local to fold in. A brand-new user with no
  /// local data yet would otherwise see a hollow "0/0/0" confirmation.
  bool get hasLocalData =>
      accountsCount > 0 || transactionsCount > 0 || categoriesCount > 0;

  @override
  List<Object?> get props =>
      [accountsCount, transactionsCount, categoriesCount];
}
