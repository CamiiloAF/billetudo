import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/pages/pending_sync_changes_page.dart';
import 'package:billetudo/core/sync/presentation/widgets/sync_pending_row.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../pump_sync.dart';

class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// "Cambios sin subir" (`rxUil`): la única pantalla de la familia donde se
/// espera hacer scroll, porque aquí sí se listan todos. Sin acciones masivas
/// por fila y sin "Descartar" individual (eso vive solo en la hoja de
/// detalle, gateado por `attempts >= 3`). Sí ofrece "Descartar todo" bajo el
/// resumen, sin umbral, protegido solo por su hoja de confirmación.
void main() {
  final now = DateTime.now();

  PendingSyncChange change(int index) => PendingSyncChange.fromOperation(
        QuarantinedOperation(
          id: 'q-$index',
          operation: SyncOperation(
            tableName: 'transactions',
            rowId: 'row-$index',
            type: SyncOperationType.put,
            payload: {'note': 'Cambio $index'},
          ),
          kind: SyncFailureKind.brokenSchema,
          errorCode: 'PGRST204',
          errorMessage: 'column does not exist',
          quarantinedAt: now.subtract(Duration(days: 3, minutes: index)),
          updatedAt: now,
          attempts: 4,
        ),
      );

  Future<MockSyncStatusCubit> pumpPage(WidgetTester tester, int count) async {
    final cubit = MockSyncStatusCubit();
    when(cubit.discardAll).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<SyncStatusState>.empty(),
      initialState: SyncStatusState(
        status: SyncStatusStatus.ready,
        snapshot: SyncStatusSnapshot(
          state: SyncState.stalled,
          quarantinedCount: count,
          lastSyncedAt: now.subtract(const Duration(days: 3)),
          hasSyncedEver: true,
        ),
        pending: [for (var i = 0; i < count; i++) change(i)],
      ),
    );
    await tester.pumpSyncWidget(
      BlocProvider<SyncStatusCubit>.value(
        value: cubit,
        child: const PendingSyncChangesPage(),
      ),
      wrapInScaffold: false,
    );
    return cubit;
  }

  testWidgets('el resumen cuenta los 89 y desde cuándo espera el más antiguo',
      (tester) async {
    await pumpPage(tester, 89);

    expect(
      find.text('89 cambios esperando · el más antiguo, desde hace 3 días'),
      findsOneWidget,
    );
  });

  testWidgets('aquí sí se listan todos: al desplazarse aparece la fila 89',
      (tester) async {
    await pumpPage(tester, 89);

    expect(find.text('Movimiento · Cambio 0'), findsOneWidget);
    expect(find.text('Movimiento · Cambio 88'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Movimiento · Cambio 88'),
      400,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Movimiento · Cambio 88'), findsOneWidget);
  });

  testWidgets('con un solo cambio el resumen va en singular', (tester) async {
    await pumpPage(tester, 1);

    expect(find.text('1 cambio esperando · desde hace 3 días'), findsOneWidget);
    expect(find.byType(SyncPendingRow), findsOneWidget);
  });

  testWidgets('sin nada esperando no inventa filas', (tester) async {
    await pumpPage(tester, 0);

    expect(find.byType(SyncPendingRow), findsNothing);
    expect(find.text('Nada esperando para subir'), findsOneWidget);
  });

  testWidgets('no ofrece checkboxes ni selección: solo el link de bulk',
      (tester) async {
    await pumpPage(tester, 5);

    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('sin nada esperando no ofrece "Descartar todo"', (tester) async {
    await pumpPage(tester, 0);

    expect(find.textContaining('Descartar todo'), findsNothing);
  });

  testWidgets('el link "Descartar todo (N)" lleva el conteo real',
      (tester) async {
    await pumpPage(tester, 5);

    expect(find.text('Descartar todo (5)'), findsOneWidget);
  });

  testWidgets(
      'tocar "Descartar todo" abre la confirmación; confirmar llama al caso '
      'de uso de bulk', (tester) async {
    final cubit = await pumpPage(tester, 5);

    await tester.tap(find.text('Descartar todo (5)'));
    await tester.pumpAndSettle();

    expect(find.text('¿Descartar los 5 cambios pendientes?'), findsOneWidget);

    await tester.tap(find.text('Descartar todo'));
    await tester.pumpAndSettle();

    verify(cubit.discardAll).called(1);
  });

  testWidgets('cancelar la confirmación no descarta nada', (tester) async {
    final cubit = await pumpPage(tester, 5);

    await tester.tap(find.text('Descartar todo (5)'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(cubit.discardAll);
    expect(find.text('Descartar todo (5)'), findsOneWidget);
  });

  testWidgets('ninguna fila filtra el nombre de la tabla ni el código',
      (tester) async {
    await pumpPage(tester, 5);

    expect(find.textContaining('transactions'), findsNothing);
    expect(find.textContaining('PGRST204'), findsNothing);
  });
}
