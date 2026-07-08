import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _localeLabel(BuildContext context, Locale? locale) =>
      switch (locale?.languageCode) {
        'en' => context.l10n.settingsLanguageEnglish,
        'vi' => context.l10n.settingsLanguageVietnamese,
        _ => context.l10n.settingsLanguageSystem,
      };

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(localeControllerProvider);
    final selected = await showDialog<_LanguageChoice>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: [
          for (final (choice, label) in [
            (const _LanguageChoice(null), l10n.settingsLanguageSystem),
            (
              const _LanguageChoice(Locale('en')),
              l10n.settingsLanguageEnglish,
            ),
            (
              const _LanguageChoice(Locale('vi')),
              l10n.settingsLanguageVietnamese,
            ),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(choice),
              child: Row(
                children: [
                  Icon(
                    choice.locale?.languageCode == current?.languageCode
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(label),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected != null) {
      await ref.read(localeControllerProvider.notifier).set(selected.locale);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_localeLabel(context, locale)),
            onTap: () => _pickLanguage(context, ref),
          ),
        ],
      ),
    );
  }
}

/// Wrapper so the dialog can distinguish "picked System (null)" from
/// "dismissed without picking".
class _LanguageChoice {
  const _LanguageChoice(this.locale);

  final Locale? locale;
}
