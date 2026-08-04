/// A snapshot of the sync engine, reduced to what this app reads.
///
/// Owned by us on purpose: PowerSync's own `SyncStatus` is a `final class`
/// whose constructor is `@internal`, so it cannot be built in a test without
/// reaching into the package. Copying the fields into a plain value object
/// keeps the state mapping verifiable.
class SyncSourceStatus {
  const SyncSourceStatus({
    required this.connected,
    required this.uploading,
    required this.downloading,
    this.lastSyncedAt,
    this.hasSynced = false,
    this.uploadError,
    this.downloadError,
  });

  /// The engine has a live link to the sync service.
  final bool connected;

  /// Local changes are being pushed.
  final bool uploading;

  /// Remote changes are being pulled.
  final bool downloading;

  /// When the last full sync cycle completed, if any.
  ///
  /// Used to be dropped here, which is part of why a queue could stay blocked
  /// for three days with the app showing a healthy indicator: nothing in the
  /// product could tell "synced a minute ago" from "synced last Tuesday".
  final DateTime? lastSyncedAt;

  /// Whether a full cycle ever completed on this device.
  final bool hasSynced;

  /// Last upload/download error the engine saw. Kept as `Object?` because that
  /// is what PowerSync exposes; it never leaves `data/` in this shape — the
  /// repository turns it into a string for `domain`.
  final Object? uploadError;
  final Object? downloadError;
}

/// Narrow port over the sync engine: only what the status repository uses.
///
/// Lives in `data/` because it models infrastructure, not business rules;
/// `domain` and `presentation` keep seeing `SyncState` only.
abstract class SyncStatusSource {
  /// The state right now, without waiting for a change.
  SyncSourceStatus get currentStatus;

  /// Emits on every change (not on subscription).
  Stream<SyncSourceStatus> get statusStream;

  /// How many local operations are still waiting to be pushed, right now.
  ///
  /// A one-shot read on purpose: the sign-out sheet needs a photo to decide
  /// on, not a live counter.
  Future<int> pendingUploadCount();
}
