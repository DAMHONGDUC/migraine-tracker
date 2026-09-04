/// Where a tap on the home-screen widget, or a Siri shortcut, leads.
enum HomeWidgetDestination { log, checkIn }

/// The URL contract between `BaroEaseWidgetView.swift`, `BaroEaseShortcuts.swift` and the app.
final class HomeWidgetLink {
  /// Registered in `ios/Runner/Info.plist`.
  static const String scheme = 'baroease';

  static const String logHost = 'log';

  /// The daily check-in, reached by Siri rather than by the widget — hard rule 18 keeps the widget itself at three things.
  static const String checkInHost = 'checkin';

  /// Load-bearing, and not ours.
  static const String pluginMarkerParam = 'homeWidget';

  /// What [uri] points at, or null if it points at nothing we serve.
  static HomeWidgetDestination? resolve(Uri? uri) {
    if (uri == null || uri.scheme != scheme) return null;

    // `baroease://log` puts the word in the host, `baroease:///log` in the path. Read either rather than depend on which the Swift side wrote.
    final String target = uri.host.isNotEmpty
        ? uri.host
        : (uri.pathSegments.firstOrNull ?? '');

    return switch (target) {
      logHost => HomeWidgetDestination.log,
      checkInHost => HomeWidgetDestination.checkIn,
      _ => null,
    };
  }
}
