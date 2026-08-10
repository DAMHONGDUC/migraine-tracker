/// Where a tap on the home-screen widget leads.
enum HomeWidgetDestination { log }

/// The URL contract between `BaroEaseWidgetView.swift` and the app.
///
/// Pure Dart and its own class rather than a couple of lines inside the tap
/// listener: this is the one place that says what a widget URL looks like, and
/// it is the piece a test can hold still.
final class HomeWidgetLink {
  /// Registered in `ios/Runner/Info.plist`.
  static const String scheme = 'baroease';

  static const String logHost = 'log';

  /// **Load-bearing, and not ours.** `home_widget`'s `isWidgetUrl` matches on
  /// the presence of this query parameter and silently drops any URL without
  /// it — so a widget URL missing it reaches the app and goes nowhere. The
  /// value is never read; only the name matters.
  static const String pluginMarkerParam = 'homeWidget';

  /// What [uri] points at, or null if it points at nothing we serve.
  ///
  /// The marker is deliberately NOT required here. The plugin has already
  /// enforced it by the time a URL arrives, and demanding it twice would be a
  /// second thing to keep in step for no extra safety.
  static HomeWidgetDestination? resolve(Uri? uri) {
    if (uri == null || uri.scheme != scheme) return null;

    // `baroease://log` puts the word in the host, `baroease:///log` in the
    // path. Read either rather than depend on which the Swift side wrote.
    final String target = uri.host.isNotEmpty
        ? uri.host
        : (uri.pathSegments.firstOrNull ?? '');

    return target == logHost ? HomeWidgetDestination.log : null;
  }
}
