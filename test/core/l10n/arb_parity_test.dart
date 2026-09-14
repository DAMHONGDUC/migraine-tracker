import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The ARB files themselves, read off disk.
///
/// **A key missing from one locale is not a crash — it is a silent fall-through
/// to English**, which reads as a half-translated app rather than as a bug, and
/// nothing in a build or a normal test run notices. This is the only thing that
/// does.
void main() {
  const String templateLocale = 'en';
  const List<String> locales = <String>[
    'en',
    'vi',
    'ja',
    'de',
    'es',
    'fr',
    'zh',
  ];

  Map<String, dynamic> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;

  /// Message keys only — the `@`-prefixed entries are metadata, and only the template carries them.
  Set<String> messageKeys(Map<String, dynamic> file) =>
      file.keys.where((String key) => !key.startsWith('@')).toSet();

  final Map<String, Map<String, dynamic>> files =
      <String, Map<String, dynamic>>{
        for (final String locale in locales) locale: arb(locale),
      };

  test('every locale carries exactly the template\'s keys', () {
    final Set<String> template = messageKeys(files[templateLocale]!);

    expect(template, isNotEmpty);
    for (final String locale in locales) {
      final Set<String> keys = messageKeys(files[locale]!);

      expect(
        keys.difference(template),
        isEmpty,
        reason: '$locale has keys app_en.arb does not',
      );
      expect(
        template.difference(keys),
        isEmpty,
        reason: '$locale is missing keys and will fall through to English',
      );
    }
  });

  // A key nobody described is a key a translator has to guess at.
  test('every template key has a description', () {
    final Map<String, dynamic> template = files[templateLocale]!;

    for (final String key in messageKeys(template)) {
      expect(
        template['@$key'],
        isA<Map<String, dynamic>>(),
        reason: '$key has no @$key description in the template',
      );
    }
  });

  /// `{name}` placeholders, first appearance first — which is the order
  /// `gen_l10n` gives the generated method's positional parameters.
  ///
  /// `{count, plural, …}` counts too, and its body repeats the name, so the
  /// list is deduplicated rather than taken raw.
  List<String> placeholdersOf(String message) {
    final List<String> found = <String>[];

    for (final RegExpMatch match in RegExp(
      r'\{(\w+)\s*[,}]',
    ).allMatches(message)) {
      final String name = match.group(1)!;

      if (!found.contains(name)) found.add(name);
    }
    return found;
  }

  test('every locale uses the same placeholders as the template', () {
    final Map<String, dynamic> template = files[templateLocale]!;

    for (final String key in messageKeys(template)) {
      final Set<String> expected = placeholdersOf(
        template[key] as String,
      ).toSet();

      for (final String locale in locales) {
        expect(
          placeholdersOf(files[locale]![key] as String).toSet(),
          expected,
          reason:
              '$locale\'s $key uses different placeholders from the template, '
              'so it will throw or print the wrong value at runtime',
        );
      }
    }
  });

  // The trap this test exists for: the generated signature follows the TEMPLATE's order, so a call site written against the ARB's declaration order silently swaps arguments of the same type.
  test('the template declares placeholders in the order it uses them', () {
    final Map<String, dynamic> template = files[templateLocale]!;

    for (final String key in messageKeys(template)) {
      final Object? meta = template['@$key'];

      if (meta is! Map<String, dynamic>) continue;

      final Object? declared = meta['placeholders'];

      if (declared is! Map<String, dynamic>) continue;

      expect(
        declared.keys.toList(),
        placeholdersOf(template[key] as String),
        reason:
            '$key declares its placeholders in a different order from the '
            'message, which makes the generated parameter order surprising',
      );
    }
  });
}
