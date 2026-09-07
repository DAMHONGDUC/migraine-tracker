part of 'settings_screen.dart';

/// One way to reach a human, and the way into [AboutScreen] — which carries the full feature list.
class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      children: [
        SettingsTile(
          icon: AppIconConstant.email,
          title: l10n.settingsContactSupport,
          onTap: () => context.pushNamed(AppRoutes.contact.name),
        ),
        SettingsTile(
          icon: AppIconConstant.info,
          title: l10n.aboutTitle,
          onTap: () => context.pushNamed(AppRoutes.about.name),
        ),
      ],
    );
  }
}
