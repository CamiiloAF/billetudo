import 'package:clock/clock.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/capture_background_preferences_repository.dart';

/// "Ahora no" on the degraded card: hides it for [snoozeDuration] (HU-09).
///
/// It silences the surface and nothing else. Capture keeps running, the
/// permission and the issuer switches are untouched, and no capture is
/// discarded — the card is an explanation, not a setting, and saying "not now"
/// must never cost the user data.
@injectable
class SnoozeCaptureBackgroundAlert {
  const SnoozeCaptureBackgroundAlert(this._preferences);

  /// Fourteen days, from the spec. Long enough to stop the card from becoming
  /// a daily nag, short enough to say the truth again if capture stays broken.
  static const Duration snoozeDuration = Duration(days: 14);

  final CaptureBackgroundPreferencesRepository _preferences;

  FutureResult<Unit> call() =>
      _preferences.snoozeUntil(clock.now().add(snoozeDuration));
}
