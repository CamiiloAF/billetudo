import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/pages/pending_sync_changes_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// "Cambios sin subir" (`rxUil`/`xA9X1`): la lista completa, la única pantalla
/// de la familia donde el scroll es esperado. El golden captura la primera
/// pantalla, que es lo que el usuario ve al llegar.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  final now = goldenReferenceNow;

  PendingSyncChange change(int index) {
    final (table, label) = switch (index % 4) {
      0 => ('transactions', 'Café con Ana'),
      1 => ('debts', 'Préstamo a Ana'),
      2 => ('accounts', 'Cuenta de ahorros'),
      _ => ('goals', 'Viaje a Cartagena'),
    };
    return PendingSyncChange.fromOperation(
      QuarantinedOperation(
        id: 'q-$index',
        operation: SyncOperation(
          tableName: table,
          rowId: 'row-$index',
          type: SyncOperationType.put,
          payload: {'name': label, 'note': label},
        ),
        kind: SyncFailureKind.brokenSchema,
        errorCode: 'PGRST204',
        errorMessage: 'column does not exist',
        quarantinedAt: now.subtract(Duration(days: 3, minutes: index)),
        updatedAt: now,
        attempts: 4 + (index % 5),
      ),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('pending sync changes page — 89 pendientes ($suffix)',
        (tester) async {
      final cubit = MockSyncStatusCubit();
      whenListen(
        cubit,
        const Stream<SyncStatusState>.empty(),
        initialState: SyncStatusState(
          status: SyncStatusStatus.ready,
          snapshot: SyncStatusSnapshot(
            state: SyncState.stalled,
            quarantinedCount: 89,
            lastSyncedAt: now.subtract(const Duration(days: 3)),
            hasSyncedEver: true,
          ),
          pending: [for (var i = 0; i < 89; i++) change(i)],
        ),
      );

      await pumpWithFixedClock(
        tester,
        BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: const PendingSyncChangesPage(),
        ),
        brightness: brightness,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/pending_sync_changes_page_$suffix.png'),
      );
    });

    // La lista se vacía sola: las filas desaparecen una a una al confirmar
    // cada operación, así que el usuario puede quedarse mirando esta pantalla
    // hasta que no quede ninguna. El resumen pasa a decir que no hay nada
    // esperando, en vez de dejar un encabezado con un contador en cero.
    testWidgets('pending sync changes page — sin pendientes ($suffix)',
        (tester) async {
      final cubit = MockSyncStatusCubit();
      whenListen(
        cubit,
        const Stream<SyncStatusState>.empty(),
        initialState: SyncStatusState(
          status: SyncStatusStatus.ready,
          snapshot: SyncStatusSnapshot(
            state: SyncState.synced,
            quarantinedCount: 0,
            lastSyncedAt: now,
            hasSyncedEver: true,
          ),
        ),
      );

      await pumpWithFixedClock(
        tester,
        BlocProvider<SyncStatusCubit>.value(
          value: cubit,
          child: const PendingSyncChangesPage(),
        ),
        brightness: brightness,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/pending_sync_changes_page_empty_$suffix.png',
        ),
      );
    });
  }
}
