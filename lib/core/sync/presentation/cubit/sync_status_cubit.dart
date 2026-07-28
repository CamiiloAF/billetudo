import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/quarantined_operation.dart';
import '../../domain/entities/sync_status_snapshot.dart';
import '../../domain/usecases/retry_all_quarantined_operations.dart';
import '../../domain/usecases/retry_quarantined_operation.dart';
import '../../domain/usecases/watch_quarantined_operations.dart';
import '../../domain/usecases/watch_sync_status_details.dart';
import '../models/pending_sync_change.dart';
import 'sync_status_state.dart';

/// Orchestrates "Estado de sincronización" (HU-08).
///
/// Two local streams, no network: the engine's snapshot (when the last full
/// sync landed, what it is doing now) and the quarantine (what is held back).
/// The screen is painted from the local queue on purpose — asking the cloud
/// how the cloud is doing is the question that cannot be answered when the
/// cloud is the problem.
///
/// **Nothing here repaints optimistically.** A manual retry only flips
/// [SyncStatusState.isRetrying]; the hero keeps saying the writes are on the
/// phone and the rows only disappear as the repository confirms each one.
/// Both come from the streams, so "confirmed" is the only thing that can
/// change them.
@injectable
class SyncStatusCubit extends Cubit<SyncStatusState> {
  SyncStatusCubit(
    this._watchSyncStatusDetails,
    this._watchQuarantinedOperations,
    this._retryAllQuarantinedOperations,
    this._retryQuarantinedOperation,
  ) : super(const SyncStatusState());

  final WatchSyncStatusDetails _watchSyncStatusDetails;
  final WatchQuarantinedOperations _watchQuarantinedOperations;
  final RetryAllQuarantinedOperations _retryAllQuarantinedOperations;
  final RetryQuarantinedOperation _retryQuarantinedOperation;

  StreamSubscription<SyncStatusSnapshot>? _statusSub;
  StreamSubscription<List<QuarantinedOperation>>? _quarantineSub;

  bool _hasStatus = false;
  bool _hasQuarantine = false;

  Future<void> start() async {
    await _statusSub?.cancel();
    await _quarantineSub?.cancel();
    _statusSub = _watchSyncStatusDetails().listen(_onStatus);
    _quarantineSub = _watchQuarantinedOperations().listen(
      _onQuarantine,
      // A quarantine we cannot read must not take the screen down with it:
      // the rest of the status is still true and still worth showing.
      onError: (Object _) {
        _hasQuarantine = true;
        _settleStatus();
      },
    );
  }

  void _onStatus(SyncStatusSnapshot snapshot) {
    if (isClosed) {
      return;
    }
    _hasStatus = true;
    emit(state.copyWith(snapshot: snapshot, status: _resolvedStatus()));
  }

  void _onQuarantine(List<QuarantinedOperation> operations) {
    if (isClosed) {
      return;
    }
    _hasQuarantine = true;
    // Oldest first: the three the screen shows are the ones that have been
    // waiting longest, which is what makes the passage of time legible.
    final sorted = [...operations]
      ..sort((a, b) => a.quarantinedAt.compareTo(b.quarantinedAt));
    emit(
      state.copyWith(
        pending: sorted.map(PendingSyncChange.fromOperation).toList(),
        status: _resolvedStatus(),
      ),
    );
  }

  void _settleStatus() {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(status: _resolvedStatus()));
  }

  /// The skeleton stays only until both local reads have answered — it exists
  /// for SQLite latency, not for the network.
  SyncStatusStatus _resolvedStatus() => _hasStatus && _hasQuarantine
      ? SyncStatusStatus.ready
      : SyncStatusStatus.loading;

  /// "Reintentar ahora" / "Sincronizar ahora": replays every held-back write.
  ///
  /// The outcome is reported with a snackbar, never by quietly rewriting the
  /// hero. A partial result is still honest news: what did not upload is
  /// still complete on the phone.
  Future<void> retryAll() async {
    if (state.isRetrying) {
      return;
    }
    final expected = state.pendingCount;
    emit(
      state.copyWith(
        isRetrying: true,
        retryOutcome: SyncRetryOutcome.none,
        retriedCount: 0,
      ),
    );
    final result = await _retryAllQuarantinedOperations();
    if (isClosed) {
      return;
    }
    final uploaded = result.getRight().toNullable() ?? 0;
    emit(
      state.copyWith(
        isRetrying: false,
        retriedCount: uploaded,
        retryOutcome: result.isLeft() || uploaded < expected
            ? SyncRetryOutcome.partial
            : SyncRetryOutcome.allUploaded,
      ),
    );
  }

  /// "Reintentar" from a single change's detail sheet.
  Future<void> retryOne(String id) async {
    if (state.isRetrying) {
      return;
    }
    emit(
      state.copyWith(
        isRetrying: true,
        retryOutcome: SyncRetryOutcome.none,
        retriedCount: 0,
      ),
    );
    final result = await _retryQuarantinedOperation(id);
    if (isClosed) {
      return;
    }
    final succeeded = result.isRight();
    emit(
      state.copyWith(
        isRetrying: false,
        retriedCount: succeeded ? 1 : 0,
        retryOutcome:
            succeeded ? SyncRetryOutcome.allUploaded : SyncRetryOutcome.partial,
      ),
    );
  }

  /// The page raises each outcome once; this clears it afterwards.
  void acknowledgeRetryOutcome() {
    if (isClosed || state.retryOutcome == SyncRetryOutcome.none) {
      return;
    }
    emit(state.copyWith(retryOutcome: SyncRetryOutcome.none));
  }

  @override
  Future<void> close() async {
    await _statusSub?.cancel();
    await _quarantineSub?.cancel();
    return super.close();
  }
}
