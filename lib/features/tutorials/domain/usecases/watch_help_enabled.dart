import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/tutorials_repository.dart';

/// Observes `AppSettings.showHelpOnSectionEntry` (HU-04,
/// `docs/requirements/fase-1/16-minitutoriales.md`): whether a tutorial the user
/// hasn't seen yet may appear unprompted.
///
/// Not in the original change map, added here because both `AppSettingsCubit`
/// (Ajustes' switch) and `TutorialGateCubit` (the auto-show orchestration)
/// must never call `TutorialsRepository` directly — presentation only talks
/// to `domain/usecases`, and this is the one read the repository interface
/// exposes that had no wrapping use case yet.
@injectable
class WatchHelpEnabled {
  const WatchHelpEnabled(this._repository);

  final TutorialsRepository _repository;

  Stream<Result<bool>> call() => _repository.watchHelpEnabled();
}
