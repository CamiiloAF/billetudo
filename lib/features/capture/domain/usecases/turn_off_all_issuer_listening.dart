import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../repositories/issuer_settings_repository.dart';
import '../repositories/notification_capture_repository.dart';

/// Stops listening to every issuer in one action (HU-02/HU-09) — the "Apagar
/// todas" of the catalog screen and the app's own kill switch.
///
/// Exists so the user can stop capture **without** going out to Android's
/// settings to revoke the system permission: needing to leave the app to turn
/// something off is what makes a permission feel like a trap.
///
/// Writes both stores for the same reason `SetIssuerListening` does. What it
/// deliberately does **not** touch is the inbox: captures already taken stay
/// there until the user dispatches them, and deleting them is a separate,
/// explicit decision (`DeleteAllCaptureData`).
@injectable
class TurnOffAllIssuerListening {
  const TurnOffAllIssuerListening(this._capture, this._issuers);

  final NotificationCaptureRepository _capture;
  final IssuerSettingsRepository _issuers;

  FutureResult<Unit> call() async {
    final Result<Unit> written =
        await _capture.setEnabledIssuers(const <String>{});
    if (written case Left(value: final Failure failure)) {
      return Left(failure);
    }
    await _issuers.disableAllIssuers();
    return const Right(unit);
  }
}
