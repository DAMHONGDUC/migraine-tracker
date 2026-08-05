part of 'settings_screen.dart';

/// Account, alerts, language. Anything about what the app *holds* goes in
/// [_DataSection] instead.
class _GeneralSection extends ConsumerWidget {
  const _GeneralSection();

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final AppLanguage current = AppLanguage.fromCode(
      ref.read(localeControllerProvider)?.languageCode,
    );

    // Inline: a LanguageSheet widget would wrap this and add nothing.
    final AppLanguage? picked = await showSdFilterSheetV2<AppLanguage>(
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
        // Only with an account: a subscription needs one to belong to.
        if (ref.watch(isSignedInProvider)) const PremiumSettingsTile(),
        const AlertsSettingsTile(),
        const HealthSection(),
        SettingsTile(
          icon: Icons.language,
          title: context.l10n.settingsLanguage,
          value: current.label(context),
          onTap: () => _pickLanguage(context, ref),
        ),
      ],
    );
  }
}

/// The domain enum stays pure Dart, so [Locale] and the label attach here.
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
