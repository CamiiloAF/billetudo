import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account.dart' show AccountType;
import '../../../budgets/domain/entities/budget.dart' show BudgetPeriod;
import '../../../scheduled_payments/domain/entities/scheduled_payment.dart'
    show ScheduledPaymentType;

/// One active account, reduced to what a model can reason about.
///
/// `last4` and `institution` are absent by construction, not by filtering:
/// they are the two fields that would turn an aggregate into an identifiable
/// banking profile, and nothing here is allowed to carry them off-device.
class SnapshotAccount extends Equatable {
  const SnapshotAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balanceMinor,
  });

  /// The id the model must echo back verbatim in a proposal. Inventing one is
  /// what the tool descriptions forbid; sending them is what makes obeying
  /// possible.
  final String id;

  final String name;
  final AccountType type;
  final String currency;

  /// Cents of [currency]. For a card this is its balance, negative when owed.
  final int balanceMinor;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'type': type.name,
        'currency': currency,
        'balanceMinor': balanceMinor,
      };

  @override
  List<Object?> get props => [id, name, type, currency, balanceMinor];
}

/// Net worth and card debt for a single currency. Never summed with another
/// currency's — there is no base currency in this data model.
class SnapshotCurrencyTotal extends Equatable {
  const SnapshotCurrencyTotal({
    required this.currency,
    required this.netWorthMinor,
    required this.debtMinor,
  });

  final String currency;

  /// Cards excluded entirely: a card neither adds as an asset nor nets in as
  /// a liability here, same rule as `AccountsOverview`.
  final int netWorthMinor;

  /// Card debt in this currency, as a positive figure.
  final int debtMinor;

  Map<String, Object?> toJson() => <String, Object?>{
        'currency': currency,
        'netWorthMinor': netWorthMinor,
        'debtMinor': debtMinor,
      };

  @override
  List<Object?> get props => [currency, netWorthMinor, debtMinor];
}

/// One root category's spend over the snapshot's period.
class SnapshotCategoryLine extends Equatable {
  const SnapshotCategoryLine({
    required this.name,
    required this.amountMinor,
    required this.movementCount,
    this.categoryId,
  });

  /// `null` for the "sin categoría" bucket, which only ever holds
  /// debt-linked movements. A proposal must never echo a null id back.
  final String? categoryId;

  final String name;
  final int amountMinor;
  final int movementCount;

  Map<String, Object?> toJson() => <String, Object?>{
        if (categoryId != null) 'categoryId': categoryId,
        'name': name,
        'amountMinor': amountMinor,
        'movementCount': movementCount,
      };

  @override
  List<Object?> get props => [categoryId, name, amountMinor, movementCount];
}

/// One month of the cash-flow series.
class SnapshotCashflowPoint extends Equatable {
  const SnapshotCashflowPoint({
    required this.periodStart,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  /// First day of the month the point covers.
  final DateTime periodStart;

  /// Debt movements included, matching the report's default: hiding them
  /// would make the net stop matching the account balances above.
  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;

  Map<String, Object?> toJson() => <String, Object?>{
        'periodStart': FinancialSnapshot.unixSeconds(periodStart),
        'incomeMinor': incomeMinor,
        'expenseMinor': expenseMinor,
        'netMinor': netMinor,
      };

  @override
  List<Object?> get props => [periodStart, incomeMinor, expenseMinor];
}

/// An active budget with its current-period progress.
class SnapshotBudget extends Equatable {
  const SnapshotBudget({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.spentMinor,
    required this.currency,
    required this.period,
    required this.periodStart,
    required this.periodEndExclusive,
  });

  final String id;
  final String name;
  final int amountMinor;
  final int spentMinor;
  final String currency;
  final BudgetPeriod period;
  final DateTime periodStart;
  final DateTime periodEndExclusive;

  /// Negative when overspent — the model is told the sign means exactly that,
  /// so it never has to guess from an absolute value.
  int get remainingMinor => amountMinor - spentMinor;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'amountMinor': amountMinor,
        'spentMinor': spentMinor,
        'remainingMinor': remainingMinor,
        'currency': currency,
        'period': period.name,
        'periodStart': FinancialSnapshot.unixSeconds(periodStart),
        'periodEnd': FinancialSnapshot.unixSeconds(periodEndExclusive),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        amountMinor,
        spentMinor,
        currency,
        period,
        periodStart,
        periodEndExclusive,
      ];
}

/// An active savings goal with its derived progress.
class SnapshotGoal extends Equatable {
  const SnapshotGoal({
    required this.id,
    required this.name,
    required this.targetMinor,
    required this.savedMinor,
    required this.currency,
    this.targetDate,
  });

