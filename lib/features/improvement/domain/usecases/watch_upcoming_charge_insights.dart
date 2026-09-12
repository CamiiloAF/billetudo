import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import '../../../scheduled_payments/domain/usecases/get_scheduled_payments.dart';
import '../../../scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import '../entities/insight.dart';
import '../entities/insight_thresholds.dart';

/// "Netflix se cobra en 3 días" — a charge already scheduled that falls
/// inside the horizon.
///
/// Deterministic arithmetic over Drift data, **no LLM**: it costs no AI quota,
/// works offline and is available to everyone regardless of tier
/// (`docs/requirements/fase-3/22-centro-notificaciones.md`). The projection
/// reuses [ProjectUpcomingOccurrences], which is pure domain with no I/O and
/// was built precisely as the seam for callers like this one.
///
/// Tone: this states a fact and its date. It never warns, never advises and
/// never implies the user cannot afford it.
@injectable
class WatchUpcomingChargeInsights {
  const WatchUpcomingChargeInsights(this._getScheduledPayments, this._project);

  final GetScheduledPayments _getScheduledPayments;
  final ProjectUpcomingOccurrences _project;

  Stream<Result<List<Insight>>> call() =>
      _getScheduledPayments().map((result) => result.map(_insightsFrom));

  List<Insight> _insightsFrom(List<ScheduledPaymentSummary> summaries) {
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    final horizonEnd = today.add(
      const Duration(days: InsightThresholds.upcomingChargeHorizonDays),
    );

    final byId = <String, ScheduledPaymentSummary>{
      for (final summary in summaries) summary.scheduledPayment.id: summary,
    };

    final projected = _project(
      // `byId`, not `summaries`: `GetScheduledPayments` can now emit more
      // than one summary per template (one per projected upcoming date), so
      // iterating `summaries` here would hand the same `ScheduledPayment` to
      // `ProjectUpcomingOccurrences` N times and recompute its projection
      // redundantly — `byId.values` is already deduplicated by template id.
      templates: [
        for (final summary in byId.values)
          if (summary.scheduledPayment.amountMinor >=
              InsightThresholds.minimumAmountMinor)
            summary.scheduledPayment,
      ],
      windowStart: today,
      windowEndInclusive: horizonEnd,
    );

    final insights = <String, Insight>{};
    for (final occurrence in projected) {
      final summary = byId[occurrence.scheduledPaymentId];
      if (summary == null) {
        continue;
      }
      // A template with a pending occurrence is already covered by
      // `WatchPendingOccurrenceInsights`, and that one is actionable.
      // Announcing both would say the same thing twice.
      if (summary.hasPendingOccurrence) {
        continue;
      }
      final date = DateTime(
        occurrence.date.year,
        occurrence.date.month,
        occurrence.date.day,
      );
      final daysUntil = date.difference(today).inDays;
      final id = 'upcomingCharge:${occurrence.scheduledPaymentId}:'
          '${date.toIso8601String()}';
      // Only the nearest occurrence of each template: a daily template would
      // otherwise fill the whole surface by itself.
      insights.putIfAbsent(
        occurrence.scheduledPaymentId,
        () => Insight(
          id: id,
          type: InsightType.upcomingCharge,
          subject: summary.scheduledPayment.note ?? summary.accountName,
          relevantOn: date,
          targetId: occurrence.scheduledPaymentId,
          amountMinor: occurrence.amountMinor,
          currency: occurrence.currency,
          daysUntil: daysUntil,
        ),
      );
    }

    final result = insights.values.toList()
      ..sort((a, b) => a.relevantOn.compareTo(b.relevantOn));
    return result;
  }
}
