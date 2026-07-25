part of 'settings_screen.dart';

/// How the app behaves for you: who you are signed in as, whether pressure
/// alerts reach you, and which language it speaks. Anything that changes
/// what the app *holds* belongs in [_DataSection] instead.
class _GeneralSection extends ConsumerWidget {
  const _GeneralSection();

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final AppLanguage current = AppLanguage.fromCode(
      ref.read(localeControllerProvider)?.languageCode,
    );

    // The generic single-choice sheet, opened inline: a dedicated
    // LanguageSheet widget would be a wrapper with nothing of its own in it
    // (see CLAUDE.md § Code style).
    final AppLanguage? picked = await showAppFilterSheet<AppLanguage>(
      context,
      title: context.l10n.settingsLanguage,
      options: AppLanguage.values,
      selected: current,
      labelBuilder: (AppLanguage language) => language.label(context),
    );
    if (picked == null) return;

    await ref.read(localeControllerProvider.notifier).set(picked.locale);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLanguage current = AppLanguage.fromCode(
      ref.watch(localeControllerProvider)?.languageCode,
    );

    return Column(
      children: [
        const AccountSection(),
        const _AlertsSection(),
        ListTile(
          leading: const AppIcon(Icons.language),
          title: Text(context.l10n.settingsLanguage),
          subtitle: Text(current.label(context)),
          onTap: () => _pickLanguage(context, ref),
        ),
      ],
    );
  }
}

/// Presentation-side view of [AppLanguage]: the domain enum stays pure Dart,
/// so the Flutter [Locale] and the localized label are attached here.
extension _AppLanguageX on AppLanguage {
  Locale? get locale {
    final String? code = languageCode;

    return code == null ? null : Locale(code);
  }

  String label(BuildContext context) => switch (this) {
    AppLanguage.system => context.l10n.settingsLanguageSystem,
    AppLanguage.english => context.l10n.settingsLanguageEnglish,
    AppLanguage.vietnamese => context.l10n.settingsLanguageVietnamese,
  };
}
