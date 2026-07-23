import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_activity_item.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_view.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_period_window.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_progress.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scheduled_item.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_scope.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';

import '../../domain/budget_fixtures.dart';

/// Shared fixtures for the Budgets golden suite.
///
/// Two rules every fixture here follows, both learned from the previous
/// fidelity audit (`docs/dev-runs/bug-fixes-pixel-audit.md`):
///
/// 1. **Realistic, long content.** Real es-CO budget names ("Tarjeta de
///    crédito Bancolombia"), 7-figure COP amounts (`$4.500.000` = `450000000`
///    minor units — COP renders with no decimals, see
///    `MoneyFormatter.currencyDecimals`) and long category names, so a golden
///    actually protects the ellipsis/overflow behaviour instead of rendering
///    comfortable short strings.
/// 2. **Icons that exist.** Every `icon` string below is a real entry of
///    `CategoryIconCatalog.names` (`credit-card`, `shopping-cart`,
///    `utensils-crossed`, `house`, `bus`), so `CategoryAppearance.iconFor`
///    resolves the designed glyph and never silently falls back to
///    `sparkles`. Budgets carry no color by design (HU-01), so there is no
///    color token to verify.
///
/// **Dates are fixed, never relative to `DateTime.now()`.** The period stepper
/// prints an absolute range ("1–31 jul"), so a now-relative window would make
/// every detail golden differ each day. The hero's right caption is fully
/// auditable now: it renders `BudgetProgress.daysLeft` (the value the domain
/// computed), not `DateTime.now()`, so `healthyEntry` prints the designed
/// "Restan 18 días".

/// A period window with fixed dates. [status] is independent of the dates on
/// purpose: the designed frames show a "vigente" pill, and the dates must stay
/// fixed for determinism.
BudgetPeriodWindow buildWindow({
  DateTime? start,
  DateTime? endExclusive,
  int index = 6,
  BudgetWindowStatus status = BudgetWindowStatus.current,
  bool hasPrevious = true,
  bool hasNext = true,
}) =>
    BudgetPeriodWindow(
      start: start ?? DateTime(2025, 7),
      endExclusive: endExclusive ?? DateTime(2025, 8),
      index: index,
      status: status,
      hasPrevious: hasPrevious,
      hasNext: hasNext,
    );

/// Scope narrowed on both dimensions (2 alive accounts, 3 alive categories) —
/// renders the longest scope label the list can show.
const BudgetScope customScope = BudgetScope(
  accounts: [
    BudgetScopeRef(id: 'acc-bancolombia', referentAlive: true),
    BudgetScopeRef(id: 'acc-nequi', referentAlive: true),
  ],
  categories: [
    BudgetScopeRef(id: 'cat-mercado', referentAlive: true),
    BudgetScopeRef(id: 'cat-restaurantes', referentAlive: true),
    BudgetScopeRef(id: 'cat-domicilios', referentAlive: true),
  ],
);

/// Scope whose referents were all deleted elsewhere: matches nothing, and the
/// meta line warns with "Sin alcance válido" (HU-04).
const BudgetScope strandedScope = BudgetScope(
  categories: [
    BudgetScopeRef(id: 'cat-borrada', referentAlive: false),
  ],
);

/// A healthy, recurring, custom-scoped budget: 69% spent of `$4.500.000`.
BudgetWithProgress get healthyEntry => BudgetWithProgress(
      budget: buildBudget(
        id: 'bud-tarjeta',
        name: 'Tarjeta de crédito Bancolombia',
        icon: 'credit-card',
        amountMinor: 450000000,
        startDate: DateTime(2025, 1, 21),
      ),
      scope: customScope,
      window: buildWindow(
        start: DateTime(2025, 7, 21),
        endExclusive: DateTime(2025, 8, 21),
      ),
      progress: const BudgetProgress(
        amountMinor: 450000000,
        spentMinor: 312450000,
        daysLeft: 18,
      ),
    );

/// A global budget close to (but under) its limit.
BudgetWithProgress get globalEntry => BudgetWithProgress(
      budget: buildBudget(
        id: 'bud-mercado',
        name: 'Mercado y domicilios del mes',
        icon: 'shopping-cart',
        amountMinor: 185000000,
        startDate: DateTime(2025, 7),
      ),
      scope: const BudgetScope.empty(),
      window: buildWindow(),
      progress: const BudgetProgress(
        amountMinor: 185000000,
        spentMinor: 176300000,
        daysLeft: 4,
      ),
    );

