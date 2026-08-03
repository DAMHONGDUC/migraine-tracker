import 'package:meta/meta.dart';

/// What the details form holds while it is being filled in: a name and the
/// five optional fields, before any of it is a saved [Medication].
///
/// It is also what a label scan produces — the scan never writes anything, it
/// only proposes a draft the user then edits and saves.
@immutable
class MedicationDraft {
  const MedicationDraft({
    this.name,
    this.description,
    this.ingredients,
    this.strength,
    this.dosage,
    this.instructions,
  });

  final String? name;
  final String? description;
  final String? ingredients;
  final String? strength;
  final String? dosage;
  final String? instructions;

  /// Whether the scan found anything worth pre-filling.
  bool get isEmpty =>
      name == null &&
      description == null &&
      ingredients == null &&
      strength == null &&
      dosage == null &&
      instructions == null;
}
