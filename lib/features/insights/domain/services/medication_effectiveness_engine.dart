import '../../../../core/utils/date_time_utils.dart';
import '../../../attacks/domain/entities/attack.dart';
import '../../../attacks/domain/enums/medication_effect.dart';
import '../entities/medication_effectiveness_result.dart';

/// Medication effectiveness: of the drugs this user actually takes, which
/// ones work?
///
/// Pure Dart and deterministic. It reads only what the app already stores —
/// [Attack.medicationName], [Attack.medicationEffect] and [Attack.duration] —
/// so it needs no new question in the log flow (hard rule 5).
///
/// Like every engine here it grades the answer rather than withholding it:
/// a thin sample comes back as counts, never as a percentage.
class MedicationEffectivenessEngine {
  const MedicationEffectivenessEngine({
    this.minAnswers = defaultMinAnswers,
    this.minAnswersForShare = defaultMinAnswersForShare,
  }) : assert(minAnswers > 0, 'minAnswers must be positive'),
       assert(minAnswersForShare > 0, 'minAnswersForShare must be positive');

  /// Where the rates settle. Lower than the 15 the other engines use because
  /// this sample is split across the drugs the user takes: at 15 per drug a
  /// three-drug regimen would still read "preliminary" past a hundred attacks.
  static const int defaultMinAnswers = 10;

  /// Below this the row asks for counts instead of a percentage.
  static const int defaultMinAnswersForShare = 5;

  final int minAnswers;
  final int minAnswersForShare;

  MedicationEffectivenessResult analyze(List<Attack> attacks) {
    final Map<String, List<Attack>> byMedication = <String, List<Attack>>{};
    int answeredAttacks = 0;
    int timesTaken = 0;

    for (final Attack attack in attacks) {
      final String name = attack.medicationName?.trim() ?? '';

      if (name.isEmpty) {
        continue;
      }

      timesTaken++;
      if (attack.medicationEffect != null) {
        answeredAttacks++;
      }
      byMedication.putIfAbsent(name, () => <Attack>[]).add(attack);
    }

    // No answer anywhere means there is nothing to rank — the rows would all
    // be "taken 6 times, effect unknown", which is the prompt, not the answer.
    if (answeredAttacks == 0) {
      return MedicationEffectivenessInsufficientData(
        answeredAttacks: 0,
        requiredAnswers: minAnswers,
        timesTaken: timesTaken,
      );
    }

    final List<MedicationEffectiveness> medications = byMedication.entries
        .map((entry) => _summarise(entry.key, entry.value))
        .toList();

    // Most-used first, and never by relief rate: ranking by a rate puts the
    // drug taken twice above the one taken forty times.
    medications.sort((a, b) {
      final int byUse = b.timesTaken.compareTo(a.timesTaken);

      return byUse != 0 ? byUse : a.name.compareTo(b.name);
    });

    return MedicationEffectivenessInsight(
      answeredAttacks: answeredAttacks,
      requiredAnswers: minAnswers,
      medications: medications,
    );
  }

  MedicationEffectiveness _summarise(String name, List<Attack> attacks) {
    final List<int> intensities = <int>[];
    final List<Duration> durations = <Duration>[];
    int helped = 0;
    int partly = 0;
    int didNotHelp = 0;

    for (final Attack attack in attacks) {
      intensities.add(attack.intensity);

      final Duration? duration = attack.duration;

      if (duration != null) {
        durations.add(duration);
      }
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

    return MedicationEffectiveness(
      name: name,
      timesTaken: attacks.length,
      helpedCount: helped,
      partlyCount: partly,
      didNotHelpCount: didNotHelp,
      minAnswersForShare: minAnswersForShare,
      medianIntensity: _median(intensities),
      // The one median the app already owns, and it stays owned there —
      // duration arithmetic belongs to DateTimeUtils by house rule.
      medianDuration: DateTimeUtils.median(durations),
    );
  }

  /// Median, not mean: one attack at 10/10 among a dozen mild ones drags an
  /// average somewhere no attack actually was.
  double? _median(List<int> values) {
    if (values.isEmpty) {
      return null;
    }

    final List<int> sorted = List<int>.of(values)..sort();
    final int middle = sorted.length ~/ 2;

    return sorted.length.isOdd
        ? sorted[middle].toDouble()
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}
