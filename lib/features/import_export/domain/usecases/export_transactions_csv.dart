import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/cancellation_token.dart';
import '../entities/csv_vocabulary.dart';
import '../entities/export_scope.dart';
import '../entities/progress_callback.dart';
import '../repositories/export_repository.dart';

/// HU-01: writes the transactions CSV for `scope` at `outputPath`. Returns
/// the number of rows written, so the caller can show "Sin datos que
/// exportar" (HU-09) instead of sharing an empty file when it is `0`.
@injectable
class ExportTransactionsCsv {
  const ExportTransactionsCsv(this._repository);

  final ExportRepository _repository;

  FutureResult<int> call({
    required String outputPath,
    required ExportScope scope,
    required CsvLanguage language,
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  }) =>
      _repository.exportTransactionsCsv(
        outputPath: outputPath,
        scope: scope,
        language: language,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
}
