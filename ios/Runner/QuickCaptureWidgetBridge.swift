import Flutter
import Foundation

/// Hands the tapped widget shortcut to Dart
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// Mirror of `QuickCaptureWidgetBridge.kt`. Written by hand rather than with
/// the `home_widget` package: the widget is a pure shortcut, so there is no
/// shared data store to write and the whole bridge is one string travelling
/// one way. There is no App Group here for the same reason.
///
/// Cold start and warm resume take different paths: on a cold start Dart is
/// not listening yet, so the shortcut waits in `pending` until Dart asks for
/// it with `getInitialShortcut`; once the engine is up it is pushed with
/// `onShortcut`.
final class QuickCaptureWidgetBridge {
  static let channelName = "com.billetudo.app/capture_shortcuts"

  /// Host of the URLs the widget opens: `<bundle id>://captura/<shortcut>`.
  static let urlHost = "captura"

  private static let methodGetInitial = "getInitialShortcut"
  private static let methodOnShortcut = "onShortcut"

  /// Shortcut ids this build understands. Must match the Dart enum in
  /// `lib/features/capture/domain/entities/capture_shortcut.dart` and
  /// `QuickCaptureShortcut.swift` in the extension. `bank_inbox` is missing
  /// on purpose: reading bank notifications is Android-only, so iOS never
  /// offers that shortcut.
  private static let knownShortcutIds: Set<String> = ["expense", "income", "voice"]

  private var channel: FlutterMethodChannel?
  private var pendingShortcutId: String?
  /// Whether Dart has already asked for the launching shortcut. Until it
  /// does, `onShortcut` would be shouting into a void: on a cold start the
  /// URL reaches `application(_:open:)` before Dart has registered its
  /// handler, so the shortcut has to wait instead of being pushed.
  private var didRequestInitial = false

  /// Wires the Dart→native side of the channel.
  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: QuickCaptureWidgetBridge.channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == QuickCaptureWidgetBridge.methodGetInitial else {
        result(FlutterMethodNotImplemented)
        return
      }
      // Reading also clears it: a resume must not replay a tap the user
      // already got their form for.
      let shortcutId = self?.pendingShortcutId
      self?.pendingShortcutId = nil
      self?.didRequestInitial = true
      result(shortcutId)
    }
    self.channel = channel
  }

  /// Handles a URL opened by the widget. Returns `false` when it is not ours,
  /// so the caller can let the plugins (Google Sign-In) have it.
  func handle(url: URL) -> Bool {
    guard url.host == QuickCaptureWidgetBridge.urlHost else {
      return false
    }
    let id = url.lastPathComponent
    guard QuickCaptureWidgetBridge.knownShortcutIds.contains(id) else {
      // An unknown id (newer widget, older app) opens the app and nothing
      // else — never an error screen.
      return true
    }
    if let channel = channel, didRequestInitial {
      channel.invokeMethod(QuickCaptureWidgetBridge.methodOnShortcut, arguments: id)
    } else {
      pendingShortcutId = id
    }
    return true
  }
}
