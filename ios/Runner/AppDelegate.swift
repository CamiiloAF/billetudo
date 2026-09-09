import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let captureShortcutBridge = QuickCaptureWidgetBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    captureShortcutBridge.attach(messenger: engineBridge.applicationRegistrar.messenger())
  }

  /// A tap on the home-screen widget arrives as a URL open
  /// (`docs/requirements/fase-2/20-widget-captura-rapida.md`). Anything that
  /// is not ours — Google Sign-In's callback — goes on to the plugins.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if captureShortcutBridge.handle(url: url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
