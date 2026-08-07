import 'package:equatable/equatable.dart';

import 'import_batch.dart';

/// The final report `ConfirmImport` returns (HU-06): "importadas, omitidas
/// por duplicado, omitidas por error, cuentas/categorías/etiquetas creadas".
class ImportSummary extends Equatable {
  const ImportSummary({
    required this.batch,
    required this.rowsImported,
    required this.rowsSkippedDuplicate,
    required this.rowsSkippedError,
    required this.accountsCreated,
    required this.categoriesCreated,
    required this.tagsCreated,
  });

  final ImportBatch batch;
  final int rowsImported;
  final int rowsSkippedDuplicate;
  final int rowsSkippedError;
  final int accountsCreated;
  final int categoriesCreated;
  final int tagsCreated;

  @override
  List<Object?> get props => [
        batch,
        rowsImported,
        rowsSkippedDuplicate,
        rowsSkippedError,
        accountsCreated,
        categoriesCreated,
        tagsCreated,
      ];
}
