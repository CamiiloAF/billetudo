import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/zero_based_summary.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debts_summary.dart';
import 'package:billetudo/features/goals/domain/entities/goal_momentum.dart';
import 'package:billetudo/features/goals/domain/entities/goal_with_progress.dart';
import 'package:billetudo/features/import_export/domain/entities/import_batch.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown.dart';
import 'package:billetudo/features/reports/domain/entities/category_breakdown_item.dart';
import 'package:billetudo/features/reports/domain/entities/date_range.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';

import '../features/accounts/account_fixtures.dart' as accounts_fixtures;
import '../features/debts/presentation/debts_presentation_fixtures.dart';
import '../features/goals/presentation/goals_presentation_fixtures.dart';
import '../features/scheduled_payments/scheduled_payment_fixtures.dart';
import '../features/transactions/transaction_fixtures.dart' as tx_fixtures;

/// **The showcase dataset** — the single source of truth for the nine store
/// screenshots (F1 of `docs/marketing/plan-fichas-de-tienda.md`, §4.1
/// "Datos de vitrina").
///
/// This is deliberately **not** the data the goldens use. Goldens optimise for
/// edge cases (overspent budgets, stranded scopes, 20-character names that
/// force an ellipsis); a store screenshot optimises for a believable, coherent
/// household that someone can read in two seconds while scrolling a listing.
///
/// Rules this file enforces, so the nine images survive being swiped one after
/// another:
///
/// 1. **One household, one month.** The same three accounts, the same six
///    categories and the same period appear everywhere. The month's total
///    expense is `showcaseMonthExpenseMinor` and it is the *same number* on
///    Inicio (hero), on Gráficas (donut total) and inside the presupuesto
///    global — because all three are computed from the very same movement
///    list, not typed in three times.
/// 2. **COP, in minor units, always.** `$1.200.000` is `120000000` — COP
///    renders with no decimals but is still stored with two (see
///    `MoneyFormatter`). No `double` ever appears here.
/// 3. **No real people, no bank trademarks.** Accounts are generic and
///    plausible ("Cuenta de ahorros", "Billetera digital"); counterparties are
///    first names or a generic "Banco". Nothing here is a real account,
///    balance or person.
/// 4. **Positive but honest.** Budgets are mostly healthy, one is tight
///    (`arriendoBudget`, at 99%) and none is blown; goals show real progress;
///    debts exist and are being paid down. Nothing is punitive and nothing is
///    a fantasy.
///
/// ## Why the dates are anchored to "now"
///
/// Two of the nine screens (Pagos programados, and Inicio's relative "hoy /
/// ayer" row dates) compare their data against `DateTime.now()` at render
/// time — a scheduled payment with a hardcoded date would read "vencido"
/// forever. So the whole dataset is derived from [showcaseToday] instead of a
/// frozen instant, which keeps the nine captures coherent *with each other*
/// on any regeneration day.
///
/// The one consequence to know about: the month's movements are laid out
/// backwards from today and clamped to the 1st, so **regenerating during the
/// first days of a month bunches several rows onto day 1**. The images are
/// still correct, just less varied. Regenerate from the 6th of the month
/// onwards for the richest Inicio feed.

/// The instant every date below is derived from, normalised to midnight.
final DateTime showcaseToday = DateTime(
  DateTime.now().year,
  DateTime.now().month,
  DateTime.now().day,
);

/// First day of the showcase month (= the current calendar month).
final DateTime showcaseMonth =
    DateTime(showcaseToday.year, showcaseToday.month);

/// First day of the month after [showcaseMonth] (exclusive bound).
final DateTime showcaseMonthEndExclusive =
    DateTime(showcaseMonth.year, showcaseMonth.month + 1);

/// Days still to run in the showcase month, counted the way
/// `BudgetProgress.daysLeft` does (today excluded).
int get showcaseDaysLeftInMonth =>
    showcaseMonthEndExclusive.difference(showcaseToday).inDays;

