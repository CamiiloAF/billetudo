import 'package:injectable/injectable.dart';

import '../entities/notification_kind.dart';
import '../repositories/notification_preferences.dart';

/// Turns one kind of notice on or off from Ajustes.
///
/// Persisting the preference is all this does. Cancelling whatever is already
/// scheduled is the reconciler's job (`SyncScheduledPaymentReminders`), which
/// reads this preference and drops what no longer has a reason to exist — one
/// place that decides what should be pending, instead of two that can
/// disagree.
@injectable
class SetNotificationKindEnabled {
  const SetNotificationKindEnabled(this._preferences);

  final NotificationPreferences _preferences;

  Future<void> call(NotificationKind kind, {required bool enabled}) =>
      _preferences.setEnabled(kind, enabled: enabled);
}
