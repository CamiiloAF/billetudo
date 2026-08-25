import 'package:billetudo/core/widgets/sheet_buttons_row.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/confirm_account_conflict_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../pump_widget.dart';

void main() {
  Future<bool?> openSheet(WidgetTester tester) async {
    bool? result;
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ConfirmAccountConflictSheet.show(context);
          },
          child: const Text('abrir'),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets(
      'muestra un mensaje genérico, sin nombrar ni dar pistas de la cuenta '
      'dueña de los datos en conflicto', (tester) async {
    await openSheet(tester);

    expect(
      find.text('Hay datos de otra cuenta en este dispositivo'),
      findsOneWidget,
    );
    expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
  });

  testWidgets(
      'ningún botón está preseleccionado: ninguno lleva autofocus ni foco '
      'inicial', (tester) async {
    await openSheet(tester);

    final row = tester.widget<SheetButtonsRow>(find.byType(SheetButtonsRow));
    final left = row.left as OutlinedButton;
    final right = row.right as FilledButton;

    expect(left.autofocus, isFalse);
    expect(right.autofocus, isFalse);
  });

  testWidgets('no es dismissible con un tap fuera de la hoja (scrim)',
      (tester) async {
    await openSheet(tester);
    expect(find.byType(ConfirmAccountConflictSheet), findsOneWidget);

    // Tap well above the sheet, on the barrier/scrim.
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();

    expect(find.byType(ConfirmAccountConflictSheet), findsOneWidget);
  });

  testWidgets(
      'el botón/gesto atrás de Android no puede cerrar la hoja (PopScope '
      'con canPop: false)', (tester) async {
    await openSheet(tester);

    final finder = find.byWidgetPredicate((widget) => widget is PopScope);
    expect(finder, findsOneWidget);
    final popScope = tester.widget(finder) as PopScope;
    expect(popScope.canPop, isFalse);

    expect(find.byType(ConfirmAccountConflictSheet), findsOneWidget);
  });

  testWidgets('"Borrar y continuar" resuelve a true', (tester) async {
    bool? result;
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ConfirmAccountConflictSheet.show(context);
          },
          child: const Text('abrir'),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Borrar y continuar'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.byType(ConfirmAccountConflictSheet), findsNothing);
  });

  testWidgets('"Cancelar" resuelve a false', (tester) async {
    bool? result;
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ConfirmAccountConflictSheet.show(context);
          },
          child: const Text('abrir'),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.byType(ConfirmAccountConflictSheet), findsNothing);
  });
}
