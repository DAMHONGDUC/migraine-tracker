import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';
import 'package:migraine_tracker/features/history/domain/services/chart_analytics.dart';

Attack _attack({
  required DateTime startedAt,
  int intensity = 5,
  List<HeadRegion> regions = const <HeadRegion>[HeadRegion.templeL],
}) => Attack(
  id: startedAt.toIso8601String(),
  startedAt: startedAt,
  intensity: intensity,
  regions: regions,
);

void main() {
  group('IntensityTrendCalculator', () {
    test('averages intensity per week and leaves empty weeks null', () {
      // A fixed "now" mid-week so week bucketing is deterministic.
      final now = DateTime(2026, 7, 22); // a Wednesday
      final thisWeek = DateTime(2026, 7, 20); // Monday of that week
      final lastWeek = DateTime(2026, 7, 13);

      final points = const IntensityTrendCalculator().compute(
        [
          _attack(
            startedAt: thisWeek.add(const Duration(days: 1)),
            intensity: 4,
          ),
          _attack(
            startedAt: thisWeek.add(const Duration(days: 2)),
            intensity: 8,
          ),
        ],
        now: now,
        weeks: 3,
      );

      expect(points, hasLength(3));
      // Newest week (last element) averages 4 and 8 → 6.
      expect(points.last.weekStart, thisWeek);
      expect(points.last.average, 6.0);
      expect(points.last.count, 2);
      // The middle week had no attacks → null average, zero count.
      expect(points[1].weekStart, lastWeek);
      expect(points[1].average, isNull);
      expect(points[1].count, 0);
    });
  });

  group('SeverityBreakdownCalculator', () {
    test('bands split on 3/6/8 boundaries and always return all four', () {
      const calc = SeverityBreakdownCalculator();
      expect(calc.bandOf(1), SeverityBand.mild);
      expect(calc.bandOf(3), SeverityBand.mild);
      expect(calc.bandOf(4), SeverityBand.moderate);
      expect(calc.bandOf(6), SeverityBand.moderate);
      expect(calc.bandOf(7), SeverityBand.severe);
      expect(calc.bandOf(8), SeverityBand.severe);
      expect(calc.bandOf(9), SeverityBand.extreme);
      expect(calc.bandOf(10), SeverityBand.extreme);

      final counts = calc.compute([
        _attack(startedAt: DateTime(2026, 1, 1), intensity: 2),
        _attack(startedAt: DateTime(2026, 1, 2), intensity: 3),
        _attack(startedAt: DateTime(2026, 1, 3), intensity: 10),
      ]);
      expect(counts, hasLength(4));
      expect(counts.map((c) => c.band).toList(), SeverityBand.values);
      expect(counts.first.count, 2); // two mild
      expect(counts.last.count, 1); // one extreme
      expect(counts[1].count, 0); // no moderate
    });
  });

  group('LocationBreakdownCalculator', () {
    test('drops empty areas and sorts most-frequent first', () {
      final counts = const LocationBreakdownCalculator().compute([
        _attack(
          startedAt: DateTime(2026, 1, 1),
          regions: const <HeadRegion>[HeadRegion.templeL],
        ),
        _attack(
          startedAt: DateTime(2026, 1, 2),
          regions: const <HeadRegion>[HeadRegion.templeL],
        ),
        _attack(
          startedAt: DateTime(2026, 1, 3),
          regions: const <HeadRegion>[HeadRegion.crown],
        ),
      ]);

      expect(counts, hasLength(2));
      expect(counts.first.region, HeadRegion.templeL);
      expect(counts.first.count, 2);
      expect(counts.last.region, HeadRegion.crown);
      expect(counts.any((c) => c.region == HeadRegion.templeR), isFalse);
    });

    test('counts one attack once in every area it names', () {
      final counts = const LocationBreakdownCalculator().compute([
        _attack(
          startedAt: DateTime(2026, 1, 1),
          regions: const <HeadRegion>[
            HeadRegion.templeL,
            HeadRegion.eyeL,
            HeadRegion.nape,
          ],
        ),
      ]);

      // Three bars from one attack: the chart answers "how often does this area hurt", so the column total deliberately exceeds the attack count.
      expect(counts, hasLength(3));
      expect(counts.every((c) => c.count == 1), isTrue);
    });
  });

  group('TimeOfDayCalculator', () {
    test('buckets on the 6/12/18 hour boundaries', () {
      const calc = TimeOfDayCalculator();
      expect(calc.partOf(DateTime(2026, 1, 1, 0)), DayPart.night);
      expect(calc.partOf(DateTime(2026, 1, 1, 5, 59)), DayPart.night);
      expect(calc.partOf(DateTime(2026, 1, 1, 6)), DayPart.morning);
      expect(calc.partOf(DateTime(2026, 1, 1, 11, 59)), DayPart.morning);
      expect(calc.partOf(DateTime(2026, 1, 1, 12)), DayPart.afternoon);
      expect(calc.partOf(DateTime(2026, 1, 1, 17, 59)), DayPart.afternoon);
      expect(calc.partOf(DateTime(2026, 1, 1, 18)), DayPart.evening);
      expect(calc.partOf(DateTime(2026, 1, 1, 23, 59)), DayPart.evening);

      final counts = calc.compute([
        _attack(startedAt: DateTime(2026, 1, 1, 8)),
        _attack(startedAt: DateTime(2026, 1, 1, 9)),
        _attack(startedAt: DateTime(2026, 1, 1, 20)),
      ]);
      expect(counts, hasLength(4));
      expect(counts.map((c) => c.part).toList(), DayPart.values);
      expect(counts[DayPart.morning.index].count, 2);
      expect(counts[DayPart.evening.index].count, 1);
    });
  });
}
