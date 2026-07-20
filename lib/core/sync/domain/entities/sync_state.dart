/// What the backup/sync engine is doing right now, in product terms (HU-10).
///
/// Deliberately coarse: the Home shows a single passive icon, so the three
/// values below are everything the UI can express. Infrastructure detail
/// (PowerSync's `SyncStatus`, its errors, its download progress) never leaves
/// `core/sync/data/`.
enum SyncState {
  /// Connected to the sync service with no pending work.
  synced,

  /// Uploading local changes or downloading remote ones — including the
  /// post-login merge, which is exactly when the user needs to see movement.
  syncing,

  /// Not talking to the sync service: no session, no network, or connecting.
  /// Local-first, so this is informative and never an error.
  offline,
}
