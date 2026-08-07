import '../../../../core/error/result.dart';
import '../entities/backup_header.dart';
import '../entities/cancellation_token.dart';
import '../entities/progress_callback.dart';
import '../entities/restore_mode.dart';
import '../entities/restore_summary.dart';

/// HU-03/HU-04: the full-copy (`.billetudo.json`) side of this feature.
/// Implemented in `data/` by walking every sync-managed Drift table directly
/// — this is a copy of raw storage state (including `deletedAt`/
/// `tombstonedAt`), not a view built from other features' domain entities,
/// which intentionally hide those columns.
abstract class BackupRepository {
  /// Streams every sync-managed table to a new `.billetudo.json` file at
  /// [outputPath], table by table, never materializing the whole database in
  /// memory. Excludes `userId` (there is no `accountNumberEnc` column to
  /// exclude — it never lived in Drift). Returns the header written.
  ///
  /// [onProgress] fires once per table written — `processed`/`total` count
  /// *tables*, not rows, matching HU-03's "streaming, tabla por tabla".
  /// [cancellationToken] stops the write at the next table boundary and
  /// deletes the partial file, same as HU-01.
  FutureResult<BackupHeader> createFullBackup({
    required String outputPath,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  });

  /// Reads only the cabecera of the copy at [inputPath], without touching any
  /// table — HU-04's very first, cheap step, so a copy from a newer format
  /// version can be rejected before reading a single row.
  FutureResult<BackupHeader> parseBackupHeader(String inputPath);

  /// HU-04: restores the copy at [inputPath] per [mode], entirely inside one
  /// database transaction — it either lands complete or not at all.
  ///
  /// [onProgress] fires once per table merged (`processed`/`total` count
  /// tables, same granularity as [createFullBackup]).
  /// [cancellationToken] stops the merge at the next table boundary; because
  /// the whole restore is one Drift transaction, cancelling rolls it back —
  /// "cancelar no deja filas a medias" holds by construction.
  FutureResult<RestoreSummary> restoreBackup({
    required String inputPath,
    required RestoreMode mode,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  });
}
