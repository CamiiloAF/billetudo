import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/undo_summary.dart';
import '../repositories/import_batch_repository.dart';

/// HU-08: "Deshacer esta importación". The escalated confirmation itself is a
/// `presentation/` concern (a checkbox gate, not a business rule); by the
/// time this runs the user has already confirmed.
@injectable
class UndoImportBatch {
  const UndoImportBatch(this._repository);

  final ImportBatchRepository _repository;

  FutureResult<UndoSummary> call(String batchId) =>
      _repository.undoBatch(batchId);
}
