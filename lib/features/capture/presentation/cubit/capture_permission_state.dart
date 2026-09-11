import 'package:equatable/equatable.dart';

/// Which of the two faces of the permission screen is showing.
enum CapturePermissionView {
  /// `FRtfP` — the explainer: what is read, what is stored, what syncs, and
  /// what Android is about to warn about. Always the first thing the user
  /// sees; the app never sends anyone to the system screen cold.
  explainer,

  /// `ZGtoE` — came back from Ajustes without granting it, or revoked it from
  /// the system. Stated once, with no alarm iconography and no second ask.
  notGranted,
}

/// State of the permission screen (HU-01/HU-09).
class CapturePermissionState extends Equatable {
  const CapturePermissionState({
    this.view = CapturePermissionView.explainer,
    this.isChecking = false,
    this.granted = false,
  });

  final CapturePermissionView view;

  /// A re-check is in flight. Only ever true briefly, on return from Ajustes.
  final bool isChecking;

  /// The **system's** answer, from the last check. Never a stored flag: the
  /// user can revoke this from Android without telling the app (HU-09).
  final bool granted;

  CapturePermissionState copyWith({
    CapturePermissionView? view,
    bool? isChecking,
    bool? granted,
  }) =>
      CapturePermissionState(
        view: view ?? this.view,
        isChecking: isChecking ?? this.isChecking,
        granted: granted ?? this.granted,
      );

  @override
  List<Object?> get props => <Object?>[view, isChecking, granted];
}
