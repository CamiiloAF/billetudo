import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the one-shot latch of the contextual permission offer (HU-01).
///
/// Local and per-device, not a synced Drift column, for the same reason the
/// issuer switches are (`IssuerSettingsPreferenceDatasource`): the
/// notification-access permission is granted per device, so "already offered"
/// is a fact about **this phone**. Syncing it would silently swallow the
/// offer on a second device that has nothing granted.
@lazySingleton
class CaptureOfferPreferenceDatasource {
  const CaptureOfferPreferenceDatasource(this._prefs);

  static const String _key = 'capture_permission_offered';

  final SharedPreferencesAsync _prefs;

  /// Defaults to `false`: a device that has never been asked has never been
  /// offered.
  Future<bool> readOffered() async => await _prefs.getBool(_key) ?? false;

  Future<void> writeOffered() => _prefs.setBool(_key, true);
}
