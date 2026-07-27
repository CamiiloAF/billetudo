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

  /// One-shot read of the settings singleton (not a stream). Returns
  /// [AppSettings.defaults] semantics if the row is somehow missing.
  FutureResult<AppSettings> getSettings();

  /// Turns "Modo sobres" (zero-based) on or off (HU-06).
  FutureResult<Unit> setZeroBasedEnabled({required bool enabled});

  /// Latches the onboarding default categories as seeded for this installation
  /// (HU-06). Idempotent: safe to call again.
  FutureResult<Unit> markCategoriesSeeded();
}
