import 'package:meta/meta.dart';

/// A medication the user takes; feeds the picker in the 3-tap log flow.
@immutable
class Medication {
  const Medication({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is Medication && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
