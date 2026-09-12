import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/scheduled_payment_summary.dart';
import '../repositories/scheduled_payment_repository.dart';
import 'project_upcoming_occurrences.dart';

/// How far ahead the "Activos" list projects a template's future occurrences
/// (see [GetScheduledPayments._expand]). This screen has no period boundary
/// of its own the way a budget cycle does, so a fixed forward window stands
/// in for one: long enough that a monthly/weekly template's next few real
/// dates show up, short enough that a daily one does not flood the list.
const _projectionWindowDays = 90;

/// HU-04: reactive list of active templates' upcoming occurrences, ordered
/// by date ascending, for the "próximos vencimientos" screen.
///
/// **2026-09 fix — projected dates, not the raw cursor.** Before this, the
/// list showed exactly one row per template: `scheduledPayment.nextDate`,
/// the template's persisted cursor (only advanced by the catch-up run or by
/// resolving an occurrence). Presupuestos' "Pagos programados del período"
/// sheet reads the very same templates but never trusts that cursor
/// directly — it walks it forward with `ProjectUpcomingOccurrences` until it
/// lands real cadence dates inside the budget's period, which also means it
/// can surface *several* upcoming dates of one template when more than one
/// falls inside that period. A real DB investigation showed the two screens
/// disagreeing on a monthly template's upcoming dates for the exact same
/// reason: this list rendered the stale cursor untouched, Presupuestos'
/// math had already walked past it. The fix adopts the same projection
/// here so both screens agree, per explicit product decision (Presupuestos'
/// behavior is the correct one).
///
/// What did **not** change:
/// - A template with a DUE occurrence is untouched — [ScheduledPaymentsListView](../widgets/scheduled_payments_list_view.dart)
///   still hides it entirely and it surfaces from "Por confirmar" instead; a
///   real due obligation has nothing to project, so [_expand] passes it
///   through as-is.
/// - A template with a non-due *awaiting* occurrence (a future snooze) keeps
///   showing that occurrence's own date — a materialized, already-real
///   commitment always outranks a mere projection (see
///   `ScheduledPaymentSummary.nextPaymentDate`). It is never duplicated by
///   the projection: a projected date that lands on the same day is
///   skipped, the same (template, day) de-duplication Presupuestos' own
///   merge (`BudgetProgressCalculator.scheduledItemsIn`) uses.
/// - A template whose only active occurrences fall entirely outside the
///   window (e.g. a `yearly` one due in 200 days) still shows up — with its
///   raw cursor, same as before — instead of vanishing: it reached this
///   list because the repository's `_activeExpr()` already decided it is
///   still generating occurrences, so an empty projection here only means
///   "farther than the window", never "inactive". A template genuinely past
///   its `endDate` or with its `once` already resolved never reaches this
///   usecase at all — `_activeExpr()` excludes it upstream, same as before.
@injectable
class GetScheduledPayments {
  GetScheduledPayments(this._repository, this._projectOccurrences);

  final ScheduledPaymentRepository _repository;
  final ProjectUpcomingOccurrences _projectOccurrences;

  Stream<Result<List<ScheduledPaymentSummary>>> call() =>
      _repository.watchActiveScheduledPayments().map(
            (result) => result.map(_expand),
          );

  List<ScheduledPaymentSummary> _expand(List<ScheduledPaymentSummary> items) {
    final now = clock.now();
    final windowStart = DateTime(now.year, now.month, now.day);
    final windowEnd = windowStart.add(
      const Duration(days: _projectionWindowDays),
    );

    final expanded = <ScheduledPaymentSummary>[];
    for (final item in items) {
      // A DUE occurrence hides the card entirely downstream (moved to "Por
      // confirmar"): nothing to project, so it is left exactly as before.
      if (item.hasPendingOccurrence) {
        expanded.add(item);
        continue;
      }

      final projected = _projectOccurrences(
        templates: [item.scheduledPayment],
        windowStart: windowStart,
        windowEndInclusive: windowEnd,
      );
      final awaitingDate = item.nextAwaitingDate;

      var projectedAny = false;
      for (final occurrence in projected) {
        if (awaitingDate != null && _isSameDay(occurrence.date, awaitingDate)) {
          // Already represented by the awaiting occurrence's own row below —
          // never double it.
          continue;
        }
        projectedAny = true;
        expanded.add(item.withProjectedDate(occurrence.date));
      }

      if (awaitingDate != null) {
        expanded.add(item);
      } else if (!projectedAny) {
        // Nothing landed inside the window (a rare, far-out cadence): keep
        // the template visible with its raw cursor rather than dropping an
        // active template the repository already vouched for.
        expanded.add(item);
      }
    }

    expanded.sort((a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate));
    return expanded;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
