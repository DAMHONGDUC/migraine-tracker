import 'package:meta/meta.dart';

import '../enums/map_factor.dart';

/// Which side of the map a factor lands on.
enum FactorVerdict {
  /// Attacks are meaningfully more likely on the days that carry it.
  trigger,

  /// Meaningfully less likely — the days that carry it are the quieter ones.
  protector,

  /// Both groups are close enough that the difference is noise.
  notAssociated,

  /// Too few days on one side or the other to say anything at all.
  insufficient,
}

/// One factor, its two groups of days, and what they add up to.
@immutable
class FactorAssociation {
  const FactorAssociation({
    required this.factor,
    required this.verdict,
    required this.daysWith,
    required this.daysWithout,
    required this.attackRateWith,
    required this.attackRateWithout,
    required this.effect,
  });

  final MapFactor factor;
  final FactorVerdict verdict;

  /// Days the factor was recorded on, and days it was not — both counted only among days the user actually answered.
  final int daysWith;
  final int daysWithout;

  /// Share of each group's days that carried an attack, 0–1.
  final double attackRateWith;
  final double attackRateWithout;

  /// How far apart the two rates sit, as a share of the larger — the same measure `TriggerStrength` uses, so the two screens cannot grade the same gap differently.
  final double effect;
}

/// Every factor the map could weigh, and what the whole map is still waiting for.
@immutable
class FactorMap {
  const FactorMap({
    required this.associations,
    required this.answeredDays,
    required this.requiredDays,
    required this.attacks,
    required this.requiredAttacks,
  });

  /// Widest gap first, so the strongest thing the map found leads.
  final List<FactorAssociation> associations;

  final int answeredDays;
  final int requiredDays;
  final int attacks;
  final int requiredAttacks;

  /// Whether there is enough behind the whole map to draw it at all.
  bool get isReady =>
      answeredDays >= requiredDays && attacks >= requiredAttacks;

  List<FactorAssociation> of(FactorVerdict verdict) => associations
      .where((FactorAssociation a) => a.verdict == verdict)
      .toList(growable: false);
}
