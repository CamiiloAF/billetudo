import Flutter
import UIKit
import XCTest

@testable import Runner

/// Regression tests for the widget URL contract
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// The scenario this guards is the one that shipped broken: the app adopts the
/// UIScene lifecycle, so a widget tap reaches `QuickCaptureWidgetBridge` as a
/// scene URL rather than through `application(_:open:options:)`. These tests
/// pin the parsing/ownership rules the scene delegate relies on. The scene
/// plumbing itself (`addSceneDelegate` registration) can only be exercised by
/// tapping a real widget on a device/simulator — see
/// `docs/dev-runs/widget-ios-deeplink-fix.md`.
class RunnerTests: XCTestCase {

  private func widgetURL(_ shortcut: String) -> URL {
    URL(string: "com.camiloagudelo.billetudo.dev://captura/\(shortcut)")!
  }

  func testShortcutIdParsesEveryKnownWidgetShortcut() {
    XCTAssertEqual(QuickCaptureWidgetBridge.shortcutId(from: widgetURL("expense")), "expense")
    XCTAssertEqual(QuickCaptureWidgetBridge.shortcutId(from: widgetURL("income")), "income")
    XCTAssertEqual(QuickCaptureWidgetBridge.shortcutId(from: widgetURL("voice")), "voice")
  }

  func testShortcutIdRejectsForeignHostAndForeignScheme() {
    let otherHost = URL(string: "com.camiloagudelo.billetudo.dev://otro/income")!
    XCTAssertNil(QuickCaptureWidgetBridge.shortcutId(from: otherHost))

    // Google Sign-In's callback: the plugins must keep receiving it, so the
    // bridge has to report that the URL is not ours instead of consuming it.
    let googleCallback = URL(string: "com.googleusercontent.apps.123:/oauth2redirect")!
    XCTAssertNil(QuickCaptureWidgetBridge.shortcutId(from: googleCallback))
  }

  func testShortcutIdIsNilForUnknownIdsButTheURLStillBelongsToTheWidget() {
    // `bank_inbox` is Android-only, but an id a newer widget knows and this
    // build does not must just open the app: never an error screen (HU-01).
    let futureShortcut = widgetURL("bank_inbox")
    XCTAssertNil(QuickCaptureWidgetBridge.shortcutId(from: futureShortcut))

    let bridge = QuickCaptureWidgetBridge()
    XCTAssertTrue(bridge.handle(url: futureShortcut))
    XCTAssertTrue(bridge.handle(url: widgetURL("expense")))
    XCTAssertTrue(bridge.handle(url: widgetURL("income")))
  }

  func testHandlePassesForeignURLsThrough() {
    let bridge = QuickCaptureWidgetBridge()
    XCTAssertFalse(bridge.handle(url: URL(string: "com.googleusercontent.apps.123:/oauth2redirect")!))
  }
}
