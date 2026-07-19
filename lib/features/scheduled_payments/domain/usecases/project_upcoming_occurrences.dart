import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../entities/scheduled_payment.dart';

/// A single projected (not materialized) future date of a [ScheduledPayment],
/// with the amount/type it would carry if generated today.
class ProjectedScheduledOccurrence extends Equatable {
  const ProjectedScheduledOccurrence({
    required this.scheduledPaymentId,
    required this.date,
    required this.amountMinor,
    required this.currency,
    required this.type,
  });

  final String scheduledPaymentId;
  final DateTime date;
  final int amountMinor;
  final String currency;
  final ScheduledPaymentType type;

  @override
  List<Object?> get props =>
      [scheduledPaymentId, date, amountMinor, currency, type];
}

/// Pure domain projection of future occurrence dates within a window,
/// **without** materializing any `ScheduledPaymentOccurrence` row and
/// without touching the repository — a deliberate seam (no I/O) so other
/// features can call it with templates they already hold in memory. Built
/// for Presupuestos' future "próximos pagos programados dentro del período"
/// (HU-12 there), which this corrida does not implement.
///
/// [advance] is also the single source of truth for how a scheduled
/// payment's cadence steps forward; the catch-up generator in `data/` reuses
/// it so the two never drift apart.
@injectable
class ProjectUpcomingOccurrences {
  const ProjectUpcomingOccurrences();

  List<ProjectedScheduledOccurrence> call({
    required List<ScheduledPayment> templates,
    required DateTime windowStart,
    required DateTime windowEndInclusive,
  }) {
    final result = <ProjectedScheduledOccurrence>[];
    for (final template in templates) {
      var date = template.nextDate;
      final endDate = template.endDate;

      while (!date.isAfter(windowEndInclusive)) {
        if (endDate != null && date.isAfter(endDate)) {
          break;
        }
        if (!date.isBefore(windowStart)) {
          result.add(
            ProjectedScheduledOccurrence(
              scheduledPaymentId: template.id,
              date: date,
              amountMinor: template.amountMinor,
              currency: template.currency,
              type: template.type,
            ),
          );
        }
        if (template.frequency == ScheduledPaymentFrequency.once) {
          break;
        }
        date = advance(date, template.frequency, template.interval);
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// Steps [date] forward by one [frequency] unit times [interval]. Calendar
  /// aware for `monthly`/`yearly` (clamps the day-of-month instead of
  /// overflowing into the next month, e.g. Jan 31 + 1 month -> Feb 28/29).
  static DateTime advance(
    DateTime date,
    ScheduledPaymentFrequency frequency,
    int interval,
  ) {
    final step = frequency == ScheduledPaymentFrequency.once ? 1 : interval;
    return switch (frequency) {
      ScheduledPaymentFrequency.once => date,
      ScheduledPaymentFrequency.daily => date.add(Duration(days: step)),
      ScheduledPaymentFrequency.weekly => date.add(Duration(days: 7 * step)),
      ScheduledPaymentFrequency.monthly => _addMonths(date, step),
      ScheduledPaymentFrequency.yearly => _addMonths(date, step * 12),
    };
  }

  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final daysInTargetMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > daysInTargetMonth ? daysInTargetMonth : date.day;
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
