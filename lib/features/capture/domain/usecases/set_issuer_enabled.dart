import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/issuer_settings_repository.dart';

/// Turns listening to one issuer app on or off (HU-02).
///
/// This is the only thing that decides whether a notification is looked at at
/// all: the filter runs on `packageName` before any content is read, so an
/// issuer that is off never has its notifications parsed, logged or counted.
@injectable
class SetIssuerEnabled {
  const SetIssuerEnabled(this._repository);

  final IssuerSettingsRepository _repository;

  FutureResult<Unit> call({
    required String packageName,
    required bool enabled,
  }) =>
      _repository.setIssuerEnabled(packageName: packageName, enabled: enabled);
}
