import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/tutorial_key.dart';
import '../repositories/tutorials_repository.dart';

/// Whether the account has already dismissed a given tutorial
/// (`docs/requirements/fase-1/16-minitutoriales.md`, "Ya lo vi").
@injectable
class HasSeenTutorial {
  const HasSeenTutorial(this._repository);

  final TutorialsRepository _repository;

  FutureResult<bool> call(TutorialKey key) => _repository.hasSeen(key);
}
