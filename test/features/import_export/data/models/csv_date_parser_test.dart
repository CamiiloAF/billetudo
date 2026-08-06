import 'package:billetudo/features/import_export/data/models/csv_date_parser.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_dialect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CsvDateParser.parse — ISO', () {
    test('YYYY-MM-DD se interpreta correctamente', () {
      final parsed = CsvDateParser.parse(
        '2026-07-29',
        order: DateComponentOrder.isoYmd,
        separator: DateSeparatorChar.dash,
      );

      expect(parsed!.date, DateTime(2026, 7, 29));
      expect(parsed.ambiguous, isFalse);
    });
  });

  group('CsvDateParser.parse — día/mes/año', () {
    test('03/04/2026 con orden DMY es el 3 de abril', () {
      final parsed = CsvDateParser.parse(
        '03/04/2026',
        order: DateComponentOrder.dayMonthYear,
        separator: DateSeparatorChar.slash,
      );

      expect(parsed!.date, DateTime(2026, 4, 3));
    });

    test('día y mes <= 12 se marca ambiguo (podría ser MDY)', () {
      final parsed = CsvDateParser.parse(
        '03/04/2026',
        order: DateComponentOrder.dayMonthYear,
        separator: DateSeparatorChar.slash,
      );

      expect(parsed!.ambiguous, isTrue);
    });

    test('día > 12 nunca es ambiguo (solo puede ser DMY)', () {
      final parsed = CsvDateParser.parse(
        '25/04/2026',
        order: DateComponentOrder.dayMonthYear,
        separator: DateSeparatorChar.slash,
      );

      expect(parsed!.date, DateTime(2026, 4, 25));
      expect(parsed.ambiguous, isFalse);
    });
  });

  group('CsvDateParser.parse — mes/día/año', () {
    test('04/25/2026 con orden MDY es el 25 de abril', () {
      final parsed = CsvDateParser.parse(
        '04/25/2026',
        order: DateComponentOrder.monthDayYear,
        separator: DateSeparatorChar.slash,
      );

      expect(parsed!.date, DateTime(2026, 4, 25));
    });
  });

  group('CsvDateParser.parse — fechas inválidas', () {
    test('un día fuera de rango (Feb 30) se rechaza, no se normaliza', () {
      final parsed = CsvDateParser.parse(
        '2026-02-30',
        order: DateComponentOrder.isoYmd,
        separator: DateSeparatorChar.dash,
      );

      expect(parsed, isNull);
    });

    test('un mes fuera de 1..12 se rechaza', () {
      final parsed = CsvDateParser.parse(
        '2026-13-01',
        order: DateComponentOrder.isoYmd,
        separator: DateSeparatorChar.dash,
      );

      expect(parsed, isNull);
    });

    test('texto vacío se rechaza', () {
      expect(
        CsvDateParser.parse(
          '',
          order: DateComponentOrder.isoYmd,
          separator: DateSeparatorChar.dash,
        ),
        isNull,
      );
    });

    test('un separador distinto al configurado no matchea', () {
      expect(
        CsvDateParser.parse(
          '03-04-2026',
          order: DateComponentOrder.dayMonthYear,
          separator: DateSeparatorChar.slash,
        ),
        isNull,
      );
    });
  });

  group('CsvDateParser.parse — sufijo de hora (exportaciones de terceros)', () {
    test('ISO con hora "2026-07-05 22:14:10" parsea solo la fecha', () {
      final parsed = CsvDateParser.parse(
        '2026-07-05 22:14:10',
        order: DateComponentOrder.isoYmd,
        separator: DateSeparatorChar.dash,
      );

      expect(parsed!.date, DateTime(2026, 7, 5));
    });

    test('DMY con hora "05/07/2026 22:14:10" parsea solo la fecha', () {
      final parsed = CsvDateParser.parse(
        '05/07/2026 22:14:10',
        order: DateComponentOrder.dayMonthYear,
        separator: DateSeparatorChar.slash,
      );

      expect(parsed!.date, DateTime(2026, 7, 5));
    });

    test('MDY con hora "07/25/2026 08:00:00" parsea solo la fecha', () {
      final parsed = CsvDateParser.parse(
        '07/25/2026 08:00:00',
        order: DateComponentOrder.monthDayYear,
        separator: DateSeparatorChar.slash,
      );

      expect(parsed!.date, DateTime(2026, 7, 25));
    });

    test('con punto como separador y hora, también parsea solo la fecha', () {
      final parsed = CsvDateParser.parse(
        '05.07.2026 22:14',
        order: DateComponentOrder.dayMonthYear,
        separator: DateSeparatorChar.dot,
      );

      expect(parsed!.date, DateTime(2026, 7, 5));
    });

    test('sin sufijo de hora el comportamiento no cambia', () {
      final parsed = CsvDateParser.parse(
        '2026-07-05',
        order: DateComponentOrder.isoYmd,
        separator: DateSeparatorChar.dash,
      );

      expect(parsed!.date, DateTime(2026, 7, 5));
    });
  });
}
