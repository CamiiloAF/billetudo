import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/issuer_app.dart';
import '../repositories/issuer_settings_repository.dart';
import '../repositories/notification_capture_repository.dart';

/// Turns listening to one issuer app on or off (HU-02) — the single business
/// action behind the switch of the catalog screen.
///
/// **It writes to both stores on purpose.** The two exist and are keyed
/// differently, and neither one alone leaves the app correct:
///
///  - the **native** set ([NotificationCaptureRepository], keyed by
///    `issuerId`) is the gate: `IssuerFilter` reads it on every notification,
///    with no Flutter engine alive, so this is the only write that actually
///    starts or stops capture;
///  - the **local** catalog ([IssuerSettingsRepository], keyed by
///    `packageName`) is what the inbox watches to decide whether to show
///    "todavía no escuchamos ninguna app".
///
/// Writing only the first would leave the inbox telling a user with issuers
/// on that they have none; writing only the second would leave a switch that
/// looks on and captures nothing. The native write goes first and its result
/// is the one returned: if the gate did not move, nothing moved. The mirror's
/// own failure is already recorded by its repository, and reverting the
/// switch over it would misreport what the service is really doing.
@injectable
class SetIssuerListening {
  const SetIssuerListening(this._capture, this._issuers);

  final NotificationCaptureRepository _capture;
  final IssuerSettingsRepository _issuers;

  FutureResult<Unit> call({
    required IssuerApp issuer,
    required bool enabled,
  }) async {
    final Result<Set<String>> current = await _capture.getEnabledIssuers();
    if (current case Left(value: final Failure failure)) {
      return Left(failure);
    }
    final Set<String> next = <String>{
      ...(current as Right<Failure, Set<String>>).value,
    };
    if (enabled) {
      next.add(issuer.issuerId);
    } else {
      next.remove(issuer.issuerId);
    }

    final Result<Unit> written = await _capture.setEnabledIssuers(next);
    if (written case Left(value: final Failure failure)) {
      return Left(failure);
    }

    await _issuers.setIssuerEnabled(
      packageName: issuer.packageName,
      enabled: enabled,
    );
    return const Right(unit);
  }
}
