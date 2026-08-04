import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/date_picker_sheet.dart';
import 'package:billetudo/core/widgets/month_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(initializeDateFormatting);

  Future<DateTime?> openPicker(
    WidgetTester tester, {
    required DateTime initialDate,
  }) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await DatePickerSheet.show(
                    context,
                    initialDate: initialDate,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('muestra el título y el mes inicial', (tester) async {
    await openPicker(tester, initialDate: DateTime(2026, 7, 15));

    expect(find.text('Elegir fecha'), findsOneWidget);
    expect(find.text('Julio 2026'), findsOneWidget);
    // Weekday header Monday-first.
    expect(find.byType(MonthCalendar), findsOneWidget);
  });

  testWidgets('tocar un día selecciona sin cerrar; Confirmar devuelve la fecha',
      (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  picked = await DatePickerSheet.show(
                    context,
                    initialDate: DateTime(2026, 7, 15),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();

    // Selecting a day keeps the sheet open.
    expect(find.text('Elegir fecha'), findsOneWidget);

    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Elegir fecha'), findsNothing); // cerró
    expect(picked, DateTime(2026, 7, 20));
  });

  testWidgets('Cancelar cierra el sheet sin devolver fecha', (tester) async {
    DateTime? picked;
    var completed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  picked = await DatePickerSheet.show(
                    context,
                    initialDate: DateTime(2026, 7, 15),
                  );
                  completed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Elegir fecha'), findsNothing);
    expect(completed, isTrue);
    expect(picked, isNull);
  });

  testWidgets('los chevrons cambian de mes con wrap de año', (tester) async {
    await openPicker(tester, initialDate: DateTime(2026, 1, 10));

    expect(find.text('Enero 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Diciembre 2025'), findsOneWidget);
  });

  group('sin initialDate (sin selección aún, ej. meta nueva sin fecha)', () {
    Future<DateTime?> openWithoutInitialDate(WidgetTester tester) async {
      DateTime? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await DatePickerSheet.show(context);
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('abre en el mes actual sin ningún día resaltado',
        (tester) async {
      await openWithoutInitialDate(tester);

      expect(find.byType(MonthCalendar), findsOneWidget);
      final calendar = tester.widget<MonthCalendar>(find.byType(MonthCalendar));
      expect(calendar.selected, isNull);
    });

    testWidgets('Confirmar queda deshabilitado hasta tocar un día',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => DatePickerSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final confirmButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirmar'),
      );
      expect(confirmButton.onPressed, isNull);
    });

    testWidgets('tocar un día habilita Confirmar y lo devuelve',
        (tester) async {
      final picked = await () async {
        DateTime? result;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await DatePickerSheet.show(context);
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final today = DateTime.now();
        await tester.tap(find.text(today.day.toString()));
        await tester.pumpAndSettle();

        final confirmButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Confirmar'),
        );
        expect(confirmButton.onPressed, isNotNull);

        await tester.tap(find.text('Confirmar'));
        await tester.pumpAndSettle();
        return result;
      }();

      final today = DateUtils.dateOnly(DateTime.now());
      expect(picked, today);
    });
  });
}
