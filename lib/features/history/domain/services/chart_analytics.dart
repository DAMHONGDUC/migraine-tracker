import 'package:meta/meta.dart';

import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/head_region.dart';

/// Pure-Dart aggregations behind the History → Chart view's richer charts.
/// Each calculator is const and side-effect free (unit-tested independently);
/// widgets only render the results. All bucketing is done in the user's local
/// timezone — [Attack.startedAt] is stored in UTC.
///
/// The weekly attack-frequency chart keeps its own `WeeklyBucketsCalculator`;
/// these cover the trend, severity, location and time-of-day breakdowns.

/// One week's average pain intensity (null when that week had no attacks, so
/// the line can leave a gap rather than plunge to zero).
@immutable
class IntensityTrendPoint {
  const IntensityTrendPoint({
    required this.weekStart,
    required this.average,
    required this.count,
  });

  final DateTime weekStart;
  final double? average;
  final int count;
}

/// Average pain intensity per calendar week (Monday-start), oldest first —
/// the same window as the frequency chart so the two read together.
class IntensityTrendCalculator {
  const IntensityTrendCalculator();

  static DateTime _mondayOf(DateTime d) {
    final midnight = DateTime(d.year, d.month, d.day);
    return midnight.subtract(Duration(days: midnight.weekday - 1));
  }

  List<IntensityTrendPoint> compute(
    List<Attack> attacks, {
    required DateTime now,
    int weeks = 8,
  }) {
    final currentWeek = _mondayOf(now.toLocal());
    final starts = [
      for (int i = weeks - 1; i >= 0; i--)
        currentWeek.subtract(Duration(days: 7 * i)),
    ];
    final sums = {for (final start in starts) start: 0};
    final counts = {for (final start in starts) start: 0};

    for (final attack in attacks) {
      final week = _mondayOf(attack.startedAt.toLocal());
      if (counts.containsKey(week)) {
        counts[week] = counts[week]! + 1;
        sums[week] = sums[week]! + attack.intensity;
      }
    }

    return [
      for (final start in starts)
        IntensityTrendPoint(
          weekStart: start,
          count: counts[start]!,
          average: counts[start]! == 0 ? null : sums[start]! / counts[start]!,
        ),
    ];
  }
}

/// Pain severity in four bands, matching `AppColors.intensity`'s green →
/// yellow → orange → red scale.
enum SeverityBand { mild, moderate, severe, extreme }

/// A representative intensity for each band, so the chart can colour a band
/// through `AppColors.intensity` without duplicating the thresholds.
extension SeverityBandX on SeverityBand {
  int get sampleIntensity => switch (this) {
    SeverityBand.mild => 2,
    SeverityBand.moderate => 5,
    SeverityBand.severe => 8,
    SeverityBand.extreme => 10,
  };
}

@immutable
class SeverityCount {
  const SeverityCount({required this.band, required this.count});

  final SeverityBand band;
  final int count;
}

/// Counts attacks into the four severity bands (always returns all four, in
/// order, so the legend/colours stay stable even when a band is empty).
class SeverityBreakdownCalculator {
  const SeverityBreakdownCalculator();

  SeverityBand bandOf(int intensity) {
    if (intensity <= 3) return SeverityBand.mild;
    if (intensity <= 6) return SeverityBand.moderate;
    if (intensity <= 8) return SeverityBand.severe;
    return SeverityBand.extreme;
  }

  List<SeverityCount> compute(List<Attack> attacks) {
    final counts = {for (final band in SeverityBand.values) band: 0};
    for (final attack in attacks) {
      final band = bandOf(attack.intensity);
      counts[band] = counts[band]! + 1;
    }
    return [
      for (final band in SeverityBand.values)
        SeverityCount(band: band, count: counts[band]!),
    ];
  }
}

@immutable
class LocationCount {
  const LocationCount({required this.region, required this.count});

  final HeadRegion region;
  final int count;
}

/// Counts attacks per head area, dropping areas that never occur and sorting
/// most-frequent first (ties keep enum order for a stable layout).
///
/// **An attack counts once in every area it names**, so the column totals add
/// up to more than the number of attacks. That is the honest reading: the
/// chart answers "how often does my left temple hurt", not "how do my attacks
/// divide up", and picking one area per attack to make the sum tidy would
/// throw away the very thing the multi-area picker exists to record.
class LocationBreakdownCalculator {
  const LocationBreakdownCalculator();

  List<LocationCount> compute(List<Attack> attacks) {
    final Map<HeadRegion, int> counts = <HeadRegion, int>{
      for (final HeadRegion region in HeadRegion.values) region: 0,
    };

    for (final Attack attack in attacks) {
      for (final HeadRegion region in attack.regions) {
        counts[region] = counts[region]! + 1;
      }
    }

    return <LocationCount>[
      for (final HeadRegion region in HeadRegion.values)
        if (counts[region]! > 0)
          LocationCount(region: region, count: counts[region]!),
    ]..sort((LocationCount a, LocationCount b) => b.count.compareTo(a.count));
  }
}

/// Quarters of the day, so "when do attacks strike" reads at a glance.
enum DayPart { night, morning, afternoon, evening }

@immutable
class DayPartCount {
  const DayPartCount({required this.part, required this.count});

  final DayPart part;
  final int count;
}

/// Counts attacks by quarter of the (local) day: night 00–06, morning 06–12,
/// afternoon 12–18, evening 18–24. Always returns all four in chronological
/// order so the bars never reshuffle.
class TimeOfDayCalculator {
  const TimeOfDayCalculator();

  DayPart partOf(DateTime local) {
    final hour = local.hour;
    if (hour < 6) return DayPart.night;
    if (hour < 12) return DayPart.morning;
    if (hour < 18) return DayPart.afternoon;
    return DayPart.evening;
  }

  List<DayPartCount> compute(List<Attack> attacks) {
    final counts = {for (final part in DayPart.values) part: 0};
    for (final attack in attacks) {
      final part = partOf(attack.startedAt.toLocal());
      counts[part] = counts[part]! + 1;
    }
    return [
      for (final part in DayPart.values)
        DayPartCount(part: part, count: counts[part]!),
    ];
  }
}
