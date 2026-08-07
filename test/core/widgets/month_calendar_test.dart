import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/month_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  group('CalendarMonthGrid', () {
    testWidgets('siempre renderiza 6 filas de 44px, mes de 4 filas visibles',
        (tester) async {
      // February 2026 starts on a Sunday: only 4 visible weeks of real days.
      await tester.pumpWidget(
        wrap(
          CalendarMonthGrid(
            visibleMonth: DateTime(2026, 2),
            selected: null,
            onDaySelected: (_) {},
          ),
        ),
      );

      final rows = tester.widgetList<Row>(find.byType(Row)).toList();
      expect(rows.length, MonthCalendar.weekRows);
    });

    testWidgets('siempre renderiza 6 filas de 44px, mes de 6 filas visibles',
        (tester) async {
      // August 2026 starts on a Saturday: spans 6 visible weeks.
      await tester.pumpWidget(
        wrap(
          CalendarMonthGrid(
            visibleMonth: DateTime(2026, 8),
            selected: null,
            onDaySelected: (_) {},
          ),
        ),
      );

      final rows = tester.widgetList<Row>(find.byType(Row)).toList();
      expect(rows.length, MonthCalendar.weekRows);
    });

    testWidgets('la altura total es igual entre un mes de 4 y uno de 6 filas',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          CalendarMonthGrid(
            visibleMonth: DateTime(2026, 2),
            selected: null,
            onDaySelected: (_) {},
          ),
        ),
      );
      final fourRowHeight =
          tester.getSize(find.byType(CalendarMonthGrid)).height;

      await tester.pumpWidget(
        wrap(
          CalendarMonthGrid(
            visibleMonth: DateTime(2026, 8),
            selected: null,
            onDaySelected: (_) {},
          ),
        ),
      );
      final sixRowHeight =
          tester.getSize(find.byType(CalendarMonthGrid)).height;

      expect(fourRowHeight, sixRowHeight);
    });
  });

  group('MonthCalendar — vista de año', () {
    testWidgets('tocar el label abre la vista de año', (tester) async {
      await tester.pumpWidget(
        wrap(
          MonthCalendar(
            visibleMonth: DateTime(2026, 7),
            selected: null,
            onDaySelected: (_) {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onYearSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(CalendarMonthGrid), findsOneWidget);
      expect(find.byType(CalendarYearGrid), findsNothing);

      await tester.tap(find.text('Julio 2026'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarMonthGrid), findsNothing);
      expect(find.byType(CalendarYearGrid), findsOneWidget);
    });

    testWidgets('elegir un año dispara onYearSelected y vuelve al mes',
        (tester) async {
      int? pickedYear;
      await tester.pumpWidget(
        wrap(
          MonthCalendar(
            visibleMonth: DateTime(2026, 7),
            selected: null,
            onDaySelected: (_) {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onYearSelected: (year) => pickedYear = year,
          ),
        ),
      );

      await tester.tap(find.text('Julio 2026'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2020'));
      await tester.pumpAndSettle();

      expect(pickedYear, 2020);
      expect(find.byType(CalendarMonthGrid), findsOneWidget);
      expect(find.byType(CalendarYearGrid), findsNothing);
    });

    testWidgets(
        'años fuera de disabledBefore/disabledAfter están deshabilitados',
        (tester) async {
      int? pickedYear;
      await tester.pumpWidget(
        wrap(
          MonthCalendar(
            visibleMonth: DateTime(2026, 7),
            selected: null,
            onDaySelected: (_) {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onYearSelected: (year) => pickedYear = year,
            disabledBefore: DateTime(2020),
            disabledAfter: DateTime(2027, 12, 31),
          ),
        ),
      );

      await tester.tap(find.text('Julio 2026'));
      await tester.pumpAndSettle();

      // 2016 is inside the visible 12-year page (2016–2027) but before the
      // disabledBefore floor's year — disabled, tap is a no-op.
      await tester.tap(find.text('2016'));
      await tester.pumpAndSettle();
      expect(pickedYear, isNull);

      final cell2016 = tester.widget<CalendarYearCell>(
        find.byWidgetPredicate(
          (w) => w is CalendarYearCell && w.year == 2016,
        ),
      );
      expect(cell2016.isDisabled, isTrue);

      final cell2026 = tester.widget<CalendarYearCell>(
        find.byWidgetPredicate(
          (w) => w is CalendarYearCell && w.year == 2026,
        ),
      );
      expect(cell2026.isDisabled, isFalse);

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(pickedYear, 2026);
    });

    testWidgets('tocar el rango de años cierra la vista sin elegir',
        (tester) async {
      int? pickedYear;
      await tester.pumpWidget(
        wrap(
          MonthCalendar(
            visibleMonth: DateTime(2026, 7),
            selected: null,
            onDaySelected: (_) {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onYearSelected: (year) => pickedYear = year,
          ),
        ),
      );

      await tester.tap(find.text('Julio 2026'));
      await tester.pumpAndSettle();
      expect(find.text('2016–2027'), findsOneWidget);

      await tester.tap(find.text('2016–2027'));
      await tester.pumpAndSettle();

      expect(pickedYear, isNull);
      expect(find.byType(CalendarMonthGrid), findsOneWidget);
      expect(find.byType(CalendarYearGrid), findsNothing);
    });

    testWidgets('no pierde la selección previa de día al pasar por la vista de año',
        (tester) async {
      final selected = DateTime(2026, 7, 20);
      await tester.pumpWidget(
        wrap(
          MonthCalendar(
            visibleMonth: DateTime(2026, 7),
            selected: selected,
            onDaySelected: (_) {},
            onPreviousMonth: () {},
            onNextMonth: () {},
            onYearSelected: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('Julio 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2016–2027'));
      await tester.pumpAndSettle();

      final calendar = tester.widget<MonthCalendar>(find.byType(MonthCalendar));
      expect(calendar.selected, selected);
    });
  });
}
