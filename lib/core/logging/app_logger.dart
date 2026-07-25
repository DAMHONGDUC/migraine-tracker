import 'package:logger/logger.dart';

/// App-wide developer logger, built on the `logger` package.
///
/// Silent unless in a debug build (detected via an assert, so this stays pure
/// Dart and can be called from `domain/` too) — nothing is logged in
/// profile/release, so it's purely a development-visibility aid that never
/// leaks in production. Tests flip [enabled] off to keep their console clean.
///
/// Each entry is a single line: `«time?» «emoji» «message»`. Toggle the
/// leading timestamp with [includeTime].
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

  /// Whether each line is prefixed with the time (HH:MM:SS.mmm). Set false for
  /// terser logs.
  static bool includeTime = true;

  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: _OneLinePrinter(),
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
    bool enabled = false;
    assert(enabled = true);
    return enabled;
  }
}

/// One line per entry: `«time?» «level-emoji» «message»`, with the error and
/// each stack-trace frame on their own following lines (errors need the trace,
/// but ordinary logs stay single-line). No ANSI colors or box borders — the
/// Flutter/IDE console renders neither.
class _OneLinePrinter extends LogPrinter {
  static const _emojis = {
    Level.trace: '🔍',
    Level.debug: '🐛',
    Level.info: '💡',
    Level.warning: '⚠️',
    Level.error: '⛔',
    Level.fatal: '💀',
  };

  @override
  List<String> log(LogEvent event) {
    final time = AppLogger.includeTime ? '${_formatTime(event.time)} ' : '';
    final emoji = _emojis[event.level] ?? '';
    final lines = <String>['$time$emoji ${event.message}'];

    if (event.error != null) lines.add('    ${event.error}');
    final stackTrace = event.stackTrace;
    if (stackTrace != null) {
      lines.addAll(stackTrace.toString().trimRight().split('\n'));
    }
    return lines;
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}'
        '.${three(t.millisecond)}';
  }
}
