import 'package:billetudo/core/sync/presentation/widgets/sheets/confirm_discard_all_quarantined_changes_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../pump_sync.dart';

/// La hoja de confirmación del bulk (`EtwDY`), pluralizada alrededor del
/// conteo. Mismo patrón destructivo que la individual (`qZvmL`), pero el
/// botón de confirmar dice "Descartar todo" sin el número.
void main() {
  Future<void> openViaShow(WidgetTester tester, int count) =>
      tester.pumpSyncWidget(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ConfirmDiscardAllQuarantinedChangesSheet.show(
              context,
              count: count,
            ),
            child: const Text('abrir'),
          ),
        ),
      );

  testWidgets('el título y el cuerpo llevan el conteo real, plural',
      (tester) async {
    await openViaShow(tester, 5);
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('¿Descartar los 5 cambios pendientes?'), findsOneWidget);
    expect(
      find.textContaining('Se van a descartar 5 cambios pendientes'),
      findsOneWidget,
    );
  });

  testWidgets('un solo pendiente usa singular', (tester) async {
    await openViaShow(tester, 1);
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('¿Descartar el cambio pendiente?'), findsOneWidget);
  });

  testWidgets('el botón de confirmar dice "Descartar todo" sin el número',
      (tester) async {
    await openViaShow(tester, 89);
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Descartar todo'), findsOneWidget);
    expect(find.text('Descartar todo (89)'), findsNothing);
  });

  testWidgets('confirmar resuelve a true', (tester) async {
    late Future<bool?> result;
    await tester.pumpSyncWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            result = ConfirmDiscardAllQuarantinedChangesSheet.show(
              context,
              count: 3,
            );
          },
          child: const Text('abrir'),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Descartar todo'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('cancelar resuelve a false', (tester) async {
    late Future<bool?> result;
    await tester.pumpSyncWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            result = ConfirmDiscardAllQuarantinedChangesSheet.show(
              context,
              count: 3,
            );
          },
          child: const Text('abrir'),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });
}
