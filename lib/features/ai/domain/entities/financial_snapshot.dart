import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/account.dart' show AccountType;
import '../../../budgets/domain/entities/budget.dart' show BudgetPeriod;
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../debts/domain/entities/debt.dart' show DebtDirection;
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
    required this.balanceFormatted,
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

  /// See [SnapshotBudget.amountFormatted]: every amount in this snapshot
  /// carries its pre-formatted twin, and the prompt tells the model so.
  final String balanceFormatted;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'type': type.name,
        'currency': currency,
        'balanceMinor': balanceMinor,
        'balanceFormatted': balanceFormatted,
      };

  @override
  List<Object?> get props =>
      [id, name, type, currency, balanceMinor, balanceFormatted];
}

/// Net worth and card debt for a single currency. Never summed with another
/// currency's — there is no base currency in this data model.
class SnapshotCurrencyTotal extends Equatable {
  const SnapshotCurrencyTotal({
    required this.currency,
    required this.netWorthMinor,
    required this.debtMinor,
    required this.netWorthFormatted,
    required this.debtFormatted,
  });

  final String currency;

  /// Cards excluded entirely: a card neither adds as an asset nor nets in as
  /// a liability here, same rule as `AccountsOverview`.
  final int netWorthMinor;

  /// Card debt in this currency, as a positive figure.
  final int debtMinor;

  /// See [SnapshotBudget.amountFormatted]. [netWorthFormatted] may read
  /// negative; the sign is kept, never dropped.
  final String netWorthFormatted;
  final String debtFormatted;

  Map<String, Object?> toJson() => <String, Object?>{
        'currency': currency,
        'netWorthMinor': netWorthMinor,
        'netWorthFormatted': netWorthFormatted,
        'debtMinor': debtMinor,
        'debtFormatted': debtFormatted,
      };

  @override
  List<Object?> get props => [
        currency,
        netWorthMinor,
        debtMinor,
        netWorthFormatted,
        debtFormatted,
      ];
}

/// One root category's spend over the snapshot's period.
class SnapshotCategoryLine extends Equatable {
  const SnapshotCategoryLine({
    required this.name,
    required this.amountMinor,
    required this.amountFormatted,
    required this.movementCount,
    this.categoryId,
  });

  /// `null` for the "sin categoría" bucket, which only ever holds
  /// debt-linked movements. A proposal must never echo a null id back.
  final String? categoryId;

  final String name;
  final int amountMinor;

  /// See [SnapshotBudget.amountFormatted]. Formatted in the enclosing
  /// section's `spendingCurrency` — this section only ships single-currency.
  final String amountFormatted;

  final int movementCount;

  Map<String, Object?> toJson() => <String, Object?>{
        if (categoryId != null) 'categoryId': categoryId,
        'name': name,
        'amountMinor': amountMinor,
        'amountFormatted': amountFormatted,
        'movementCount': movementCount,
      };

  @override
  List<Object?> get props => [
        categoryId,
        name,
        amountMinor,
        amountFormatted,
        movementCount,
      ];
}

/// One category the person has, full stop — unlike [SnapshotCategoryLine],
/// this is not scoped to any spending period. Found live (issue tracker, AI
/// dogfooding): [FinancialSnapshot.spendingByCategory] was the model's ONLY
/// source of category ids, and it only lists categories with a movement in
/// the CURRENT period — a category used every month except this one (a debt
/// payment due outside the current cycle, say) was invisible, so the model
/// proposed creating a duplicate instead of reusing the real one. This list
/// exists so "does a category for X already exist" never depends on when it
/// was last used.
class SnapshotCategory extends Equatable {
  const SnapshotCategory({
    required this.categoryId,
    required this.name,
    required this.kind,
    this.parentId,
  });

  /// Named `categoryId`, not `id`, on purpose: the backend's
  /// `indexSnapshot` only recognises a category id under this exact key
  /// (`validate.ts`'s `SnapshotIndex.categoryIds`) — a plain `id` here would
  /// silently fall back to the type-blind set and reopen the bug above.
  final String categoryId;

