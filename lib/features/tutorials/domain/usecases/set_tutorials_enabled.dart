import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/tutorials_repository.dart';

/// Turns "Mostrar ayuda al entrar a una sección" on or off (HU-04,
/// `docs/requirements/16-minitutoriales.md`), writing
/// `AppSettings.showHelpOnSectionEntry`.
///
/// A plain on/off switch: it never touches the tutorials' "seen" registry.
@injectable
class SetTutorialsEnabled {
  const SetTutorialsEnabled(this._repository);

  final TutorialsRepository _repository;

  FutureResult<Unit> call({required bool enabled}) {
    return _repository.setHelpEnabled(enabled: enabled);
  }
}
