import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/notification_capture_repository.dart';

/// Replaces the set of issuers the service is allowed to read (HU-02).
/// Turning one off stops its captures from that instant; the pending ones it
/// already produced stay in the inbox until the user dispatches them.
@injectable
class SetEnabledIssuers {
  const SetEnabledIssuers(this._repository);

  final NotificationCaptureRepository _repository;

  FutureResult<Unit> call(Set<String> issuerIds) =>
      _repository.setEnabledIssuers(issuerIds);
}
