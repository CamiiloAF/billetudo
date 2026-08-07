import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/export_repository.dart';

/// HU-02: bundles the CSV files written for a multi-kind export into a single
/// `.zip`, so the share sheet only ever offers one artifact.
@injectable
class ZipExportFiles {
  const ZipExportFiles(this._repository);

  final ExportRepository _repository;

  FutureResult<Unit> call({
    required String outputPath,
    required List<String> inputPaths,
  }) =>
      _repository.zipFiles(outputPath: outputPath, inputPaths: inputPaths);
}
