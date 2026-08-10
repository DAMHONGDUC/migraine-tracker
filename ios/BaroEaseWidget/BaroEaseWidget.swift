import SwiftUI
import WidgetKit

/// Reads the App Group and hands WidgetKit at most two entries.
///
/// The second one exists because nothing republishes while the phone sits
/// untouched: the app writes an expiry alongside the pressure reading, and
/// this schedules a redraw at that instant with the reading blanked. Without
/// it a two-day-old number would sit on the home screen looking current.
struct BaroEaseProvider: TimelineProvider {
  func placeholder(in context: Context) -> BaroEaseEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (BaroEaseEntry) -> Void) {
    completion(.fromStore(date: Date(), withPressure: true))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<BaroEaseEntry>) -> Void) {
    let now = Date()
    var entries = [BaroEaseEntry.fromStore(date: now, withPressure: true)]

    if let expiry = BaroEaseWidgetStore.pressureExpiry(), expiry > now {
      entries.append(.fromStore(date: expiry, withPressure: false))
    }

    // `.never`: every other refresh is the app's, which reloads the timeline
    // on launch, on resume, and whenever the attack list moves.
    completion(Timeline(entries: entries, policy: .never))
  }
}

/// Two widgets, one kind, and only one is ever registered — `@WidgetBundleBuilder`
/// picks by availability, which is the one place an `if #available` can choose
/// between two `WidgetConfiguration` types at all. An extension on the
/// configuration cannot: `contentMarginsDisabled()` returns a different
/// concrete type, and `some WidgetConfiguration` admits only one.
@main
struct BaroEaseWidgetBundle: WidgetBundle {
  var body: some Widget {
    if #available(iOSApplicationExtension 17.0, *) {
      BaroEaseWidgetEdgeToEdge()
    } else {
      BaroEaseWidget()
    }
  }
}

struct BaroEaseWidget: Widget {
  /// Must match `HomeWidgetConstant.iOSWidgetName` — it is what the app names
  /// when it asks WidgetKit to reload. Both variants below share it, so the
  /// app's reload finds whichever one is registered.
  static let kind = "BaroEaseWidget"

  /// Shared so the iOS 17 variant differs by exactly one modifier.
  static var configuration: some WidgetConfiguration {
    StaticConfiguration(kind: Self.kind, provider: BaroEaseProvider()) { entry in
      BaroEaseWidgetView(entry: entry)
    }
    .configurationDisplayName("BaroEase")
    .description("Log an attack, and see this week's count and the latest pressure.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }

  var body: some WidgetConfiguration { Self.configuration }
}

/// The same widget with the system's content margins turned off.
///
/// iOS 17 gives every widget ~16pt of margin of its own, which stacked on top
/// of `widgetBackground`'s insets and took roughly a third of a small widget's
/// ~155pt width before anything was drawn. With this off, those insets are the
/// only horizontal padding there is — change one and check the other.
@available(iOSApplicationExtension 17.0, *)
struct BaroEaseWidgetEdgeToEdge: Widget {
  var body: some WidgetConfiguration {
    BaroEaseWidget.configuration.contentMarginsDisabled()
  }
}
