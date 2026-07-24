import 'package:meta/meta.dart';

/// A medication the user takes; feeds the picker in the 3-tap log flow and
/// the medications tab's list/filter/sort.
@immutable
class Medication {
  const Medication({required this.id, required this.name, this.createdAt});

  final String id;
  final String name;

  /// When this was saved (UTC), or null for rows saved before schema v3 —
  /// their real creation date was never recorded. See the column doc on
  /// `Medications.createdAt` for why that's left null rather than guessed.
  final DateTime? createdAt;

  // Identity is id + name only: createdAt is display/sort metadata, not part
  // of what makes two medications "the same" — keeping it out of equality
  // means callers (tests included) can compare medications without also
  // having to thread a timestamp through.
  @override
  bool operator ==(Object other) =>
      other is Medication && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
