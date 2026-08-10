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

@main
struct BaroEaseWidgetBundle: WidgetBundle {
  var body: some Widget { BaroEaseWidget() }
}

struct BaroEaseWidget: Widget {
  /// Must match `HomeWidgetConstant.iOSWidgetName` — it is what the app names
  /// when it asks WidgetKit to reload.
  static let kind = "BaroEaseWidget"

  /// **The system's own content margins are left on, deliberately.**
  /// `contentMarginsDisabled()` is iOS 17+, and there is no way to apply it
  /// conditionally: it returns a different concrete type, `some
  /// WidgetConfiguration` admits only one, and `@WidgetBundleBuilder` rejects
  /// the `if #available` that would pick between two widgets. Turning it on
  /// unconditionally means raising this extension's deployment target to 17
  /// and dropping the widget for iOS 15/16 — a product call, not a layout one.
  ///
  /// So the margins are handled where availability *is* allowed: in the view,
  /// see `widgetBackground`.
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: Self.kind, provider: BaroEaseProvider()) { entry in
      BaroEaseWidgetView(entry: entry)
    }
    .configurationDisplayName("BaroEase")
    .description("Log an attack, and see this week's count and the latest pressure.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
