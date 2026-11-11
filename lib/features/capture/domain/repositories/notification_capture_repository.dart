import '../../../../core/error/result.dart';
import '../entities/capture_diagnostics.dart';
import '../entities/issuer_app.dart';
import '../entities/parsed_notification.dart';

/// Contract with the Android notification listener service. Implemented in
/// `data/` over the `com.billetudo.app/capture` method channel.
///
/// **Android only.** On any other platform every call resolves to the "off"
/// answer (no permission, no issuers, no captures) so callers never have to
/// branch on the platform to stay correct — but iOS must not surface this
/// feature at all, not even disabled (see "Alcance por plataforma").
abstract class NotificationCaptureRepository {
  /// Whether this platform can listen to notifications at all (Android and
  /// only Android).
  ///
  /// Distinct from [isPermissionGranted] on purpose: both answer `false` on
  /// iOS, but they mean opposite things to the UI. "Not granted" invites the
  /// user to grant it; "not supported" must hide the feature entirely — iOS
  /// must not surface it even disabled behind a padlock, because that would
  /// be advertising something the platform makes impossible.
  bool get isSupported;

  /// Whether the system-level notification access is currently granted.
  /// Must be asked to the system on every app start and on every return to
  /// foreground: the user can revoke it from Settings without telling the app
  /// (HU-09). Never cache it in a flag.
  FutureResult<bool> isPermissionGranted();

  /// Opens `ACTION_NOTIFICATION_LISTENER_SETTINGS`. The app can only open that
  /// screen, never control it, so the result says nothing about whether the
  /// permission ended up granted — re-check with [isPermissionGranted] when
  /// coming back.
  FutureResult<Unit> openPermissionSettings();

  /// Issuer ids the user switched on. Empty by default.
  FutureResult<Set<String>> getEnabledIssuers();

  /// Replaces the enabled set. The native service reads it on every
  /// notification, so turning an issuer off stops captures immediately.
  FutureResult<Unit> setEnabledIssuers(Set<String> issuerIds);

  /// Returns the captures the native service buffered while no Flutter engine
  /// was alive AND empties the buffer, atomically. The caller is expected to
  /// persist them into `PendingCaptures` right away; anything it drops is
  /// lost, which is the accepted trade-off of never keeping the text.
  FutureResult<List<ParsedNotification>> drainPendingCaptures();

  /// The catalog crossed with the apps actually installed on the device
  /// (HU-02), each carrying its current on/off state.
  FutureResult<List<IssuerApp>> getInstalledIssuerApps();

  /// The phone-side facts behind background capture (HU-09): when the listener
  /// last produced a capture, whether Android already exempts the app from
  /// battery optimization, the manufacturer, and whether that manufacturer has
  /// an autostart screen worth opening.
  ///
  /// **Off Android this is a no-op** and answers
  /// [CaptureDiagnostics.empty] — never a failure. The feature does not exist
  /// there, and a diagnostics probe must not be the thing that crashes a build
  /// without the native side.
  FutureResult<CaptureDiagnostics> getDiagnostics();

  /// Opens `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` for this app, falling
  /// back to `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`.
  ///
  /// **Off Android this is a no-op** that resolves to `Right(unit)`. The app
  /// can only open the screen: the result says nothing about whether the
  /// exemption was granted, so re-read [getDiagnostics] when the user returns.
  FutureResult<Unit> requestIgnoreBatteryOptimizations();

  /// Opens the manufacturer's autostart screen, falling back to the app's
  /// details page. A channel failure (no screen could be opened) becomes a
  /// `Left` so the caller can keep the sheet open instead of pretending.
  ///
  /// **Off Android this is a no-op** that resolves to `Right(unit)`.
  FutureResult<Unit> openAutostartSettings();
}
