import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/widgets/sync_pending_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_sync.dart';

/// Contrato de texto de `VtiBc`: el título nombra la fila en el idioma del
/// usuario (tipo + descripción), **nunca** un nombre de tabla ni un código.
/// La jerga técnica solo existe en el registro técnico (`T7Iw0C`).
void main() {
  PendingSyncChange change({
    String tableName = 'transactions',
    Map<String, dynamic>? payload,
    int attempts = 2,
    DateTime? pendingSince,
  }) =>
      PendingSyncChange.fromOperation(
        QuarantinedOperation(
          id: 'q-1',
          operation: SyncOperation(
            tableName: tableName,
            rowId: 'row-1',
            type: SyncOperationType.put,
            payload: payload,
          ),
          kind: SyncFailureKind.brokenSchema,
          errorCode: 'PGRST204',
          errorMessage: 'column goal_contributions.streak does not exist',
          quarantinedAt: pendingSince ?? DateTime(2026, 7, 25),
          updatedAt: pendingSince ?? DateTime(2026, 7, 25),
          attempts: attempts,
        ),
      );

  Future<void> pumpRow(
    WidgetTester tester,
    PendingSyncChange value, {
    VoidCallback? onTap,
  }) =>
      tester.pumpSyncWidget(
        SyncPendingRow(change: value, onTap: onTap ?? () {}),
      );

  group('título: tipo · descripción, en el idioma del usuario', () {
    testWidgets('un movimiento con nota se titula "Movimiento · Café con Ana"',
        (tester) async {
      await pumpRow(
        tester,
        change(payload: const {'note': 'Café con Ana'}),
      );

      expect(find.text('Movimiento · Café con Ana'), findsOneWidget);
    });

    testWidgets('sin descripción muestra solo el tipo, nunca la tabla',
        (tester) async {
      await pumpRow(tester, change());

      expect(find.text('Movimiento'), findsOneWidget);
      expect(find.textContaining('transactions'), findsNothing);
    });
  });

  group('NUNCA se filtra jerga técnica (regla de producto, no cosmética)', () {
    testWidgets(
        'goal_contributions se lee "Aporte a meta", jamás el nombre '
        'de la tabla', (tester) async {
      await pumpRow(tester, change(tableName: 'goal_contributions'));

      expect(find.text('Aporte a meta'), findsOneWidget);
      expect(find.textContaining('goal_contributions'), findsNothing);
    });

    testWidgets('una tabla no mapeada degrada a "Cambio", no la expone',
        (tester) async {
      await pumpRow(tester, change(tableName: 'goal_contribution_streaks'));

      expect(find.text('Cambio'), findsOneWidget);
      expect(find.textContaining('goal_contribution_streaks'), findsNothing);
      expect(find.textContaining('_'), findsNothing);
    });

    testWidgets('ningún texto de la fila contiene un código del backend',
        (tester) async {
      await pumpRow(
        tester,
        change(
          tableName: 'debts',
          payload: const {'name': 'Préstamo a Ana'},
        ),
      );

      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(SyncPendingRow),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data ?? '')
          .join(' | ');

      expect(texts, contains('Deuda · Préstamo a Ana'));
      expect(texts, isNot(contains('PGRST204')));
      expect(texts, isNot(contains('debts')));
      expect(texts, isNot(contains('does not exist')));
    });

    testWidgets('la meta no imprime un timestamp ISO', (tester) async {
      await pumpRow(tester, change(pendingSince: DateTime(2026, 7, 25, 9, 30)));

      expect(find.textContaining('2026-07-25T'), findsNothing);
      expect(find.textContaining('09:30'), findsNothing);
    });
  });

  group('meta: desde cuándo espera y cuántos intentos lleva', () {
    testWidgets('pluraliza los intentos', (tester) async {
      await pumpRow(tester, change(attempts: 8));

      expect(find.textContaining('8 intentos'), findsOneWidget);
    });

    testWidgets('un solo intento va en singular', (tester) async {
      await pumpRow(tester, change(attempts: 1));

      expect(find.textContaining('1 intento'), findsOneWidget);
      expect(find.textContaining('1 intentos'), findsNothing);
    });
  });

  group('la fila entera es el objetivo táctil, no el chevron', () {
    testWidgets('tocar el título abre el detalle', (tester) async {
      var taps = 0;
      await pumpRow(
        tester,
        change(payload: const {'note': 'Café con Ana'}),
        onTap: () => taps++,
      );

      await tester.tap(find.text('Movimiento · Café con Ana'));
      expect(taps, 1);
    });

    testWidgets('alto mínimo de 72pt', (tester) async {
      await pumpRow(tester, change());

      expect(
        tester.getSize(find.byType(SyncPendingRow)).height,
        greaterThanOrEqualTo(72),
      );
    });
  });

  testWidgets('no ofrece ninguna acción de descarte', (tester) async {
    await pumpRow(tester, change());

    expect(find.text('Descartar'), findsNothing);
    expect(find.text('Eliminar'), findsNothing);
  });
}
