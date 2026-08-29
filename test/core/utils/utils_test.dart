import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/utils/chart_axis_utils.dart';
import 'package:migraine_tracker/core/utils/comma_list_utils.dart';
import 'package:migraine_tracker/core/utils/date_time_utils.dart';
import 'package:migraine_tracker/core/utils/locale_utils.dart';

/// The logic that used to live inside widgets and controllers. Testable now, which is most of the point of moving it.
void main() {
  group('DateTimeUtils — clock', () {
    test('pads both halves of a clock time', () {
      expect(DateTimeUtils.hhmm(7, 5), '07:05');
      expect(DateTimeUtils.hhmm(0, 0), '00:00');
      expect(DateTimeUtils.hhmm(23, 59), '23:59');
    });

    test('counts down to local midnight', () {
      expect(
        DateTimeUtils.untilMidnight(DateTime(2026, 8, 8, 23, 59, 30)),
        '00:00:30',
      );
      expect(DateTimeUtils.untilMidnight(DateTime(2026, 8, 8)), '24:00:00');
    });
  });

  group('CommaListUtils', () {
    test('trims, and drops what a trailing comma leaves behind', () {
      expect(CommaListUtils.split('aura, nausea,  ,'), <String>[
        'aura',
        'nausea',
      ]);
    });

    test('nothing typed is no values, never one empty one', () {
      expect(CommaListUtils.split(''), isEmpty);
      expect(CommaListUtils.split('   '), isEmpty);
    });

    test('join and split are inverses', () {
      const List<String> values = <String>['aura', 'red wine', 'stress'];

      expect(CommaListUtils.split(CommaListUtils.join(values)), values);
    });
  });

  group('ChartAxisUtils', () {
    test('bounds leave headroom either side, snapped outwards', () {
      expect(ChartAxisUtils.minBound(<double>[1004.4, 1010]), 1002);
      expect(ChartAxisUtils.maxBound(<double>[1004.4, 1010.2]), 1013);
    });

    test('a flat series still gets an interval it can draw', () {
      // Zero would make fl_chart draw gridlines forever.
      expect(ChartAxisUtils.interval(1000, 1000), 1);
    });

    test('hours and times are inverses across the axis origin', () {
      final DateTime from = DateTime(2026, 8, 8, 12);

      expect(DateTimeUtils.hoursBetween(from, DateTime(2026, 8, 8, 13, 30)),
          1.5);
      expect(DateTimeUtils.hoursBetween(from, DateTime(2026, 8, 8, 11)), -1);
      expect(DateTimeUtils.timeAt(from, 1.5), DateTime(2026, 8, 8, 13, 30));
    });
  });

  group('LocaleUtils', () {
    const List<Locale> supported = <Locale>[Locale('en'), Locale('vi')];

    test('the user choice wins over the platform', () {
      expect(
        LocaleUtils.resolve(
          chosen: const Locale('vi'),
          platform: const Locale('en'),
          supported: supported,
        ),
        const Locale('vi'),
      );
    });

    test('a regional platform locale still matches its language', () {
      expect(
        LocaleUtils.resolve(
          chosen: null,
          platform: const Locale('en', 'GB'),
          supported: supported,
        ),
        const Locale('en'),
      );
    });

    test('a language the app does not ship falls back', () {
      expect(
        LocaleUtils.resolve(
          chosen: null,
          platform: const Locale('ja'),
          supported: supported,
        ),
        const Locale('en'),
      );
    });
  });

  group('DateTimeUtils — calendar', () {
    test('a month is its first day', () {
      expect(DateTimeUtils.monthOf(DateTime(2026, 8, 8, 23)), DateTime(2026, 8));
    });

    test('selection runs to the end of next year, not to today', () {
      expect(
        DateTimeUtils.lastSelectableDay(DateTime(2026, 8, 8)),
        DateTime(2027, 12, 31),
      );
    });
  });
}
