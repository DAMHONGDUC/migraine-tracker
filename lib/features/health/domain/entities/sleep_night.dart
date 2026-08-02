import 'package:meta/meta.dart';

/// How long the user slept across one night.
@immutable
class SleepNight {
  const SleepNight({required this.date, required this.duration});

  /// Local calendar date (midnight) the night *ends* on — the morning the
  /// user woke up. That is the day an attack would follow, so it is the key
  /// the correlation joins on.
  final DateTime date;

  final Duration duration;

  double get hours => duration.inMinutes / 60;
}