  final String name;
  final CategoryKind kind;

  /// `null` for a root category. A subcategory's own [categoryId] is what a
  /// proposal must use — parent-only bookkeeping is not something the model
  /// needs to reason about here.
  final String? parentId;

  Map<String, Object?> toJson() => <String, Object?>{
        'categoryId': categoryId,
        'name': name,
        'kind': kind.name,
        if (parentId != null) 'parentId': parentId,
      };

  @override
  List<Object?> get props => [categoryId, name, kind, parentId];
}

/// One month of the cash-flow series.
class SnapshotCashflowPoint extends Equatable {
  const SnapshotCashflowPoint({
    required this.periodStart,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.incomeFormatted,
    required this.expenseFormatted,
    required this.netFormatted,
  });

  /// First day of the month the point covers.
  final DateTime periodStart;

  /// Debt movements included, matching the report's default: hiding them
  /// would make the net stop matching the account balances above.
  final int incomeMinor;
  final int expenseMinor;

  /// See [SnapshotBudget.amountFormatted]. Formatted in the enclosing
  /// section's `cashflowCurrency`.
  final String incomeFormatted;
  final String expenseFormatted;

  /// [netMinor] formatted. Negative months keep their sign — a month that
  /// spent more than it earned must not read as a surplus.
  final String netFormatted;

  int get netMinor => incomeMinor - expenseMinor;

  Map<String, Object?> toJson() => <String, Object?>{
        'periodStart': FinancialSnapshot.unixSeconds(periodStart),
        'incomeMinor': incomeMinor,
        'incomeFormatted': incomeFormatted,
        'expenseMinor': expenseMinor,
        'expenseFormatted': expenseFormatted,
        'netMinor': netMinor,
        'netFormatted': netFormatted,
      };

  @override
  List<Object?> get props => [
        periodStart,
        incomeMinor,
        expenseMinor,
        incomeFormatted,
        expenseFormatted,
        netFormatted,
      ];
}

/// An active budget with its current-period progress.
///
/// [scheduledMinor] is what makes overspend-RISK questions answerable at all
/// (dogfooding bug: the assistant used to only see [spentMinor] against
/// [amountMinor], so a budget that was fine on real spend but had a big
/// scheduled payment still ahead in the window read as "you're fine" — the
/// exact case that prompted this field). It is the same number
/// `BudgetProgress.scheduledMinor` already computes and the Home
/// "riesgo de sobregiro proyectado" insight already shows; this section must
/// never re-derive it.
class SnapshotBudget extends Equatable {
  const SnapshotBudget({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.spentMinor,
    required this.scheduledMinor,
    required this.currency,
    required this.period,
    required this.periodStart,
    required this.periodEndExclusive,
    required this.amountFormatted,
    required this.spentFormatted,
    required this.remainingFormatted,
    required this.scheduledFormatted,
    required this.projectedTotalFormatted,
  });

  final String id;
  final String name;
  final int amountMinor;
  final int spentMinor;

  /// Projected but not-yet-materialized scheduled-payment expense still
  /// inside the window — `BudgetProgress.scheduledMinor` verbatim. `0` when
  /// there is none, never omitted (unlike the section itself, a per-row `0`
  /// is a real fact, not a missing read).
  final int scheduledMinor;

  final String currency;
  final BudgetPeriod period;
  final DateTime periodStart;
  final DateTime periodEndExclusive;

  /// Pre-formatted "$1.234.567"-style strings, in the app's own
  /// `MoneyFormatter` convention — the same one every screen renders with.
  /// Every amount in this snapshot carries one: dividing `amountMinor` by 100
  /// in its head is exactly the arithmetic step a model gets wrong under
  /// load (confirmed live: a 730.000 COP scheduled payment read back as
  /// 73.000.000). Quoting these instead of the raw integer turns that into a
  /// lookup instead of mental math.
  final String amountFormatted;
  final String spentFormatted;
  final String remainingFormatted;
  final String scheduledFormatted;

