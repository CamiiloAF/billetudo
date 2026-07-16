import 'package:billetudo/features/home/presentation/widgets/month_cell.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/month_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pump_widget.dart';

void main() {
  setUpAll(initializeDateFormatting);

  MonthCell cellFor(WidgetTester tester, String label) =>
      tester.widget<MonthCell>(
        find.ancestor(of: find.text(label), matching: find.byType(MonthCell)),
      );

  testWidgets(
      'marca el mes seleccionado y deshabilita los meses futuros '
      '(HU-04)', (tester) async {
    // Current month = July 2026; showing July.
    await tester.pumpHomeWidget(
      // A phone-width sheet anchored to the bottom, mirroring how the modal
      // bottom sheet renders on a device. The full-width test surface would
      // otherwise stretch the month grid tall enough to overflow — which never
      // happens on a real (narrow) screen.
      Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 360,
          child: MonthPickerSheet(
            selected: DateTime(2026, 7),
            currentMonth: DateTime(2026, 7),
          ),
        ),
      ),
    );

    // July is selected; August..December are in the future and disabled.
    expect(cellFor(tester, 'Jul').isSelected, isTrue);
    expect(cellFor(tester, 'Jul').isDisabled, isFalse);
    expect(cellFor(tester, 'Jun').isDisabled, isFalse);
    expect(cellFor(tester, 'Ago').isDisabled, isTrue);
    expect(cellFor(tester, 'Dic').isDisabled, isTrue);
  });

  testWidgets('etiquetas de mes en inglés cuando el locale es en',
      (tester) async {
    await tester.pumpHomeWidget(
      Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 360,
          child: MonthPickerSheet(
            selected: DateTime(2026, 7),
            currentMonth: DateTime(2026, 7),
          ),
        ),
      ),
      locale: const Locale('en'),
    );

    // English short month names, not the Spanish 'Ago'/'Dic'.
    expect(find.text('Aug'), findsOneWidget);
    expect(find.text('Dec'), findsOneWidget);
  });

  testWidgets('elegir un mes pasado resuelve con el primer día de ese mes',
      (tester) async {
    DateTime? picked;
    await tester.pumpHomeWidget(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await MonthPickerSheet.show(
              context,
              selected: DateTime(2026, 7),
              currentMonth: DateTime(2026, 7),
            );
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mar'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 3));
  });

  testWidgets('tocar un mes futuro deshabilitado no resuelve nada',
      (tester) async {
    DateTime? picked;
    var closed = false;
    await tester.pumpHomeWidget(
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await MonthPickerSheet.show(
              context,
              selected: DateTime(2026, 7),
              currentMonth: DateTime(2026, 7),
            );
            closed = true;
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // December 2026 is in the future: the cell is not tappable.
    await tester.tap(find.text('Dic'));
    await tester.pumpAndSettle();

    // The sheet is still open and nothing was resolved.
    expect(closed, isFalse);
    expect(picked, isNull);
    expect(find.byType(MonthCell), findsNWidgets(12));
  });

  testWidgets('el navegador de año no avanza más allá del año en curso',
      (tester) async {
    await tester.pumpHomeWidget(
      // A phone-width sheet anchored to the bottom, mirroring how the modal
      // bottom sheet renders on a device. The full-width test surface would
      // otherwise stretch the month grid tall enough to overflow — which never
      // happens on a real (narrow) screen.
      Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 360,
          child: MonthPickerSheet(
            selected: DateTime(2026, 7),
            currentMonth: DateTime(2026, 7),
          ),
        ),
      ),
    );

    final navigator = tester.widget<YearNavigator>(find.byType(YearNavigator));
    // Already on the current year: forward is blocked.
    expect(navigator.canGoForward, isFalse);
    expect(navigator.onNext, isNull);

    // Going back a year re-enables forward and lifts the future lock for
    // every month of the past year.
    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    expect(find.text('2025'), findsOneWidget);
    expect(cellFor(tester, 'Dic').isDisabled, isFalse);
  });
}
