import Flutter
import Foundation
import UIKit

/// Hands the tapped widget shortcut to Dart
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// Mirror of `QuickCaptureWidgetBridge.kt`. Written by hand rather than with
/// the `home_widget` package: the widget is a pure shortcut, so there is no
/// shared data store to write and the whole bridge is one string travelling
/// one way. There is no App Group here for the same reason.
///
/// **The entry point is the scene lifecycle, not the app delegate.** The app
/// adopts `UIApplicationSceneManifest` (`ios/Runner/Info.plist`), so iOS
/// delivers a widget tap to `scene(_:openURLContexts:)` /
/// `scene(_:willConnectToSession:options:)` and never to
/// `application(_:open:options:)`. This class registers itself as a
/// `FlutterSceneLifeCycleDelegate` (see `AppDelegate`), which runs before
/// Flutter's default deep-link handling: returning `true` here keeps the raw
/// `<bundle id>://captura/<shortcut>` URL away from the framework. Otherwise
/// Flutter pushes it to Dart as route information and go_router renders
/// `GoException: no routes for location: <url>` instead of the capture form.
///
/// Cold start and warm resume take different paths: on a cold start Dart is
/// not listening yet, so a URL arriving in `scene(_:willConnectToSession:)`
/// waits in `pending` until Dart asks for it with `getInitialShortcut`; once
/// the engine is up and Dart has asked, a tap is pushed with `onShortcut`.
final class QuickCaptureWidgetBridge: NSObject, FlutterSceneLifeCycleDelegate {
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
  /// URL reaches the scene delegate before Dart has registered its handler,
  /// so the shortcut has to wait instead of being pushed.
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

  // MARK: - FlutterSceneLifeCycleDelegate

  /// Cold start: the widget tap arrives inside the scene's connection
  /// options, before the first frame.
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let connectionOptions else {
      return false
    }
    return handle(urlContexts: connectionOptions.urlContexts)
  }

  /// Warm resume: the widget tap arrives while the app is already running or
  /// suspended in memory.
  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    handle(urlContexts: URLContexts)
  }

  /// The shortcut id encoded in `url`, or `nil` when it is not one of the
  /// known widget shortcuts. Pure, so the URL contract is unit-testable.
  static func shortcutId(from url: URL) -> String? {
    guard url.host == QuickCaptureWidgetBridge.urlHost else {
      return nil
    }
    let id = url.lastPathComponent
    return QuickCaptureWidgetBridge.knownShortcutIds.contains(id) ? id : nil
  }

  /// Handles a URL opened by the widget. Returns `false` when it is not ours,
  /// so the caller can let the plugins (Google Sign-In) have it.
  @discardableResult
  func handle(url: URL) -> Bool {
    guard url.host == QuickCaptureWidgetBridge.urlHost else {
      return false
    }
    guard let id = QuickCaptureWidgetBridge.shortcutId(from: url) else {
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

  /// True when at least one URL in `urlContexts` is ours. The scene API
  /// returns a single Bool for the whole batch, so a batch containing a
  /// widget URL is consumed whole; returning `true` is what stops Flutter
  /// from pushing our raw URL to Dart as route information — the reason this
  /// class is a scene delegate at all.
  private func handle(urlContexts: Set<UIOpenURLContext>) -> Bool {
    let ours = urlContexts.filter { $0.url.host == QuickCaptureWidgetBridge.urlHost }
    guard !ours.isEmpty else {
      return false
    }
    for context in ours {
      handle(url: context.url)
    }
    return true
  }
}
