import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_reminder.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/scheduled_payment_reminder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

/// `HyuO3` (`Reminder Select Sheet`) tal como se abre desde el campo
/// "Recordatorio" del formulario (`dx4G1`).
///
/// "Sin recordatorio" va primero, es el default y lleva `bell-off`: el estado
/// no puede depender solo del check.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required ScheduledPaymentReminder? selected,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            // Por `show`, no por `showModalBottomSheet` a pelo: es la ruta
            // real y la unica que aplica el padding de `BottomSheetBase`.
            // Sin el, el golden hornea una hoja pegada al borde inferior que
            // en la app no existe.
            onPressed: () => ScheduledPaymentReminderSheet.show(
              context,
              selected: selected,
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_reminder_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('sin recordatorio, el default ($suffix)', (tester) async {
      await golden(
        tester,
        'default_$suffix',
        brightness: brightness,
        selected: null,
      );
    });

    testWidgets('con una anticipación elegida ($suffix)', (tester) async {
      await golden(
        tester,
        'selected_$suffix',
        brightness: brightness,
        selected: ScheduledPaymentReminder.threeDaysBefore,
      );
    });
  }
}
