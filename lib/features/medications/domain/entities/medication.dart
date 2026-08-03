import 'package:meta/meta.dart';

/// A medication the user takes; feeds the picker in the 3-tap log flow and
/// the medications tab's list/filter/sort.
///
/// [name] is the only thing a medication needs — quick add saves one with
/// nothing else. The rest is what the details form (and the label scan that
/// pre-fills it) collects, all free text: a box says "500mg" or "2 tablets
/// twice a day" in a hundred shapes, and parsing that into structured fields
/// would be guessing at the user's medicine.
@immutable
class Medication {
  const Medication({
    required this.id,
    required this.name,
    this.createdAt,
    this.description,
    this.ingredients,
    this.strength,
    this.dosage,
    this.instructions,
  });

  final String id;
  final String name;

  /// When this was saved (UTC), or null for rows saved before schema v3 —
  /// their real creation date was never recorded. See the column doc on
  /// `Medications.createdAt` for why that's left null rather than guessed.
  final DateTime? createdAt;

  /// What it is, or what it is for, in the user's own words.
  final String? description;

  /// Active ingredients, e.g. "Sumatriptan succinate".
  final String? ingredients;

  /// How much per unit, e.g. "50 mg".
  final String? strength;

  /// How much to take, e.g. "1 tablet, twice a day".
  final String? dosage;

  /// How to take it, e.g. "After food, with water".
  final String? instructions;

  /// Whether anything beyond the name was filled in — what the detail screen
  /// asks before drawing its details section.
  bool get hasDetails =>
      description != null ||
      ingredients != null ||
      strength != null ||
      dosage != null ||
      instructions != null;

  // Identity is id + name only: createdAt and the optional fields are
  // display metadata, not part of what makes two medications "the same" —
  // keeping them out of equality means callers (tests included) can compare
  // medications without threading every field through.
  @override
  bool operator ==(Object other) =>
      other is Medication && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
