import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/parsed_notification.dart';
import '../repositories/notification_capture_repository.dart';

/// Pulls whatever the native service buffered while the app was closed and
/// empties that buffer.
///
/// The buffer exists because `NotificationListenerService` runs without a
/// Flutter engine and therefore cannot write to Drift. It holds ONLY extracted
/// fields — never the notification text — and it is bounded, so a long absence
/// drops the oldest entries instead of growing without limit.
///
/// Persisting the result into `PendingCaptures` belongs to the inbox feature;
/// this use case only hands the candidates over.
@injectable
class DrainNativeCaptures {
  const DrainNativeCaptures(this._repository);

  final NotificationCaptureRepository _repository;

  FutureResult<List<ParsedNotification>> call() =>
      _repository.drainPendingCaptures();
}
