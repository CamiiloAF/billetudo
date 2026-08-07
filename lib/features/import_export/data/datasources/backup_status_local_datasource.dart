import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local "last local copy saved at" marker (HU-03/HU-09). Same
/// storage decision as `ThemePreferenceDatasource`/
/// `MappingTemplatesLocalDatasource`: a small per-device value with no
/// business meaning to sync, so `shared_preferences` rather than a Drift
/// column.
@lazySingleton
class BackupStatusLocalDatasource {
  const BackupStatusLocalDatasource(this._prefs);

  static const String _key = 'import_export_last_backup_saved_at';

  final SharedPreferencesAsync _prefs;

  Future<DateTime?> getLastSavedAt() async {
    final raw = await _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> setLastSavedAt(DateTime savedAt) =>
      _prefs.setString(_key, savedAt.toIso8601String());
}