  /// [spentMinor] + [scheduledMinor], formatted — "if every scheduled payment
  /// still due in this window actually happens, this is the running total"
  /// (`BudgetProgress.committedFraction`'s numerator).
  final String projectedTotalFormatted;

  /// Negative when overspent — the model is told the sign means exactly that,
  /// so it never has to guess from an absolute value.
  int get remainingMinor => amountMinor - spentMinor;

  /// `spentMinor + scheduledMinor` — the projected running total if every
  /// scheduled payment still due in the window actually happens.
  int get projectedTotalMinor => spentMinor + scheduledMinor;

  /// True exactly when `BudgetProgress.isScheduledOverspendRisk` would be:
  /// real spend has not crossed the budget yet, but spend + what is still
  /// scheduled would. This is the flag a "will I go over?" question must
  /// check — [spentMinor] alone cannot answer it.
  bool get isProjectedOverspendRisk =>
      spentMinor <= amountMinor && projectedTotalMinor > amountMinor;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'amountMinor': amountMinor,
        'amountFormatted': amountFormatted,
        'spentMinor': spentMinor,
        'spentFormatted': spentFormatted,
        'remainingMinor': remainingMinor,
        'remainingFormatted': remainingFormatted,
        'scheduledMinor': scheduledMinor,
        'scheduledFormatted': scheduledFormatted,
        'projectedTotalMinor': projectedTotalMinor,
        'projectedTotalFormatted': projectedTotalFormatted,
        'isProjectedOverspendRisk': isProjectedOverspendRisk,
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
        scheduledMinor,
        currency,
        period,
        periodStart,
        periodEndExclusive,
        amountFormatted,
        spentFormatted,
        remainingFormatted,
        scheduledFormatted,
        projectedTotalFormatted,
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
    required this.targetFormatted,
    required this.savedFormatted,
    this.targetDate,
  });

  final String id;
  final String name;
  final int targetMinor;
  final int savedMinor;
  final String currency;

  /// See [SnapshotBudget.amountFormatted].
  final String targetFormatted;
  final String savedFormatted;

  final DateTime? targetDate;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'targetMinor': targetMinor,
        'targetFormatted': targetFormatted,
        'savedMinor': savedMinor,
        'savedFormatted': savedFormatted,
        'currency': currency,
        if (targetDate != null)
          'targetDate': FinancialSnapshot.unixSeconds(targetDate!),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        targetMinor,
        savedMinor,
        currency,
        targetFormatted,
        savedFormatted,
        targetDate,
      ];
}

/// Outstanding debt for a single currency, both directions.
class SnapshotDebtTotal extends Equatable {
  const SnapshotDebtTotal({
    required this.currency,
    required this.iOweMinor,
    required this.owedToMeMinor,
    required this.iOweFormatted,
    required this.owedToMeFormatted,
  });

  final String currency;
  final int iOweMinor;
  final int owedToMeMinor;

  /// See [SnapshotBudget.amountFormatted].
  final String iOweFormatted;
  final String owedToMeFormatted;

  Map<String, Object?> toJson() => <String, Object?>{
        'currency': currency,
        'iOweMinor': iOweMinor,
        'iOweFormatted': iOweFormatted,
        'owedToMeMinor': owedToMeMinor,
        'owedToMeFormatted': owedToMeFormatted,
      };

  @override
  List<Object?> get props => [
        currency,
        iOweMinor,
        owedToMeMinor,
        iOweFormatted,
        owedToMeFormatted,
      ];
}

