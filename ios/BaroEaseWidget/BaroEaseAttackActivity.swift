import ActivityKit
import SwiftUI
import WidgetKit

/// The Live Activity's attributes. The name is fixed by the `live_activities`
/// plugin — rename it and the activity is created but never appears.
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState

  public struct ContentState: Codable, Hashable {}

  var id = UUID()
}

extension LiveActivitiesAppAttributes {
  /// The plugin writes every value into the App Group under `<id>_<key>`.
  func prefixedKey(_ key: String) -> String {
    return "\(id)_\(key)"
  }
}

/// The running attack on the Lock Screen and in the Dynamic Island.
///
/// Every word here is written by the app, already localized, exactly as the
/// home screen widget's are — the extension carries no strings of its own
/// because it has no `AppLocalizations` to read (see `home_widget/CLAUDE.md`).
///
/// The clock is `Text(timerInterval:)`, so iOS ticks it. Pushing an update a
/// second would spend the activity's whole update budget on a number the system
/// can count on its own.
@available(iOS 16.1, *)
struct BaroEaseAttackActivity: Widget {
  private static let defaults = UserDefaults(suiteName: BaroEaseWidgetStore.appGroupId)

  private static func string(_ context: ActivityViewContext<LiveActivitiesAppAttributes>, _ key: String) -> String {
    defaults?.string(forKey: context.attributes.prefixedKey(key)) ?? ""
  }

  /// When the attack started, as unix seconds. Absent means the app never wrote one, and the clock falls back to now rather than to 1970.
  private static func startedAt(_ context: ActivityViewContext<LiveActivitiesAppAttributes>) -> Date {
    guard let raw = defaults?.string(forKey: context.attributes.prefixedKey("startedAt")),
          let seconds = TimeInterval(raw)
    else { return Date() }

    return Date(timeIntervalSince1970: seconds)
  }

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(Self.string(context, "title"))
            .font(.headline)
            .foregroundColor(BaroEasePalette.textPrimary)
          Text(Self.string(context, "body"))
            .font(.caption)
            .foregroundColor(BaroEasePalette.textSecondary)
        }
        Spacer()
        Text(timerInterval: Self.startedAt(context)...Date.distantFuture, countsDown: false)
          .font(.system(.title2, design: .rounded).monospacedDigit())
          .foregroundColor(BaroEasePalette.primary)
          .frame(maxWidth: 90, alignment: .trailing)
      }
      .padding(16)
      .activityBackgroundTint(BaroEasePalette.surface)
      .activitySystemActionForegroundColor(BaroEasePalette.primary)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text(Self.string(context, "title"))
            .font(.caption)
            .foregroundColor(BaroEasePalette.textSecondary)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(timerInterval: Self.startedAt(context)...Date.distantFuture, countsDown: false)
            .font(.system(.body, design: .rounded).monospacedDigit())
            .foregroundColor(BaroEasePalette.primary)
            .frame(maxWidth: 80, alignment: .trailing)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(Self.string(context, "body"))
            .font(.caption)
            .foregroundColor(BaroEasePalette.textSecondary)
        }
      } compactLeading: {
        Image(systemName: "bolt.heart")
          .foregroundColor(BaroEasePalette.primary)
      } compactTrailing: {
        Text(timerInterval: Self.startedAt(context)...Date.distantFuture, countsDown: false)
          .font(.system(.caption, design: .rounded).monospacedDigit())
          .foregroundColor(BaroEasePalette.primary)
          .frame(maxWidth: 44)
      } minimal: {
        Image(systemName: "bolt.heart")
          .foregroundColor(BaroEasePalette.primary)
      }
    }
  }
}
