import 'package:injectable/injectable.dart';

import '../../../error/result.dart';
import '../repositories/notification_scheduler.dart';

/// Whether the OS currently lets billetudo post notifications, **without
/// asking for it**.
///
/// Distinct from `EnsureNotificationPermission`, which prompts: this one only
/// reads, so a screen can render the "tu teléfono tiene las notificaciones
/// apagadas" state without a permission dialog popping up just because
/// somebody opened Ajustes.
@injectable
class ReadNotificationPermission {
  const ReadNotificationPermission(this._scheduler);

  final NotificationScheduler _scheduler;

  FutureResult<bool> call() => _scheduler.hasPermission();
}