/// [days] before today, never crossing into the previous month — see the
/// "Why the dates are anchored to now" note above.
DateTime showcaseDaysAgo(int days) {
  final candidate = showcaseToday.subtract(Duration(days: days));
  return candidate.isBefore(showcaseMonth) ? showcaseMonth : candidate;
}

/// [days] after today. Used by the screens that look forward (pagos
/// programados, cuota de una deuda).
DateTime showcaseDaysAhead(int days) => showcaseToday.add(Duration(days: days));

// ---------------------------------------------------------------------------
// Cuentas
// ---------------------------------------------------------------------------

const String savingsAccountId = 'acc-ahorros';
const String cashAccountId = 'acc-efectivo';
const String walletAccountId = 'acc-billetera';

// Short on purpose: Inicio's balance strip and the pagos-programados card
// subtitle both ellipsize at around 16 characters, and a store screenshot must
// never show a truncated account name.
const String savingsAccountName = 'Ahorros';
const String cashAccountName = 'Efectivo';
const String walletAccountName = 'Billetera digital';

const int savingsBalanceMinor = 845000000; // $8.450.000
const int cashBalanceMinor = 21500000; // $215.000
const int walletBalanceMinor = 64300000; // $643.000

Account get savingsAccount => accounts_fixtures.buildAccount(
      id: savingsAccountId,
      name: savingsAccountName,
      sortOrder: 0,
    );

Account get cashAccount => accounts_fixtures.buildAccount(
      id: cashAccountId,
      name: cashAccountName,
      type: AccountType.cash,
      sortOrder: 1,
    );

Account get walletAccount => accounts_fixtures.buildAccount(
      id: walletAccountId,
      name: walletAccountName,
      sortOrder: 2,
    );

/// The three accounts with their balances, in the order Inicio's balance strip
/// shows them. Liquid total: `$9.308.500` — comfortably above what the goals
/// of [showcaseGoals] have saved, so the household reads as coherent.
List<AccountWithBalance> get showcaseAccounts => [
      accounts_fixtures.buildAccountWithBalance(
        account: savingsAccount,
        balanceMinor: savingsBalanceMinor,
      ),
      accounts_fixtures.buildAccountWithBalance(
        account: cashAccount,
        balanceMinor: cashBalanceMinor,
      ),
      accounts_fixtures.buildAccountWithBalance(
        account: walletAccount,
        balanceMinor: walletBalanceMinor,
      ),
    ];

// ---------------------------------------------------------------------------
// Categorías
//
// Every icon name below is a real entry of `CategoryIconCatalog.names`, so it
// resolves to the designed glyph instead of falling back to `sparkles`, and
// every color is a real appearance token.
// ---------------------------------------------------------------------------

class ShowcaseCategory {
  const ShowcaseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
}

const ShowcaseCategory homeCategory = ShowcaseCategory(
  id: 'cat-hogar',
  name: 'Hogar',
  icon: 'house',
  color: 'indigo',
);
const ShowcaseCategory groceriesCategory = ShowcaseCategory(
  id: 'cat-mercado',
  name: 'Mercado',
  icon: 'shopping-cart',
  color: 'mint',
);
const ShowcaseCategory restaurantsCategory = ShowcaseCategory(
  id: 'cat-restaurantes',
  name: 'Restaurantes',
  icon: 'utensils-crossed',
  color: 'peach',
);
const ShowcaseCategory transportCategory = ShowcaseCategory(
  id: 'cat-transporte',
  name: 'Transporte',
  icon: 'bus',
  color: 'sky',
);
const ShowcaseCategory healthCategory = ShowcaseCategory(
  id: 'cat-salud',
  name: 'Salud',
  icon: 'heart-pulse',
  color: 'amber',
);
const ShowcaseCategory salaryCategory = ShowcaseCategory(
  id: 'cat-salario',
  name: 'Salario',
  icon: 'wallet',
  color: 'mint',
);

