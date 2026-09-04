import AppIntents
import Foundation
import UIKit

/// "Hey Siri, log a migraine" — and the check-in beside it.
///
/// Both open the app on the URL the home-screen widget already uses, so there
/// is one deep-link contract and one place in Dart that resolves it
/// (`HomeWidgetLink`). An intent that did the work itself would need the
/// database, the free-plan gate and the log flow's state machine in Swift.
///
/// iOS 16 is where `AppIntents` starts; the app's floor is 15, so every symbol
/// here is behind an availability guard and simply does not exist on 15.
@available(iOS 16.0, *)
struct LogAttackIntent: AppIntent {
  static var title: LocalizedStringResource = "Log a migraine"
  static var description = IntentDescription(
    "Opens BaroEase on the three-tap log."
  )

  /// The app has to come to the front: the flow it opens is a screen, not a background action.
  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    await BaroEaseShortcutOpener.open(host: "log")
    return .result()
  }
}

@available(iOS 16.0, *)
struct DailyCheckInIntent: AppIntent {
  static var title: LocalizedStringResource = "Check in for today"
  static var description = IntentDescription(
    "Opens BaroEase on today's 30-second check-in."
  )

  static var openAppWhenRun: Bool = true

  @MainActor
  func perform() async throws -> some IntentResult {
    await BaroEaseShortcutOpener.open(host: "checkin")
    return .result()
  }
}

/// Opens the app's own URL scheme, which is what carries the destination into Dart.
@available(iOS 16.0, *)
enum BaroEaseShortcutOpener {
  @MainActor
  static func open(host: String) async {
    // `homeWidget=true` is the plugin's marker: the same listener answers for the widget and for Siri, and it only reads URLs carrying it.
    guard let url = URL(string: "baroease://\(host)?homeWidget=true") else {
      return
    }
    await UIApplication.shared.open(url)
  }
}

/// The phrases Siri accepts, and what the Shortcuts app lists without the user building anything.
@available(iOS 16.0, *)
struct BaroEaseShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: LogAttackIntent(),
      phrases: [
        "Log a migraine in \(.applicationName)",
        "Log an attack in \(.applicationName)",
      ],
      shortTitle: "Log a migraine",
      systemImageName: "bolt.heart"
    )
    AppShortcut(
      intent: DailyCheckInIntent(),
      phrases: [
        "Check in with \(.applicationName)",
        "Daily check-in in \(.applicationName)",
      ],
      shortTitle: "Check in",
      systemImageName: "calendar.badge.checkmark"
    )
  }
}
