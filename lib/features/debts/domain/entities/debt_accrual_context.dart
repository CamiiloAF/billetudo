import 'package:equatable/equatable.dart';

import 'debt.dart';

/// The one-shot snapshot `AccrueInterest` needs to post an interest entry: the
/// debt, its current raw outstanding balance (the base interest accrues on),
/// and the date interest was last accrued to (so the day-count starts there).
class DebtAccrualContext extends Equatable {
  const DebtAccrualContext({
    required this.debt,
    required this.rawOutstandingMinor,
    this.lastAccrualDate,
  });

  final Debt debt;

  /// Raw (possibly-negative) outstanding — interest compounds on the real
  /// figure, so it uses the unclamped value.
  final int rawOutstandingMinor;

  /// The `entryDate` of the newest `interestAccrual` entry, or null when the
  /// debt has never accrued — the caller falls back to the debt's creation
  /// date.
  final DateTime? lastAccrualDate;

  @override
  List<Object?> get props => [debt, rawOutstandingMinor, lastAccrualDate];
}
