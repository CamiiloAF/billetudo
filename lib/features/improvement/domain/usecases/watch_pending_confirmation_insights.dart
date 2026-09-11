import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../scheduled_payments/domain/entities/pending_scheduled_occurrence.dart';
import '../../../scheduled_payments/domain/usecases/get_pending_occurrences.dart';
import '../entities/insight.dart';
import '../entities/insight_thresholds.dart';

/// "Arriendo espera tu confirmación" — a manual-mode occurrence that is
/// already due and has not been resolved.
///
/// Reuses `GetPendingOccurrences`, which already filters to occurrences that
/// are actually due today or earlier, so nothing here has to re-derive that
/// rule. Deterministic, offline, no LLM.
///
/// Tone: the pending state is a design decision the user made when they chose
/// manual mode, not a mistake. The insight says it is waiting, never that
/// they forgot.
@injectable
class WatchPendingConfirmationInsights {
  const WatchPendingConfirmationInsights(this._getPendingOccurrences);

  final GetPendingOccurrences _getPendingOccurrences;

  Stream<Result<List<Insight>>> call() =>
      _getPendingOccurrences().map((result) => result.map(_insightsFrom));

  List<Insight> _insightsFrom(List<PendingScheduledOccurrence> pending) {
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);

    final insights = <Insight>[];
    for (final item in pending) {
      final template = item.scheduledPayment;
      if (template.amountMinor < InsightThresholds.minimumAmountMinor) {
        continue;
      }
      final due = item.occurrence.effectiveDate;
      final date = DateTime(due.year, due.month, due.day);
      insights.add(
        Insight(
          id: 'pendingConfirmation:${item.occurrence.id}',
          type: InsightType.pendingConfirmation,
          subject: template.note ?? item.accountName,
          relevantOn: date,
          targetId: template.id,
          amountMinor: template.amountMinor,
          currency: template.currency,
          daysUntil: date.difference(today).inDays,
        ),
      );
    }
    insights.sort((a, b) => a.relevantOn.compareTo(b.relevantOn));
    return insights;
  }
}
