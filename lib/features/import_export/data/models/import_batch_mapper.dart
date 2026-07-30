import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/import_batch.dart';

/// Translates between Drift's generated `ImportBatch` row and the domain
/// entity — the only place where the generated type meets `domain`.
abstract final class ImportBatchMapper {
  static ImportBatch toEntity(db.ImportBatche row) => ImportBatch(
        id: row.id,
        fileName: row.fileName,
        templateName: row.templateName,
        importedAt: row.importedAt,
        rowsImported: row.rowsImported,
        rowsSkipped: row.rowsSkipped,
        revertedAt: row.revertedAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
