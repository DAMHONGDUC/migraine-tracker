import 'package:meta/meta.dart';

/// How long the user slept across one night.
@immutable
class SleepNight {
  const SleepNight({required this.date, required this.duration});

  /// Local calendar date (midnight) the night *ends* on — the morning the user woke up.
  final DateTime date;

  final Duration duration;

  double get hours => duration.inMinutes / 60;
}
