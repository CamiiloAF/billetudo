import 'package:equatable/equatable.dart';

/// A budget as offered by the Movimientos "Presupuesto" filter sheet: just
/// enough to render a row and build a `DatePeriodFilter.budget` window
/// (`start`/`endExclusive`, resolved live from `BudgetWithProgress.window`).
///
/// Deliberately does not carry `BudgetWithProgress`/`BudgetScope`/`Budget`
/// itself — those are Presupuestos domain types, and presentation for
/// Movimientos should not need to import that feature's entities, same
/// reasoning as `AccountFilterCubit` using `AccountWithBalance` instead of a
/// Drift row.
class BudgetPeriodOption extends Equatable {
  const BudgetPeriodOption({
    required this.budgetId,
    required this.name,
    required this.start,
    required this.endExclusive,
    this.index = 0,
    this.hasPrevious = false,
    this.hasNext = false,
    this.icon,
  });

  /// UUID as text, matches `Budget.id`.
  final String budgetId;
  final String name;

  /// Lucide icon name (`Budget.icon`), `null` when the budget has none.
  final String? icon;

  /// Inclusive start of the budget's current period (date-only).
  final DateTime start;

  /// Exclusive end of the budget's current period (date-only), already
  /// half-open — matches `BudgetPeriodWindow.endExclusive`.
  final DateTime endExclusive;

  /// 0-based position of this window in the budget's cadence — mirrors
  /// `BudgetPeriodWindow.index`, carried through so the Period Nav Bar
  /// (`design-system/billetudo/pages/transacciones.md` § "Period Nav Bar")
  /// can step to `index ± 1` via `GetBudgetPeriodWindowAt` without needing to
  /// reach into Presupuestos' own domain types.
  final int index;

  /// Whether a previous/next window exists within the budget's bounds —
  /// mirrors `BudgetPeriodWindow.hasPrevious`/`hasNext`, drives the Period Nav
  /// Bar's disabled chevrons.
  final bool hasPrevious;
  final bool hasNext;

  @override
  List<Object?> get props =>
      [budgetId, name, icon, start, endExclusive, index, hasPrevious, hasNext];
}