/// The showcase categories as real [Category] entities, for the pickers of the
/// transaction form (screenshot #2), which need entities rather than the plain
/// value object above.
Category showcaseCategoryEntity(ShowcaseCategory category) => Category(
      id: category.id,
      name: category.name,
      kind: category.id == salaryCategory.id
          ? CategoryKind.income
          : CategoryKind.expense,
      icon: category.icon,
      color: category.color,
      sortOrder: 0,
      createdAt: showcaseMonth,
      updatedAt: 0,
    );

/// The expense categories, in "most used first" order — what the form's
/// Category Quick Picker shows as chips.
///
/// Order matters: the first three become the chips. `Restaurantes` is
/// deliberately **not** among them — at 12 characters its chip label wraps
/// mid-word ("Restaurant / es"), which is a real rendering defect reported to
/// `flutter-dev`, not something a store screenshot should immortalise.
const List<ShowcaseCategory> showcaseExpenseCategories = [
  groceriesCategory,
  transportCategory,
  homeCategory,
  restaurantsCategory,
  healthCategory,
];

// ---------------------------------------------------------------------------
// Movimientos del mes
// ---------------------------------------------------------------------------

/// Salary of the showcase month: `$4.850.000`.
const int showcaseMonthIncomeMinor = 485000000;

/// Total spent in the showcase month: `$2.640.000`.
///
/// Asserted implicitly everywhere: it is the sum of [showcaseMonthMovements]'
/// expenses, of [showcaseCategoryBreakdown]'s items, and the `spentMinor` of
/// [monthlyBudget].
const int showcaseMonthExpenseMinor = 264000000;

TransactionWithDetails _movement({
  required String id,
  required ShowcaseCategory category,
  required int amountMinor,
  required int daysAgo,
  required String accountId,
  required String accountName,
  TransactionType type = TransactionType.expense,
}) =>
    TransactionWithDetails(
      transaction: tx_fixtures.buildTransaction(
        id: id,
        accountId: accountId,
        categoryId: category.id,
        amountMinor: amountMinor,
        type: type,
        date: showcaseDaysAgo(daysAgo),
      ),
      accountName: accountName,
      categoryName: category.name,
      categoryIcon: category.icon,
      categoryColor: category.color,
    );

