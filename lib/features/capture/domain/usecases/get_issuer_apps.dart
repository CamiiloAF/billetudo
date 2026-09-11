import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/issuer_app.dart';
import '../repositories/notification_capture_repository.dart';

/// The issuer list of HU-02: catalogued apps that are actually installed on
/// this device, with their on/off state. Everything is off by default.
@injectable
class GetIssuerApps {
  const GetIssuerApps(this._repository);

  final NotificationCaptureRepository _repository;

  FutureResult<List<IssuerApp>> call() => _repository.getInstalledIssuerApps();
}
