import 'package:meta/meta.dart';

/// What the Settings row is allowed to know about a wipe in flight.
@immutable
class WipeStatus {
  const WipeStatus({this.isRunning = false, this.progress = 0});

  static const WipeStatus idle = WipeStatus();

  final bool isRunning;

  /// How far the wipe in flight has got, 0 to 1. Only meaningful while [isRunning].
  final double progress;

  /// [progress] as whole percent, which is all the UI ever shows.
  int get percent => (progress * 100).round();
}
