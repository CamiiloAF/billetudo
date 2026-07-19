import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/usecases/project_upcoming_occurrences.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scheduled_payment_fixtures.dart';

void main() {
  group('ProjectUpcomingOccurrences.advance', () {
    test('daily/weekly avanzan por días', () {
      expect(
        ProjectUpcomingOccurrences.advance(
          DateTime(2026, 7, 1),
          ScheduledPaymentFrequency.daily,
          3,
        ),
        DateTime(2026, 7, 4),
      );
      expect(
        ProjectUpcomingOccurrences.advance(
          DateTime(2026, 7, 1),
          ScheduledPaymentFrequency.weekly,
          2,
        ),
        DateTime(2026, 7, 15),
      );
    });

    test('monthly conserva el día cuando cabe en el mes destino', () {
      expect(
        ProjectUpcomingOccurrences.advance(
          DateTime(2026, 1, 15),
          ScheduledPaymentFrequency.monthly,
          1,
        ),
        DateTime(2026, 2, 15),
      );
    });

    test('monthly ajusta al último día cuando el mes destino es más corto',
        () {
      // 31 de enero + 1 mes -> 28 de febrero de 2026 (no bisiesto).
      expect(
        ProjectUpcomingOccurrences.advance(
          DateTime(2026, 1, 31),
          ScheduledPaymentFrequency.monthly,
          1,
        ),
        DateTime(2026, 2, 28),
      );
    });

    test('yearly avanza por años completos', () {
      expect(
        ProjectUpcomingOccurrences.advance(
          DateTime(2026, 3, 10),
          ScheduledPaymentFrequency.yearly,
          1,
        ),
        DateTime(2027, 3, 10),
      );
    });

    test('once nunca avanza', () {
      final date = DateTime(2026, 7, 1);
      expect(
        ProjectUpcomingOccurrences.advance(
          date,
          ScheduledPaymentFrequency.once,
          1,
        ),
        date,
      );
    });
  });

  group('ProjectUpcomingOccurrences.call', () {
    test('proyecta una única fecha para once dentro de la ventana', () {
      final templates = [
        buildScheduledPayment(
          frequency: ScheduledPaymentFrequency.once,
          nextDate: DateTime(2026, 7, 10),
        ),
      ];

      final result = const ProjectUpcomingOccurrences()(
        templates: templates,
        windowStart: DateTime(2026, 7, 1),
        windowEndInclusive: DateTime(2026, 7, 31),
      );

      expect(result, hasLength(1));
      expect(result.single.date, DateTime(2026, 7, 10));
    });

    test('proyecta varias fechas repetibles respetando endDate', () {
      final templates = [
        buildScheduledPayment(
          nextDate: DateTime(2026, 6, 1),
          endDate: DateTime(2026, 8, 15),
        ),
      ];

      final result = const ProjectUpcomingOccurrences()(
        templates: templates,
        windowStart: DateTime(2026, 1, 1),
        windowEndInclusive: DateTime(2026, 12, 31),
      );

      expect(
        result.map((o) => o.date),
        [DateTime(2026, 6, 1), DateTime(2026, 7, 1), DateTime(2026, 8, 1)],
      );
    });
  });
}
