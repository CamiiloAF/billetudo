import SwiftUI
import WidgetKit

/// Home-screen widget: shortcuts into the capture screens
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// A pure shortcut — no balances, no totals, no counters. That is why its
/// timeline has a single entry with `.never`: there is no data that could go
/// stale, so the system never needs to refresh it (HU-05), and there is no
/// App Group nor mirrored store behind it (decision 3).
struct QuickCaptureEntry: TimelineEntry {
  let date: Date
}

struct QuickCaptureProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuickCaptureEntry {
    QuickCaptureEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (QuickCaptureEntry) -> Void) {
    completion(QuickCaptureEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuickCaptureEntry>) -> Void) {
    completion(Timeline(entries: [QuickCaptureEntry(date: Date())], policy: .never))
  }
}

/// One shortcut: the brand-coloured circle plus its label.
struct QuickCaptureShortcutView: View {
  let shortcut: QuickCaptureShortcut

  var body: some View {
    VStack(spacing: 6) {
      ZStack {
        Circle().fill(Color("WidgetPrimary"))
        Image(systemName: shortcut.symbolName)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(Color("WidgetOnPrimary"))
      }
      .frame(width: 44, height: 44)

      Text(LocalizedStringKey(shortcut.labelKey))
        .font(QuickCaptureTypography.label)
        .foregroundColor(Color("WidgetTextPrimary"))
        // Pencil does not render ellipsis and SwiftUI wraps by default:
        // a long localization must truncate instead of pushing the row's
        // layout around.
        .lineLimit(1)
        .truncationMode(.tail)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(LocalizedStringKey(shortcut.accessibilityKey)))
  }
}

struct QuickCaptureWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: QuickCaptureEntry

  var body: some View {
    content.widgetBackgroundCompat(Color("WidgetSurface"))
  }

  @ViewBuilder
  private var content: some View {
    switch family {
    case .systemSmall:
      // `systemSmall` takes a single tap for its whole surface, so it is one
      // shortcut by construction — not a squeezed row (HU-06).
      QuickCaptureShortcutView(shortcut: .expense)
        .widgetURL(QuickCaptureShortcut.expense.url)
    default:
      HStack(spacing: 0) {
        ForEach(QuickCaptureShortcut.allCases, id: \.id) { shortcut in
          if let url = shortcut.url {
            Link(destination: url) {
              QuickCaptureShortcutView(shortcut: shortcut)
                .frame(maxWidth: .infinity)
            }
          } else {
            QuickCaptureShortcutView(shortcut: shortcut)
              .frame(maxWidth: .infinity)
          }
        }
      }
      .padding(.horizontal, 8)
    }
  }
}

struct QuickCaptureWidget: Widget {
  private let kind = "QuickCaptureWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QuickCaptureProvider()) { entry in
      QuickCaptureWidgetView(entry: entry)
    }
    .configurationDisplayName(Text(LocalizedStringKey("widget_quick_capture_name")))
    .description(Text(LocalizedStringKey("widget_quick_capture_description")))
    // `systemLarge` is out of scope: with no data to show there is nothing
    // that would justify the surface.
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
