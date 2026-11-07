import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage for the manual "new movement" attempt counter.
///
/// `SharedPreferencesAsync` (not a Drift column) for the same reason as
/// `CaptureOfferPreferenceDatasource`: this is a fact about the device's
/// onboarding, not user data worth syncing. PowerSync would put it on every
/// device of the same account, which is exactly what the counter must not do.
@lazySingleton
class ManualMovementAttemptPreferenceDatasource {
  const ManualMovementAttemptPreferenceDatasource(this._prefs);

  static const String _key = 'voice_gesture_manual_movement_attempts';

  final SharedPreferencesAsync _prefs;

  /// Defaults to `0`: a device that never opened the form has no attempts.
  Future<int> readAttempts() async => await _prefs.getInt(_key) ?? 0;

  Future<void> writeAttempts(int attempts) => _prefs.setInt(_key, attempts);
}