/// One open debt, by name — added alongside [SnapshotDebtTotal] (dogfooding
/// bug: the aggregate-only total meant the model had no id/name to reason
/// about a SPECIFIC debt like "la KTM 1390" or "el crédito hipotecario",
/// only a blended currency total). [id] is what `get_debt_detail` takes.
class SnapshotDebt extends Equatable {
  const SnapshotDebt({
    required this.id,
    required this.name,
    required this.direction,
    required this.currency,
    required this.outstandingMinor,
    required this.outstandingFormatted,
    this.nextInstallmentAmountMinor,
    this.nextInstallmentAmountFormatted,
    this.nextInstallmentDate,
  });

  final String id;
  final String name;

  /// `iOwe`: the user owes this. `owedToMe`: someone owes the user.
  final DebtDirection direction;

  final String currency;
  final int outstandingMinor;
  final String outstandingFormatted;

  /// The linked scheduled payment's amount/date when this debt has a cuota
  /// configured (`DebtWithBalance.installment`) — e.g. the KTM 1390's own
  /// "abono a capital". `null` when the debt has none.
  final int? nextInstallmentAmountMinor;
  final String? nextInstallmentAmountFormatted;
  final DateTime? nextInstallmentDate;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'direction': direction.name,
        'currency': currency,
        'outstandingMinor': outstandingMinor,
        'outstandingFormatted': outstandingFormatted,
        if (nextInstallmentAmountMinor != null) ...{
          'nextInstallmentAmountMinor': nextInstallmentAmountMinor,
          'nextInstallmentAmountFormatted': nextInstallmentAmountFormatted,
          'nextInstallmentDate':
              FinancialSnapshot.unixSeconds(nextInstallmentDate!),
        },
      };

  @override
  List<Object?> get props => [
        id,
        name,
        direction,
        currency,
        outstandingMinor,
        outstandingFormatted,
        nextInstallmentAmountMinor,
        nextInstallmentAmountFormatted,
        nextInstallmentDate,
      ];
}

/// A scheduled payment due inside the look-ahead window.
///
/// [name] combines the payment's category AND account — never its `note`:
/// that field is the user's own free text and free text does not leave the
/// device. Category alone used to be the whole name (dogfooding bug: two
/// scheduled payments sharing one category, e.g. rent and a mortgage both
/// filed under "Vivienda", were indistinguishable to the model — it answered
/// about one while the user asked about the other). Combining both is not a
/// full guarantee when two payments also share an account, but it is the
/// strongest disambiguation available without crossing into free text.
class SnapshotUpcoming extends Equatable {
  const SnapshotUpcoming({
    required this.scheduledPaymentId,
    required this.name,
    required this.date,
    required this.amountMinor,
    required this.currency,
    required this.type,
    required this.amountFormatted,
    this.note,
  });

  final String scheduledPaymentId;
  final String name;
  final DateTime date;
  final int amountMinor;
  final String currency;
  final ScheduledPaymentType type;

  /// See `SnapshotBudget.amountFormatted` — same reasoning, same fix for the
  /// same live bug, just for this section's amount.
  final String amountFormatted;

  /// The scheduled payment's own free text, and the ONLY user-written text in
  /// the whole snapshot. Always `null` unless the person turned
  /// `AppSettings.aiNotesAccessEnabled` on: `BuildFinancialSnapshot` is what
  /// decides, and it falls back to omitting the note whenever the setting
  /// cannot be read.
  final String? note;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': scheduledPaymentId,
        'name': name,
        'date': FinancialSnapshot.unixSeconds(date),
        'amountMinor': amountMinor,
        'amountFormatted': amountFormatted,
        'currency': currency,
        'type': type.name,
        // Absent, never `null`: the key exists only when the note does and the
        // user allowed it.
        if (note != null) 'note': note,
      };

  @override
  List<Object?> get props => [
        scheduledPaymentId,
        name,
        date,
        amountMinor,
        currency,
        type,
        amountFormatted,
        note,
      ];
}

/// The "modo sobres" figures for one reference currency.
class SnapshotZeroBased extends Equatable {
  const SnapshotZeroBased({
    required this.currency,
    required this.incomeMinor,
    required this.assignedMinor,
    required this.incomeFormatted,
    required this.assignedFormatted,
    required this.unassignedFormatted,
  });

