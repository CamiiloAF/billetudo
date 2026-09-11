import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/notification_kind.dart';
import '../domain/repositories/notification_preferences.dart';

/// `shared_preferences` implementation of [NotificationPreferences] — the
/// project's channel for per-device UI preferences.
@LazySingleton(as: NotificationPreferences)
class SharedPreferencesNotificationPreferences
    implements NotificationPreferences {
  const SharedPreferencesNotificationPreferences(this._prefs);

  final SharedPreferencesAsync _prefs;

  static String _keyFor(NotificationKind kind) => 'notifications_${kind.name}';

  @override
  Future<bool> isEnabled(NotificationKind kind) async =>
      // Defaults to on: none of these fire on their own without the user
      // having created the underlying thing (a template with a reminder, a
      // goal, a manual-mode payment), so the default is not a cold push.
      await _prefs.getBool(_keyFor(kind)) ?? true;

  @override
  Future<void> setEnabled(
    NotificationKind kind, {
    required bool enabled,
  }) =>
      _prefs.setBool(_keyFor(kind), enabled);

  @override
  Future<Map<NotificationKind, bool>> readAll() async {
    final entries = <NotificationKind, bool>{};
    for (final kind in NotificationKind.values) {
      entries[kind] = await isEnabled(kind);
    }
    return entries;
  }
}
