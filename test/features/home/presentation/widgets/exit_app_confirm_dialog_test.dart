import 'package:billetudo/features/home/presentation/widgets/exit_app_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_widget.dart';

void main() {
  Widget triggerButton() => Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            await ExitAppConfirmDialog.show(context);
          },
          child: const Text('open'),
        ),
      );

  testWidgets('muestra título, mensaje y ambos botones', (tester) async {
    await tester.pumpHomeWidget(triggerButton());

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('¿Salir de Billetudo?'), findsOneWidget);
    expect(
      find.text('Puedes volver cuando quieras, tus datos se quedan guardados.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Salir'), findsOneWidget);
  });

  testWidgets('Cancelar cierra el diálogo y resuelve false', (tester) async {
    bool? result;
    await tester.pumpHomeWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ExitAppConfirmDialog.show(context);
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Salir de Billetudo?'), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('Salir cierra el diálogo y resuelve true', (tester) async {
    bool? result;
    await tester.pumpHomeWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ExitAppConfirmDialog.show(context);
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Salir'));
    await tester.pumpAndSettle();

    expect(find.text('¿Salir de Billetudo?'), findsNothing);
    expect(result, isTrue);
  });
}
