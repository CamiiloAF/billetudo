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

import '../pump_sync.dart';

class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// "Cambios sin subir" (`rxUil`): la única pantalla de la familia donde se
/// espera hacer scroll, porque aquí sí se listan todos. Sin acciones masivas y
/// sin "Descartar": el hero de la pantalla anterior ya reintenta todo.
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

  Future<void> pumpPage(WidgetTester tester, int count) async {
    final cubit = MockSyncStatusCubit();
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

  testWidgets('no ofrece acciones masivas ni "Descartar"', (tester) async {
    await pumpPage(tester, 5);

    expect(find.textContaining('Descartar'), findsNothing);
    expect(find.textContaining('Eliminar'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('ninguna fila filtra el nombre de la tabla ni el código',
      (tester) async {
    await pumpPage(tester, 5);

    expect(find.textContaining('transactions'), findsNothing);
    expect(find.textContaining('PGRST204'), findsNothing);
  });
}
