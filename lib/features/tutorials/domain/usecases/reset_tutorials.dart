import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/tutorials_repository.dart';

/// Clears the "already seen" registry for every tutorial (HU-04): the only
/// way a sheet can appear unprompted again after having been dismissed.
/// Invoked by `SetTutorialsEnabled` when the account help preference toggles
/// from off back to on — never called directly by presentation.
@injectable
class ResetTutorials {
  const ResetTutorials(this._repository);

  final TutorialsRepository _repository;

  FutureResult<Unit> call() => _repository.resetAll();
}
