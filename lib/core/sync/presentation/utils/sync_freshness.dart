/// How old a successful sync may get before the UI stops calling it normal.
///
/// The threshold is the literal lesson of the 2026-07-25 incident: the app
/// spent three days showing a healthy spinner while its upload queue was
/// blocked. Below 24 h a gap is ordinary (a phone in a lift, a night with the
/// app closed); past it, "syncing" and "syncing for three days" must not look
/// the same, so the time row turns `$amber-text` and the cloud sheet swaps to
/// its "taking too long" copy.
abstract final class SyncFreshness {
  const SyncFreshness._();

  /// Documented in `design-system/billetudo/pages/sincronizacion.md`.
  static const Duration staleAfter = Duration(hours: 24);

  /// Whether [lastSyncedAt] is old enough to be shown as attention.
  ///
  /// A device that never synced is **not** stale: that is an informative
  /// state ("Aún no se ha sincronizado"), never an amber one.
  static bool isStale(DateTime? lastSyncedAt, {required DateTime now}) {
    if (lastSyncedAt == null) {
      return false;
    }
    return now.difference(lastSyncedAt) >= staleAfter;
  }
}
