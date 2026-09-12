import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/app_settings_repository.dart';

/// Turns the AI assistant's access to the records' free-text `note` on or off
/// (`AppSettings.aiNotesAccessEnabled`).
///
/// Opt-in only: `false` is the default and the state of anyone who has never
/// touched the switch, and with it not a single note travels in any payload.
/// Reading the current value goes through `GetAppSettings`, like every other
/// preference.
@injectable
class SetAiNotesAccessEnabled {
  const SetAiNotesAccessEnabled(this._repository);

  final AppSettingsRepository _repository;

  FutureResult<Unit> call({required bool enabled}) =>
      _repository.setAiNotesAccessEnabled(enabled: enabled);
}
