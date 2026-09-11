import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/issuer_app.dart';
import '../../domain/usecases/get_issuer_apps.dart';
import '../../domain/usecases/is_notification_access_granted.dart';
import '../../domain/usecases/set_issuer_listening.dart';
import '../../domain/usecases/turn_off_all_issuer_listening.dart';
import 'capture_issuers_state.dart';

/// Drives the issuer catalog (HU-02): which installed bank apps are listened
/// to, and the app's own way to stop listening to all of them at once.
///
/// The list always comes back from the native side rather than from a local
/// copy, because that side is the one the filter reads: what this screen
/// shows and what the service actually does can never be allowed to drift.
@injectable
class CaptureIssuersCubit extends Cubit<CaptureIssuersState> {
  CaptureIssuersCubit(
    this._getIssuerApps,
    this._isGranted,
    this._setIssuerListening,
    this._turnOffAll,
  ) : super(const CaptureIssuersState());

  final GetIssuerApps _getIssuerApps;
  final IsNotificationAccessGranted _isGranted;
  final SetIssuerListening _setIssuerListening;
  final TurnOffAllIssuerListening _turnOffAll;

  Future<void> start() => _load();

  /// Re-runs on every return to foreground: the user may have revoked the
  /// permission, or installed a bank app, while the app sat in the background
  /// (HU-09).
  Future<void> refresh() => _load();

  Future<void> setEnabled({
    required IssuerApp issuer,
    required bool enabled,
  }) async {
    await _setIssuerListening(issuer: issuer, enabled: enabled);
    // Re-read instead of patching the list optimistically: a write the native
    // side rejected must leave the switch showing what is really stored, not
    // what the tap implied.
    await _load(silent: true);
  }

  Future<void> turnOffAll() async {
    await _turnOffAll();
    await _load(silent: true);
  }

  /// [silent] keeps the spinner away on the re-read that follows a toggle:
  /// flashing a loader under the user's finger reads as a failure.
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isLoading: true, hasError: false));
    }

    final Result<bool> granted = await _isGranted();
    final bool isGranted = switch (granted) {
      Right(value: final bool value) => value,
      Left() => false,
    };
    if (!isGranted) {
      emit(
        state.copyWith(
          isLoading: false,
          hasError: false,
          permissionGranted: false,
        ),
      );
      return;
    }

    final Result<List<IssuerApp>> apps = await _getIssuerApps();
    switch (apps) {
      case Right(value: final List<IssuerApp> value):
        emit(
          state.copyWith(
            isLoading: false,
            hasError: false,
            permissionGranted: true,
            issuers: value,
          ),
        );
      case Left():
        emit(
          state.copyWith(
            isLoading: false,
            hasError: true,
            permissionGranted: true,
          ),
        );
    }
  }
}
