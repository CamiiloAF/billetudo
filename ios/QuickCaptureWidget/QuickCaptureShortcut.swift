import Foundation
import SwiftUI

/// The shortcuts the iOS home-screen widget can offer
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// `bankInbox` is absent on purpose: reading bank notifications is
/// Android-only, so iOS does not show that shortcut at all rather than
/// showing it disabled behind a padlock — that would promise something the
/// platform cannot deliver.
///
/// Every `id` must match the Dart enum in
/// `lib/features/capture/domain/entities/capture_shortcut.dart`.
enum QuickCaptureShortcut: String, CaseIterable {
  case expense
  case income
  case voice

  var id: String { rawValue }

  /// Key of the localized label in `Localizable.strings`.
  var labelKey: String {
    switch self {
    case .expense: return "widget_shortcut_expense"
    case .income: return "widget_shortcut_income"
    case .voice: return "widget_shortcut_voice"
    }
  }

  /// Key of the localized accessibility label. Generic on purpose: a widget
  /// label never reveals anything about the user's money (HU-08).
  var accessibilityKey: String {
    switch self {
    case .expense: return "widget_shortcut_expense_a11y"
    case .income: return "widget_shortcut_income_a11y"
    case .voice: return "widget_shortcut_voice_a11y"
    }
  }

  /// SF Symbol. The app's own iconography lives in Flutter assets the widget
  /// process cannot read, so the shape comes from the system while the
  /// colour comes from the design system.
  var symbolName: String {
    switch self {
    case .expense: return "arrow.up"
    case .income: return "arrow.down"
    case .voice: return "mic.fill"
    }
  }

  /// Deep link that opens the app on this shortcut's capture screen.
  ///
  /// The scheme is the host app's bundle id, derived from the extension's own
  /// (`<app id>.QuickCaptureWidget`), so the `dev` and `prod` builds never
  /// fight over the same URL scheme when both are installed. Tapping only
  /// navigates: the widget never writes a transaction, and whatever the user
  /// saves afterwards is `source = manual`.
  var url: URL? {
    guard let scheme = QuickCaptureShortcut.hostAppScheme else {
      return nil
    }
    return URL(string: "\(scheme)://captura/\(id)")
  }

  private static var hostAppScheme: String? {
    guard let extensionId = Bundle.main.bundleIdentifier else {
      return nil
    }
    var components = extensionId.split(separator: ".")
    guard components.count > 1 else {
      return extensionId
    }
    components.removeLast()
    return components.joined(separator: ".")
  }
}
