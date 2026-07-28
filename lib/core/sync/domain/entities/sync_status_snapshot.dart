import 'package:equatable/equatable.dart';

import 'sync_state.dart';

/// Everything a screen can say about the backup, in domain terms.
///
/// [SyncState] alone answers "what is it doing right now"; this adds the two
/// questions the 2026-07-25 incident left unanswerable from inside the app —
/// *when did anything last reach the cloud* and *is something held back* — for
/// three days, while the UI kept showing a healthy icon.
class SyncStatusSnapshot extends Equatable {
  const SyncStatusSnapshot({
    required this.state,
    required this.quarantinedCount,
    this.lastSyncedAt,
    this.hasSyncedEver = false,
    this.lastErrorMessage,
  });

  /// Nothing known yet (before the first emission).
  const SyncStatusSnapshot.unknown()
      : state = SyncState.offline,
        quarantinedCount = 0,
        lastSyncedAt = null,
        hasSyncedEver = false,
        lastErrorMessage = null;

  final SyncState state;

  /// Writes the cloud rejected, held locally. Never dropped silently.
  final int quarantinedCount;

  /// When a full sync cycle last completed. `null` when it never has (a fresh
  /// install, or a session that has not synced yet).
  final DateTime? lastSyncedAt;

  /// Whether a full sync ever completed on this device. Tells "never synced"
  /// apart from "synced a while ago", which read the same when [lastSyncedAt]
  /// is the only signal.
  final bool hasSyncedEver;

  /// Technical description of the last upload/download error, in English.
  /// Diagnostics only — a screen shows a localized message, never this.
  final String? lastErrorMessage;

  bool get hasQuarantinedOperations => quarantinedCount > 0;

  @override
  List<Object?> get props => [
        state,
        quarantinedCount,
        lastSyncedAt,
        hasSyncedEver,
        lastErrorMessage,
      ];
}
