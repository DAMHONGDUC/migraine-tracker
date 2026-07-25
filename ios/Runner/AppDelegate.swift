import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Present reminders in the foreground (banner + sound). Without a delegate
  // returning these options, iOS silently drops notifications while the app is
  // open, so reminders only showed when backgrounded.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Claim the notification-center delegate AFTER plugins register, so
    // foreground presentation is governed by willPresent above rather than the
    // flutter_local_notifications delegate it installs during registration
    // (setting it in didFinishLaunching gets overwritten by that registration).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
  }
}
