import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/alerts/domain/entities/alert_threshold_range.dart';

void main() {
  group('AlertThresholdRange.parse', () {
    test('accepts a whole number inside the range', () {
      expect(AlertThresholdRange.parse('7'), 7);
      expect(AlertThresholdRange.parse(' 12 '), 12);
    });

    test('accepts both ends', () {
      expect(AlertThresholdRange.parse('2'), AlertThresholdRange.min);
      expect(AlertThresholdRange.parse('20'), AlertThresholdRange.max);
    });

    test('refuses a number outside the range', () {
      expect(AlertThresholdRange.parse('1'), isNull);
      expect(AlertThresholdRange.parse('21'), isNull);
      expect(AlertThresholdRange.parse('-5'), isNull);
    });

    test('refuses anything that is not a whole number', () {
      // The forecast cannot pay for halves, so the field never accepts one.
      expect(AlertThresholdRange.parse('7.5'), isNull);
      expect(AlertThresholdRange.parse(''), isNull);
      expect(AlertThresholdRange.parse('abc'), isNull);
      expect(AlertThresholdRange.parse('7 hPa'), isNull);
    });
  });

  group('AlertThresholdRange.clamp', () {
    test('pulls a stored value onto the slider', () {
      expect(AlertThresholdRange.clamp(0), AlertThresholdRange.min);
      expect(AlertThresholdRange.clamp(99), AlertThresholdRange.max);
      expect(AlertThresholdRange.clamp(5), 5);
    });
  });

  group('AlertThresholdRange.divisionsBetween', () {
    test('lands every whole hPa across the whole range', () {
      expect(
        AlertThresholdRange.divisions,
        AlertThresholdRange.max - AlertThresholdRange.min,
      );
    });

    test('lands every whole hPa across a narrowed window', () {
      // The sheet lets the user shrink the slider to get finer control; the
      // stops have to follow, or a 5-wide window would keep 18 of them.
      expect(AlertThresholdRange.divisionsBetween(5, 10), 5);
    });
  });
}
