part of 'settings_screen.dart';

/// One way to reach a human, and the way into [AboutScreen] — which carries
/// the full feature list. Nothing else belongs here.
///
/// The About row's value is the same diagnostic string the version row used
/// to show on its own (env, version, build): a bug report still names its
/// build without anyone opening a screen.
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
          icon: AppIconConstant.email,
          title: l10n.settingsContactSupport,
          onTap: () => context.pushNamed(AppRoutes.contact.name),
        ),
        SettingsTile(
          icon: AppIconConstant.info,
          title: l10n.aboutTitle,
          value: AppVersionLabel.build(version),
          onTap: () => context.pushNamed(AppRoutes.about.name),
        ),
      ],
    );
  }
}
