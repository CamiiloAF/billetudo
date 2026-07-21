import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads/writes the user's chosen [ThemeMode] (Ajustes → "Apariencia") to
/// local, per-device storage.
///
/// Deliberately not part of `AppSettings` (Drift, synced via PowerSync):
/// appearance is a device preference, not an account one, so a signed-in
/// user's devices never fight over it. First use of `shared_preferences` in
/// the project — every other persisted value so far goes through Drift.
@lazySingleton
class ThemePreferenceDatasource {
  const ThemePreferenceDatasource(this._prefs);

  static const String _key = 'theme_mode';

  final SharedPreferencesAsync _prefs;

  /// Falls back to [ThemeMode.system] when nothing has been saved yet (first
  /// launch, or a value this version no longer recognizes).
  Future<ThemeMode> read() async {
    final stored = await _prefs.getString(_key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> write(ThemeMode mode) => _prefs.setString(_key, mode.name);
}
