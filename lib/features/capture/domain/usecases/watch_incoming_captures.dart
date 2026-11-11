import 'package:injectable/injectable.dart';

import '../repositories/notification_capture_repository.dart';

/// Signals that the native listener parked a new capture while the app is
/// running, so the inbox and its badge can be refreshed right away.
///
/// It is a doorbell, not data: whoever hears it drains the native buffer with
/// `DrainAndIngestCaptures`. That split is deliberate — the notification
/// content only ever crosses the channel through the atomic drain, which
/// empties the native buffer in the same call.
@injectable
class WatchIncomingCaptures {
  const WatchIncomingCaptures(this._repository);

  final NotificationCaptureRepository _repository;

  Stream<void> call() => _repository.incomingCaptureEvents();
}
