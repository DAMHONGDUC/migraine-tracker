import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../storage/secure_store.dart';

/// The user's language choice. `null` means "follow the system locale".
final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  static const _prefsKey = 'app_locale';

  @override
  Locale? build() {
    final String? code = ref.watch(secureStoreProvider).getString(_prefsKey);
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    final SecureStore store = ref.read(secureStoreProvider);
    if (locale == null) {
      await store.remove(_prefsKey);
    } else {
      await store.setString(_prefsKey, locale.languageCode);
    }
  }
}