/// Every movement of the showcase month, newest first.
///
/// The per-category sums are exactly [showcaseCategoryBreakdown]'s slices:
/// Hogar `$1.384.300` · Mercado `$612.400` · Restaurantes `$286.500` ·
/// Transporte `$214.800` · Salud `$142.000` → `$2.640.000`.
List<TransactionWithDetails> get showcaseMonthMovements => [
      _movement(
        id: 'tx-mercado-3',
        category: groceriesCategory,
        amountMinor: 8250000, // $82.500
        daysAgo: 0,
        accountId: cashAccountId,
        accountName: cashAccountName,
      ),
      _movement(
        id: 'tx-restaurantes-3',
        category: restaurantsCategory,
        amountMinor: 10460000, // $104.600
        daysAgo: 1,
        accountId: walletAccountId,
        accountName: walletAccountName,
      ),
      _movement(
        id: 'tx-transporte-3',
        category: transportCategory,
        amountMinor: 7080000, // $70.800
        daysAgo: 2,
        accountId: cashAccountId,
        accountName: cashAccountName,
      ),
      _movement(
        id: 'tx-mercado-2',
        category: groceriesCategory,
        amountMinor: 21740000, // $217.400
        daysAgo: 3,
        accountId: savingsAccountId,
        accountName: savingsAccountName,
      ),
      _movement(
        id: 'tx-salud-1',
        category: healthCategory,
        amountMinor: 14200000, // $142.000
        daysAgo: 4,
        accountId: savingsAccountId,
        accountName: savingsAccountName,
      ),
      _movement(
        id: 'tx-restaurantes-2',
        category: restaurantsCategory,
        amountMinor: 12300000, // $123.000
        daysAgo: 5,
        accountId: walletAccountId,
        accountName: walletAccountName,
      ),
      _movement(
        id: 'tx-transporte-2',
        category: transportCategory,
        amountMinor: 9800000, // $98.000
        daysAgo: 6,
        accountId: walletAccountId,
        accountName: walletAccountName,
      ),
      _movement(
        id: 'tx-restaurantes-1',
        category: restaurantsCategory,
        amountMinor: 5890000, // $58.900
        daysAgo: 7,
        accountId: cashAccountId,
        accountName: cashAccountName,
      ),
      _movement(
        id: 'tx-transporte-1',
        category: transportCategory,
        amountMinor: 4600000, // $46.000
        daysAgo: 8,
        accountId: cashAccountId,
        accountName: cashAccountName,
      ),
      _movement(
        id: 'tx-mercado-1',
        category: groceriesCategory,
        amountMinor: 31250000, // $312.500
        daysAgo: 9,
        accountId: savingsAccountId,
        accountName: savingsAccountName,
      ),
      _movement(
        id: 'tx-servicios-1',
        category: homeCategory,
        amountMinor: 18430000, // $184.300 — servicios públicos
        daysAgo: 10,
        accountId: savingsAccountId,
        accountName: savingsAccountName,
      ),
      _movement(
        id: 'tx-arriendo-1',
        category: homeCategory,
        amountMinor: 120000000, // $1.200.000 — arriendo
        daysAgo: 11,
        accountId: savingsAccountId,
        accountName: savingsAccountName,
      ),
      _movement(
        id: 'tx-salario-1',
        category: salaryCategory,
        amountMinor: showcaseMonthIncomeMinor,
        daysAgo: 12,
        accountId: savingsAccountId,
        accountName: savingsAccountName,
        type: TransactionType.income,
      ),
    ];

// ---------------------------------------------------------------------------
// Presupuestos
// ---------------------------------------------------------------------------

BudgetPeriodWindow get _monthWindow => BudgetPeriodWindow(
      start: showcaseMonth,
      endExclusive: showcaseMonthEndExclusive,
      index: 6,
      status: BudgetWindowStatus.current,
      hasPrevious: true,
      hasNext: false,
    );

BudgetWithProgress _budget({
  required String id,
  required String name,
  required String icon,
  required int amountMinor,
  required int spentMinor,
  BudgetScope scope = const BudgetScope.empty(),
}) =>
    BudgetWithProgress(
      budget: Budget(
        id: id,
        name: name,
        icon: icon,
        amountMinor: amountMinor,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: showcaseMonth,
        recurring: true,
        rollover: false,
        alertThresholdPct: 80,
        createdAt: showcaseMonth,
        updatedAt: 0,
      ),
      scope: scope,
      window: _monthWindow,
      progress: BudgetProgress(
        amountMinor: amountMinor,
        spentMinor: spentMinor,
        daysLeft: showcaseDaysLeftInMonth,
      ),
    );

/// The global monthly budget Inicio features in its hero: it covers the whole
/// month, so its `spentMinor` **is** [showcaseMonthExpenseMinor].
/// `$2.640.000` of `$3.200.000` → 82%, tight but not blown.
BudgetWithProgress get monthlyBudget => _budget(
      id: 'bud-mes',
      name: 'Gastos del mes',
      icon: 'wallet',
      amountMinor: 320000000,
      spentMinor: showcaseMonthExpenseMinor,
    );

/// `$1.384.300` spent of `$1.400.000` — the one tight envelope. Kept on
/// purpose: a set where every budget sits at 40% reads as staged.
BudgetWithProgress get arriendoBudget => _budget(
      id: 'bud-hogar',
      name: 'Arriendo y servicios',
      icon: 'house',
      amountMinor: 140000000,
      spentMinor: 138430000,
    );

