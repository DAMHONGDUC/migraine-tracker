import '../entities/home_widget_content.dart';

/// The bridge to the OS home screen.
///
/// Best-effort throughout, like every other platform surface here: a device
/// with no widget placed, or a platform with no extension shipped, is a
/// no-op rather than an error. Nothing on screen ever waits on it.
abstract interface class HomeWidgetRepository {
  /// Whether this platform has a widget extension at all. Only iOS does —
  /// Android stays compiling but unpolished, so nothing is drawn there.
  bool get isSupported;

  /// Writes [content] into the shared App Group and asks the OS to redraw.
  Future<void> publish(HomeWidgetContent content);

  /// Empties the shared container and redraws.
  ///
  /// Two callers, and they are different things: switching the widget off,
  /// and the GDPR wipe — a week count and a pressure reading sitting in an
  /// App Group are a copy of the user's data like any other (hard rule 8).
  Future<void> clear();

  /// Taps on the widget while the app is already running.
  Stream<Uri?> get taps;

  /// The tap that launched the app, if it was one. Taken once — reading it
  /// again would reopen the same screen on the next resume.
  Future<Uri?> takeLaunchUri();
}
