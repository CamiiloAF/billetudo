import '../../../../core/error/result.dart';
import '../entities/import_batch.dart';
import '../entities/undo_summary.dart';

/// HU-08: the import history and its one action, "Deshacer esta
/// importación". Kept separate from `ImportRepository` because it is a
/// different screen/lifecycle (browsing past batches, not running a new
/// import) and has its own data needs (streaming the batch list, reverting).
abstract class ImportBatchRepository {
  /// Every batch ever created, newest first, never excluding reverted ones —
  /// "el registro del lote no se borra" (HU-08).
  Stream<Result<List<ImportBatch>>> watchBatches();

  /// HU-08: marks [batchId] `revertedAt`, trashes (`deletedAt`) every
  /// transaction it created plus every account/category/tag it created that
  /// has no use outside it (kept otherwise), all inside one transaction. With
  /// a session active, propagates to the cloud like any other trash — this is
  /// not a "local only" write.
  FutureResult<UndoSummary> undoBatch(String batchId);
}
