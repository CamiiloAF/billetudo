import SwiftUI
import WidgetKit

/// Home-screen widget: shortcuts into the capture screens
/// (`docs/requirements/fase-2/20-widget-captura-rapida.md`).
///
/// A pure shortcut — no balances, no totals, no counters. That is why its
/// timeline has a single entry with `.never`: there is no data that could go
/// stale, so the system never needs to refresh it (HU-05), and there is no
/// App Group nor mirrored store behind it (decision 3). The only thing that
/// ever changes its content is the user editing the widget's own
/// configuration (HU-03), which reloads the timeline on its own.
struct QuickCaptureEntry: TimelineEntry {
  let date: Date
  let shortcuts: [QuickCaptureShortcut]
}

/// `IntentTimelineProvider`, not the plain `TimelineProvider`: the shortcuts
/// shown come from `SelectQuickCaptureShortcutsIntent`
/// (`QuickCaptureWidget.intentdefinition`), the classic (pre-iOS 17)
/// WidgetKit configuration mechanism — chosen because the app's deployment
/// target is iOS 15, below what `AppIntentConfiguration` requires.
struct QuickCaptureProvider: IntentTimelineProvider {
  func placeholder(in context: Context) -> QuickCaptureEntry {
    QuickCaptureEntry(date: Date(), shortcuts: QuickCaptureShortcut.defaultShortcuts)
  }

  func getSnapshot(
    for configuration: SelectQuickCaptureShortcutsIntent,
    in context: Context,
    completion: @escaping (QuickCaptureEntry) -> Void
  ) {
    completion(entry(for: configuration))
  }

  func getTimeline(
    for configuration: SelectQuickCaptureShortcutsIntent,
    in context: Context,
    completion: @escaping (Timeline<QuickCaptureEntry>) -> Void
  ) {
    completion(Timeline(entries: [entry(for: configuration)], policy: .never))
  }

  private func entry(for configuration: SelectQuickCaptureShortcutsIntent) -> QuickCaptureEntry {
    QuickCaptureEntry(date: Date(), shortcuts: QuickCaptureShortcut.shortcuts(for: configuration.preset))
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
      // shortcut by construction (HU-06) — the first of whatever the user
      // configured (HU-03), never a squeezed row.
      let shortcut = entry.shortcuts.first ?? .expense
      QuickCaptureShortcutView(shortcut: shortcut)
        .widgetURL(shortcut.url)
    default:
      HStack(spacing: 0) {
        ForEach(entry.shortcuts, id: \.id) { shortcut in
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
    // Classic `IntentConfiguration`, not `AppIntentConfiguration`: the app's
    // deployment target is iOS 15, and `AppIntentConfiguration` needs iOS 17
    // (HU-03). The user edits the shortcut set from the widget's own "Edit
    // Widget" screen, which iOS builds from `SelectQuickCaptureShortcutsIntent`.
    IntentConfiguration(
      kind: kind,
      intent: SelectQuickCaptureShortcutsIntent.self,
      provider: QuickCaptureProvider()
    ) { entry in
      QuickCaptureWidgetView(entry: entry)
    }
    .configurationDisplayName(Text(LocalizedStringKey("widget_quick_capture_name")))
    .description(Text(LocalizedStringKey("widget_quick_capture_description")))
    // `systemLarge` is out of scope: with no data to show there is nothing
    // that would justify the surface.
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
