import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the two per-device dates behind the degraded state (HU-09):
/// when the user configured capture, and until when the card is silenced.
///
/// SharedPreferences and not Drift, for the same reason as
/// `CaptureOfferPreferenceDatasource` and
/// `IssuerSettingsPreferenceDatasource`: the notification permission is
/// granted per device, so both dates are facts about **this phone**. Syncing
/// them would silence the card on a phone that never saw it, or hide a real
/// problem on a phone whose owner never dismissed anything.
///
/// Stored as epoch milliseconds (an `int`) because `SharedPreferencesAsync`
/// has no date type; the value is a timestamp, never notification content.
@lazySingleton
class CaptureBackgroundPreferenceDatasource {
  const CaptureBackgroundPreferenceDatasource(this._prefs);

  static const String _configuredAtKey = 'capture_background_configured_at';
  static const String _snoozeUntilKey = 'capture_background_snooze_until';

  final SharedPreferencesAsync _prefs;

  /// `null` means "never configured on this device", which is different from
  /// "configured just now": only the first starts the grace period.
  Future<DateTime?> readConfiguredAt() => _readDate(_configuredAtKey);

  Future<DateTime?> readSnoozeUntil() => _readDate(_snoozeUntilKey);

  Future<void> writeConfiguredAt(DateTime at) =>
      _prefs.setInt(_configuredAtKey, at.millisecondsSinceEpoch);

  Future<void> writeSnoozeUntil(DateTime until) =>
      _prefs.setInt(_snoozeUntilKey, until.millisecondsSinceEpoch);

  Future<DateTime?> _readDate(String key) async {
    final int? millis = await _prefs.getInt(key);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
