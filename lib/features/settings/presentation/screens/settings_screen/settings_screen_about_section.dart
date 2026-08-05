part of 'settings_screen.dart';

/// One diagnostic row (env, version, build in one string — always shown, no
/// gating), and one way to reach a human. Nothing else belongs here.
class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final InstalledAppVersion? version = ref
        .watch(installedAppVersionProvider)
        .value;

    return Column(
      children: [
        SettingsTile(
          icon: Icons.email_outlined,
          title: l10n.settingsContactSupport,
          onTap: () => context.pushNamed(AppRoutes.contact.name),
        ),
        SettingsTile(
          icon: Icons.info_outline,
          title: l10n.settingsAppVersion,
          value: AppVersionLabel.build(version),
        ),
      ],
    );
  }
}
