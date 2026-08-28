import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/app_settings_repository.dart';

/// Withdraws the AI assistant's third-party data-sharing consent — the exact
/// counterpart of `MarkAiConsentAccepted`, and a legal requirement, not a
/// convenience: RGPD art. 7.3 says withdrawing consent must be as easy as
/// giving it.
///
/// Withdrawing does three things at once, and the third is the business rule
/// this use case exists to hold: `AppSettings.aiNotesAccessEnabled` is turned
/// **off** together with the consent. The notes opt-in is a narrower
/// permission granted inside the broad one; leaving it on after the broad
/// consent is gone would keep a permission alive that the person is entitled
/// to believe they just cancelled.
///
/// It does **not** touch the conversation history (`AiMessages`,
/// `AiConversations` — both local-only tables): erasing a transcript is a
/// separate, irreversible decision the user makes through `ClearAllAiHistory`
/// in the assistant's own history screen. Withdrawing a permission stops
/// future sending; it is not a data-deletion request.
@injectable
class ClearAiConsent {
  const ClearAiConsent(this._repository);

  final AppSettingsRepository _repository;

  FutureResult<Unit> call() => _repository.clearAiConsent();
}
