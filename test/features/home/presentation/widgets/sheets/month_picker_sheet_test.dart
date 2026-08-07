import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/home/presentation/widgets/month_cell.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/month_picker_sheet.dart';
import 'package:billetudo/features/home/presentation/widgets/year_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Non-golden coverage for [MonthPickerSheet] (HU-04, `k7kv4`/`iGwrg`): the
/// year stepper's bound (disabled at the real current year, never
/// hardcoded), the 12-cell grid, month selection dispatching
/// [MonthPickerSheet.onMonthSelected] and closing the sheet, and future
/// months being disabled — computed against `DateTime.now()`, per the
/// widget's own doc ("no hardcodees el mes futuro").
void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required DateTime initialMonth,
    required ValueChanged<DateTime> onMonthSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => MonthPickerSheet.show(
                context,
                initialMonth: initialMonth,
                onMonthSelected: onMonthSelected,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }

  testWidgets('abre con el año del mes inicial y una grilla de 12 celdas',
      (tester) async {
    await pumpSheet(
      tester,
      initialMonth: DateTime(2024, 3),
      onMonthSelected: (_) {},
    );

    expect(find.text('2024'), findsOneWidget);
    expect(find.byType(MonthCell), findsNWidgets(12));
  });

  testWidgets(
      'la celda del mes inicial se marca seleccionada; las demás no',
      (tester) async {
    await pumpSheet(
      tester,
      initialMonth: DateTime(2024, 3),
      onMonthSelected: (_) {},
    );

    final cells =
        tester.widgetList<MonthCell>(find.byType(MonthCell)).toList();
    final selected = cells.where((cell) => cell.isSelected).toList();
    expect(selected, hasLength(1));
    expect(selected.single.label, 'Mar');
  });

  testWidgets(
      'tocar una celda habilitada dispara onMonthSelected con año/mes y '
      'cierra la hoja', (tester) async {
    DateTime? picked;
    await pumpSheet(
      tester,
      initialMonth: DateTime(2024, 3),
      onMonthSelected: (month) => picked = month,
    );

    await tester.tap(find.text('Ene'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2024));
    expect(find.byType(MonthPickerSheet), findsNothing);
  });

  testWidgets(
      'los meses posteriores al mes real actual quedan deshabilitados',
      (tester) async {
    final now = DateTime.now();
    await pumpSheet(
      tester,
      initialMonth: DateTime(now.year, now.month),
      onMonthSelected: (_) {},
    );

    final cells =
        tester.widgetList<MonthCell>(find.byType(MonthCell)).toList();
    // Exactly the months strictly after `now.month` are disabled, within the
    // current year's grid.
    final disabledCount = cells.where((cell) => cell.isDisabled).length;
    expect(disabledCount, 12 - now.month);
  });

  testWidgets(
      'un mes futuro deshabilitado no dispara onMonthSelected ni cierra la '
      'hoja', (tester) async {
    final now = DateTime.now();
    if (now.month == 12) {
      // No future month exists within the current year to assert against.
      return;
    }
    var tapped = 0;
    await pumpSheet(
      tester,
      initialMonth: DateTime(now.year, now.month),
      onMonthSelected: (_) => tapped++,
    );

    final futureCell = tester
        .widgetList<MonthCell>(find.byType(MonthCell))
        .firstWhere((cell) => cell.isDisabled);
    await tester.tap(find.byWidget(futureCell), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tapped, 0);
    expect(find.byType(MonthPickerSheet), findsOneWidget);
  });

  testWidgets(
      'el botón "año siguiente" está deshabilitado en el año actual y no '
      'avanza', (tester) async {
    final now = DateTime.now();
    await pumpSheet(
      tester,
      initialMonth: DateTime(now.year, now.month),
      onMonthSelected: (_) {},
    );

    final nextButton = tester
        .widgetList<YearNavButton>(find.byType(YearNavButton))
        .last;
    expect(nextButton.onPressed, isNull);
    expect(find.text('${now.year}'), findsOneWidget);
  });

  testWidgets(
      'navegar a un año anterior habilita "siguiente" y muestra sus 12 '
      'meses sin deshabilitados', (tester) async {
    final now = DateTime.now();
    await pumpSheet(
      tester,
      initialMonth: DateTime(now.year, now.month),
      onMonthSelected: (_) {},
    );

    final prevButton =
        tester.widgetList<YearNavButton>(find.byType(YearNavButton)).first;
    // `previous year` is always enabled (no lower bound in the widget).
    expect(prevButton.onPressed, isNotNull);

    await tester.tap(find.byType(YearNavButton).first);
    await tester.pumpAndSettle();

    expect(find.text('${now.year - 1}'), findsOneWidget);
    final cells =
        tester.widgetList<MonthCell>(find.byType(MonthCell)).toList();
    expect(cells.every((cell) => !cell.isDisabled), isTrue);

    final nextButtonAfter = tester
        .widgetList<YearNavButton>(find.byType(YearNavButton))
        .last;
    expect(nextButtonAfter.onPressed, isNotNull);
  });
}
