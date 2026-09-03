import 'package:meta/meta.dart';

import '../enums/daily_factor.dart';

/// One day of how the user was, attack or no attack.
///
/// This is the control group the correlation engine never had: v1.0 recorded
/// only days that hurt, so it could say what an attack followed but never what
/// a quiet day followed too.
@immutable
class DailyLog {
  DailyLog({
    required DateTime day,
    this.sleepQuality,
    this.stressLevel,
    this.factors = const <DailyFactor>[],
    this.steps,
  }) : day = DateTime(day.year, day.month, day.day),
       assert(
         sleepQuality == null || (sleepQuality >= 1 && sleepQuality <= 5),
         'sleepQuality must be within 1..5',
       ),
       assert(
         stressLevel == null || (stressLevel >= 1 && stressLevel <= 5),
         'stressLevel must be within 1..5',
       );

  /// The local calendar day this describes, at midnight. Local rather than UTC: a user's day is the one they lived, not the one in Greenwich.
  final DateTime day;

  /// How the night before felt, 1 (worst) to 5 (best). Null is "not answered", which every field here allows — a check-in nobody can leave half-done is one they stop opening.
  final int? sleepQuality;

  /// How the day felt, 1 (calm) to 5 (worst).
  final int? stressLevel;

  final List<DailyFactor> factors;

  /// Steps that day, from Apple Health. Nullable for the same reasons `Attack.steps` is: not iOS, not granted, or no samples.
  ///
  /// The night's sleep has no field here on purpose. It is read from HealthKit
  /// when the screen asks and never stored, so it cannot be synced, exported or
  /// left behind by a wipe — `features/health/CLAUDE.md` is the rule.
  final int? steps;

  /// True once the user has actually answered something. An empty row exists only where Health filled it in on its own, and must not count as a check-in.
  bool get isAnswered =>
      sleepQuality != null || stressLevel != null || factors.isNotEmpty;

  DailyLog copyWith({
    int? sleepQuality,
    int? stressLevel,
    List<DailyFactor>? factors,
    int? steps,
  }) => DailyLog(
    day: day,
    sleepQuality: sleepQuality ?? this.sleepQuality,
    stressLevel: stressLevel ?? this.stressLevel,
    factors: factors ?? this.factors,
    steps: steps ?? this.steps,
  );
}
