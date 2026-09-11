import SwiftUI
import WidgetKit

/// Colours and typography of the widget, replicated natively.
///
/// `Assets.xcassets` holds one color set per design-system token, each with
/// an Any/Dark variant — a deliberate duplication (HU-10): the extension runs
/// in its own process and cannot read Flutter's theme.
///
/// | Color set           | Token          | Light     | Dark      |
/// |---------------------|----------------|-----------|-----------|
/// | `WidgetSurface`     | `$surface`     | `#FFFFFF` | `#1E1E2E` |
/// | `WidgetPrimary`     | `$primary`     | `#6C5CE7` | `#6D4FE0` |
/// | `WidgetOnPrimary`   | `$on-primary`  | `#FFFFFF` | `#FFFFFF` |
/// | `WidgetTextPrimary` | `$text-primary`| `#1C1B29` | `#F4F3FA` |
///
/// A token that changes in `billetudo.pen` has to change here and in
/// `android/app/src/main/res/values{,-night}/colors.xml`. The widget follows
/// the *system* theme, not Ajustes → Apariencia (decision 7): reading that
/// preference would need the cross-process mirror the pure-shortcut scope
/// removed.

/// Typography of the widget.
///
/// Plus Jakarta Sans is bundled with the extension (`UIAppFonts` in its
/// `Info.plist`) because a widget process cannot read Flutter's asset
/// bundle. If the family ever fails to register, the fallback is the system
/// font — a visible change of brand, deliberately made explicit here instead
/// of failing silently.
enum QuickCaptureTypography {
  static let label: Font = .custom("PlusJakartaSans-SemiBold", size: 13, relativeTo: .caption)
}

extension View {
  /// Opaque widget background (HU-10: the widget does not control the
  /// wallpaper behind it, so text never sits on a translucent surface).
  ///
  /// iOS 17 requires `containerBackground`; before that the colour is drawn
  /// behind the content instead.
  @ViewBuilder
  func widgetBackgroundCompat(_ color: Color) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      ZStack {
        color
        self
      }
    }
  }
}
