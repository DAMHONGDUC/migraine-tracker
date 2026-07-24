import 'package:logger/logger.dart';

/// App-wide developer logger, built on the `logger` package.
///
/// Silent unless in a debug build (detected via an assert, so this stays pure
/// Dart and can be called from `domain/` too) — nothing is logged in
/// profile/release, so it's purely a development-visibility aid that never
/// leaks in production. Tests flip [enabled] off to keep their console clean.
///
/// Categories (pick by intent, so the console reads as a story of what the app
/// is doing):
/// - [action]  — a user-driven action ("logged attack", "added medication")
/// - [info]    — notable state/flow ("weather snapshot attached")
/// - [warning] — recoverable oddities ("notification permission denied")
/// - [error]   — a caught failure, with its error object + stack trace
/// - [debug]   — fine-grained detail while chasing something down
///
/// Optional [data] is appended to the message, e.g.
/// `AppLogger.action('Attack logged', {'intensity': 7})`.
abstract final class AppLogger {
  /// True only in debug builds (asserts run) — the on/off switch for all
  /// logging. Mutable so tests can silence it.
  static bool enabled = _assertsEnabled();

  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      // The Flutter/IDE console doesn't render ANSI colors (they'd print as
      // raw `^[[38;5;12m` escapes) and the box borders just add noise — keep
      // it plain, one line per log.
      colors: false,
      noBoxingByDefault: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void action(String message, [Object? data]) {
    if (!enabled) return;
    _logger.i(_compose('🎯 $message', data));
  }

  static void info(String message, [Object? data]) {
    if (!enabled) return;
    _logger.i(_compose(message, data));
  }

  static void debug(String message, [Object? data]) {
    if (!enabled) return;
    _logger.d(_compose(message, data));
  }

  static void warning(String message, [Object? data]) {
    if (!enabled) return;
    _logger.w(_compose(message, data));
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!enabled) return;
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  static String _compose(String message, Object? data) =>
      data == null ? message : '$message — $data';

  /// Pure-Dart debug-mode check: the assignment only runs when asserts are on
  /// (debug builds), so this is true in debug and false in release/profile —
  /// no `dart:ui`/Flutter import needed.
  static bool _assertsEnabled() {
    var enabled = false;
    assert(enabled = true);
    return enabled;
  }
}
