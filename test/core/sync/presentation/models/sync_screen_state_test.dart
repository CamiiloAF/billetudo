import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/models/sync_screen_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// El orden de las comprobaciones es la decisión de producto, no un detalle:
/// **los cambios sin subir mandan sobre la falta de conexión**. El riesgo pesa
/// más que su causa.
void main() {
  PendingSyncChange change(String id) => PendingSyncChange.fromOperation(
        QuarantinedOperation(
          id: id,
          operation: const SyncOperation(
            tableName: 'transactions',
            rowId: 'row',
            type: SyncOperationType.put,
          ),
          kind: SyncFailureKind.brokenSchema,
          errorMessage: 'boom',
          quarantinedAt: DateTime(2026, 7, 25),
          updatedAt: DateTime(2026, 7, 25),
          attempts: 1,
        ),
      );

  /// [neverSynced] es el caso "recién inició sesión": sin `lastSyncedAt` y sin
  /// haber sincronizado jamás en este dispositivo.
  SyncStatusState stateWith({
    SyncState syncState = SyncState.synced,
    bool neverSynced = false,
    int pending = 0,
  }) =>
      SyncStatusState(
        status: SyncStatusStatus.ready,
        snapshot: SyncStatusSnapshot(
          state: syncState,
          quarantinedCount: pending,
          lastSyncedAt: neverSynced ? null : DateTime(2026, 7, 28, 11),
          hasSyncedEver: !neverSynced,
        ),
        pending: [for (var i = 0; i < pending; i++) change('q-$i')],
      );

  group('PRECEDENCIA (la regla que un refactor rompe sin querer)', () {
    test('cambios sin subir Y sin conexión: gana ATENCIÓN, no sin conexión',
        () {
      final state = stateWith(syncState: SyncState.offline, pending: 2);

      expect(
        SyncScreenState.resolve(state, isSignedIn: true),
        SyncScreenState.attention,
      );
    });

    test('cambios sin subir mandan también sobre "nunca sincronizó"', () {
      final state = stateWith(
        syncState: SyncState.stalled,
        neverSynced: true,
        pending: 1,
      );

      expect(
        SyncScreenState.resolve(state, isSignedIn: true),
        SyncScreenState.attention,
      );
    });

    test('sin sesión manda sobre todo lo demás, incluso con pendientes', () {
      final state = stateWith(syncState: SyncState.stalled, pending: 5);

      expect(
        SyncScreenState.resolve(state, isSignedIn: false),
        SyncScreenState.signedOut,
      );
    });

    test('"nunca sincronizó" gana a "sin conexión" cuando no hay pendientes',
        () {
      final state = stateWith(syncState: SyncState.offline, neverSynced: true);

      expect(
        SyncScreenState.resolve(state, isSignedIn: true),
        SyncScreenState.neverSynced,
      );
    });
  });

  group('los cinco estados', () {
    test('con pendientes: atención', () {
      expect(
        SyncScreenState.resolve(stateWith(pending: 3), isSignedIn: true),
        SyncScreenState.attention,
      );
    });

    test('sin pendientes y sincronizado: todo bien', () {
      expect(
        SyncScreenState.resolve(stateWith(), isSignedIn: true),
        SyncScreenState.healthy,
      );
    });

    test('sin sincronizar nunca: informativo, no atención', () {
      final resolved = SyncScreenState.resolve(
        stateWith(neverSynced: true),
        isSignedIn: true,
      );

      expect(resolved, SyncScreenState.neverSynced);
      expect(resolved.isAttention, isFalse);
    });

    test('sin conexión y nada esperando: sin conexión', () {
      expect(
        SyncScreenState.resolve(
          stateWith(syncState: SyncState.offline),
          isSignedIn: true,
        ),
        SyncScreenState.offline,
      );
    });

    test('sin sesión: sin sesión', () {
      expect(
        SyncScreenState.resolve(stateWith(), isSignedIn: false),
        SyncScreenState.signedOut,
      );
    });

    test(
        'sincronizando sin pendientes se pinta como todo bien (el hero no se '
        'reescribe por movimiento)', () {
      expect(
        SyncScreenState.resolve(
          stateWith(syncState: SyncState.syncing),
          isSignedIn: true,
        ),
        SyncScreenState.healthy,
      );
    });
  });

  test('isAttention solo es cierto en el estado de atención', () {
    for (final state in SyncScreenState.values) {
      expect(state.isAttention, state == SyncScreenState.attention);
    }
  });
}
