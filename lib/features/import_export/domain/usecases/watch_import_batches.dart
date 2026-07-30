import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/import_batch.dart';
import '../repositories/import_batch_repository.dart';

/// HU-08: the "Importaciones" history screen.
@injectable
class WatchImportBatches {
  const WatchImportBatches(this._repository);

  final ImportBatchRepository _repository;

  Stream<Result<List<ImportBatch>>> call() => _repository.watchBatches();
}
