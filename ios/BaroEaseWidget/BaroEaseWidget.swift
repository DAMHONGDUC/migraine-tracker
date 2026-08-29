import SwiftUI
import WidgetKit

/// Reads the App Group and hands WidgetKit at most two entries.
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

    // `.never`: every other refresh is the app's, which reloads the timeline on launch, on resume, and whenever the attack list moves.
    completion(Timeline(entries: entries, policy: .never))
  }
}

@main
struct BaroEaseWidgetBundle: WidgetBundle {
  var body: some Widget { BaroEaseWidget() }
}

struct BaroEaseWidget: Widget {
  /// Must match `HomeWidgetConstant.iOSWidgetName` — it is what the app names when it asks WidgetKit to reload.
  static let kind = "BaroEaseWidget"

  /// The system's own content margins are left on, deliberately.
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: Self.kind, provider: BaroEaseProvider()) { entry in
      BaroEaseWidgetView(entry: entry)
    }
    .configurationDisplayName("BaroEase")
    .description("Log an attack, and see this week's count and the latest pressure.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
