import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/tutorial_key.dart';
import '../repositories/tutorials_repository.dart';

/// Marks a tutorial as seen — called on its primary CTA, "Entendido", or the
/// sheet's standard close gesture (swipe/tap-outside), all of which count as
/// seen per HU-01/HU-02 (`docs/requirements/16-minitutoriales.md`). Reopening
/// a tutorial from "Ver ayuda"/`?` must NOT call this — HU-03 requires that
/// reopening never alters the registry.
@injectable
class MarkTutorialSeen {
  const MarkTutorialSeen(this._repository);

  final TutorialsRepository _repository;

  FutureResult<Unit> call(TutorialKey key) => _repository.markSeen(key);
}
