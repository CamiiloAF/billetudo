import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/capture_diagnostics.dart';

/// State of the "background capture may have stopped" surfaces of Avisos
/// (HU-09): the degraded card, the contextual empty state and the sheet.
///
/// The three surfaces read the **same** snapshot on purpose. The card states
/// the problem, the empty state replaces "Todo al día" and the sheet lists the
/// two system settings; if each one re-derived the rule from its own reads,
/// the card could say "degraded" while the sheet already shows the battery
/// exemption as granted.
///
/// [showsAttention] is the only flag the page branches on. It is the product
/// answer ("draw the degraded surface today"), while [diagnostics] carries the
/// device facts the sheet renders. [failure] never hides the card silently:
/// the surfaces fail closed, so a failed probe leaves [showsAttention] `false`
/// and the failure is reported for diagnostics instead of pretending a problem
/// that was not verified.
class CaptureBackgroundState extends Equatable {
  const CaptureBackgroundState({
    this.isSupported = false,
    this.isLoading = true,
    this.showsAttention = false,
    this.degraded = false,
    this.snoozedUntil,
    this.diagnostics,
    this.permissionGranted = false,
    this.enabledCount = 0,
    this.failure,
  });

  /// Whether this platform can listen to notifications at all. iOS must not
  /// surface any of these rules, so `false` keeps everything hidden.
  final bool isSupported;

  /// Only the first load spins. A refresh after returning from Android
  /// Settings is silent: flashing a loader over the card reads as a failure.
  final bool isLoading;

  /// Whether the degraded card (with captures) or the degraded empty state
  /// (without them) should be drawn right now.
  final bool showsAttention;

  /// Whether capture may have stopped, **including** while silenced. It is
  /// the product truth; [showsAttention] is the "draw it today" flag.
  final bool degraded;

  /// Until when "Ahora no" hides the degraded surfaces. `null` when the alert
  /// was never silenced on this device.
  final DateTime? snoozedUntil;

  /// The device facts behind the decision, or `null` when they were not read
  /// (unsupported platform, revoked permission, no enabled issuer, failed
  /// probe). The sheet needs them to render its rows.
  final CaptureDiagnostics? diagnostics;

  /// The system's answer, re-read on every start and return to foreground.
  final bool permissionGranted;

  /// How many issuers are switched on **on this device**, read from the native
  /// side rather than from the Drift mirror, so the count matches what the
  /// service actually filters.
  final int enabledCount;

  /// The last probe failure, if any. The page does not render it: it only
  /// keeps the surfaces honest by not showing attention on unverified data.
  final Failure? failure;

  /// Whether the battery-optimization exemption is already granted. `false`
  /// also covers "not read", which is why the sheet only renders after the
  /// health snapshot exists.
  bool get batteryOptimizationExempt =>
      diagnostics?.batteryOptimizationExempt ?? false;

  /// Whether this manufacturer exposes an autostart screen worth opening.
  /// When `false` the sheet hides the row instead of inventing a destination.
  bool get autostartAvailable => diagnostics?.autostartAvailable ?? false;

  /// The manufacturer name used in the autostart row copy ("En Xiaomi, …").
  String get manufacturer => diagnostics?.manufacturer ?? '';

  /// When the listener last produced a capture, or `null` when nothing has
  /// ever arrived on this device. Drives the footer copy.
  DateTime? get lastCaptureAt => diagnostics?.lastCaptureAt;

  /// Whether the capture is degraded **and** currently silenced by "Ahora
  /// no". [degraded] stays true through the silence; only [showsAttention]
  /// turns off, which is what lets the Ajustes row say "Silenciada por 14
  /// días" without pretending the capture works.
  bool get isSnoozed => degraded && !showsAttention;

  /// Whether the preconditions of the rule are still missing: no system
  /// permission or no bank app switched on. The permanent Ajustes row uses it
  /// to route the tap to permission / issuers instead of opening the sheet,
  /// which would explain settings the user cannot use yet.
  bool get needsSetup => !permissionGranted || enabledCount == 0;

  CaptureBackgroundState copyWith({
    bool? isSupported,
    bool? isLoading,
    bool? showsAttention,
    bool? degraded,
    DateTime? snoozedUntil,
    CaptureDiagnostics? diagnostics,
    bool? permissionGranted,
    int? enabledCount,
    Failure? failure,
    bool clearSnoozedUntil = false,
    bool clearDiagnostics = false,
    bool clearFailure = false,
  }) =>
      CaptureBackgroundState(
        isSupported: isSupported ?? this.isSupported,
        isLoading: isLoading ?? this.isLoading,
        showsAttention: showsAttention ?? this.showsAttention,
        degraded: degraded ?? this.degraded,
        snoozedUntil:
            clearSnoozedUntil ? null : (snoozedUntil ?? this.snoozedUntil),
        diagnostics:
            clearDiagnostics ? null : (diagnostics ?? this.diagnostics),
        permissionGranted: permissionGranted ?? this.permissionGranted,
        enabledCount: enabledCount ?? this.enabledCount,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => <Object?>[
        isSupported,
        isLoading,
        showsAttention,
        degraded,
        snoozedUntil,
        diagnostics,
        permissionGranted,
        enabledCount,
        failure,
      ];
}
