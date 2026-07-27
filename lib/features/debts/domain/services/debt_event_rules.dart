import '../../../transactions/domain/entities/transaction.dart'
    show TransactionType;
import '../entities/debt.dart';
import '../entities/debt_cash_event.dart';
import '../entities/debt_entry.dart';

/// The single source of truth for how each debt event affects the outstanding
/// balance. Pure static rules with no state — both `DebtBalanceCalculator` and
/// the write use cases (RegisterDebtCashEvent) route through here so the sign
/// logic has exactly one implementation.
///
/// The core subtlety (`docs/requirements/08-deudas.md`): a `Transaction` with a
/// debt id does NOT always reduce the debt. The effect is the pair
/// (`direction` × `type`):
///
/// | direction | type    | means               | effect |
/// |-----------|---------|---------------------|--------|
/// | iOwe      | income  | took the loan       | +      |
/// | iOwe      | expense | abono / cuota (pay) | −      |
/// | owedToMe  | expense | lent the money      | +      |
/// | owedToMe  | income  | got paid back       | −      |
abstract final class DebtEventRules {
  /// Signed effect (cents) of a cash `Transaction` on the debt. [amountMinor]
  /// is the transaction's positive amount; the returned value is + when the
  /// event increases the debt and − when it reduces it. A `transfer` never
  /// belongs to a debt, so it contributes 0 (defensive).
  static int cashEventEffect({
    required DebtDirection direction,
    required TransactionType type,
    required int amountMinor,
  }) {
    final magnitude = amountMinor.abs();
    return switch ((direction, type)) {
      (DebtDirection.iOwe, TransactionType.income) => magnitude,
      (DebtDirection.iOwe, TransactionType.expense) => -magnitude,
      (DebtDirection.owedToMe, TransactionType.expense) => magnitude,
      (DebtDirection.owedToMe, TransactionType.income) => -magnitude,
      _ => 0,
    };
  }

  /// The `income`/`expense` a cash event of [kind] must become for a debt that
  /// points [direction]. The inverse of [cashEventEffect]: it turns the user's
  /// intent ("this is a disbursement" / "this is an abono") into the concrete
  /// transaction type the repository persists.
  static TransactionType cashEventType({
    required DebtDirection direction,
    required DebtCashEventKind kind,
  }) =>
      switch ((direction, kind)) {
        (DebtDirection.iOwe, DebtCashEventKind.disbursement) =>
          TransactionType.income,
        (DebtDirection.iOwe, DebtCashEventKind.payment) =>
          TransactionType.expense,
        (DebtDirection.owedToMe, DebtCashEventKind.disbursement) =>
          TransactionType.expense,
        (DebtDirection.owedToMe, DebtCashEventKind.payment) =>
          TransactionType.income,
      };

  /// The signed [DebtEntry.amountMinor] a cash-less ledger event of [kind]
  /// (`payment`/`disbursement`, HU-02 toggle "No") must store, given a positive
  /// [magnitudeMinor]. A `payment` reduces the debt (−), a `disbursement`
  /// increases it (+).
  static int ledgerEventAmount({
    required DebtCashEventKind kind,
    required int magnitudeMinor,
  }) {
    final magnitude = magnitudeMinor.abs();
    return switch (kind) {
      DebtCashEventKind.disbursement => magnitude,
      DebtCashEventKind.payment => -magnitude,
    };
  }
}
