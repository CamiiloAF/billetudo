import 'dart:math' as math;

import 'package:injectable/injectable.dart';

import '../entities/debt_payoff_projection.dart';

/// Pure domain service for the **automatic** interest mode (HU-06, Fase 0
/// opcional). Simple daily interest, compounded: the day's interest is added to
/// the balance and the next day's larger balance earns more. Between two events
/// this is the closed form
///
///   balance × (1 + rate/365)^days
///
/// where `rate = interestRateBps / 10000` (annual). Every figure returned is an
/// integer of cents; the rate math is fractional (a rate is not money) and the
/// result is rounded once, half away from zero, at the end. All of it is
/// "estimado" — see the doc.
@lazySingleton
class DebtInterestCalculator {
  const DebtInterestCalculator();

  static const int _bpsPerUnit = 10000;
  static const int _daysPerYear = 365;

  /// The interest accrued on [balanceMinor] over [days] at annual [rateBps],
  /// compounded daily. Returns 0 for a non-positive balance, rate or day count
  /// (nothing accrues, and the debt never goes up from interest alone below 0).
  int accruedInterestMinor({
    required int balanceMinor,
    required int rateBps,
    required int days,
  }) {
    if (balanceMinor <= 0 || rateBps <= 0 || days <= 0) return 0;
    return projectedBalanceMinor(
          balanceMinor: balanceMinor,
          rateBps: rateBps,
          days: days,
        ) -
        balanceMinor;
  }

  /// The balance after [days] of compounding: `balance × (1 + rate/365)^days`,
  /// rounded to whole cents. Returns [balanceMinor] unchanged when nothing can
  /// accrue.
  int projectedBalanceMinor({
    required int balanceMinor,
    required int rateBps,
    required int days,
  }) {
    if (balanceMinor <= 0 || rateBps <= 0 || days <= 0) return balanceMinor;
    final dailyRate = rateBps / _bpsPerUnit / _daysPerYear;
    final factor = math.pow(1 + dailyRate, days).toDouble();
    return (balanceMinor * factor).round();
  }

  /// Projects how long a fixed [installmentMinor] at a fixed [rateBps] takes to
  /// clear [balanceMinor], starting at [from] (HU-06). Simulates the same daily
  /// model forward, one calendar month per installment: accrue the month's
  /// interest, then subtract the installment (trimming the last one to the
  /// remaining balance).
  ///
  /// Returns `null` when the debt never pays off — the installment does not
  /// even cover the first month's interest — or when the caller passes a
  /// non-positive balance/installment. Capped at [maxInstallments] so a barely
  /// converging schedule cannot loop forever; hitting the cap returns `null`.
  ///
  /// A closed-form French amortization is deliberately not used: projecting IS
  /// running `(interés − cuota)` forward, so one model serves both.
  DebtPayoffProjection? projectPayoff({
    required int balanceMinor,
    required int rateBps,
    required int installmentMinor,
    required DateTime from,
    int maxInstallments = 600,
  }) {
    if (balanceMinor <= 0 || installmentMinor <= 0) return null;

    var balance = balanceMinor;
    var totalInterest = 0;
    var totalPaid = 0;
    var count = 0;
    var date = from;

    while (balance > 0 && count < maxInstallments) {
      final nextDate = _addMonth(date);
      final days = nextDate.difference(date).inDays;
      final interest = accruedInterestMinor(
        balanceMinor: balance,
        rateBps: rateBps,
        days: days,
      );
      balance += interest;
      totalInterest += interest;

      // The installment cannot cover even the interest: the debt grows every
      // period and never clears.
      if (installmentMinor <= interest && count == 0) return null;

      final payment = math.min(installmentMinor, balance);
      balance -= payment;
      totalPaid += payment;
      count++;
      date = nextDate;
    }

    if (balance > 0) return null; // hit the cap without clearing.

    return DebtPayoffProjection(
      installmentCount: count,
      payoffDate: date,
      totalInterestMinor: totalInterest,
      totalPaidMinor: totalPaid,
    );
  }

  /// Same calendar day one month on, clamped to the month's last day
  /// (e.g. Jan 31 -> Feb 28). Keeps the day-count between installments honest.
  DateTime _addMonth(DateTime date) {
    final year = date.month == 12 ? date.year + 1 : date.year;
    final month = date.month == 12 ? 1 : date.month + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = math.min(date.day, lastDay);
    return DateTime(year, month, day);
  }
}
