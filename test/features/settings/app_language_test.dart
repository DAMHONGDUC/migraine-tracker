import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_tracker/features/settings/domain/enums/app_language.dart';
import 'package:migraine_tracker/l10n/gen/app_localizations.dart';

void main() {
  group('AppLanguage', () {
    test('every offered language has translations shipped for it', () {
      final Set<String> supported = AppLocalizations.supportedLocales
          .map((Locale locale) => locale.languageCode)
          .toSet();
      final List<String> offered = AppLanguage.values
          .map((AppLanguage language) => language.languageCode)
          .nonNulls
          .toList();

      expect(offered, isNotEmpty);
      expect(supported.containsAll(offered), isTrue);
    });

    test('every shipped translation is offered in the picker', () {
      final Set<String?> offered = AppLanguage.values
          .map((AppLanguage language) => language.languageCode)
          .toSet();

      for (final Locale locale in AppLocalizations.supportedLocales) {
        expect(
          offered,
          contains(locale.languageCode),
          reason: '${locale.languageCode} has an ARB but no picker entry',
        );
      }
    });

    test('an unknown or absent code falls back to system', () {
      expect(AppLanguage.fromCode(null), AppLanguage.system);
      expect(AppLanguage.fromCode('xx'), AppLanguage.system);
      expect(AppLanguage.fromCode('ja'), AppLanguage.japanese);
    });
  });
}