  final String id;
  final String name;
  final int targetMinor;
  final int savedMinor;
  final String currency;
  final DateTime? targetDate;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'targetMinor': targetMinor,
        'savedMinor': savedMinor,
        'currency': currency,
        if (targetDate != null)
          'targetDate': FinancialSnapshot.unixSeconds(targetDate!),
      };

  @override
  List<Object?> get props =>
      [id, name, targetMinor, savedMinor, currency, targetDate];
}

/// Outstanding debt for a single currency, both directions.
class SnapshotDebtTotal extends Equatable {
  const SnapshotDebtTotal({
    required this.currency,
    required this.iOweMinor,
    required this.owedToMeMinor,
  });

  final String currency;
  final int iOweMinor;
  final int owedToMeMinor;

  Map<String, Object?> toJson() => <String, Object?>{
        'currency': currency,
        'iOweMinor': iOweMinor,
        'owedToMeMinor': owedToMeMinor,
      };

  @override
  List<Object?> get props => [currency, iOweMinor, owedToMeMinor];
}

/// A scheduled payment due inside the look-ahead window.
///
/// [name] is the payment's category (falling back to its account), never its
/// `note`: that field is the user's own free text and free text does not leave
/// the device.
class SnapshotUpcoming extends Equatable {
  const SnapshotUpcoming({
    required this.scheduledPaymentId,
    required this.name,
    required this.date,
    required this.amountMinor,
    required this.currency,
    required this.type,
  });

  final String scheduledPaymentId;
  final String name;
  final DateTime date;
  final int amountMinor;
  final String currency;
  final ScheduledPaymentType type;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': scheduledPaymentId,
        'name': name,
        'date': FinancialSnapshot.unixSeconds(date),
        'amountMinor': amountMinor,
        'currency': currency,
        'type': type.name,
      };

  @override
  List<Object?> get props =>
      [scheduledPaymentId, name, date, amountMinor, currency, type];
}

/// The "modo sobres" figures for one reference currency.
class SnapshotZeroBased extends Equatable {
  const SnapshotZeroBased({
    required this.currency,
    required this.incomeMinor,
    required this.assignedMinor,
  });

  final String currency;
  final int incomeMinor;
  final int assignedMinor;

  /// May be negative (over-assigned). Guidance, never a blocker — the prompt
  /// relies on that framing to keep the tone non-punitive.
  int get unassignedMinor => incomeMinor - assignedMinor;

  Map<String, Object?> toJson() => <String, Object?>{
        'currency': currency,
        'incomeMinor': incomeMinor,
        'assignedMinor': assignedMinor,
        'unassignedMinor': unassignedMinor,
      };

  @override
  List<Object?> get props => [currency, incomeMinor, assignedMinor];
}

/// How many rows exist behind the lists above.
///
/// Every list in the snapshot is capped; without these the model cannot tell
/// "you have three accounts" from "here are three of your accounts".
class SnapshotCounts extends Equatable {
  const SnapshotCounts({
    required this.accounts,
    required this.budgets,
    required this.goals,
    required this.debts,
    required this.upcoming,
  });

  final int accounts;
  final int budgets;
  final int goals;
  final int debts;
  final int upcoming;

  Map<String, Object?> toJson() => <String, Object?>{
        'accounts': accounts,
        'budgets': budgets,
        'goals': goals,
        'debts': debts,
        'upcoming': upcoming,
      };

  @override
  List<Object?> get props => [accounts, budgets, goals, debts, upcoming];
}