/// The category budgets shown in the list, in display order. Each
/// `spentMinor` equals what [showcaseMonthMovements] actually spent in that
/// category.
List<BudgetWithProgress> get showcaseBudgets => [
      _budget(
        id: 'bud-mercado',
        name: 'Mercado y domicilios',
        icon: 'shopping-cart',
        amountMinor: 90000000, // $900.000
        spentMinor: 61240000, // $612.400 → 68%
      ),
      arriendoBudget,
      _budget(
        id: 'bud-restaurantes',
        name: 'Restaurantes y salidas',
        icon: 'utensils-crossed',
        amountMinor: 45000000, // $450.000
        spentMinor: 28650000, // $286.500 → 64%
      ),
      _budget(
        id: 'bud-transporte',
        name: 'Transporte',
        icon: 'bus',
        amountMinor: 32000000, // $320.000
        spentMinor: 21480000, // $214.800 → 67%
      ),
      _budget(
        id: 'bud-salud',
        name: 'Salud y farmacia',
        icon: 'heart-pulse',
        amountMinor: 25000000, // $250.000
        spentMinor: 14200000, // $142.000 → 57%
      ),
    ];

/// Modo sobres (base cero): `$4.850.000` de ingresos, `$4.180.000` ya
/// asignados → quedan `$670.000` por asignar. Positive on purpose: the
/// actionable, non-punitive state the design sells.
const ZeroBasedSummary showcaseEnvelopeSummary = ZeroBasedSummary(
  currency: 'COP',
  incomeMinor: showcaseMonthIncomeMinor,
  assignedMinor: 418000000,
);

// ---------------------------------------------------------------------------
// Gráficas — desglose por categoría
// ---------------------------------------------------------------------------

DateRange get showcaseMonthRange => DateRange(
      start: showcaseMonth,
      endExclusive: showcaseMonthEndExclusive,
      granularity: DateGranularity.daily,
    );

/// The donut of screenshot #3. Its total is [showcaseMonthExpenseMinor] and
/// its slices are the per-category sums of [showcaseMonthMovements], so the
/// figures line up with Inicio and with the presupuestos list.
CategoryBreakdown get showcaseCategoryBreakdown => CategoryBreakdown(
      items: const [
        CategoryBreakdownItem(
          categoryId: 'cat-hogar',
          name: 'Hogar',
          icon: 'house',
          color: 'indigo',
          amountMinor: 138430000, // $1.384.300
          movementCount: 2,
          subcategories: [
            CategoryBreakdownItem(
              categoryId: 'cat-hogar-arriendo',
              name: 'Arriendo',
              icon: 'house',
              color: 'indigo',
              amountMinor: 120000000,
              movementCount: 1,
            ),
            CategoryBreakdownItem(
              categoryId: 'cat-hogar-servicios',
              name: 'Servicios públicos',
              icon: 'zap',
              color: 'indigo',
              amountMinor: 18430000,
              movementCount: 1,
            ),
          ],
        ),
        CategoryBreakdownItem(
          categoryId: 'cat-mercado',
          name: 'Mercado',
          icon: 'shopping-cart',
          color: 'mint',
          amountMinor: 61240000, // $612.400
          movementCount: 3,
        ),
        CategoryBreakdownItem(
          categoryId: 'cat-restaurantes',
          name: 'Restaurantes',
          icon: 'utensils-crossed',
          color: 'peach',
          amountMinor: 28650000, // $286.500
          movementCount: 3,
        ),
        CategoryBreakdownItem(
          categoryId: 'cat-transporte',
          name: 'Transporte',
          icon: 'bus',
          color: 'sky',
          amountMinor: 21480000, // $214.800
          movementCount: 3,
        ),
        CategoryBreakdownItem(
          categoryId: 'cat-salud',
          name: 'Salud',
          icon: 'heart-pulse',
          color: 'amber',
          amountMinor: 14200000, // $142.000
          movementCount: 1,
        ),
      ],
      totalMinor: showcaseMonthExpenseMinor,
      range: showcaseMonthRange,
    );