/// Overspent (>100%): the only case that switches to the semantic `expense`
/// family (soft icon-wrap, red amount and percent).
BudgetWithProgress get overspentEntry => BudgetWithProgress(
      budget: buildBudget(
        id: 'bud-restaurantes',
        name: 'Restaurantes y salidas con amigos',
        icon: 'utensils-crossed',
        amountMinor: 90000000,
        startDate: DateTime(2025, 7),
      ),
      scope: customScope,
      window: buildWindow(),
      progress: const BudgetProgress(
        amountMinor: 90000000,
        spentMinor: 124800000,
        daysLeft: 4,
      ),
    );

/// One-off (non-recurring, "custom" period): its anchor reads "termina
/// el <fecha>" instead of "se reinicia el <fecha>".
BudgetWithProgress get oneOffEntry => BudgetWithProgress(
      budget: buildBudget(
        id: 'bud-remodelacion',
        name: 'Remodelación de la cocina del apartamento',
        icon: 'house',
        amountMinor: 1250000000,
        period: BudgetPeriod.custom,
        recurring: false,
        startDate: DateTime(2025, 6, 15),
        endDate: DateTime(2025, 9, 30),
      ),
      scope: customScope,
      window: buildWindow(
        start: DateTime(2025, 6, 15),
        endExclusive: DateTime(2025, 10),
        index: 0,
        hasPrevious: false,
        hasNext: false,
      ),
      progress: const BudgetProgress(
        amountMinor: 1250000000,
        spentMinor: 738900000,
        daysLeft: 42,
      ),
    );

/// HU-12: healthy "programado" — spent 60%, scheduled another 20%, so the
/// projection (`committedFraction`) lands at 80%, still under 100%. The bar's
/// third segment renders `$primary-light` and the hero/entry-card caption
/// reads "+ $X programado (llega a 80% si se ejecuta)".
BudgetWithProgress get scheduledHealthyEntry => BudgetWithProgress(
      budget: buildBudget(
        id: 'bud-suscripciones',
        name: 'Suscripciones y streaming del hogar',
        icon: 'credit-card',
        amountMinor: 90000000,
        startDate: DateTime(2025, 7),
      ),
      scope: const BudgetScope.empty(),
      window: buildWindow(),
      progress: const BudgetProgress(
        amountMinor: 90000000,
        spentMinor: 54000000,
        daysLeft: 10,
        scheduledMinor: 18000000,
      ),
    );

/// HU-12: "riesgo de sobregiro proyectado" — spent 80% (still not overspent)
/// plus 30% scheduled pushes the projection to 110%, so
/// `isScheduledOverspendRisk` is true and `scheduledOverageMinor` is
/// `$90.000`. Bar segment and captions switch to `$amber`/`$amber-text`
/// (documented MASTER exception), never confused with a real overspend (the
/// existing `overspentEntry` fixture stays the red `expense` case).
BudgetWithProgress get scheduledRiskEntry => BudgetWithProgress(
      budget: buildBudget(
        id: 'bud-servicios',
        name: 'Servicios públicos y facturas del apartamento',
        icon: 'house',
        amountMinor: 90000000,
        startDate: DateTime(2025, 7),
      ),
      scope: const BudgetScope.empty(),
      window: buildWindow(),
      progress: const BudgetProgress(
        amountMinor: 90000000,
        spentMinor: 72000000,
        daysLeft: 10,
        scheduledMinor: 27000000,
      ),
    );

/// A budget whose scope referents were all deleted (stranded, HU-04): 0 spent
/// because it can never match a transaction.
BudgetWithProgress get strandedEntry => BudgetWithProgress(
      budget: buildBudget(
        id: 'bud-huerfano',
        name: 'Transporte y movilidad diaria',
        icon: 'bus',
        amountMinor: 48000000,
        startDate: DateTime(2025, 7),
      ),
      scope: strandedScope,
      window: buildWindow(),
      progress: const BudgetProgress(
        amountMinor: 48000000,
        spentMinor: 0,
        daysLeft: 4,
      ),
    );

