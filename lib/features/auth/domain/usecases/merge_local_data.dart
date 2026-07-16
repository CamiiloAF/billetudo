import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/merge_summary.dart';
import '../repositories/auth_repository.dart';

/// HU-04: folds this device's local data into the account right after a
/// first sign-in and reports what got merged.
@injectable
class MergeLocalData {
  const MergeLocalData(this._repository);

  final AuthRepository _repository;

  FutureResult<MergeSummary> call() => _repository.mergeLocalData();
}
