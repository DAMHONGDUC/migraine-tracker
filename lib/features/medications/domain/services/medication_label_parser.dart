import '../entities/medication_draft.dart';

/// Turns the lines read off a medicine box into a [MedicationDraft].
///
/// Pure Dart and deliberately timid: it proposes, the user confirms. A box
/// is not a form — the same line can be a brand, a salt and a strength — so
/// this only claims what a label reliably marks, and leaves everything else
/// for the person holding the box. Nothing here is medical advice, and
/// nothing is saved without the user pressing save.
final class MedicationLabelParser {
  const MedicationLabelParser();

  /// A strength on a label is a number glued to a unit: "500mg", "50 MG",
  /// "1.5 ml", "2,5 g". Anchored to a word boundary so a batch number like
  /// "L20250416" never reads as 2025 mg.
  static final RegExp _strength = RegExp(
    r'\b(\d+(?:[.,]\d+)?)\s*(mg|mcg|µg|ug|g|ml|iu)\b',
    caseSensitive: false,
  );

  /// Lines that label a field rather than being one. The value may follow the
  /// colon on the same line, or sit on the next line.
  static const Map<String, _Field> _labels = <String, _Field>{
    'ingredient': _Field.ingredients,
    'ingredients': _Field.ingredients,
    'active ingredient': _Field.ingredients,
    'active ingredients': _Field.ingredients,
    'composition': _Field.ingredients,
    'thanh phan': _Field.ingredients,
    'dosage': _Field.dosage,
    'dose': _Field.dosage,
    'lieu dung': _Field.dosage,
    'directions': _Field.instructions,
    'usage': _Field.instructions,
    'how to use': _Field.instructions,
    'cach dung': _Field.instructions,
  };

  /// Longest a scanned value may be before it is more likely a paragraph of
  /// small print than the field it was labelled as.
  static const int _maxValueLength = 120;

  MedicationDraft parse(List<String> lines) {
    final List<String> cleaned = <String>[
      for (final String line in lines)
        if (line.trim().isNotEmpty) line.trim(),
    ];

    if (cleaned.isEmpty) return const MedicationDraft();

    final Map<_Field, String> found = <_Field, String>{};

    for (int i = 0; i < cleaned.length; i++) {
      final _Labelled? labelled = _labelledValue(cleaned, i);

      if (labelled == null) continue;
      found.putIfAbsent(labelled.field, () => labelled.value);
    }

    return MedicationDraft(
      // The name is the first line that is not itself a labelled field: on a
      // box the brand is printed biggest and first, and reading order puts it
      // at the top.
      name: _name(cleaned),
      ingredients: found[_Field.ingredients],
      strength: _strengthIn(cleaned),
      dosage: found[_Field.dosage],
      instructions: found[_Field.instructions],
    );
  }

  /// The first line that reads like a product name rather than a field label
  /// or a bare measurement.
  String? _name(List<String> lines) {
    for (final String line in lines) {
      final String normalized = _normalize(line);

      if (_labels.keys.any((String label) => normalized.startsWith(label))) {
        continue;
      }
      // A line that is nothing but a strength ("500 mg") names nothing.
      if (_strength.stringMatch(line)?.length == line.length) continue;
      if (line.length < 2 || line.length > _maxValueLength) continue;

      return line;
    }
    return null;
  }

  /// The first strength anywhere in the text — including inside the name
  /// line, where boxes usually print it ("Panadol Extra 500mg").
  String? _strengthIn(List<String> lines) {
    for (final String line in lines) {
      final RegExpMatch? match = _strength.firstMatch(line);

      if (match != null) return match.group(0)!.trim();
    }
    return null;
  }

  /// The value for a labelled line: after the colon when there is one, else
  /// the next line down.
  _Labelled? _labelledValue(List<String> lines, int index) {
    final String line = lines[index];
    final int colon = line.indexOf(':');
    final String head = _normalize(
      colon >= 0 ? line.substring(0, colon) : line,
    );
    final _Field? field = _labels[head];

    if (field == null) return null;

    final String inline = colon >= 0 ? line.substring(colon + 1).trim() : '';
    final String value = inline.isNotEmpty
        ? inline
        : (index + 1 < lines.length ? lines[index + 1] : '');

    if (value.isEmpty || value.length > _maxValueLength) return null;
    return _Labelled(field, value);
  }

  /// Lower-cased, punctuation- and accent-free, so "Thành phần:" and
  /// "ACTIVE INGREDIENTS" both match their key.
  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[àáảãạăằắẳẵặâầấẩẫậ]'), 'a')
      .replaceAll(RegExp('[èéẻẽẹêềếểễệ]'), 'e')
      .replaceAll(RegExp('[ìíỉĩị]'), 'i')
      .replaceAll(RegExp('[òóỏõọôồốổỗộơờớởỡợ]'), 'o')
      .replaceAll(RegExp('[ùúủũụưừứửữự]'), 'u')
      .replaceAll(RegExp('[ỳýỷỹỵ]'), 'y')
      .replaceAll('đ', 'd')
      .replaceAll(RegExp('[^a-z0-9 ]'), '')
      .replaceAll(RegExp(' +'), ' ')
      .trim();
}

/// Which draft field a labelled line fills.
enum _Field { ingredients, dosage, instructions }

/// A label line and the value read off it.
class _Labelled {
  const _Labelled(this.field, this.value);

  final _Field field;
  final String value;
}
