import 'package:injectable/injectable.dart';

import '../entities/debt.dart';
import '../entities/debt_balance.dart';
import '../entities/debt_cash_event.dart';
import '../entities/debt_entry.dart';
import '../entities/debt_ledger_entry.dart';
import 'debt_event_rules.dart';

/// Pure domain service that derives a debt's outstanding balance and its
/// unified history from the three inputs that make up the ledger:
///
///   outstanding = principal (opening)
///               + Σ effect of cash events   (Transactions with the debt id)
///               + Σ signed DebtEntry amounts (interest, adjustments, cash-less
///                                             payments/disbursements)
///
/// How it combines the two natures of event:
///  - **Cash events** ([DebtCashEvent]) carry a positive amount; their sign
///    depends on the debt's `direction` × the transaction `type`, resolved once
///    in [DebtEventRules.cashEventEffect]. Same money direction means opposite
///    things for `iOwe` vs `owedToMe`.
///  - **Ledger entries** ([DebtEntry]) already carry a signed `amountMinor`
///    (+ increases, − reduces), so they are summed as-is.
///
/// Each contribution is bucketed into "increases" or "decreases" by the sign of
/// its effect, which is what powers the "pagado / total" progress bar. The raw
/// balance may pass below 0 (over-payment); [DebtBalance] clamps the displayed
/// figure and flags `settled`.
@lazySingleton
class DebtBalanceCalculator {
  const DebtBalanceCalculator();

  DebtBalance calculate({
    required Debt debt,
    required List<DebtEntry> entries,
    required List<DebtCashEvent> cashEvents,
  }) {
    // The opening principal is an increase. Clamp defensively: a debt should
    // never carry a negative opening figure.
    final principal = debt.principalMinor < 0 ? 0 : debt.principalMinor;
    var increases = principal;
    var decreases = 0;
    var interest = 0;

    for (final event in cashEvents) {
      final effect = DebtEventRules.cashEventEffect(
        direction: debt.direction,
        type: event.type,
        amountMinor: event.amountMinor,
      );
      if (effect >= 0) {
        increases += effect;
      } else {
        decreases += -effect;
      }
    }

    for (final entry in entries) {
      final effect = entry.amountMinor;
      if (entry.kind == DebtEntryKind.interestAccrual) {
        interest += effect;
      }
      if (effect >= 0) {
        increases += effect;
      } else {
        decreases += -effect;
      }
    }

    return DebtBalance(
      principalMinor: principal,
      totalIncreasesMinor: increases,
      totalDecreasesMinor: decreases,
      interestAccruedMinor: interest,
    );
  }

  /// Builds the unified, newest-first history (HU-04): an opening row (when the
  /// principal is non-zero), every cash event and every ledger entry, each with
  /// its signed effect already resolved so presentation renders it verbatim.
  List<DebtLedgerEntry> buildLedger({
    required Debt debt,
    required List<DebtEntry> entries,
    required List<DebtCashEvent> cashEvents,
  }) {
    final items = <DebtLedgerEntry>[];

    if (debt.principalMinor != 0) {
      items.add(
        DebtLedgerEntry(
          id: 'opening',
          kind: DebtLedgerKind.opening,
          // The synthetic opening row is dated on the debt's start date (its
          // first day), not on `createdAt` (when the row was written). A
          // solo-deuda opening has no backing `Transaction`, so this derived
          // date is the only date the user sees for it — it must follow the
          // "Fecha" field and move when that is edited. `createdAt` stays the
          // ordering key (see the same-day tiebreak in `sort`).
          date: debt.effectiveStartDate,
          createdAt: debt.createdAt,
          effectMinor: debt.principalMinor,
        ),
      );
    }

    for (final event in cashEvents) {
      final effect = DebtEventRules.cashEventEffect(
        direction: debt.direction,
        type: event.type,
        amountMinor: event.amountMinor,
      );
      items.add(
        DebtLedgerEntry(
          id: event.transactionId,
          kind: effect >= 0
              ? DebtLedgerKind.cashDisbursement
              : DebtLedgerKind.cashPayment,
          date: event.date,
          createdAt: event.createdAt,
          effectMinor: effect,
          note: event.note,
          transactionId: event.transactionId,
        ),
      );
    }

    for (final entry in entries) {
      items.add(
        DebtLedgerEntry(
          id: entry.id,
          kind: _ledgerKindOf(entry),
          date: entry.entryDate,
          createdAt: entry.createdAt,
          effectMinor: entry.amountMinor,
          note: entry.note,
          entryId: entry.id,
        ),
      );
    }

    // Newest first by event date. On the same day, break ties by creation time
    // (newest-created first) so the opening/initial row — created before any
    // abono — sinks to the bottom of its day and the running balance stays
    // consistent. A final id tiebreak keeps the order deterministic.
    items.sort((a, b) {
      // Primary order is by the event's calendar DAY (not the raw timestamp),
      // so any two movements on the same day fall through to the creation-time
      // tiebreak below — the rule is "same day → order by creation", which must
      // hold even if an event's `date` ever carries a time component.
      final aDay = DateTime(a.date.year, a.date.month, a.date.day);
      final bDay = DateTime(b.date.year, b.date.month, b.date.day);
      final byDate = bDay.compareTo(aDay);
      if (byDate != 0) {
        return byDate;
      }
      final byCreatedAt = b.createdAt.compareTo(a.createdAt);
      if (byCreatedAt != 0) {
        return byCreatedAt;
      }
      return a.id.compareTo(b.id);
    });
    return items;
  }

  DebtLedgerKind _ledgerKindOf(DebtEntry entry) => switch (entry.kind) {
        DebtEntryKind.interestAccrual => DebtLedgerKind.interestAccrual,
        DebtEntryKind.manualAdjustment => DebtLedgerKind.manualAdjustment,
        DebtEntryKind.payment => DebtLedgerKind.ledgerPayment,
        DebtEntryKind.disbursement => DebtLedgerKind.ledgerDisbursement,
      };
}
