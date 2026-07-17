import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/app_settings.dart';
import '../repositories/app_settings_repository.dart';

/// Observes the account-level app settings singleton (HU-06).
@injectable
class GetAppSettings {
  const GetAppSettings(this._repository);

  final AppSettingsRepository _repository;

  Stream<Result<AppSettings>> call() => _repository.watchSettings();
}
