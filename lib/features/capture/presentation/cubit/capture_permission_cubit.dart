import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/usecases/is_notification_access_granted.dart';
import '../../domain/usecases/open_notification_access_settings.dart';
import 'capture_permission_state.dart';

/// Drives the permission screen (HU-01/HU-09).
///
/// The whole point of this cubit is that **it never assumes**. The app can
/// only open `ACTION_NOTIFICATION_LISTENER_SETTINGS`; it cannot grant the
/// permission, pre-select it or observe it. So going to Ajustes tells us
/// nothing, and the state is re-derived from the system on entry and on every
/// return to foreground.
@injectable
class CapturePermissionCubit extends Cubit<CapturePermissionState> {
  CapturePermissionCubit(this._isGranted, this._openSettings)
      : super(const CapturePermissionState());

  final IsNotificationAccessGranted _isGranted;
  final OpenNotificationAccessSettings _openSettings;

  /// Whether the user has been sent out to Ajustes at least once in this
  /// visit. It is what separates "hasn't decided yet" (keep showing the
  /// explainer) from "went and did not grant it" (show the calm off state):
  /// showing the off state to someone who never left would read as a
  /// complaint about a decision they were never asked to make.
  bool _returningFromSettings = false;

  Future<void> start() => _refresh();

  /// Sends the user to the system screen, after the explainer and never
  /// before it.
  Future<void> openSettings() async {
    _returningFromSettings = true;
    await _openSettings();
  }

  /// Called when the app comes back to foreground. Re-asks the system, which
  /// also covers the revocation case of HU-09 for a user who was already on
  /// this screen.
  Future<void> recheck() => _refresh();

  /// `ZGtoE`'s "Ver cómo funciona": back to the explainer from the off state,
  /// without leaving the screen.
  void showExplainer() =>
      emit(state.copyWith(view: CapturePermissionView.explainer));

  Future<void> _refresh() async {
    emit(state.copyWith(isChecking: true));
    final Result<bool> result = await _isGranted();
    // A failure to ask the system is treated as "not granted": claiming a
    // coverage we could not verify is the one answer that would make the app
    // lie about whether it is listening.
    final bool granted = switch (result) {
      Right(value: final bool value) => value,
      Left() => false,
    };
    emit(
      state.copyWith(
        isChecking: false,
        granted: granted,
        view: granted || !_returningFromSettings
            ? state.view
            : CapturePermissionView.notGranted,
      ),
    );
  }
}
