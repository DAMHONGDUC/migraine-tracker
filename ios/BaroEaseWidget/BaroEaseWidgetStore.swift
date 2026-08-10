import Foundation

/// The App Group the Flutter app writes and this extension reads.
///
/// Every key here is a contract with `HomeWidgetContent.toData()` on the Dart
/// side — the app renders the strings, because the widget cannot reach the
/// app's ARB files and a hardcoded English label would ignore the language
/// the user picked.
enum BaroEaseWidgetStore {
  /// Must match `HomeWidgetConstant.appGroupId`.
  static let appGroupId = "group.app.dd.migraine.tracker"

  static func string(_ key: String) -> String? {
    guard
      let defaults = UserDefaults(suiteName: appGroupId),
      let value = defaults.string(forKey: key),
      !value.isEmpty
    else { return nil }

    return value
  }

  /// The instant the pressure reading stops standing for "now", decided by
  /// the app. Absent means there is no reading to expire.
  static func pressureExpiry() -> Date? {
    guard
      let raw = string("pressure_expires_at"),
      let seconds = TimeInterval(raw)
    else { return nil }

    return Date(timeIntervalSince1970: seconds)
  }
}
