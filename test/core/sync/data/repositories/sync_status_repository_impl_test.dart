import 'dart:async';
import 'dart:io';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/data/datasources/sync_status_source.dart';
import 'package:billetudo/core/sync/data/repositories/sync_status_repository_impl.dart';
import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/domain/repositories/sync_quarantine_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plain fake of the narrow port: a configurable snapshot plus a controller
/// that only emits when the test pushes, mirroring PowerSync's real stream
/// (which emits on change, never on subscription).
class FakeSyncStatusSource implements SyncStatusSource {
  FakeSyncStatusSource({SyncSourceStatus? initial})
      : currentStatus = initial ?? offlineStatus;

  final StreamController<SyncSourceStatus> _controller =
      StreamController<SyncSourceStatus>.broadcast();

  @override
  SyncSourceStatus currentStatus;

  @override
  Stream<SyncSourceStatus> get statusStream => _controller.stream;

  /// What `pendingUploadCount()` resolves to; set it to a throwing value by
  /// assigning `pendingUploadError` instead.
  int pendingCount = 0;
  Error? pendingUploadError;

  @override
  Future<int> pendingUploadCount() async {
    if (pendingUploadError case final error?) {
      throw error;
    }
    return pendingCount;
  }

  void emit(SyncSourceStatus status) => _controller.add(status);

  /// Whether the repository is still subscribed — the way to see that
  /// cancelling the merged stream releases both sources.
  bool get hasListeners => _controller.hasListener;

  Future<void> close() => _controller.close();
}

/// Quarantine seen through its domain port: the repository only ever reads
/// the stream, so everything else throws if it is ever called by mistake.
class FakeSyncQuarantineRepository implements SyncQuarantineRepository {
  final StreamController<List<QuarantinedOperation>> _controller =
      StreamController<List<QuarantinedOperation>>.broadcast();

  /// What a fresh subscription sees before the test pushes anything.
  List<QuarantinedOperation> initial = const <QuarantinedOperation>[];

  /// When set, the stream fails right after the initial value instead of
  /// emitting: a quarantine file that cannot be read.
  Object? error;

  @override
  Stream<List<QuarantinedOperation>> watchFailures() async* {
    yield initial;
    if (error case final failure?) {
      yield* Stream<List<QuarantinedOperation>>.error(failure);
    }
    yield* _controller.stream;
  }

  void emit(List<QuarantinedOperation> operations) =>
      _controller.add(operations);

