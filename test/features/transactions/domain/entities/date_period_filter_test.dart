import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-06b — "Este mes" por defecto', () {
    test('el default es siempre el mes en curso', () {
      final filter = DatePeriodFilter.thisMonth(DateTime(2026, 7, 15));

      expect(filter.granularity, DateGranularity.month);
      expect(filter.isCustomRange, isFalse);
      expect(filter.start, DateTime(2026, 7));
      expect(filter.endExclusive, DateTime(2026, 8));
    });
  });

  group('periodos granulares', () {
    test('semana: lunes a lunes siguiente (ISO)', () {
      // Miércoles 15 de julio de 2026.
      final filter = DatePeriodFilter.granular(
          DateGranularity.week, DateTime(2026, 7, 15));

      expect(filter.start, DateTime(2026, 7, 13)); // lunes
      expect(filter.endExclusive, DateTime(2026, 7, 20)); // lunes siguiente
    });

    test('mes: primer día al primer día del mes siguiente', () {
      final filter = DatePeriodFilter.granular(
          DateGranularity.month, DateTime(2026, 2, 10));

      expect(filter.start, DateTime(2026, 2));
      expect(filter.endExclusive, DateTime(2026, 3));
    });

    test('mes: diciembre cruza al año siguiente', () {
      final filter = DatePeriodFilter.granular(
          DateGranularity.month, DateTime(2026, 12, 25));

      expect(filter.start, DateTime(2026, 12));
      expect(filter.endExclusive, DateTime(2027));
    });

    test('año: 1 de enero a 1 de enero del año siguiente', () {
      final filter = DatePeriodFilter.granular(
          DateGranularity.year, DateTime(2026, 7, 15));

      expect(filter.start, DateTime(2026));
      expect(filter.endExclusive, DateTime(2027));
    });
  });

  group('HU-06b — stepper de granularidad, aplica de inmediato', () {
    test('mes siguiente/anterior', () {
      final julio = DatePeriodFilter.granular(
          DateGranularity.month, DateTime(2026, 7, 15));

      expect(julio.stepped(1).start, DateTime(2026, 8));
      expect(julio.stepped(-1).start, DateTime(2026, 6));
    });

    test('mes siguiente cruza de diciembre a enero', () {
      final diciembre =
          DatePeriodFilter.granular(DateGranularity.month, DateTime(2026, 12));

      expect(diciembre.stepped(1).start, DateTime(2027));
    });

    test('semana siguiente/anterior avanza 7 días', () {
      final semana = DatePeriodFilter.granular(
          DateGranularity.week, DateTime(2026, 7, 15));

      expect(semana.stepped(1).start, DateTime(2026, 7, 20));
      expect(semana.stepped(-1).start, DateTime(2026, 7, 6));
    });

    test('año siguiente/anterior', () {
      final anio = DatePeriodFilter.granular(
          DateGranularity.year, DateTime(2026, 7, 15));

      expect(anio.stepped(1).start, DateTime(2027));
      expect(anio.stepped(-1).start, DateTime(2025));
    });

    test(
        'cambiar de granularidad reancla al periodo que contiene la fecha activa',
        () {
      final mes = DatePeriodFilter.granular(
          DateGranularity.month, DateTime(2026, 7, 15));

      final anio = mes.withGranularity(DateGranularity.year);

      expect(anio.granularity, DateGranularity.year);
      expect(anio.start, DateTime(2026));
      expect(anio.endExclusive, DateTime(2027));
    });
  });

  group('HU-06b — rango personalizado', () {
    test('exige aplicar: no tiene granularidad ni stepper', () {
      final range = DatePeriodFilter.custom(
        start: DateTime(2026, 7, 3),
        end: DateTime(2026, 7, 9),
      );

      expect(range.isCustomRange, isTrue);
      expect(range.granularity, isNull);
      expect(range.start, DateTime(2026, 7, 3));
      // Fin inclusivo -> exclusivo: incluye todo el 9 de julio.
      expect(range.endExclusive, DateTime(2026, 7, 10));
    });

    test('rechaza un rango con fin anterior al inicio', () {
      expect(
        () => DatePeriodFilter.custom(
          start: DateTime(2026, 7, 9),
          end: DateTime(2026, 7, 3),
        ),
        throwsArgumentError,
      );
    });

    test('la "X" regresa siempre a "Este mes", nunca a "sin filtro"', () {
      final cleared =
          DatePeriodFilter.clearedToThisMonth(DateTime(2026, 7, 15));

      expect(cleared.isCustomRange, isFalse);
      expect(cleared.granularity, DateGranularity.month);
      expect(cleared.start, DateTime(2026, 7));
    });
  });
}
