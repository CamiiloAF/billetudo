import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/parsed_csv_sample.dart';
import '../repositories/import_repository.dart';

/// HU-05: reads a candidate import file's headers, a data-row sample and its
/// detected dialect. Fails with `IoFailure` on an unreadable/empty file
/// (HU-09).
@injectable
class ParseCsvHeaders {
  const ParseCsvHeaders(this._repository);

  final ImportRepository _repository;

  FutureResult<ParsedCsvSample> call(String filePath) =>
      _repository.readCsvSample(filePath);
}