// ---------------------------------------------------------------------------
// Metas
// ---------------------------------------------------------------------------

/// Five goals with real, uneven progress and an active saving streak — the
/// HU-15 momentum header is what screenshot #5 is about. Saved across all
/// five: `$7.050.000`, comfortably inside the `$8.450.000` of
/// [savingsAccount], so the coherence banner would have nothing to warn about.
List<GoalWithProgress> get showcaseGoals => [
      buildGoalWithProgress(
        goal: buildGoal(
          id: 'goal-viaje',
          name: 'Viaje a Santa Marta',
          targetMinor: 350000000, // $3.500.000
          targetDate: DateTime(showcaseToday.year + 1, 1, 15),
        ),
        savedMinor: 210000000, // $2.100.000
        displayedPercent: 60,
        momentum: const GoalMomentum(
          streakWeeks: 6,
          nextMilestonePct: 75,
          amountToNextMilestoneMinor: 52500000, // $525.000
        ),
      ),
      buildGoalWithProgress(
        goal: buildGoal(
          id: 'goal-emergencia',
          name: 'Fondo de emergencia',
          targetMinor: 600000000, // $6.000.000
          lastMilestonePct: 25,
        ),
        savedMinor: 270000000, // $2.700.000
        displayedPercent: 45,
        momentum: const GoalMomentum(streakWeeks: 3),
      ),
      buildGoalWithProgress(
        goal: buildGoal(
          id: 'goal-computador',
          name: 'Computador nuevo',
          targetMinor: 420000000, // $4.200.000
        ),
        savedMinor: 105000000, // $1.050.000
        displayedPercent: 25,
      ),
      buildGoalWithProgress(
        goal: buildGoal(
          id: 'goal-curso',
          name: 'Curso de inglés',
          targetMinor: 180000000, // $1.800.000
        ),
        savedMinor: 72000000, // $720.000
        displayedPercent: 40,
      ),
      buildGoalWithProgress(
        goal: buildGoal(
          id: 'goal-regalos',
          name: 'Regalos de fin de año',
          targetMinor: 120000000, // $1.200.000
        ),
        savedMinor: 48000000, // $480.000
        displayedPercent: 40,
      ),
    ];

// ---------------------------------------------------------------------------
// Deudas
// ---------------------------------------------------------------------------

/// One COP summary card ("Yo debo `$11.600.000` / Me deben `$300.000`") over
/// three debts, all being paid down. Single currency on purpose: the golden
/// suite covers the two-currency split, a store screenshot should read in one
/// glance.
DebtsSummary get showcaseDebtsSummary => DebtsSummary.from([
      buildDebtWithBalance(
        debt: buildDebt(
          id: 'debt-vehiculo',
          name: 'Crédito de vehículo',
          counterparty: 'Banco',
        ),
        balance: buildBalance(
          principalMinor: 1800000000, // $18.000.000
          totalIncreasesMinor: 1800000000,
          totalDecreasesMinor: 720000000, // $7.200.000 abonados
        ),
        installment: buildDebtInstallment(
          amountMinor: 62000000, // $620.000
          nextDate: showcaseDaysAhead(18),
        ),
      ),
      buildDebtWithBalance(
        debt: buildDebt(
          id: 'debt-computador',
          // Short enough to render whole: the debt card ellipsizes its title
          // once the "Yo debo" pill is beside it.
          name: 'Portátil a cuotas',
          counterparty: 'Almacén',
        ),
        balance: buildBalance(
          principalMinor: 240000000, // $2.400.000
          totalIncreasesMinor: 240000000,
          totalDecreasesMinor: 160000000, // $1.600.000 abonados
        ),
      ),
      buildDebtWithBalance(
        debt: buildDebt(
          id: 'debt-andres',
          name: 'Le presté a Andrés',
          counterparty: 'Andrés',
          direction: DebtDirection.owedToMe,
        ),
        balance: buildBalance(
          principalMinor: 45000000, // $450.000
          totalIncreasesMinor: 45000000,
          totalDecreasesMinor: 15000000, // $150.000 devueltos
        ),
      ),
    ]);

