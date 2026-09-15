import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/core/constants/attack_progress_constant.dart';
import 'package:migraine_tracker/core/utils/date_time_utils.dart';
import 'package:migraine_tracker/features/attacks/domain/entities/attack.dart';
import 'package:migraine_tracker/features/attacks/domain/enums/head_region.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 7, 1, 12);

  Attack attack({required DateTime startedAt, DateTime? endedAt}) => Attack(
    id: 'a1',
    startedAt: startedAt,
    intensity: 6,
    regions: const <HeadRegion>[HeadRegion.templeR],
    endedAt: endedAt,
  );

  test('an unfinished attack that started an hour ago is running', () {
    expect(
      attack(
        startedAt: now.subtract(const Duration(hours: 1)),
      ).isRunningAt(now),
      isTrue,
    );
  });

  test('an attack with an end recorded is not running', () {
    expect(
      attack(
        startedAt: now.subtract(const Duration(hours: 1)),
        endedAt: now.subtract(const Duration(minutes: 5)),
      ).isRunningAt(now),
      isFalse,
    );
  });

  // The column collapses "still going" and "never said" into one null, so the window is the only thing that can tell them apart.
  test('an unfinished attack past the window is not running', () {
    expect(
      attack(
        startedAt: now.subtract(
          AttackProgressConstant.window + const Duration(minutes: 1),
        ),
      ).isRunningAt(now),
      isFalse,
    );
  });

  test('the window edge itself still counts as running', () {
    expect(
      attack(
        startedAt: now.subtract(AttackProgressConstant.window),
      ).isRunningAt(now),
      isTrue,
    );
  });

  // A device whose clock stepped backwards must not report an attack from the future as running.
  test('an attack starting in the future is not running', () {
    expect(
      attack(startedAt: now.add(const Duration(hours: 1))).isRunningAt(now),
      isFalse,
    );
  });

  group('the elapsed clock', () {
    test('pads every field to two digits', () {
      expect(
        DateTimeUtils.elapsed(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '01:02:03',
      );
    });

    // Hours accumulate rather than wrapping: a 30-hour attack reads 30, not 06.
    test('hours never wrap to a second day', () {
      expect(
        DateTimeUtils.elapsed(const Duration(hours: 30, minutes: 5)),
        '30:05:00',
      );
    });
  });
}
