part of 'settings_screen.dart';

/// App-wide preferences. Just the language today; this is where anything
/// that changes how the app behaves rather than what it holds belongs.
class _GeneralSection extends ConsumerWidget {
  const _GeneralSection();

  String _localeLabel(BuildContext context, Locale? locale) =>
      switch (locale?.languageCode) {
        'en' => context.l10n.settingsLanguageEnglish,
        'vi' => context.l10n.settingsLanguageVietnamese,
        _ => context.l10n.settingsLanguageSystem,
      };

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(localeControllerProvider);
    final selected = await showAppDialog<_LanguageChoice>(
      context,
      builder: (dialogContext) => AppDialog(
        title: l10n.settingsLanguage,
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
              AppDialogOption(
                label: label,
                selected: choice.locale?.languageCode == current?.languageCode,
                onTap: () => Navigator.of(dialogContext).pop(choice),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await ref.read(localeControllerProvider.notifier).set(selected.locale);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);

    return ListTile(
      leading: const AppIcon(Icons.language),
      title: Text(context.l10n.settingsLanguage),
      subtitle: Text(_localeLabel(context, locale)),
      onTap: () => _pickLanguage(context, ref),
    );
  }
}

/// Wrapper so the dialog can distinguish "picked System (null)" from
/// "dismissed without picking".
class _LanguageChoice {
  const _LanguageChoice(this.locale);

  final Locale? locale;
}
