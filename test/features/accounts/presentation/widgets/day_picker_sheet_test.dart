import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/presentation/widgets/day_cell.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/day_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  // `tYzxA`/`p6SGT`: tapping a day only stages it — a "Guardar" button below
  // the grid confirms explicitly, instead of the sheet closing on first tap.

  // The 1-31 grid plus the "Guardar" button do not fit the default 800x600
  // test surface; a taller one avoids an unrelated RenderFlex overflow.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(800, 1400);
    view.devicePixelRatio = 1;
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  // `FilledButton.icon` returns the private `_FilledButtonWithIcon` subclass,
  // so `find.byType(FilledButton)` (exact-type match) finds nothing — this
  // predicate matches by `is` instead.
  Finder findSaveButton() =>
      find.byWidgetPredicate((widget) => widget is FilledButton);

  testWidgets('sin selección, "Guardar" arranca deshabilitado', (
    tester,
  ) async {
    await tester.pumpAppWidget(
      const DayPickerSheet(title: 'Día de corte', selected: null),
    );

    final save = tester.widget<FilledButton>(findSaveButton());
    expect(save.onPressed, isNull);
  });

  testWidgets('con selección inicial, "Guardar" arranca habilitado', (
    tester,
  ) async {
    await tester.pumpAppWidget(
      const DayPickerSheet(title: 'Día de corte', selected: 15),
    );

    final save = tester.widget<FilledButton>(findSaveButton());
    expect(save.onPressed, isNotNull);
  });

  testWidgets(
    'tocar un día solo lo marca: no cierra el sheet ni resuelve el Future',
    (tester) async {
      int? poppedValue = -1;
      var didPop = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  final value = await DayPickerSheet.show(
                    context,
                    title: 'Día de corte',
                    selected: null,
                  );
                  didPop = true;
                  poppedValue = value;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10'));
      await tester.pump();

      // El sheet sigue abierto: no se resolvió el Future todavía.
      expect(didPop, isFalse);
      expect(find.byType(DayPickerSheet), findsOneWidget);

      // El día tocado queda marcado como seleccionado.
      final cell = tester.widget<DayCell>(
        find.byWidgetPredicate((w) => w is DayCell && w.day == 10),
      );
      expect(cell.isSelected, isTrue);

      // Y ahora que hay selección, "Guardar" se habilita.
      final save = tester.widget<FilledButton>(findSaveButton());
      expect(save.onPressed, isNotNull);

      // Solo tocar "Guardar" cierra el sheet y resuelve el Future con el día.
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
      expect(poppedValue, 10);
    },
  );

  testWidgets(
    'tocar otro día reemplaza la selección previa (una sola marca a la vez)',
    (tester) async {
      await tester.pumpAppWidget(
        const DayPickerSheet(title: 'Día de corte', selected: 15),
      );

      await tester.tap(find.text('20'));
      await tester.pump();

      final oldCell = tester.widget<DayCell>(
        find.byWidgetPredicate((w) => w is DayCell && w.day == 15),
      );
      final newCell = tester.widget<DayCell>(
        find.byWidgetPredicate((w) => w is DayCell && w.day == 20),
      );
      expect(oldCell.isSelected, isFalse);
      expect(newCell.isSelected, isTrue);
    },
  );
}
