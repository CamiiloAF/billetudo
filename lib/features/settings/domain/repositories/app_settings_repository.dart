import '../../../../core/error/result.dart';
import '../entities/app_settings.dart';

/// Contract for reading and writing the account-level [AppSettings] singleton.
/// Implemented in `data/` over the Drift `AppSettings` row (id `'app'`).
///
/// Writes are an upsert on that constant id — never a second row — and stamp
/// `updatedAt` so PowerSync merges last-write-wins.
abstract class AppSettingsRepository {
  /// Observes the settings singleton, re-emitting on every change. Emits
  /// [AppSettings.defaults] semantics if the row is somehow missing.
  Stream<Result<AppSettings>> watchSettings();

  /// Turns "Modo sobres" (zero-based) on or off (HU-06).
  FutureResult<Unit> setZeroBasedEnabled(bool enabled);
}
