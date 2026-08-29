import '../entities/home_widget_content.dart';

/// The bridge to the OS home screen.
abstract interface class HomeWidgetRepository {
  /// Whether this platform has a widget extension at all. Only iOS does — Android stays compiling but unpolished, so nothing is drawn there.
  bool get isSupported;

  /// Writes [content] into the shared App Group and asks the OS to redraw.
  Future<void> publish(HomeWidgetContent content);

  /// Empties the shared container and redraws.
  Future<void> clear();

  /// Taps on the widget while the app is already running.
  Stream<Uri?> get taps;

  /// The tap that launched the app, if it was one. Taken once — reading it again would reopen the same screen on the next resume.
  Future<Uri?> takeLaunchUri();
}
