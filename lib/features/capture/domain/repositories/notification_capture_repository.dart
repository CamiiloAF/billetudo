import '../../../../core/error/result.dart';
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
}
