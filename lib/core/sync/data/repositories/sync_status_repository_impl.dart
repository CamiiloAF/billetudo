import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../../domain/entities/quarantined_operation.dart';
import '../../domain/entities/sync_state.dart';
import '../../domain/entities/sync_status_snapshot.dart';
import '../../domain/repositories/sync_quarantine_repository.dart';
import '../../domain/repositories/sync_status_repository.dart';
import '../datasources/sync_status_source.dart';

/// Translates the sync engine's status into the domain's [SyncState].
///
/// It reads the engine through [SyncStatusSource], never through PowerSync
/// directly: the package type stops at that adapter and never reaches
/// `domain` or `presentation`. The quarantine is read through its `domain`
/// repository, which is a dependency pointing inwards and therefore fine.
@LazySingleton(as: SyncStatusRepository)
class SyncStatusRepositoryImpl implements SyncStatusRepository {
  const SyncStatusRepositoryImpl(this._source, this._quarantine);

  final SyncStatusSource _source;
  final SyncQuarantineRepository _quarantine;

  @override
  Stream<SyncState> watchSyncState() =>
      watchStatus().map((snapshot) => snapshot.state).distinct();

  /// Merges two independent streams (the engine's status and the quarantine)
  /// by hand: `rxdart` is not a dependency of this project, and the merge is
  /// small enough that adding one would cost more than it saves.
  @override
  Stream<SyncStatusSnapshot> watchStatus() {
    late final StreamController<SyncStatusSnapshot> controller;
    StreamSubscription<SyncSourceStatus>? sourceSub;
    StreamSubscription<List<QuarantinedOperation>>? quarantineSub;

    // `statusStream` only emits on change, so seed with the current value —
    // otherwise the indicator would sit on its default until sync moved.
    var status = _source.currentStatus;
    var quarantined = 0;

    void emit() {
      if (!controller.isClosed) {
        controller.add(_snapshot(status, quarantined));
      }
    }

    controller = StreamController<SyncStatusSnapshot>(
      onListen: () {
        emit();
        sourceSub = _source.statusStream.listen((next) {
          status = next;
          emit();
        });
        quarantineSub = _quarantine.watchFailures().listen(
          (operations) {
            quarantined = operations.length;
            emit();
          },
          // A quarantine we cannot read must not take the sync indicator down
          // with it: keep the last known count and carry on.
          onError: (Object _) {},
        );
      },
      onCancel: () async {
        await sourceSub?.cancel();
        await quarantineSub?.cancel();
        await controller.close();
      },
    );
    return controller.stream.distinct();
  }

  @override
  FutureResult<int> pendingUploadCount() async {
    try {
      return Right(await _source.pendingUploadCount());
    } catch (e, st) {
      // The queue lives in the local SQLite file (`ps_crud`), so a failure
      // here is a database failure, not a network one.
      return Left(
        DatabaseFailure(
          'could not read the upload queue',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  SyncStatusSnapshot _snapshot(SyncSourceStatus status, int quarantined) {
    final error = status.uploadError ?? status.downloadError;
    return SyncStatusSnapshot(
      state: _map(status, quarantined),
      quarantinedCount: quarantined,
      lastSyncedAt: status.lastSyncedAt,
      hasSyncedEver: status.hasSynced,
      lastErrorMessage: error?.toString(),
    );
  }

  /// Signed out, the repository never calls `connect()` (and sign-out calls
  /// `disconnect()`), so `connected` is false and this reports `offline` —
  /// the product decision for "no session" without dragging auth into core.
  ///
  /// `connecting` counts as offline: there is no link yet, and a spinner that
  /// starts before anything is actually moving reads as noise.
  ///
  /// Order matters. Movement wins (something *is* happening), then held-back
  /// writes: `stalled` outranks both `synced` — which would claim everything
  /// reached the cloud when it did not — and `offline`, which would hide the
  /// only condition here that needs a decision from the user.
  SyncState _map(SyncSourceStatus status, int quarantined) {
    if (status.uploading || status.downloading) {
      return SyncState.syncing;
    }
    if (quarantined > 0) {
      return SyncState.stalled;
    }
    if (status.connected) {
      return SyncState.synced;
    }
    return SyncState.offline;
  }
}
