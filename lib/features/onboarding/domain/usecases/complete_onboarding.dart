import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../settings/domain/usecases/set_onboarding_completed.dart';

/// `docs/requirements/fase-1/13-onboarding.md`: closes the welcome flow for good.
///
/// Called when the user acts on the closing screen (HU-04: registers a
/// transaction or skips) or when "Ya tengo cuenta" (HU-06) finishes
/// successfully. Turns on `AppSettings.onboardingCompleted`, which never
/// turns off again — thin wrapper around the settings feature's
/// [SetOnboardingCompleted] so the onboarding feature does not reach into
/// `AppSettingsRepository` directly.
@injectable
class CompleteOnboarding {
  const CompleteOnboarding(this._setOnboardingCompleted);

  final SetOnboardingCompleted _setOnboardingCompleted;

  FutureResult<Unit> call() => _setOnboardingCompleted();
}