// ---------------------------------------------------------------------------
// Pagos programados
// ---------------------------------------------------------------------------

/// Two active templates (an expense and the salary) plus one accumulated
/// pending occurrence, which is what screenshot #7 sells: "ningún pago se te
/// vuelve a pasar".
List<ScheduledPaymentSummary> get showcaseScheduledPayments => [
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(
          id: 'sp-arriendo',
          accountId: savingsAccountId,
          categoryId: homeCategory.id,
          amountMinor: 120000000, // $1.200.000
          note: 'Arriendo',
          nextDate: showcaseDaysAhead(5),
        ),
        accountName: savingsAccountName,
        categoryName: 'Hogar',
        categoryIcon: homeCategory.icon,
        categoryColor: homeCategory.color,
      ),
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(
          id: 'sp-internet',
          accountId: savingsAccountId,
          categoryId: homeCategory.id,
          amountMinor: 12990000, // $129.900
          note: 'Internet y TV',
          nextDate: showcaseDaysAhead(11),
        ),
        accountName: savingsAccountName,
        categoryName: 'Hogar',
        categoryIcon: 'wifi',
        categoryColor: 'sky',
      ),
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(
          id: 'sp-musica',
          accountId: walletAccountId,
          categoryId: homeCategory.id,
          amountMinor: 1690000, // $16.900
          note: 'Suscripción de música',
          nextDate: showcaseDaysAhead(17),
        ),
        accountName: walletAccountName,
        categoryName: 'Hogar',
        categoryIcon: 'music',
        categoryColor: 'peach',
      ),
      ScheduledPaymentSummary(
        scheduledPayment: buildScheduledPayment(
          id: 'sp-salario',
          accountId: savingsAccountId,
          categoryId: salaryCategory.id,
          amountMinor: showcaseMonthIncomeMinor,
          type: ScheduledPaymentType.income,
          note: 'Salario',
          nextDate: showcaseDaysAhead(23),
        ),
        accountName: savingsAccountName,
        categoryName: salaryCategory.name,
        categoryIcon: salaryCategory.icon,
        categoryColor: salaryCategory.color,
      ),
    ];

/// One occurrence waiting for confirmation (it fell due yesterday), so the
/// "Por confirmar" block renders above the list.
List<PendingScheduledOccurrence> get showcasePendingOccurrences => [
      buildPendingOccurrence(
        occurrence: buildOccurrence(
          id: 'occ-gimnasio',
          scheduledPaymentId: 'sp-gimnasio',
          occurrenceDate: showcaseDaysAgo(1),
        ),
        scheduledPayment: buildScheduledPayment(
          id: 'sp-gimnasio',
          accountId: walletAccountId,
          amountMinor: 8900000, // $89.000
          note: 'Gimnasio',
          requiresConfirmation: true,
          nextDate: showcaseDaysAgo(1),
        ),
        accountName: walletAccountName,
        categoryName: 'Salud',
        categoryIcon: healthCategory.icon,
        categoryColor: healthCategory.color,
      ),
    ];

// ---------------------------------------------------------------------------
// Importar / exportar
// ---------------------------------------------------------------------------

/// The last CSV this household imported, and when it last saved a copy — the
/// "tus datos son tuyos" proof of screenshot #9.
ImportBatch get showcaseImportBatch => ImportBatch(
      id: 'batch-showcase',
      fileName: 'movimientos-enero-junio.csv',
      importedAt: showcaseDaysAgo(9),
      rowsImported: 214,
      rowsSkipped: 2,
      createdAt: showcaseDaysAgo(9),
      updatedAt: 0,
    );

DateTime get showcaseLastBackupAt => showcaseDaysAgo(3);
