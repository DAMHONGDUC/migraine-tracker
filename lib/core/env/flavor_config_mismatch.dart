import 'app_env.dart';

/// The build's two halves of config naming different Firebase projects.
///
/// A build carries its configuration in two halves and **nothing ties them
/// together**: the Dart half arrives through
/// `--dart-define-from-file=env/<flavor>.json` and decides what the app thinks
/// it is, while the native half is the bundled `GoogleService-Info.plist` /
/// `google-services.json` and decides which database it actually writes to.
/// Run the app before `prepare-env.sh`, or after running it for the *other*
/// flavour, and the two name different projects.
///
/// **Nothing else catches this.** Each half is valid on its own, so there is
/// no exception, no failed build and no log line: the app compiles, installs,
/// launches, signs in and works — against the wrong project. Tests run with no
/// flavour at all, so both halves are empty and agree; the toolchains that
/// read the two halves never hold the other one; and a startup line printing
/// the flavour name is the Dart half logging itself back to itself.
final class FlavorConfigMismatch implements Exception {
  const FlavorConfigMismatch({required this.expected, required this.actual});

  /// The project `env/<flavour>.json` names — what the app thinks it is.
  final String expected;

  /// The project the native SDK actually came up on — what it writes to.
  final String actual;

  /// Whether two project ids are a *mismatch* rather than an *absence*.
  ///
  /// An empty half means "not configured yet", never "disagrees": a guard that
  /// fired there would turn a fresh clone with no backend into a broken app on
  /// day one, and whoever hit it would delete the guard rather than the cause.
  static bool disagree(String dart, String native) =>
      dart.isNotEmpty && native.isNotEmpty && dart != native;

  /// Names both projects and the command that fixes it, one labelled line
  /// each.
  ///
  /// This can only happen on a developer's machine, so these four lines are
  /// the whole value of the guard: a bare "config mismatch" leaves the reader
  /// to work out which half is wrong and which script rewrites it. Broken
  /// across lines rather than run into a sentence because it is read in two
  /// places that both punish a long one — a console, and the error screen's
  /// detail row, which centres its text and caps it at six lines.
  @override
  String toString() =>
      'Flavour config mismatch: this build is pointed at the wrong Firebase '
      'project.\n'
      'env/${AppEnv.flavor}.json expects: $expected\n'
      'native config is: $actual\n'
      'Fix: melos run prepare-env-${AppEnv.flavor}';
}
