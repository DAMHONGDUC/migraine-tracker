import 'package:meta/meta.dart';

/// The three filter axes whose values are the user's own words rather than an enum, collected from every attack on record so the sheet offers only what.
@immutable
class AttackFilterOptions {
  const AttackFilterOptions({
    required this.medicationNames,
    required this.symptoms,
    required this.triggers,
  });

  /// Nothing recorded yet — the sheet draws no section for an empty list rather than a heading over nothing.
  static const AttackFilterOptions empty = AttackFilterOptions(
    medicationNames: <String>[],
    symptoms: <String>[],
    triggers: <String>[],
  );

  final List<String> medicationNames;
  final List<String> symptoms;
  final List<String> triggers;
}
