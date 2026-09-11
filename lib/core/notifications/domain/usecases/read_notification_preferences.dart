import 'package:injectable/injectable.dart';

import '../entities/notification_kind.dart';
import '../repositories/notification_preferences.dart';

/// Current on/off value of every notice kind, for the "Avisos" section of
/// Ajustes.
@injectable
class ReadNotificationPreferences {
  const ReadNotificationPreferences(this._preferences);

  final NotificationPreferences _preferences;

  Future<Map<NotificationKind, bool>> call() => _preferences.readAll();
}
