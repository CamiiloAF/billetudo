import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/widgets/sync_pending_row.dart';
import 'package:billetudo/core/sync/presentation/widgets/sync_pending_section.dart';
import 'package:flutter_test/flutter_test.dart';

import '../pump_sync.dart';

/// "Qué está esperando" es una **muestra**, no un resumen: de 3 a 89 cambios
/// la lista no crece. Motivo medido: con la lista expandida, "Guardar una
/// copia" — la única protección real mientras la nube falla — cae fuera de
/// pantalla justo cuando más importa.
void main() {
  List<PendingSyncChange> changes(int count) => [
        for (var i = 0; i < count; i++)
          PendingSyncChange.fromOperation(
            QuarantinedOperation(
              id: 'q-$i',
              operation: SyncOperation(
                tableName: 'transactions',
                rowId: 'row-$i',
                type: SyncOperationType.put,
                payload: {'note': 'Cambio $i'},
              ),
              kind: SyncFailureKind.brokenSchema,
              errorMessage: 'boom',
              quarantinedAt: DateTime(2026, 7, 20).add(Duration(hours: i)),
              updatedAt: DateTime(2026, 7, 20).add(Duration(hours: i)),
              attempts: 1,
            ),
          ),
      ];

  Future<void> pumpSection(
    WidgetTester tester,
    int count, {
    void Function()? onSeeAll,
  }) =>
      tester.pumpSyncWidget(
        SyncPendingSection(
          changes: changes(count),
          onOpenChange: (_) {},
          onSeeAll: onSeeAll ?? () {},
        ),
      );

  testWidgets('con 89 cambios muestra 3 filas, no 89', (tester) async {
    await pumpSection(tester, 89);

    expect(find.byType(SyncPendingRow), findsNWidgets(3));
  });

  testWidgets('las 3 que muestra son las más antiguas (llegan ordenadas)',
      (tester) async {
    await pumpSection(tester, 89);

    expect(find.text('Movimiento · Cambio 0'), findsOneWidget);
    expect(find.text('Movimiento · Cambio 2'), findsOneWidget);
    expect(find.text('Movimiento · Cambio 3'), findsNothing);
  });

  testWidgets('el enlace lleva el contador real: "Ver los 89"', (tester) async {
    await pumpSection(tester, 89);

    expect(find.text('Ver los 89'), findsOneWidget);
  });

  testWidgets('con exactamente 3 no hay enlace: no falta nada por ver',
      (tester) async {
    await pumpSection(tester, 3);

    expect(find.byType(SyncPendingRow), findsNWidgets(3));
    expect(find.textContaining('Ver los'), findsNothing);
  });

  testWidgets('con 4 aparece el enlace contando los 4', (tester) async {
    await pumpSection(tester, 4);

    expect(find.byType(SyncPendingRow), findsNWidgets(3));
    expect(find.text('Ver los 4'), findsOneWidget);
  });

  testWidgets('con 1 cambio muestra una fila y ningún enlace', (tester) async {
    await pumpSection(tester, 1);

    expect(find.byType(SyncPendingRow), findsOneWidget);
    expect(find.textContaining('Ver los'), findsNothing);
  });

  testWidgets('tocar el enlace navega a la lista completa', (tester) async {
    var taps = 0;
    await pumpSection(tester, 89, onSeeAll: () => taps++);

    await tester.tap(find.text('Ver los 89'));
    expect(taps, 1);
  });

  testWidgets('tocar una fila abre ese cambio, no otro', (tester) async {
    final all = changes(89);
    PendingSyncChange? opened;
    await tester.pumpSyncWidget(
      SyncPendingSection(
        changes: all,
        onOpenChange: (change) => opened = change,
        onSeeAll: () {},
      ),
    );

    await tester.tap(find.text('Movimiento · Cambio 1'));
    expect(opened?.id, 'q-1');
  });

  testWidgets(
      'el encabezado usa el título de la sección y no ofrece '
      'descartar', (tester) async {
    await pumpSection(tester, 89);

    expect(find.text('Qué está esperando'), findsOneWidget);
    expect(find.text('Descartar'), findsNothing);
    expect(find.text('Descartar todo'), findsNothing);
  });
}
