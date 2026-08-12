import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../attacks/providers.dart';
import '../health/providers.dart';
import '../premium/providers.dart';
import '../weather/domain/entities/weather_report.dart';
import '../weather/providers.dart';
import 'domain/entities/week_summary.dart';
import 'domain/services/week_summary_calculator.dart';

/// This-week-vs-last-week summary for the dashboard card. Recomputes whenever
/// the attack stream emits; defaults to an empty week while the stream loads.
final weekSummaryProvider = Provider<WeekSummary>((ref) {
  const calculator = WeekSummaryCalculator();
  final attacks = ref.watch(attacksStreamProvider).value ?? const [];
  return calculator.compute(attacks, now: DateTime.now());
});

/// Whether the dashboard's "Today" section has anything to say.
///
/// The screen asks BEFORE placing it, because the section list inserts a gap
/// between every entry — a widget that hides itself would leave the gap
/// behind it, which is the double-gap the list is built to avoid.
///
/// Premium only: a free user is not shown a readout of analyses they cannot
/// open. And only fields that actually carry a value count, so a device with
/// no weather and no Apple Health drops the section rather than printing a
/// card of dashes.
final hasTodayReadingsProvider = Provider<bool>((ref) {
  if (!ref.watch(hasPremiumProvider)) return false;

  final WeatherConditions? now = ref.watch(weatherReportProvider).value?.current;

  return now?.temperatureCelsius != null ||
      now?.pressureHpa != null ||
      ref.watch(stepSummaryProvider).value?.latest != null ||
      ref.watch(sleepSummaryProvider).value?.latest != null;
});
