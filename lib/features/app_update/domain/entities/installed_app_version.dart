import 'package:meta/meta.dart';

/// What is actually installed on this device, read from the app bundle.
@immutable
class InstalledAppVersion {
  const InstalledAppVersion({
    required this.buildName,
    required this.buildNumber,
  });

  /// `1.4.0` — the marketing version.
  final String buildName;

  /// `+12` in pubspec. 0 means it could not be read; the checker treats that as unknown and blocks nobody.
  final int buildNumber;
}
