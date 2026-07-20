import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_occurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduledPaymentOccurrence.dateIsDueOn', () {
    final now = DateTime(2026, 7, 15, 10, 30);

    test('hoy mismo cuenta como vencido', () {
      expect(
        ScheduledPaymentOccurrence.dateIsDueOn(DateTime(2026, 7, 15), now),
        isTrue,
      );
    });

    test('una fecha pasada cuenta como vencida', () {
      expect(
        ScheduledPaymentOccurrence.dateIsDueOn(DateTime(2026, 7, 1), now),
        isTrue,
      );
    });

    test('una fecha futura no cuenta como vencida', () {
      expect(
        ScheduledPaymentOccurrence.dateIsDueOn(DateTime(2026, 7, 16), now),
        isFalse,
      );
    });

    test('ignora la hora, solo compara el día calendario', () {
      // `now` trae hora 10:30; una fecha el mismo día pero más tarde en el
      // reloj sigue contando como "hoy" (vencida), no como futura.
      expect(
        ScheduledPaymentOccurrence.dateIsDueOn(
          DateTime(2026, 7, 15, 23, 59),
          now,
        ),
        isTrue,
      );
    });
  });

  group('ScheduledPaymentOccurrence.isDueOn', () {
    final now = DateTime(2026, 7, 15);

    ScheduledPaymentOccurrence buildOccurrence({
      DateTime? occurrenceDate,
      DateTime? snoozedToDate,
    }) =>
        ScheduledPaymentOccurrence(
          id: 'occ-1',
          scheduledPaymentId: 'sp-1',
          occurrenceDate: occurrenceDate ?? DateTime(2026, 7, 15),
          status: ScheduledOccurrenceStatus.pending,
          snoozedToDate: snoozedToDate,
          createdAt: DateTime(2026, 7, 1),
          updatedAt: 0,
        );

    test('usa effectiveDate, no occurrenceDate, cuando está pospuesta', () {
      // occurrenceDate ya venció, pero el pospuesto la manda al futuro: no
      // debe aparecer como pendiente todavía.
      final occurrence = buildOccurrence(
        occurrenceDate: DateTime(2026, 6, 1),
        snoozedToDate: DateTime(2026, 8, 1),
      );

      expect(occurrence.isDueOn(now), isFalse);
    });

    test('sin posponer, usa occurrenceDate directamente', () {
      final occurrence = buildOccurrence(occurrenceDate: DateTime(2026, 7, 1));

      expect(occurrence.isDueOn(now), isTrue);
    });
  });
}
