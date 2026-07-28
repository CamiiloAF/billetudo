import '../../domain/entities/sync_state.dart';
import '../cubit/sync_status_state.dart';

/// Which of the five faces of "Estado de sincronización" is showing.
///
/// The order of the checks is the product decision, not an implementation
/// detail: **held-back writes outrank a missing connection**. If there are
/// changes that never left the phone *and* there is no signal, the screen
/// shows attention — the risk weighs more than its cause, and the cause is
/// explained inside.
enum SyncScreenState {
  /// Writes are held back. `$amber-soft` hero, list of what is waiting.
  attention,

  /// Everything reached the cloud.
  healthy,

  /// A session exists but nothing has ever synced on this device.
  /// Informative, never amber.
  neverSynced,

  /// No link right now, nothing held back. Local-first: no alarm.
  offline,

  /// No session at all. Not reachable from the normal flow (Ajustes offers
  /// "Respaldar en la nube" instead) — it is the honest fallback for signing
  /// out with this screen still on the stack.
  signedOut;

  static SyncScreenState resolve(
    SyncStatusState state, {
    required bool isSignedIn,
  }) {
    if (!isSignedIn) {
      return SyncScreenState.signedOut;
    }
    if (state.hasPending) {
      return SyncScreenState.attention;
    }
    if (!state.snapshot.hasSyncedEver && state.snapshot.lastSyncedAt == null) {
      return SyncScreenState.neverSynced;
    }
    if (state.syncState == SyncState.offline) {
      return SyncScreenState.offline;
    }
    return SyncScreenState.healthy;
  }

  bool get isAttention => this == SyncScreenState.attention;
}
