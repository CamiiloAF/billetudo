import 'package:equatable/equatable.dart';

/// Which way a debt points. Mirrors `DebtDirection` stored as text in Drift,
/// declared here so the domain never depends on the database layer.
///  - `iOwe`: money the user owes to someone (a bank, a friend).
///  - `owedToMe`: money someone owes the user (a loan the user gave).
enum DebtDirection { iOwe, owedToMe }

/// How a debt's outstanding balance grows over time. Mirrors
/// `DebtAccrualMode`.
///  - `manual` (default): the user keeps the figure current by hand via
///    "actualizar saldo" (a `manualAdjustment` ledger entry).
///  - `auto`: the app posts `interestAccrual` entries from the debt's rate.
enum DebtAccrualMode { manual, auto }

/// A debt or loan, in either direction (`iOwe` / `owedToMe`).
///
/// Pure domain entity: no Drift types, no `double`. Every money field is an
/// integer of minor units (cents). The outstanding balance is **never** stored
/// here — it is derived from the ledger (opening [principalMinor] + the debt's
/// `DebtEntry`s + the `Transaction`s that carry its id). See
/// `docs/requirements/08-deudas.md` and `DebtBalanceCalculator`.
class Debt extends Equatable {
  const Debt({
    required this.id,
    required this.name,
    required this.direction,
    required this.principalMinor,
    required this.currency,
    required this.accrualMode,
    required this.createdAt,
    required this.updatedAt,
    this.counterparty,
    this.dueDate,
    this.interestRateBps,
    this.deletedAt,
  });

  /// UUID as text.
  final String id;

  final String name;
  final DebtDirection direction;

  /// Opening balance in cents (the figure the debt had before it was tracked
  /// in the app). Non-negative. May be 0 when the whole balance is built from
  /// ledger events instead of an opening figure.
  final int principalMinor;

  /// ISO-4217 code, e.g. 'COP', 'USD'.
  final String currency;

  final DebtAccrualMode accrualMode;

  /// Optional label for the other party ('Banco Bogotá', 'Juan Pérez').
  final String? counterparty;

  final DateTime? dueDate;

  /// Annual interest rate in whole basis points (24.5% -> 2450), optional.
  /// Never `double`: a scaled percentage, not an amount.
  final int? interestRateBps;

  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` (schema v5) — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  /// Soft-delete trash timestamp (HU-05). null = active. Reversible via
  /// `RestoreDebt`; never `tombstonedAt` (the debt is restorable by design).
  final DateTime? deletedAt;

  bool get isTrashed => deletedAt != null;

  @override
  List<Object?> get props => [
        id,
        name,
        direction,
        principalMinor,
        currency,
        accrualMode,
        counterparty,
        dueDate,
        interestRateBps,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
