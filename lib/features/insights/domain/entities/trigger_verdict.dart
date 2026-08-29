import 'package:meta/meta.dart';

/// The factors the app can compare on a like-for-like footing.
enum TriggerFactor { pressure, sleep, steps }

/// One factor and how far apart its two groups sit.
@immutable
class TriggerStrength {
  const TriggerStrength({
    required this.factor,
    required this.effect,
    required this.meaningfulEffect,
  });

  final TriggerFactor factor;

  /// How far apart the attack-day group and the quiet-day group are, as a share of the larger, 0–1.
  final double effect;

  /// Where a gap stops being noise. See [TriggerVerdictEngine].
  final double meaningfulEffect;

  bool get isMeaningful => effect >= meaningfulEffect;
}

/// Whether weather is actually this user's trigger — and what is, if not.
@immutable
sealed class TriggerVerdict {
  const TriggerVerdict();
}

/// Nothing has settled yet.
class TriggerVerdictPending extends TriggerVerdict {
  const TriggerVerdictPending({
    required this.attacksAnalyzed,
    required this.requiredAttacks,
  });

  final int attacksAnalyzed;
  final int requiredAttacks;
}

/// At least one factor has enough behind it to be stated.
class TriggerVerdictAnswer extends TriggerVerdict {
  const TriggerVerdictAnswer({required this.ranked, this.weather});

  /// Every settled factor, widest gap first.
  final List<TriggerStrength> ranked;

  /// Pressure, once its baseline is settled and reliable — null while it is not, which is why [weatherRuledOut] can never fire on missing data.
  final TriggerStrength? weather;

  TriggerStrength? get strongest => ranked.isEmpty ? null : ranked.first;

  /// Pressure is settled and the gap is real.
  bool get weatherIsATrigger => weather?.isMeaningful ?? false;

  /// Pressure is settled and the gap is not.
  bool get weatherRuledOut => weather != null && !weather!.isMeaningful;

  /// The strongest settled factor that is not pressure, when there is one worth naming.
  TriggerStrength? get alternative {
    for (final TriggerStrength strength in ranked) {
      if (strength.factor != TriggerFactor.pressure && strength.isMeaningful) {
        return strength;
      }
    }

    return null;
  }
}
