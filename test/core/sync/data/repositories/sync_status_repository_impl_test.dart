import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/data/datasources/sync_status_source.dart';
import 'package:billetudo/core/sync/data/repositories/sync_status_repository_impl.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
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

  Future<void> close() => _controller.close();
}

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

  setUp(() {
    source = FakeSyncStatusSource();
  });

  tearDown(() async {
    await source.close();
  });

  /// The seed is what `watchSyncState` yields first, so driving the mapping
  /// table through `currentStatus` reads the mapper directly.
  Future<SyncState> firstStateFor(SyncSourceStatus snapshot) {
    source.currentStatus = snapshot;
    return SyncStatusRepositoryImpl(source).watchSyncState().first;
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
        SyncStatusRepositoryImpl(source).watchSyncState().first,
        completion(SyncState.syncing),
      );
    });
  });

  group('sequence', () {
    test('propagates each stream change in order after the seed', () async {
      source.currentStatus = offlineStatus;
      final Stream<SyncState> stream = SyncStatusRepositoryImpl(
        source,
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

      final result =
          await SyncStatusRepositoryImpl(source).pendingUploadCount();

      expect(result, const Right<Failure, int>(4));
    });

    test('una cola vacía es Right(0), no un fallo', () async {
      source.pendingCount = 0;

      expect(
        await SyncStatusRepositoryImpl(source).pendingUploadCount(),
        const Right<Failure, int>(0),
      );
    });

    test('una excepción del source se convierte en DatabaseFailure', () async {
      // La cola vive en el SQLite local (`ps_crud`): un fallo leyéndola es de
      // base de datos, no de red.
      source.pendingUploadError = StateError('ps_crud unavailable');

      final result =
          await SyncStatusRepositoryImpl(source).pendingUploadCount();

      final failure = result.getLeft().toNullable();
      expect(failure, isA<DatabaseFailure>());
      expect(failure!.cause, isA<StateError>());
      expect(failure.stackTrace, isNotNull);
    });
  });

  group('seed vs first stream event', () {
    test('an offline seed followed by an offline event emits offline twice',
        () async {
      // Intentional, not a bug: `distinct()` is applied to the stream only,
      // so it never compares the seed against the first stream event. Pinned
      // here so the duplicate cannot disappear (or grow) unnoticed.
      source.currentStatus = offlineStatus;
      final Stream<SyncState> stream = SyncStatusRepositoryImpl(
        source,
      ).watchSyncState();

      final Future<List<SyncState>> collected = stream.take(3).toList();
      await pumpEventQueue();

      source.emit(offlineStatus);
      await pumpEventQueue();
      source.emit(status(connected: true));
      await pumpEventQueue();

      expect(await collected.timeout(const Duration(seconds: 2)), <SyncState>[
        SyncState.offline,
        SyncState.offline,
        SyncState.synced,
      ]);
    });
  });
}