  final String currency;
  final int incomeMinor;
  final int assignedMinor;

  /// See [SnapshotBudget.amountFormatted].
  final String incomeFormatted;
  final String assignedFormatted;

  /// [unassignedMinor] formatted, sign included: over-assigning reads
  /// negative, and the model must be able to say so without re-deriving it.
  final String unassignedFormatted;

  /// May be negative (over-assigned). Guidance, never a blocker — the prompt
  /// relies on that framing to keep the tone non-punitive.
  int get unassignedMinor => incomeMinor - assignedMinor;

  Map<String, Object?> toJson() => <String, Object?>{
        'currency': currency,
        'incomeMinor': incomeMinor,
        'incomeFormatted': incomeFormatted,
        'assignedMinor': assignedMinor,
        'assignedFormatted': assignedFormatted,
        'unassignedMinor': unassignedMinor,
        'unassignedFormatted': unassignedFormatted,
      };

  @override
  List<Object?> get props => [
        currency,
        incomeMinor,
        assignedMinor,
        incomeFormatted,
        assignedFormatted,
        unassignedFormatted,
      ];
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
    this.categories,
    this.spendingByCategory,
    this.spendingCurrency,
    this.spendingTotalMinor,
    this.spendingTotalFormatted,
    this.cashflow,
    this.cashflowCurrency,
    this.budgets,
    this.goals,
    this.debtTotals,
    this.debts,
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

  /// Every active category, root and subcategories alike, regardless of
  /// whether it was used this period — see [SnapshotCategory]'s own doc for
  /// why this exists alongside [spendingByCategory].
  final List<SnapshotCategory>? categories;

  /// Expense grouped by root category over `[periodStart, periodEndExclusive)`.
  final List<SnapshotCategoryLine>? spendingByCategory;

  /// The single currency [spendingByCategory] and [spendingTotalMinor] are
  /// expressed in. Both are omitted together when it cannot be established.
  final String? spendingCurrency;

  final int? spendingTotalMinor;

  /// [spendingTotalMinor] in [spendingCurrency], pre-formatted — see
  /// [SnapshotBudget.amountFormatted]. Travels with the section or not at
  /// all: the whole section is omitted when it is missing, so the prompt's
  /// promise that every amount has a formatted twin stays true.
  final String? spendingTotalFormatted;

  /// Monthly income/expense for the last six months, oldest first.
  final List<SnapshotCashflowPoint>? cashflow;

  /// Same single-currency guarantee as [spendingCurrency], for [cashflow].
  final String? cashflowCurrency;

  final List<SnapshotBudget>? budgets;
  final List<SnapshotGoal>? goals;
  final List<SnapshotDebtTotal>? debtTotals;

  /// Open debts by name, with an id `get_debt_detail` accepts — see
  /// [SnapshotDebt]'s own doc for why this exists alongside [debtTotals].
  final List<SnapshotDebt>? debts;

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
          'currencyTotals': [
            for (final total in currencyTotals!) total.toJson()
          ],
        if (categories != null)
          'categories': [
            for (final category in categories!) category.toJson()
          ],
        if (spendingByCategory != null &&
            spendingCurrency != null &&
            spendingTotalFormatted != null)
          'spendingByCategory': <String, Object?>{
            'currency': spendingCurrency,
            'totalMinor': spendingTotalMinor ?? 0,
            'totalFormatted': spendingTotalFormatted,
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
        if (debts != null) 'debts': [for (final debt in debts!) debt.toJson()],
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
        categories,
        spendingByCategory,
        spendingCurrency,
        spendingTotalMinor,
        spendingTotalFormatted,
        cashflow,
        cashflowCurrency,
        budgets,
        goals,
        debtTotals,
        debts,
        upcoming,
        zeroBased,
        counts,
      ];
}
