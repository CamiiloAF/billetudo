import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/issuer_settings_repository.dart';

/// Stops listening to every issuer in one action (HU-02/HU-09), without
/// making the user go to Android's settings to revoke the permission.
///
/// Captures already in the inbox are left alone: the user can still dispatch
/// them, and deleting them is a separate, explicit decision
/// (`DeleteAllCaptureData`).
@injectable
class DisableAllIssuers {
  const DisableAllIssuers(this._repository);

  final IssuerSettingsRepository _repository;

  FutureResult<Unit> call() => _repository.disableAllIssuers();
}
