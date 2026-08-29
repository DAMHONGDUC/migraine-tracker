import '../entities/sleep_night.dart';
import '../entities/sleep_summary.dart';
import '../entities/step_day.dart';
import '../entities/step_summary.dart';

/// Turns what HealthKit handed over into the short summary the sleep and activity screens show back.
class HealthSummariser {
  const HealthSummariser();

  /// How many recent entries a card shows. A week: long enough to see a pattern, short enough that every bar keeps a readable label.
  static const int windowDays = 7;

  SleepSummary sleep(List<SleepNight> nights) {
    if (nights.isEmpty) return SleepSummary.empty;

    final List<SleepNight> window = _lastOf(nights);
    final int minutes = window.fold(
      0,
      (int sum, SleepNight night) => sum + night.duration.inMinutes,
    );

    return SleepSummary(
      nights: window,
      average: Duration(minutes: minutes ~/ window.length),
    );
  }

  StepSummary steps(List<StepDay> days) {
    if (days.isEmpty) return StepSummary.empty;

    final List<StepDay> window = _lastOf(days);
    final int total = window.fold(0, (int sum, StepDay day) => sum + day.count);

    return StepSummary(days: window, average: total ~/ window.length);
  }

  /// The newest [windowDays] entries of an oldest-first list.
  List<T> _lastOf<T>(List<T> entries) => entries.length <= windowDays
      ? entries
      : entries.sublist(entries.length - windowDays);
}
