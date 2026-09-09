import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores which issuer apps the user switched on (HU-02), in local,
/// per-device storage.
///
/// Deliberately not a Drift/PowerSync table, unlike the captures themselves:
/// which apps can be listened to is a fact about **this phone** — the
/// notification-access permission is granted per device and the issuer apps
/// are the ones installed on it. Syncing the switches would turn capture on
/// for a device whose owner never granted anything, and switch off a device
/// that did. Same reasoning as `ThemePreferenceDatasource` and
/// `AccountFilterPreferenceDatasource`.
///
/// The stored value is a list of package names, never anything read from a
/// notification.
@lazySingleton
class IssuerSettingsPreferenceDatasource {
  IssuerSettingsPreferenceDatasource(this._prefs);

  static const String _key = 'capture_enabled_issuers';

  final SharedPreferencesAsync _prefs;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Emits after every write, so watchers re-read. Nothing is carried in the
  /// event itself: the reader always goes back to storage, which keeps a
  /// stale in-memory copy from being served.
  Stream<void> get changes => _changes.stream;

  /// Defaults to the empty set: every issuer starts off, and a device that
  /// has never been configured captures nothing.
  Future<Set<String>> readEnabledPackages() async =>
      (await _prefs.getStringList(_key))?.toSet() ?? const <String>{};

  Future<void> writeEnabledPackages(Set<String> packageNames) async {
    if (packageNames.isEmpty) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setStringList(_key, packageNames.toList());
    }
    _changes.add(null);
  }

  /// Only used by tests: as a singleton this lives for the whole process.
  Future<void> dispose() => _changes.close();
}
