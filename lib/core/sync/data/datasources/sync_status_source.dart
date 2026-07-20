/// A snapshot of the sync engine, reduced to the three flags this app reads.
///
/// Owned by us on purpose: PowerSync's own `SyncStatus` is a `final class`
/// whose constructor is `@internal`, so it cannot be built in a test without
/// reaching into the package. Copying the flags into a plain value object
/// keeps the state mapping verifiable.
class SyncSourceStatus {
  const SyncSourceStatus({
    required this.connected,
    required this.uploading,
    required this.downloading,
  });

  /// The engine has a live link to the sync service.
  final bool connected;

  /// Local changes are being pushed.
  final bool uploading;

  /// Remote changes are being pulled.
  final bool downloading;
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
