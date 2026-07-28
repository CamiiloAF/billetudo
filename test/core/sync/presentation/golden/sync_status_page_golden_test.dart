import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/pages/sync_status_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// "Estado de sincronización" (HU-08), estado por estado y en ambos temas.
///
/// Los frames de referencia viven en `design-system/billetudo/pages/
/// sincronizacion.md`: atención `hE3Ds`/`sTebL`, todo bien `AGwSd`/`BwHgf`,
/// carga `KgGHB`/`nTlwj`, nunca sincronizó `Ux4Eo`/`reRjw`, sin conexión
/// `tUQR4`/`R72Lm`, sin sesión `b0O9jr`/`YHUON`, 89 pendientes `MG3eK`/`psOSC`
/// y sincronizando en curso `p26K0`/`R5mjuG`.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  // Fixed instants so the relative phrasing ("hace 3 días") is deterministic:
  // the widget reads `DateTime.now()`, so the fixture has to be an offset.
  final now = DateTime.now();

  PendingSyncChange change(int index, String note) =>
      PendingSyncChange.fromOperation(
        QuarantinedOperation(
          id: 'q-$index',
          operation: SyncOperation(
            tableName: switch (index % 3) {
              0 => 'transactions',
              1 => 'debts',
              _ => 'accounts',
            },
            rowId: 'row-$index',
            type: SyncOperationType.put,
            payload: {'note': note, 'name': note},
          ),
          kind: SyncFailureKind.brokenSchema,
          errorCode: 'PGRST204',
          errorMessage: 'column does not exist',
          quarantinedAt: now.subtract(Duration(days: 3, minutes: index)),
          updatedAt: now,
          attempts: 4 + index,
        ),
      );

  SyncStatusState state({
    SyncStatusStatus status = SyncStatusStatus.ready,
    SyncState syncState = SyncState.synced,
    Duration? syncedAgo = const Duration(minutes: 5),
    int pending = 0,
    bool isRetrying = false,
  }) =>
      SyncStatusState(
        status: status,
        snapshot: SyncStatusSnapshot(
          state: syncState,
          quarantinedCount: pending,
          lastSyncedAt: syncedAgo == null ? null : now.subtract(syncedAgo),
          hasSyncedEver: syncedAgo != null,
        ),
        pending: [
          for (var i = 0; i < pending; i++)
            change(
              i,
              switch (i % 3) {
                0 => 'Café con Ana',
                1 => 'Préstamo a Ana',
                _ => 'Cuenta de ahorros',
              },
            ),
        ],
        isRetrying: isRetrying,
      );

  Future<void> golden(
    WidgetTester tester,
    SyncStatusState initial,
    String name, {
    required Brightness brightness,
    bool isSignedIn = true,
  }) async {
    final cubit = MockSyncStatusCubit();
    whenListen(
      cubit,
      const Stream<SyncStatusState>.empty(),
      initialState: initial,
    );

    await pumpGolden(
      tester,
      BlocProvider<SyncStatusCubit>.value(
        value: cubit,
        child: SyncStatusPage(
          isSignedIn: isSignedIn,
          onSaveCopy: () {},
          onSignIn: () {},
          onSeeAllPending: () {},
          onOpenComingSoon: (_) {},
        ),
      ),
      brightness: brightness,
      // La pantalla debe caber sin scroll por diseño; el lienzo alto captura
      // el bloque completo para poder verificar justamente eso.
      size: tallGoldenPhoneSize(height: 1100),
    );

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sync_status_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('sync status page — atención, 3 pendientes ($suffix)',
        (tester) async {
      await golden(
        tester,
        state(syncState: SyncState.stalled, pending: 3),
        'attention_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('sync status page — atención, 89 pendientes ($suffix)',
        (tester) async {
      await golden(
        tester,
        state(
          syncState: SyncState.stalled,
          pending: 89,
          syncedAgo: const Duration(days: 3),
        ),
        'attention_89_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('sync status page — reintento en curso ($suffix)',
        (tester) async {
      await golden(
        tester,
        state(syncState: SyncState.stalled, pending: 3, isRetrying: true),
        'retrying_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('sync status page — todo bien ($suffix)', (tester) async {
      await golden(tester, state(), 'healthy_$suffix', brightness: brightness);
    });

    testWidgets('sync status page — nunca sincronizó ($suffix)',
        (tester) async {
      await golden(
        tester,
        state(syncedAgo: null),
        'never_synced_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('sync status page — sin conexión ($suffix)', (tester) async {
      await golden(
        tester,
        state(syncState: SyncState.offline),
        'offline_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('sync status page — sin sesión ($suffix)', (tester) async {
      await golden(
        tester,
        state(),
        'signed_out_$suffix',
        brightness: brightness,
        isSignedIn: false,
      );
    });

    testWidgets('sync status page — carga ($suffix)', (tester) async {
      await golden(
        tester,
        state(status: SyncStatusStatus.loading),
        'loading_$suffix',
        brightness: brightness,
      );
    });
  }
}
