/// What the backup/sync engine is doing right now, in product terms (HU-10).
///
/// Deliberately coarse: infrastructure detail (PowerSync's `SyncStatus`, its
/// errors, its download progress) never leaves `core/sync/data/`. Anything a
/// screen needs beyond the state itself — when the last successful sync was,
/// how many writes are held back — travels in `SyncStatusSnapshot`.
enum SyncState {
  /// Connected to the sync service with no pending work.
  synced,

  /// Uploading local changes or downloading remote ones — including the
  /// post-login merge, which is exactly when the user needs to see movement.
  syncing,

  /// Not talking to the sync service: no session, no network, or connecting.
  /// Local-first, so this is informative and never an error.
  offline,

  /// Some writes are held back: the cloud rejected them and they are waiting
  /// in the local quarantine for a retry or a decision.
  ///
  /// Distinct from [offline] (nothing is wrong, there is just no link) and
  /// from [synced] (which would be a lie: not everything reached the cloud).
  /// Nothing is lost in this state — that is the whole point of the
  /// quarantine — but the user has changes that are not backed up.
  stalled,
}
