import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/daily_log/domain/entities/daily_log.dart';
import 'package:migraine_tracker/features/daily_log/domain/enums/daily_factor.dart';
import 'package:migraine_tracker/features/sync/domain/services/daily_log_payload_codec.dart';

void main() {
  const DailyLogPayloadCodec codec = DailyLogPayloadCodec();

  test('a full check-in survives a round trip', () {
    final DailyLog value = DailyLog(
      day: DateTime(2026, 9, 14),
      sleepQuality: 2,
      stressLevel: 4,
      factors: const <DailyFactor>[
        DailyFactor.skippedMeal,
        DailyFactor.caffeine,
      ],
      steps: 8421,
    );

    final DailyLog back = codec.decode(codec.encode(value), id: '2026-09-14');

    expect(back.day, DateTime(2026, 9, 14));
    expect(back.sleepQuality, 2);
    expect(back.stressLevel, 4);
    expect(back.factors, value.factors);
    expect(back.steps, 8421);
  });

  // The day is the document id, so it is the one field the payload must NOT carry — two copies is two chances to disagree.
  test('the day comes from the id, never from the payload', () {
    final String json = codec.encode(DailyLog(day: DateTime(2026, 9, 14)));

    expect(json.contains('2026-09-14'), isFalse);
    expect(codec.decode(json, id: '2026-01-02').day, DateTime(2026, 1, 2));
  });

  test('an unanswered day round-trips as unanswered', () {
    final DailyLog back = codec.decode(
      codec.encode(DailyLog(day: DateTime(2026, 9, 14), steps: 300)),
      id: '2026-09-14',
    );

    expect(back.sleepQuality, isNull);
    expect(back.stressLevel, isNull);
    expect(back.factors, isEmpty);
    expect(back.isAnswered, isFalse);
    // A row Health filled in on its own still exists; it just is not a check-in.
    expect(back.steps, 300);
  });

  // A newer build may write a factor this one has never heard of; dropping it must not cost the rest of the day.
  test('an unknown factor is dropped and the rest of the day survives', () {
    const String json =
        '{"v":1,"sleepQuality":3,"stressLevel":null,'
        '"factors":["caffeine","moonPhase"],"steps":null}';

    final DailyLog back = codec.decode(json, id: '2026-09-14');

    expect(back.factors, const <DailyFactor>[DailyFactor.caffeine]);
    expect(back.sleepQuality, 3);
  });

  test('a rating outside 1..5 reads as unanswered rather than throwing', () {
    const String json =
        '{"v":1,"sleepQuality":9,"stressLevel":0,"factors":[],"steps":null}';

    final DailyLog back = codec.decode(json, id: '2026-09-14');

    expect(back.sleepQuality, isNull);
    expect(back.stressLevel, isNull);
  });

  test('a newer payload version is refused', () {
    expect(
      () => codec.decode('{"v":99,"factors":[]}', id: '2026-09-14'),
      throwsFormatException,
    );
  });
}
