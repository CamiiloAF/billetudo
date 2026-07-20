import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/app_settings_repository.dart';

/// Turns "Modo sobres" (zero-based budgeting) on or off (HU-06).
@injectable
class SetZeroBasedEnabled {
  const SetZeroBasedEnabled(this._repository);

  final AppSettingsRepository _repository;

  FutureResult<Unit> call({required bool enabled}) =>
      _repository.setZeroBasedEnabled(enabled: enabled);
}