/// Closed budgets for the history (`archivedAt` set): one that stayed within
/// its amount, one that ended overspent.
List<BudgetWithProgress> get archivedEntries => [
      BudgetWithProgress(
        budget: buildBudget(
          id: 'bud-arch-1',
          name: 'Vacaciones en San Andrés con la familia',
          icon: 'house',
          amountMinor: 780000000,
          period: BudgetPeriod.custom,
          recurring: false,
          startDate: DateTime(2025, 4),
          endDate: DateTime(2025, 4, 30),
          archivedAt: DateTime(2025, 5, 2),
        ),
        scope: customScope,
        window: buildWindow(
          start: DateTime(2025, 4),
          endExclusive: DateTime(2025, 5),
          index: 0,
          status: BudgetWindowStatus.past,
          hasNext: false,
          hasPrevious: false,
        ),
        progress: const BudgetProgress(
          amountMinor: 780000000,
          spentMinor: 712400000,
          daysLeft: 0,
        ),
      ),
      BudgetWithProgress(
        budget: buildBudget(
          id: 'bud-arch-2',
          name: 'Restaurantes y salidas con amigos',
          icon: 'utensils-crossed',
          amountMinor: 90000000,
          startDate: DateTime(2025, 5),
          archivedAt: DateTime(2025, 6),
        ),
        scope: customScope,
        window: buildWindow(
          start: DateTime(2025, 5),
          endExclusive: DateTime(2025, 6),
          status: BudgetWindowStatus.past,
        ),
        progress: const BudgetProgress(
          amountMinor: 90000000,
          spentMinor: 137650000,
          daysLeft: 0,
        ),
      ),
      // Short name on purpose: with the long names above, the row's result
      // ("Excedido por $X") ellipsizes and hides the amount. This third row
      // keeps the designed result text fully visible so it can be audited.
      BudgetWithProgress(
        budget: buildBudget(
          id: 'bud-arch-3',
          name: 'Mercado',
          icon: 'shopping-cart',
          amountMinor: 185000000,
          startDate: DateTime(2025, 5),
          archivedAt: DateTime(2025, 6),
        ),
        scope: const BudgetScope.empty(),
        window: buildWindow(
          start: DateTime(2025, 5),
          endExclusive: DateTime(2025, 6),
          status: BudgetWindowStatus.past,
        ),
        progress: const BudgetProgress(
          amountMinor: 185000000,
          spentMinor: 213400000,
          daysLeft: 0,
        ),
      ),
    ];

/// Activity of a period (newest first), long enough to trigger "Cargar más"
/// (`BudgetDetailState.activityPageSize` = 8).
List<BudgetActivityItem> buildActivity({int count = 4}) {
  const titles = [
    'Mercado y productos de aseo del hogar',
    'Restaurantes y comidas fuera de casa',
    'Domicilios y aplicaciones de entrega',
    'Transporte y movilidad diaria',
  ];
  const accounts = ['Bancolombia', 'Efectivo', 'Nequi', 'Davivienda'];
  const icons = ['shopping-cart', 'utensils-crossed', 'send', 'bus'];
  const colors = ['mint', 'peach', 'sky', 'teal'];
  const notes = [
    'Éxito Colina — compra quincenal completa',
    null,
    'Rappi — almuerzo del equipo',
    null,
  ];
  const amounts = [48750000, 12900000, 6430000, 2180000];
  return [
    for (var index = 0; index < count; index++)
      BudgetActivityItem(
        id: 'tx-$index',
        title: titles[index % titles.length],
        accountName: accounts[index % accounts.length],
        categoryIcon: icons[index % icons.length],
        categoryColor: colors[index % colors.length],
        amountMinor: amounts[index % amounts.length],
        currency: 'COP',
        date: DateTime(2025, 7, 28 - (index % 20)),
        note: notes[index % notes.length],
      ),
  ];
}

/// The detail's period view for [entry], with [activityCount] rows and
/// [scheduledItems] behind [BudgetProgress.scheduledMinor] (HU-12, empty by
/// default so existing callers are unaffected).
BudgetPeriodView buildPeriodView(
  BudgetWithProgress entry, {
  int activityCount = 4,
  List<BudgetScheduledItem> scheduledItems = const [],
}) =>
    BudgetPeriodView(
      window: entry.window,
      progress: entry.progress,
      activity: buildActivity(count: activityCount),
      scheduledItems: scheduledItems,
    );

/// HU-12's "programado" list (soonest first), long enough by default (2) to
/// show real content in `BudgetScheduledEntryCard`'s sub line and the
/// `BudgetScheduledSheet` list.
List<BudgetScheduledItem> buildScheduledItems({int count = 2}) {
  const titles = ['Netflix', 'Internet y TV hogar'];
  const icons = ['credit-card', 'house'];
  const colors = ['sky', 'peach'];
  const amounts = [9000000, 18000000];
  return [
    for (var index = 0; index < count; index++)
      BudgetScheduledItem(
        id: 'sp-$index@2025-07-${10 + index}',
        scheduledPaymentId: 'sp-$index',
        note: titles[index % titles.length],
        accountName: 'Bancolombia',
        categoryIcon: icons[index % icons.length],
        categoryColor: colors[index % colors.length],
        amountMinor: amounts[index % amounts.length],
        currency: 'COP',
        date: DateTime(2025, 7, 10 + index),
      ),
  ];
}
