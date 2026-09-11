import 'package:equatable/equatable.dart';

import '../../domain/entities/issuer_app.dart';

/// State of the issuer catalog screen (HU-02).
class CaptureIssuersState extends Equatable {
  const CaptureIssuersState({
    this.isLoading = true,
    this.permissionGranted = true,
    this.issuers = const <IssuerApp>[],
    this.hasError = false,
  });

  final bool isLoading;

  /// The system's answer, re-asked on entry and on every return to foreground
  /// (HU-09). `false` takes over the screen with the calm off state: switches
  /// that cannot capture anything would be a lie.
  ///
  /// Starts `true` so the first frame does not flash the revoked state at a
  /// user who has the permission perfectly well.
  final bool permissionGranted;

  /// Catalogued issuers whose app is installed here. An empty list with the
  /// permission granted is a legitimate state (no candidate app installed),
  /// not an error.
  final List<IssuerApp> issuers;

  final bool hasError;

  int get enabledCount => issuers.where((IssuerApp i) => i.enabled).length;

  bool get hasEnabled => enabledCount > 0;

  /// No catalogued app is installed, so there is nothing to switch on. Said
  /// plainly, because it is a fact about the phone and not a failure.
  bool get hasNoInstalledApps =>
      !isLoading && !hasError && permissionGranted && issuers.isEmpty;

  CaptureIssuersState copyWith({
    bool? isLoading,
    bool? permissionGranted,
    List<IssuerApp>? issuers,
    bool? hasError,
  }) =>
      CaptureIssuersState(
        isLoading: isLoading ?? this.isLoading,
        permissionGranted: permissionGranted ?? this.permissionGranted,
        issuers: issuers ?? this.issuers,
        hasError: hasError ?? this.hasError,
      );

  @override
  List<Object?> get props =>
      <Object?>[isLoading, permissionGranted, issuers, hasError];
}
