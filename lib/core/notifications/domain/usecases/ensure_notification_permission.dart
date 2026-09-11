import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/notification_scheduler.dart';

/// Grants-or-asks for the OS notification permission, **in context**: the
/// only caller is the moment a user turns a reminder on for the first time
/// (Android 13+ `POST_NOTIFICATIONS`, iOS alert authorization).
///
/// Asking at startup is explicitly forbidden by the feature spec: a prompt
/// with no visible reason is the one that gets denied forever, and a denied
/// permission cannot be re-requested from inside the app.
///
/// Returns whether notifications are allowed afterwards. A `false` never
/// blocks the flow that called it — the preference is still saved, it just
/// will not fire (HU-08).
@injectable
class EnsureNotificationPermission {
  const EnsureNotificationPermission(this._scheduler);

  final NotificationScheduler _scheduler;

  FutureResult<bool> call() async {
    final current = await _scheduler.hasPermission();
    return switch (current) {
      Left(value: final failure) => Left(failure),
      Right(value: true) => const Right(true),
      Right() => await _scheduler.requestPermission(),
    };
  }
}