  Future<void> close() => _controller.close();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// One quarantined record; only its presence matters to the mapping.
QuarantinedOperation quarantinedOperation(String id) => QuarantinedOperation(
      id: id,
      operation: SyncOperation(
        tableName: 'debts',
        rowId: id,
        type: SyncOperationType.patch,
      ),
      kind: SyncFailureKind.stuck,
      errorMessage: 'stuck',
      quarantinedAt: DateTime(2026, 7, 25),
      updatedAt: DateTime(2026, 7, 25),
      attempts: 20,
    );

SyncSourceStatus status({
  bool connected = false,
  bool uploading = false,
  bool downloading = false,
}) =>
    SyncSourceStatus(
      connected: connected,
      uploading: uploading,
      downloading: downloading,
    );

const SyncSourceStatus offlineStatus = SyncSourceStatus(
  connected: false,
  uploading: false,
  downloading: false,
);

void main() {
  late FakeSyncStatusSource source;
  late FakeSyncQuarantineRepository quarantine;

  setUp(() {
    source = FakeSyncStatusSource();
    quarantine = FakeSyncQuarantineRepository();
  });

  tearDown(() async {
    await source.close();
    await quarantine.close();
  });

  /// The seed is what `watchSyncState` yields first, so driving the mapping
  /// table through `currentStatus` reads the mapper directly.
  Future<SyncState> firstStateFor(SyncSourceStatus snapshot) {
    source.currentStatus = snapshot;
    return SyncStatusRepositoryImpl(source, quarantine).watchSyncState().first;
  }

  group('state mapping', () {
    test('uploading maps to syncing', () async {
      expect(await firstStateFor(status(uploading: true)), SyncState.syncing);
    });

    test('downloading maps to syncing', () async {
      expect(await firstStateFor(status(downloading: true)), SyncState.syncing);
    });

    test(
        'transfer wins over connected: both transfers while '
        'disconnected still maps to syncing', () async {
      expect(
        await firstStateFor(
          status(connected: false, uploading: true, downloading: true),
        ),
        SyncState.syncing,
      );
    });

    test('uploading while disconnected maps to syncing', () async {
      expect(
        await firstStateFor(status(connected: false, uploading: true)),
        SyncState.syncing,
      );
    });

    test('connected with no transfer maps to synced', () async {
      expect(await firstStateFor(status(connected: true)), SyncState.synced);
    });

    test('all flags false maps to offline', () async {
      expect(await firstStateFor(status()), SyncState.offline);
    });
  });

  group('seed', () {
    test('emits currentStatus before the stream has emitted anything',
        () async {
      source.currentStatus = status(connected: true);

      final Completer<SyncState> first = Completer<SyncState>();
      final StreamSubscription<SyncState> sub = SyncStatusRepositoryImpl(
        source,
        quarantine,
      ).watchSyncState().listen(first.complete);
      addTearDown(sub.cancel);

      // No `source.emit(...)` anywhere: if the seed were missing this would
      // hang and the timeout would fail the test.
      await expectLater(
        first.future.timeout(const Duration(seconds: 1)),
        completion(SyncState.synced),
      );
    });

    test('seed reads the snapshot at subscription time, not a default',
        () async {
      source.currentStatus = status(uploading: true);

      await expectLater(
        SyncStatusRepositoryImpl(source, quarantine).watchSyncState().first,
        completion(SyncState.syncing),
      );
    });
  });

  group('sequence', () {
    test('propagates each stream change in order after the seed', () async {
      source.currentStatus = offlineStatus;
      final Stream<SyncState> stream = SyncStatusRepositoryImpl(
        source,
        quarantine,
      ).watchSyncState();

      final Future<List<SyncState>> collected = stream.take(4).toList();
      await pumpEventQueue();

      source.emit(status(uploading: true));
      await pumpEventQueue();
      source.emit(status(connected: true));
      await pumpEventQueue();
      source.emit(status(connected: true, downloading: true));
      await pumpEventQueue();

      expect(await collected.timeout(const Duration(seconds: 2)), <SyncState>[
        SyncState.offline,
        SyncState.syncing,
        SyncState.synced,
        SyncState.syncing,
      ]);
    });
  });

  group('distinct', () {
    test('collapses consecutive events that map to the same state', () async {
      source.currentStatus = status(connected: true);
      final Stream<SyncState> stream = SyncStatusRepositoryImpl(
        source,
        quarantine,
      ).watchSyncState();

      final Future<List<SyncState>> collected = stream.take(3).toList();
      await pumpEventQueue();

      // uploading and downloading are different source events that both map
      // to `syncing`: only the first must reach the UI.
      source.emit(status(uploading: true));
      await pumpEventQueue();
      source.emit(status(downloading: true));
      await pumpEventQueue();
      source.emit(status(connected: true, downloading: true));
      await pumpEventQueue();
      source.emit(status(connected: true));
      await pumpEventQueue();

      expect(await collected.timeout(const Duration(seconds: 2)), <SyncState>[
        SyncState.synced,
        SyncState.syncing,
        SyncState.synced,
      ]);
    });
  });

  group('pendingUploadCount', () {
    test('mapea el conteo del source tal cual en un Right', () async {
      source.pendingCount = 4;

      final result = await SyncStatusRepositoryImpl(source, quarantine)
          .pendingUploadCount();

      expect(result, const Right<Failure, int>(4));
    });

    test('una cola vacía es Right(0), no un fallo', () async {
      source.pendingCount = 0;

      expect(
        await SyncStatusRepositoryImpl(source, quarantine).pendingUploadCount(),
        const Right<Failure, int>(0),
      );
    });

    test('una excepción del source se convierte en DatabaseFailure', () async {
      // La cola vive en el SQLite local (`ps_crud`): un fallo leyéndola es de
      // base de datos, no de red.
      source.pendingUploadError = StateError('ps_crud unavailable');

      final result = await SyncStatusRepositoryImpl(source, quarantine)
          .pendingUploadCount();

      final failure = result.getLeft().toNullable();
      expect(failure, isA<DatabaseFailure>());
      expect(failure!.cause, isA<StateError>());
      expect(failure.stackTrace, isNotNull);
    });
  });

  group('seed vs first stream event', () {
    test('an offline seed followed by an offline event emits offline once',
        () async {
      // Changed on purpose when the quarantine joined the stream: the two
      // sources are merged into one controller and `distinct()` now covers
      // the seed too, so the duplicate the previous implementation let
      // through is gone. Pinned here so it cannot come back.
      source.currentStatus = offlineStatus;
      final Stream<SyncState> stream = SyncStatusRepositoryImpl(
        source,
        quarantine,
      ).watchSyncState();

      final Future<List<SyncState>> collected = stream.take(2).toList();
      await pumpEventQueue();

      source.emit(offlineStatus);
      await pumpEventQueue();
      source.emit(status(connected: true));
      await pumpEventQueue();

      expect(await collected.timeout(const Duration(seconds: 2)), <SyncState>[
        SyncState.offline,
        SyncState.synced,
      ]);
    });
  });

  /// The two streams (engine status and quarantine) are merged by hand into a
  /// single controller — no rxdart in this project. What the merge has to
  /// guarantee: the quarantine can raise `stalled` on its own, the precedence
  /// is stable whichever stream moved last, and `distinct()` never eats a
  /// transition the UI needs.
  group('merge del stream del motor con el de cuarentena', () {
    Stream<SyncStatusSnapshot> statusStream() =>
        SyncStatusRepositoryImpl(source, quarantine).watchStatus();

    test('una cuarentena no vacía levanta stalled aunque el motor esté sano',
        () async {
      // Es la señal que faltó tres días: el motor decía "conectado" mientras
      // había escrituras retenidas que nunca llegaron a la nube.
      source.currentStatus = status(connected: true);
      quarantine.initial = [quarantinedOperation('q-1')];

      final snapshots = await statusStream()
          .take(2)
          .toList()
          .timeout(const Duration(seconds: 2));

      expect(snapshots.first.state, SyncState.synced);
      expect(snapshots.last.state, SyncState.stalled);
      expect(snapshots.last.quarantinedCount, 1);
      expect(snapshots.last.hasQuarantinedOperations, isTrue);
    });

    test('PRECEDENCIA: syncing gana sobre stalled (algo se está moviendo)',
        () async {
      source.currentStatus = status(uploading: true);
      quarantine.initial = [quarantinedOperation('q-1')];

      final snapshots = await statusStream()
          .take(2)
          .toList()
          .timeout(const Duration(seconds: 2));

      // Ya con la cuarentena cargada, el estado sigue siendo syncing…
      expect(snapshots.last.state, SyncState.syncing);
      // …y el conteo no se pierde aunque el estado sea otro.
      expect(snapshots.last.quarantinedCount, 1);
    });

    test('PRECEDENCIA: stalled gana sobre synced', () async {
      source.currentStatus = status(connected: true);
      quarantine.initial = [quarantinedOperation('q-1')];

      final snapshots = await statusStream()
          .take(2)
          .toList()
          .timeout(const Duration(seconds: 2));

      expect(snapshots.last.state, SyncState.stalled);
    });

    test('PRECEDENCIA: stalled gana sobre offline', () async {
      // Sin conexión y con cuarentena, lo que el usuario necesita saber es que
      // hay algo retenido que exige una decisión, no que no hay red.
      source.currentStatus = offlineStatus;
      quarantine.initial = [quarantinedOperation('q-1')];

      final snapshots = await statusStream()
          .take(2)
          .toList()
          .timeout(const Duration(seconds: 2));

      expect(snapshots.map((each) => each.state), <SyncState>[
        SyncState.offline,
        SyncState.stalled,
      ]);
    });

    test('vaciar la cuarentena devuelve el estado del motor', () async {
      source.currentStatus = status(connected: true);
      quarantine.initial = [quarantinedOperation('q-1')];
      final collected = statusStream().take(3).toList();
      await pumpEventQueue();

      quarantine.emit(const <QuarantinedOperation>[]);
      await pumpEventQueue();

      final snapshots = await collected.timeout(const Duration(seconds: 2));
      expect(snapshots.map((each) => each.state), <SyncState>[
        SyncState.synced,
        SyncState.stalled,
        SyncState.synced,
      ]);
      expect(snapshots.last.quarantinedCount, 0);
    });

    test('el cambio de cuarentena se refleja con el último estado del motor',
        () async {
      source.currentStatus = offlineStatus;
      final collected = statusStream().take(3).toList();
      await pumpEventQueue();

      source.emit(status(connected: true));
      await pumpEventQueue();
      quarantine.emit([quarantinedOperation('q-1')]);
      await pumpEventQueue();

      final snapshots = await collected.timeout(const Duration(seconds: 2));
      expect(snapshots.map((each) => each.state), <SyncState>[
        SyncState.offline,
        SyncState.synced,
        SyncState.stalled,
      ]);
    });

    test('el cambio del motor conserva el conteo de cuarentena vigente',
        () async {
      source.currentStatus = offlineStatus;
      quarantine.initial = [
        quarantinedOperation('q-1'),
        quarantinedOperation('q-2'),
      ];
      final collected = statusStream().take(3).toList();
      await pumpEventQueue();

      source.emit(status(uploading: true));
      await pumpEventQueue();

      final snapshots = await collected.timeout(const Duration(seconds: 2));
      expect(snapshots.last.state, SyncState.syncing);
      expect(snapshots.last.quarantinedCount, 2);
    });

    test('distinct NO colapsa un cambio que solo mueve el conteo', () async {
      // Mismo estado (`stalled`) pero 1 → 2 retenidas: la pantalla tiene que
      // enterarse, o el contador se queda viejo.
      source.currentStatus = status(connected: true);
      quarantine.initial = [quarantinedOperation('q-1')];
      final collected = statusStream().take(3).toList();
      await pumpEventQueue();

      quarantine.emit([
        quarantinedOperation('q-1'),
        quarantinedOperation('q-2'),
      ]);
      await pumpEventQueue();

      final snapshots = await collected.timeout(const Duration(seconds: 2));
      expect(
        snapshots.map((each) => each.quarantinedCount),
        <int>[0, 1, 2],
      );
      expect(snapshots.last.state, SyncState.stalled);
    });

    test('distinct NO colapsa un cambio que solo mueve lastSyncedAt', () async {
      source.currentStatus = SyncSourceStatus(
        connected: true,
        uploading: false,
        downloading: false,
        lastSyncedAt: DateTime.utc(2026, 7, 25, 15, 39),
        hasSynced: true,
      );
      final collected = statusStream().take(2).toList();
      await pumpEventQueue();

      source.emit(
        SyncSourceStatus(
          connected: true,
          uploading: false,
          downloading: false,
          lastSyncedAt: DateTime.utc(2026, 7, 28, 12),
          hasSynced: true,
        ),
      );
      await pumpEventQueue();

      final snapshots = await collected.timeout(const Duration(seconds: 2));
      expect(
        snapshots.map((each) => each.lastSyncedAt),
        <DateTime>[
          DateTime.utc(2026, 7, 25, 15, 39),
          DateTime.utc(2026, 7, 28, 12),
        ],
      );
    });

    test('distinct sí colapsa un snapshot idéntico repetido', () async {
      source.currentStatus = status(connected: true);
      final collected = statusStream().take(2).toList();
      await pumpEventQueue();

      source.emit(status(connected: true));
      await pumpEventQueue();
      source.emit(status(connected: true));
      await pumpEventQueue();
      source.emit(status(uploading: true));
      await pumpEventQueue();

      final snapshots = await collected.timeout(const Duration(seconds: 2));
      expect(snapshots.map((each) => each.state), <SyncState>[
        SyncState.synced,
        SyncState.syncing,
      ]);
    });

    test('el snapshot traslada lastSyncedAt, hasSyncedEver y el último error',
        () async {
      source.currentStatus = SyncSourceStatus(
        connected: true,
        uploading: false,
        downloading: false,
        lastSyncedAt: DateTime.utc(2026, 7, 25, 15, 39),
        hasSynced: true,
        uploadError: const SocketException('offline'),
      );

      final snapshot =
          await statusStream().first.timeout(const Duration(seconds: 2));

      expect(snapshot.lastSyncedAt, DateTime.utc(2026, 7, 25, 15, 39));
      expect(snapshot.hasSyncedEver, isTrue);
      expect(snapshot.lastErrorMessage, contains('offline'));
    });

    test('sin sincronizar nunca, lastSyncedAt es null y hasSyncedEver false',
        () async {
      source.currentStatus = status(connected: true);

      final snapshot =
          await statusStream().first.timeout(const Duration(seconds: 2));

      expect(snapshot.lastSyncedAt, isNull);
      expect(snapshot.hasSyncedEver, isFalse);
      expect(snapshot.lastErrorMessage, isNull);
    });

    test('el error de subida manda sobre el de bajada', () async {
      source.currentStatus = const SyncSourceStatus(
        connected: true,
        uploading: false,
        downloading: false,
        uploadError: SocketException('upload failed'),
        downloadError: SocketException('download failed'),
      );

      final snapshot =
          await statusStream().first.timeout(const Duration(seconds: 2));

      expect(snapshot.lastErrorMessage, contains('upload failed'));
    });

    test('una cuarentena ilegible no tumba el indicador de sync', () async {
      // El error del stream de cuarentena se traga a propósito: si lo dejara
      // pasar, un archivo corrupto apagaría también el estado del motor.
      source.currentStatus = offlineStatus;
      quarantine.error = const FileSystemException('quarantine unreadable');
      final collected = statusStream().take(2).toList();
      await pumpEventQueue();

      source.emit(status(connected: true));
      await pumpEventQueue();

      final snapshots = await collected.timeout(const Duration(seconds: 2));
      expect(snapshots.map((each) => each.state), <SyncState>[
        SyncState.offline,
        SyncState.synced,
      ]);
    });

    test('cancelar la suscripción libera las dos fuentes', () async {
      final subscription = statusStream().listen((_) {});
      await pumpEventQueue();
      expect(source.hasListeners, isTrue);

      await subscription.cancel();
      await pumpEventQueue();

      expect(source.hasListeners, isFalse);
    });

    test('watchSyncState sí colapsa lo que solo cambia el conteo', () async {
      // El mismo cambio que `watchStatus` propaga: quien solo pinta el icono
      // no necesita enterarse.
      source.currentStatus = status(connected: true);
      quarantine.initial = [quarantinedOperation('q-1')];
      final collected = SyncStatusRepositoryImpl(source, quarantine)
          .watchSyncState()
          .take(3)
          .toList();
      await pumpEventQueue();

      quarantine.emit([
        quarantinedOperation('q-1'),
        quarantinedOperation('q-2'),
      ]);
      await pumpEventQueue();
      quarantine.emit(const <QuarantinedOperation>[]);
      await pumpEventQueue();

      expect(await collected.timeout(const Duration(seconds: 2)), <SyncState>[
        SyncState.synced,
        SyncState.stalled,
        SyncState.synced,
      ]);
    });
  });
}
