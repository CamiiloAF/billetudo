import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/notification_capture_repository.dart';

/// Which issuers are currently switched on (HU-02). An empty set with the
/// permission granted still captures nothing, and the inbox says so.
@injectable
class GetEnabledIssuers {
  const GetEnabledIssuers(this._repository);

  final NotificationCaptureRepository _repository;

  FutureResult<Set<String>> call() => _repository.getEnabledIssuers();
}
