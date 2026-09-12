import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/app_settings_repository.dart';

/// Records the AI assistant's third-party data-sharing consent as accepted
/// (Apple 5.1.2(i)) — the gate `AiConsentCubit` checks before the composer
/// lets anyone type a first message.
@injectable
class MarkAiConsentAccepted {
  const MarkAiConsentAccepted(this._repository);

  final AppSettingsRepository _repository;

  FutureResult<Unit> call() => _repository.markAiConsentAccepted();
}
