import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/issuer_app.dart';
import '../../domain/usecases/get_issuer_apps.dart';
import '../../domain/usecases/is_notification_access_granted.dart';
import '../../domain/usecases/is_notification_capture_supported.dart';
import '../../domain/usecases/turn_off_all_issuer_listening.dart';
import 'capture_status_state.dart';

/// Feeds the permanent entry in Ajustes (HU-09): is the permission on, how
/// many issuers are being listened to, and the app's own switch to stop.
///
/// This is the surface that must never lie. It re-asks the system every time
/// it loads and every time the app returns to foreground, because the user
/// can revoke notification access from Android without the app hearing about
/// it — and an app that claims to be capturing when it is not is worse than
/// one that captures nothing.
@injectable
class CaptureStatusCubit extends Cubit<CaptureStatusState> {
  CaptureStatusCubit(
    this._isSupported,
    this._isGranted,
    this._getIssuerApps,
    this._turnOffAll,
  ) : super(const CaptureStatusState());

  final IsNotificationCaptureSupported _isSupported;
  final IsNotificationAccessGranted _isGranted;
  final GetIssuerApps _getIssuerApps;
  final TurnOffAllIssuerListening _turnOffAll;

  Future<void> start() => refresh();

  Future<void> refresh() async {
    if (!_isSupported()) {
      emit(const CaptureStatusState(isLoading: false));
      return;
    }

    final Result<bool> granted = await _isGranted();
    final bool isGranted = switch (granted) {
      Right(value: final bool value) => value,
      Left() => false,
    };
    if (!isGranted) {
      emit(
        state.copyWith(
          isSupported: true,
          isLoading: false,
          permissionGranted: false,
          enabledCount: 0,
        ),
      );
      return;
    }

    final Result<List<IssuerApp>> apps = await _getIssuerApps();
    final int enabled = switch (apps) {
      Right(value: final List<IssuerApp> value) =>
        value.where((IssuerApp issuer) => issuer.enabled).length,
      Left() => 0,
    };
    emit(
      state.copyWith(
        isSupported: true,
        isLoading: false,
        permissionGranted: true,
        enabledCount: enabled,
      ),
    );
  }

  /// The app's own kill switch (HU-09): stops capture without making the user
  /// go out to Android's settings to revoke anything. Pending captures are
  /// left alone — turning the feature off is not a request to throw away work
  /// the user has not reviewed yet.
  Future<void> stopListening() async {
    await _turnOffAll();
    await refresh();
  }
}