/// The aggregated picture of the user's finances that travels with every turn.
///
/// Four rules govern [toJson], and all four exist to stop a confident lie:
///
///  1. **Every figure is an integer of minor units with its `currency` next to
///     it.** No `double` ever reaches the wire; a model that sees `4500.5`
///     will happily reason with it.
///  2. **Nothing is aggregated across currencies.** The data model is
///     multi-currency per row and there is no base currency, so a COP+USD
///     total would be an invented number. Sections that cannot be
///     currency-segmented today are simply omitted when the user holds more
///     than one currency (see `BuildFinancialSnapshot`).
///  3. **Dates are unix timestamps in SECONDS**, matching the tool schemas.
///     Milliseconds would silently land the model ~50 000 years in the future.
///  4. **A section that could not be read is OMITTED, never emitted empty.**
///     Telling a model `budgets: []` asserts that the user has no budgets;
///     telling it nothing leaves it with nothing to say about them. The first
///     produces a fabricated "no tienes presupuestos", the second does not.
///
/// Also absent by construction: `last4`, `institution`, and transaction notes.
class FinancialSnapshot extends Equatable {
  const FinancialSnapshot({
    required this.generatedAt,
    required this.periodStart,
    required this.periodEndExclusive,
    this.accounts,
    this.currencyTotals,
    this.spendingByCategory,
    this.spendingCurrency,
    this.spendingTotalMinor,
    this.cashflow,
    this.cashflowCurrency,
    this.budgets,
    this.goals,
    this.debtTotals,
    this.upcoming,
    this.zeroBased,
    this.counts,
  });

  /// Unix seconds — the unit every date in this payload and in the tool
  /// schemas uses.
  static int unixSeconds(DateTime date) =>
      date.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;

  final DateTime generatedAt;

  /// The window [spendingByCategory] covers: the current calendar month.
  final DateTime periodStart;
  final DateTime periodEndExclusive;

  final List<SnapshotAccount>? accounts;
  final List<SnapshotCurrencyTotal>? currencyTotals;

  /// Expense grouped by root category over `[periodStart, periodEndExclusive)`.
  final List<SnapshotCategoryLine>? spendingByCategory;

  /// The single currency [spendingByCategory] and [spendingTotalMinor] are
  /// expressed in. Both are omitted together when it cannot be established.
  final String? spendingCurrency;

  final int? spendingTotalMinor;

  /// Monthly income/expense for the last six months, oldest first.
  final List<SnapshotCashflowPoint>? cashflow;

  /// Same single-currency guarantee as [spendingCurrency], for [cashflow].
  final String? cashflowCurrency;

  final List<SnapshotBudget>? budgets;
  final List<SnapshotGoal>? goals;
  final List<SnapshotDebtTotal>? debtTotals;
  final List<SnapshotUpcoming>? upcoming;
  final SnapshotZeroBased? zeroBased;
  final SnapshotCounts? counts;

  /// The wire shape. Every `if (x != null)` below is rule 4, not defensive
  /// coding: dropping the key is the whole point.
  Map<String, Object?> toJson() => <String, Object?>{
        'generatedAt': unixSeconds(generatedAt),
        'periodStart': unixSeconds(periodStart),
        'periodEnd': unixSeconds(periodEndExclusive),
        if (accounts != null)
          'accounts': [for (final account in accounts!) account.toJson()],
        if (currencyTotals != null)
          'currencyTotals': [for (final total in currencyTotals!) total.toJson()],
        if (spendingByCategory != null && spendingCurrency != null)
          'spendingByCategory': <String, Object?>{
            'currency': spendingCurrency,
            'totalMinor': spendingTotalMinor ?? 0,
            'items': [for (final line in spendingByCategory!) line.toJson()],
          },
        if (cashflow != null && cashflowCurrency != null)
          'cashflow': <String, Object?>{
            'currency': cashflowCurrency,
            'granularity': 'monthly',
            'points': [for (final point in cashflow!) point.toJson()],
          },
        if (budgets != null)
          'budgets': [for (final budget in budgets!) budget.toJson()],
        if (goals != null) 'goals': [for (final goal in goals!) goal.toJson()],
        if (debtTotals != null)
          'debtTotals': [for (final total in debtTotals!) total.toJson()],
        if (upcoming != null)
          'upcoming': [for (final item in upcoming!) item.toJson()],
        if (zeroBased != null) 'zeroBased': zeroBased!.toJson(),
        if (counts != null) 'counts': counts!.toJson(),
      };

  /// True when nothing but the header could be read. The turn is still worth
  /// sending — the model can say it cannot see the data — but the caller may
  /// prefer to surface a local error instead.
  bool get isEmpty => toJson().length <= 3;

  @override
  List<Object?> get props => [
        generatedAt,
        periodStart,
        periodEndExclusive,
        accounts,
        currencyTotals,
        spendingByCategory,
        spendingCurrency,
        spendingTotalMinor,
        cashflow,
        cashflowCurrency,
        budgets,
        goals,
        debtTotals,
        upcoming,
        zeroBased,
        counts,
      ];
}
