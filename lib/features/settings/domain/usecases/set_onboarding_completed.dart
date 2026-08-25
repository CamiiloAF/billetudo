import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/app_settings_repository.dart';

/// Latches the welcome flow as completed for this installation
/// (`docs/requirements/fase-1/13-onboarding.md`). Idempotent; the flag never turns
/// off once set.
@injectable
class SetOnboardingCompleted {
  const SetOnboardingCompleted(this._repository);

  final AppSettingsRepository _repository;

  FutureResult<Unit> call() => _repository.markOnboardingCompleted();
}
