import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let captureShortcutBridge = QuickCaptureWidgetBridge()

  /// Not a real plugin: the key only vends a `FlutterPluginRegistrar`, which
  /// is the object that exposes `addSceneDelegate` (see
  /// `didInitializeImplicitFlutterEngine`).
  private static let captureShortcutPluginKey = "billetudo.capture_shortcuts"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications: sin este delegate iOS no entrega una
    // notificación local mientras la app está en primer plano. No pide
    // permisos por sí solo — eso ocurre en contexto, al configurar el primer
    // recordatorio (HU-08).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    captureShortcutBridge.attach(messenger: engineBridge.applicationRegistrar.messenger())

    // A widget tap is a URL open (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
    // `Info.plist` adopts the UIScene lifecycle, so iOS delivers that URL to
    // `scene(_:openURLContexts:)` / `scene(_:willConnectToSession:options:)`
    // and never to the app delegate's `application(_:open:options:)`: the
    // scene delegate below is what actually receives the tap on iOS.
    //
    // Registered before the plugin registrant on purpose. The engine calls
    // scene delegates in registration order and stops when one returns
    // `true`, so going first means a widget URL is consumed here instead of
    // leaking to Flutter's default deep-link handling (which pushes the raw
    // URL to Dart as route information and makes go_router render
    // `GoException: no routes for location: <url>`) or to `app_links`, whose
    // stream feeds Supabase's OAuth callback handling.
    engineBridge.pluginRegistry
      .registrar(forPlugin: AppDelegate.captureShortcutPluginKey)?
      .addSceneDelegate(captureShortcutBridge)

    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
