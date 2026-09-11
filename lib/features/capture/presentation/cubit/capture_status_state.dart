import 'package:equatable/equatable.dart';

/// The live state of the capture feature as summarised in Ajustes (HU-09).
class CaptureStatusState extends Equatable {
  const CaptureStatusState({
    this.isSupported = false,
    this.isLoading = true,
    this.permissionGranted = false,
    this.enabledCount = 0,
  });

  /// Android. `false` hides the row entirely — iOS must not show this
  /// feature, not even disabled.
  final bool isSupported;

  final bool isLoading;

  /// Asked to the system on every build of this row and on every return to
  /// foreground, never read from a stored flag (HU-09).
  final bool permissionGranted;

  final int enabledCount;

  /// Capture is only really on when both halves are: a granted permission
  /// with zero issuers switched on captures nothing, and the row must not
  /// imply otherwise.
  bool get isListening => permissionGranted && enabledCount > 0;

  CaptureStatusState copyWith({
    bool? isSupported,
    bool? isLoading,
    bool? permissionGranted,
    int? enabledCount,
  }) =>
      CaptureStatusState(
        isSupported: isSupported ?? this.isSupported,
        isLoading: isLoading ?? this.isLoading,
        permissionGranted: permissionGranted ?? this.permissionGranted,
        enabledCount: enabledCount ?? this.enabledCount,
      );

  @override
  List<Object?> get props =>
      <Object?>[isSupported, isLoading, permissionGranted, enabledCount];
}
