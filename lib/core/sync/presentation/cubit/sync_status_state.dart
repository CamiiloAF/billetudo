import 'package:equatable/equatable.dart';

import '../../domain/entities/sync_state.dart';
import '../../domain/entities/sync_status_snapshot.dart';
import '../models/pending_sync_change.dart';

/// [loading] renders the skeleton. There is deliberately no failure status:
/// the screen reads the local queue, never the network (HU-08), so it has
/// nothing to fail at.
enum SyncStatusStatus { loading, ready }

/// What the last manual retry ended in, so the page can raise the right
/// snackbar exactly once.
enum SyncRetryOutcome {
  /// Nothing to report (initial, or already consumed by the page).
  none,

  /// Every held-back write went up.
  allUploaded,

  /// Some (or none) went up. Never phrased as data loss: what did not upload
  /// is still on the phone.
  partial,
}

class SyncStatusState extends Equatable {
  const SyncStatusState({
    this.status = SyncStatusStatus.loading,
    this.snapshot = const SyncStatusSnapshot.unknown(),
    this.pending = const [],
    this.isRetrying = false,
    this.retryOutcome = SyncRetryOutcome.none,
    this.retriedCount = 0,
  });

  final SyncStatusStatus status;
  final SyncStatusSnapshot snapshot;

  /// Oldest first: the screen shows a *sample* of the queue (the three that
  /// have been waiting longest), not a summary.
  final List<PendingSyncChange> pending;

  /// A manual retry is in flight. It drives the CTA only — never the hero and
  /// never the list. Repainting those optimistically is the exact failure mode
  /// of the incident this feature exists for.
  final bool isRetrying;

  final SyncRetryOutcome retryOutcome;

  /// How many writes the last retry actually landed.
  final int retriedCount;

  bool get isLoading => status == SyncStatusStatus.loading;

  bool get hasPending => pending.isNotEmpty;

  int get pendingCount => pending.length;

  /// The state of the engine, with the queue taken into account.
  SyncState get syncState => snapshot.state;

  SyncStatusState copyWith({
    SyncStatusStatus? status,
    SyncStatusSnapshot? snapshot,
    List<PendingSyncChange>? pending,
    bool? isRetrying,
    SyncRetryOutcome? retryOutcome,
    int? retriedCount,
  }) =>
      SyncStatusState(
        status: status ?? this.status,
        snapshot: snapshot ?? this.snapshot,
        pending: pending ?? this.pending,
        isRetrying: isRetrying ?? this.isRetrying,
        retryOutcome: retryOutcome ?? this.retryOutcome,
        retriedCount: retriedCount ?? this.retriedCount,
      );

  @override
  List<Object?> get props => [
        status,
        snapshot,
        pending,
        isRetrying,
        retryOutcome,
        retriedCount,
      ];
}
