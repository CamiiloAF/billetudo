import 'package:equatable/equatable.dart';

/// How often a budget repeats. Mirrors `BudgetPeriod` stored as text in Drift,
/// but declared here so the domain never depends on the database layer.
///
/// `biweekly` is the es-CO **semi-monthly fortnight** (two periods per month
/// anchored to the start day), NOT a rolling 14 days. `custom` is always a
/// single one-off window (`recurring = false`). See
/// `docs/requirements/06-presupuestos.md`.
enum BudgetPeriod { weekly, biweekly, monthly, yearly, custom }

/// A user-named budget with a configurable scope (accounts + categories, held
/// in `BudgetScope`, not here) and an anchored, optionally recurring window.
///
/// Pure domain entity: no Drift types, no `double`. [amountMinor] is always an
/// integer of minor units (cents); [alertThresholdPct] a whole percent (1-100).
class Budget extends Equatable {
  const Budget({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.currency,
    required this.period,
    required this.startDate,
    required this.recurring,
    required this.rollover,
    required this.createdAt,
    required this.updatedAt,
    this.icon,
    this.endDate,
    this.archivedAt,
    this.alertThresholdPct,
  });

  /// UUID as text.
  final String id;
  final String name;

  /// Lucide icon name (see `billetudo.pen` icon picker), e.g. 'utensils'.
  /// No color: the icon-wrap stays neutral (`$muted`) by design (HU-01).
  final String? icon;

  /// Always a positive integer of cents.
  final int amountMinor;

  /// ISO-4217 code, e.g. 'COP', 'USD'. A budget's progress only sums
  /// transactions in this same currency (HU-04).
  final String currency;

  final BudgetPeriod period;

  /// Freely chosen anchor; the whole cadence flows from it (HU-03).
  final DateTime startDate;

  /// true = periodic (repeats each [period] from [startDate]); false = a single
  /// one-off window (HU-03). `custom` always implies `recurring = false`.
  final bool recurring;

  /// End of the window. Mandatory when `recurring = false` or `period = custom`;
  /// on periodic budgets, null = "forever", a set value = stop-renewing date.
  final DateTime? endDate;

  /// Closed-to-history timestamp (HU-10/11). Non-null = closed.
  final DateTime? archivedAt;

  /// Early-alert threshold as a whole percent (1-100). null = "don't alert me".
  /// HU-08.
  final int? alertThresholdPct;

  /// Whether the leftover/overspend carries into the next period. Persisted from
  /// Phase 0 but its carry logic is deferred (HU-07).
  final bool rollover;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  /// A copy with a replaced [amountMinor]. Used to apply a Wallet-style
  /// per-period override (`BudgetPeriodOverride`) to the amount the "Modo
  /// sobres" summary counts for a budget's current window, without mutating the
  /// stored row.
  Budget withAmountMinor(int amountMinor) => Budget(
        id: id,
        name: name,
        amountMinor: amountMinor,
        currency: currency,
        period: period,
        startDate: startDate,
        recurring: recurring,
        rollover: rollover,
        createdAt: createdAt,
        updatedAt: updatedAt,
        icon: icon,
        endDate: endDate,
        archivedAt: archivedAt,
        alertThresholdPct: alertThresholdPct,
      );

  bool get isClosed => archivedAt != null;

  /// A one-off budget (no cadence to repeat). `custom` is exactly this in the
  /// data model, and any non-recurring budget behaves the same way.
  bool get isOneOff => !recurring || period == BudgetPeriod.custom;

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        amountMinor,
        currency,
        period,
        startDate,
        recurring,
        endDate,
        archivedAt,
        alertThresholdPct,
        rollover,
        createdAt,
        updatedAt,
      ];
}
