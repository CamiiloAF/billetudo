import '../../../../core/error/result.dart';

/// The hub's own memory of "when was the last local copy saved" (HU-03/HU-09,
/// `Copy Status Row`/`AGZry`). Local, per-device state — not part of the copy
/// file itself, so a copy stays discoverable across app restarts without
/// re-scanning the filesystem for `.billetudo.json` files.
abstract class BackupStatusRepository {
  FutureResult<DateTime?> getLastSavedAt();

  FutureResult<Unit> setLastSavedAt(DateTime savedAt);
}
