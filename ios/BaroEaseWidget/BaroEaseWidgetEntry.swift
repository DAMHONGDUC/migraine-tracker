import Foundation
import SwiftUI
import WidgetKit

/// Which way pressure moved. Mirrors `PressureTrend` on the Dart side; the
/// raw values are the tokens that travel in the App Group.
enum BaroEasePressureTrend: String {
  case falling
  case rising
  case steady
  case unknown

  init(token: String?) {
    self = BaroEasePressureTrend(rawValue: token ?? "") ?? .unknown
  }

  var symbol: String {
    switch self {
    case .falling: return "arrow.down.right"
    case .rising: return "arrow.up.right"
    case .steady: return "arrow.right"
    case .unknown: return "questionmark"
    }
  }
}

/// One rendering of the widget.
///
/// Every string arrives finished from the app. The only text this extension
/// owns is [placeholder]'s, which is shown in the widget gallery before any
/// data exists and is deliberately neutral rather than translated — there is
/// no locale to read at that point.
struct BaroEaseEntry: TimelineEntry {
  let date: Date
  let logLabel: String
  let weekLabel: String
  let weekValue: String
  let pressureLabel: String
  let pressureValue: String
  let pressureDetail: String
  let trend: BaroEasePressureTrend

  static let noReading = "—"

  static let placeholder = BaroEaseEntry(
    date: Date(),
    logLabel: "Log attack",
    weekLabel: "This week",
    weekValue: noReading,
    pressureLabel: "Pressure",
    pressureValue: noReading,
    pressureDetail: "",
    trend: .unknown
  )

  /// Reads the App Group. [withPressure] false is the same entry with the
  /// reading blanked — what the timeline shows once it has expired.
  static func fromStore(date: Date, withPressure: Bool) -> BaroEaseEntry {
    let hasPressure = withPressure && BaroEaseWidgetStore.string("pressure_value") != nil

    return BaroEaseEntry(
      date: date,
      logLabel: BaroEaseWidgetStore.string("log_label") ?? placeholder.logLabel,
      weekLabel: BaroEaseWidgetStore.string("week_label") ?? placeholder.weekLabel,
      weekValue: BaroEaseWidgetStore.string("week_value") ?? noReading,
      pressureLabel: BaroEaseWidgetStore.string("pressure_label") ?? placeholder.pressureLabel,
      pressureValue: hasPressure
        ? (BaroEaseWidgetStore.string("pressure_value") ?? noReading)
        : noReading,
      pressureDetail: hasPressure ? (BaroEaseWidgetStore.string("pressure_detail") ?? "") : "",
      trend: hasPressure
        ? BaroEasePressureTrend(token: BaroEaseWidgetStore.string("trend"))
        : .unknown
    )
  }
}
