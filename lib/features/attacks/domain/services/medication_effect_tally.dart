import '../entities/attack.dart';
import '../enums/medication_effect.dart';

/// How often one medication worked, over the attacks it was taken for.
class MedicationEffectCount {
  const MedicationEffectCount({
    required this.helped,
    required this.partly,
    required this.didNotHelp,
  });

  final int helped;
  final int partly;
  final int didNotHelp;

  /// Attacks where the question was actually answered — the denominator.
  /// Attacks with no answer are not counted as failures: never asked is not
  /// the same as "it did nothing", and treating it that way would make every
  /// drug look worse the less diligent the user is.
  int get answered => helped + partly + didNotHelp;

  bool get isEmpty => answered == 0;
}

/// Counts medication outcomes per medication name.
///
/// Pure domain logic, not a widget's private method: it is the arithmetic
/// behind a claim about someone's treatment, so it is testable on its own
/// (CLAUDE.md § specialised logic gets its own class on first use).
final class MedicationEffectTally {
  const MedicationEffectTally();

  /// Outcomes for [medicationName], matched exactly as it was recorded on the
  /// attack — the attack stores the name, not an id, so a renamed medication
  /// legitimately starts a fresh tally rather than inheriting one it may not
  /// have earned.
  MedicationEffectCount forMedication(
    List<Attack> attacks,
    String medicationName,
  ) {
    int helped = 0;
    int partly = 0;
    int didNotHelp = 0;

    for (final Attack attack in attacks) {
      if (attack.medicationName != medicationName) continue;
      switch (attack.medicationEffect) {
        case MedicationEffect.helped:
          helped++;
        case MedicationEffect.partly:
          partly++;
        case MedicationEffect.didNotHelp:
          didNotHelp++;
        case null:
          break;
      }
    }

    return MedicationEffectCount(
      helped: helped,
      partly: partly,
      didNotHelp: didNotHelp,
    );
  }

  /// Every medication that has at least one answer, keyed by name — what the
  /// doctor report lists.
  Map<String, MedicationEffectCount> byMedication(List<Attack> attacks) {
    final Map<String, MedicationEffectCount> result =
        <String, MedicationEffectCount>{};
    final Set<String> names = <String>{
      for (final Attack attack in attacks)
        if (attack.medicationName case final String name) name,
    };

    for (final String name in names) {
      final MedicationEffectCount count = forMedication(attacks, name);
      if (!count.isEmpty) result[name] = count;
    }
    return result;
  }
}
